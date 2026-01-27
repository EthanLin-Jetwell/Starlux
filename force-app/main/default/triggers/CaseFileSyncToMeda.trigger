trigger CaseFileSyncToMeda on ContentDocumentLink (after insert) {
    // 允許的 Case Record Type 名稱（若多語系，建議改用 DeveloperName）
    Set<String> allowedRtNames = new Set<String>{
        'First Class','Reservation and Ticketing','Feedback','Enquiry and Request'
    };

    // 1) 收集這批 CDL：分成「直接掛 Case」與「掛 EmailMessage」
    Set<Id> directCaseIds = new Set<Id>();                // 500*
    Set<Id> emailMsgIds   = new Set<Id>();                // 02s*
    Map<Id, Id> docToCase = new Map<Id, Id>();            // ContentDocumentId -> CaseId（先放直接掛 Case 的）
    Map<Id, Id> docToEmail= new Map<Id, Id>();            // ContentDocumentId -> EmailMessageId（待轉 Case）

    for (ContentDocumentLink cdl : Trigger.new) {
        if (cdl.LinkedEntityId == null || cdl.ContentDocumentId == null) continue;
        String key = String.valueOf(cdl.LinkedEntityId);
        if (key.startsWith('500')) { // Case
            directCaseIds.add(cdl.LinkedEntityId);
            docToCase.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
        } else if (key.startsWith('02s')) { // EmailMessage
            emailMsgIds.add(cdl.LinkedEntityId);
            docToEmail.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
        }
    }
    if (directCaseIds.isEmpty() && emailMsgIds.isEmpty()) return;

    // 2) 若有 EmailMessage，追溯到它的 ParentId（通常是 Case）
    Set<Id> emailParentCaseIds = new Set<Id>();
    Map<Id, Id> emailToCase = new Map<Id, Id>(); // EmailMessageId -> CaseId
    if (!emailMsgIds.isEmpty()) {
        for (EmailMessage em : [
            SELECT Id, ParentId
            FROM EmailMessage
            WHERE Id IN :emailMsgIds AND ParentId != null
        ]) {
            if (String.valueOf(em.ParentId).startsWith('500')) {
                emailToCase.put(em.Id, em.ParentId);
                emailParentCaseIds.add(em.ParentId);
            }
        }
        // 將「EmailMessage 對應的 Case」併入 docToCase
        for (Id docId : docToEmail.keySet()) {
            Id emId = docToEmail.get(docId);
            Id caseId = emailToCase.get(emId);
            if (caseId != null) {
                docToCase.put(docId, caseId);
            }
        }
    }

    // 3) 匯總本次涉及的 Case
    Set<Id> allCaseIds = new Set<Id>();
    allCaseIds.addAll(directCaseIds);
    allCaseIds.addAll(emailParentCaseIds);
    if (allCaseIds.isEmpty()) return;

    // 4) 過濾：只保留指定 Record Type 的 Case
    Set<Id> allowedCaseIds = new Set<Id>();
    for (Case c : [
        SELECT Id, RecordType.Name
        FROM Case
        WHERE Id IN :allCaseIds
    ]) {
        if (allowedRtNames.contains(c.RecordType.Name)) {
            allowedCaseIds.add(c.Id);
        }
    }
    if (allowedCaseIds.isEmpty()) return;

    // 5) 針對允許的 Case，找「要同步到的 MEDA」
    //    若同一 Case 有多筆 MEDA，取最新建立的一筆
    List<MEDA_Approval__c> medaAll = [
        SELECT Id, Case__c, CreatedDate
        FROM MEDA_Approval__c
        WHERE Case__c IN :allowedCaseIds
        ORDER BY Case__c, CreatedDate DESC
    ];
    if (medaAll.isEmpty()) return;

    Map<Id, MEDA_Approval__c> medaByCase = new Map<Id, MEDA_Approval__c>(); // CaseId -> 最新 MEDA
    for (MEDA_Approval__c m : medaAll) {
        if (!medaByCase.containsKey(m.Case__c)) {
            medaByCase.put(m.Case__c, m);
        }
    }
    if (medaByCase.isEmpty()) return;

    // 6) 計算每個 MEDA 目前已有幾個檔案（決定下一個 MEDA-n）
    Set<Id> medaIds = new Set<Id>();
    for (MEDA_Approval__c m : medaByCase.values()) medaIds.add(m.Id);

    Map<Id, Integer> medaFileCount = new Map<Id, Integer>();
    for (AggregateResult ar : [
        SELECT LinkedEntityId medaId, COUNT(Id) cnt
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN :medaIds
        GROUP BY LinkedEntityId
    ]) {
        medaFileCount.put((Id) ar.get('medaId'), (Integer) ar.get('cnt'));
    }

    // 7) 這批要處理的文件 = 本次 insert 的 CDL 中，能對應到「允許的 Case」的那些 Document
    Set<Id> targetDocIds = new Set<Id>();
    Map<Id, Id> targetDocToCase = new Map<Id, Id>(); // 只保留符合條件者
    for (Id docId : docToCase.keySet()) {
        Id caseId = docToCase.get(docId);
        if (allowedCaseIds.contains(caseId) && medaByCase.containsKey(caseId)) {
            targetDocIds.add(docId);
            targetDocToCase.put(docId, caseId);
        }
    }
    if (targetDocIds.isEmpty()) return;

    // 8) 查最新版本內容（含 VersionData）
    List<ContentVersion> latestVersions = [
        SELECT Id, ContentDocumentId, Title, FileExtension, VersionData
        FROM ContentVersion
        WHERE IsLatest = true AND ContentDocumentId IN :targetDocIds
    ];
    Map<Id, ContentVersion> cvByDoc = new Map<Id, ContentVersion>(); // ContentDocumentId -> CV
    for (ContentVersion cv : latestVersions) {
        cvByDoc.put(cv.ContentDocumentId, cv);
    }

    // 9) 複製到對應 MEDA，命名為 MEDA-(N+1)
    List<ContentVersion> toInsert = new List<ContentVersion>();
    for (Id docId : targetDocIds) {
        Id caseId = targetDocToCase.get(docId);
        MEDA_Approval__c meda = medaByCase.get(caseId);
        if (meda == null) continue;

        Integer seq = medaFileCount.containsKey(meda.Id) ? medaFileCount.get(meda.Id) : 0;
        seq++; // 下一號
        medaFileCount.put(meda.Id, seq);

        ContentVersion src = cvByDoc.get(docId);
        if (src == null) continue;

        String ext = (src.FileExtension == null) ? '' : '.' + src.FileExtension;
        String title = 'MEDA-' + String.valueOf(seq);

        toInsert.add(new ContentVersion(
            Title = title,
            PathOnClient = title + ext,
            VersionData = src.VersionData,
            FirstPublishLocationId = meda.Id
        ));
    }

    if (!toInsert.isEmpty()) {
        insert toInsert;
    }
}