public class MEDAApprovalFileCopyHandler {

    // 可維護的允許 Record Type 名稱（使用「標籤名稱」比對）
    private static final Set<String> ALLOWED_CASE_RT_NAMES = new Set<String>{
        'First Class',
        'Reservation and Ticketing',
        'Feedback',
        'Enquiry and Request'
    };

    public static void copyCaseFilesToMeda(List<MEDA_Approval__c> newMedas) {
        if (newMedas == null || newMedas.isEmpty()) {
            return;
        }

        // 收集所有有指到 Case 的 MEDA
        Set<Id> caseIds = new Set<Id>();
        Map<Id, List<Id>> caseIdToMedaIds = new Map<Id, List<Id>>();
        for (MEDA_Approval__c m : newMedas) {
            if (m.Case__c != null) {
                caseIds.add(m.Case__c);
                if (!caseIdToMedaIds.containsKey(m.Case__c)) {
                    caseIdToMedaIds.put(m.Case__c, new List<Id>());
                }
                caseIdToMedaIds.get(m.Case__c).add(m.Id);
            }
        }
        if (caseIds.isEmpty()) {
            return;
        }

        // 只挑 Record Type 符合者
        Map<Id, Case> allowedCasesById = new Map<Id, Case>(
            [SELECT Id, RecordType.Name
             FROM Case
             WHERE Id IN :caseIds AND RecordType.Name IN :ALLOWED_CASE_RT_NAMES]
        );
        if (allowedCasesById.isEmpty()) {
            return;
        }

        // 找到符合者之 Case 的所有檔案連結
        List<ContentDocumentLink> cdlList = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :allowedCasesById.keySet()
        ];
        if (cdlList.isEmpty()) {
            return;
        }

        // 針對這些檔案，抓「最新版本」的 ContentVersion（取得 VersionData 以便複製）
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdlList) {
            if (cdl.ContentDocumentId != null) {
                docIds.add(cdl.ContentDocumentId);
            }
        }
        if (docIds.isEmpty()) {
            return;
        }

        // 最新版本：用 IsLatest = true
        Map<Id, ContentVersion> latestVersionByDoc = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
        SELECT Id, ContentDocumentId, Title, PathOnClient, VersionData
        FROM ContentVersion
        WHERE ContentDocumentId IN :docIds AND IsLatest = true
        ]) {
    latestVersionByDoc.put(cv.ContentDocumentId, cv);
}

        // 針對「每一個 MEDA 」×「每一個 Case 檔案」建立新的 ContentVersion（產生新 ContentDocument）
        List<ContentVersion> versionsToInsert = new List<ContentVersion>();

        for (ContentDocumentLink sourceLink : cdlList) {
            Id parentCaseId = sourceLink.LinkedEntityId;
            if (!allowedCasesById.containsKey(parentCaseId)) {
                continue;
            }
            ContentVersion src = latestVersionByDoc.get(sourceLink.ContentDocumentId);
            if (src == null) {
                continue;
            }

            List<Id> medaIds = caseIdToMedaIds.get(parentCaseId);
            if (medaIds == null || medaIds.isEmpty()) {
                continue;
            }

            // 複製到該 Case 之下所有「剛新建」的 MEDA
            for (Id medaId : medaIds) {
                ContentVersion cloneCv = new ContentVersion();
                cloneCv.Title = src.Title;                 // 你也可以在這裡改名，例如：'MEDA - ' + src.Title
                cloneCv.PathOnClient = src.PathOnClient != null ? src.PathOnClient : ('/' + src.Title);
                cloneCv.VersionData = src.VersionData;     // 關鍵：真正複製檔案位元資料
                cloneCv.FirstPublishLocationId = medaId;   // 首次發佈位置＝MEDA → 會自動建立新 ContentDocument 並連結到 MEDA
                versionsToInsert.add(cloneCv);
            }
        }

        if (!versionsToInsert.isEmpty()) {
            insert versionsToInsert;
        }
    }
}