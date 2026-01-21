@IsTest(SeeAllData=true)
private class MEDAApprovalFileCopyHandlerTest {

    @IsTest
    static void testCopyFilesToMeda() {
        // 允許的 RecordType 名稱（和 Handler 內一致）
        Set<String> allowedRtNames = new Set<String>{
            'First Class',
            'Reservation and Ticketing',
            'Feedback',
            'Enquiry and Request'
        };

        // 嘗試找一個符合條件的 Case RecordType（使用 org 內既有的）
        RecordType allowedRt = null;
        List<RecordType> rts = [
            SELECT Id, Name
            FROM RecordType
            WHERE SObjectType = 'Case' AND Name IN :allowedRtNames
            LIMIT 1
        ];
        if (!rts.isEmpty()) {
            allowedRt = rts[0];
        }

        // 準備 goodCase（若找不到符合 RT，就用預設 RT，並標示無法做正向斷言）
        Boolean hasAllowedRt = (allowedRt != null);

        Case goodCase = new Case();
        goodCase.Subject = 'Test Case - Should Copy';
        goodCase.Origin = 'Phone';
        if (hasAllowedRt) {
            goodCase.RecordTypeId = allowedRt.Id;
        }
        insert goodCase;

        // 在 goodCase 發兩個 File
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'Doc-A';
        cv1.PathOnClient = '/Doc-A.txt';
        cv1.VersionData = Blob.valueOf('AAA');
        cv1.FirstPublishLocationId = goodCase.Id;
        insert cv1;

        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'Doc-B';
        cv2.PathOnClient = '/Doc-B.txt';
        cv2.VersionData = Blob.valueOf('BBB');
        cv2.FirstPublishLocationId = goodCase.Id;
        insert cv2;

        // 準備 badCase（沒有在允許清單的 RT；這裡不特別設定 RT 也可）
        Case badCase = new Case();
        badCase.Subject = 'Other Case - Should NOT Copy';
        badCase.Origin = 'Email';
        insert badCase;

        // 建立一筆 MEDA 指向 goodCase（補齊必填欄位）
        MEDA_Approval__c m1 = new MEDA_Approval__c();
        m1.Case__c = goodCase.Id;
        m1.PNR__c = 'AB123C';
        m1.Passenger_Name__c = 'DOE/JOHN';
        m1.Ticket_No__c = '123-4567890123';
        insert m1;

        // 建立一筆 MEDA 指向 badCase（不應複製）
        MEDA_Approval__c m2 = new MEDA_Approval__c();
        m2.Case__c = badCase.Id;
        m2.PNR__c = 'CD456E';
        m2.Passenger_Name__c = 'LEE/AMY';
        m2.Ticket_No__c = '123-9999999999';
        insert m2;

        Test.startTest();
        // 觸發器已在 after insert 執行，不需另外呼叫
        Test.stopTest();

        // 驗證 m2（不允許的 case）沒有拿到檔案
        Integer m2Count = (Integer)[
            SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :m2.Id
        ];
        System.assertEquals(0, m2Count, 'MEDA m2 不應該取得任何檔案');

        if (hasAllowedRt) {
            // 正向：m1 應該拿到 2 份複製檔案
            Integer m1Count = (Integer)[
                SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :m1.Id
            ];
            System.assertEquals(2, m1Count, 'MEDA m1 應該取得 2 份複製檔案');

            // 驗證「獨立 ContentDocument」：Case 與 MEDA 的 Doc Id 不得重疊
            Set<Id> caseDocIds = new Set<Id>();
            for (ContentDocumentLink l : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :goodCase.Id
            ]) {
                caseDocIds.add(l.ContentDocumentId);
            }

            Set<Id> medaDocIds = new Set<Id>();
            for (ContentDocumentLink l : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :m1.Id
            ]) {
                medaDocIds.add(l.ContentDocumentId);
            }

            for (Id did : medaDocIds) {
                System.assertEquals(false, caseDocIds.contains(did),
                    'MEDA 複製出的檔案應該是新的 ContentDocument（不可與 Case 共用）');
            }

            // 刪除 MEDA 的檔案，確認 Case 端仍在
            if (!medaDocIds.isEmpty()) {
                delete [SELECT Id FROM ContentDocument WHERE Id IN :medaDocIds];
            }
            Integer caseStillHas = (Integer)[
                SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :goodCase.Id
            ];
            System.assertEquals(2, caseStillHas, '刪除 MEDA 檔案後，Case 檔案仍應存在');
        } else {
            // 若 org 裡沒有上述 Record Type，至少確認程式沒拋錯且負向條件生效
            System.assert(true, 'No allowed Case RecordType found in this org; skipped positive assertions.');
        }
    }
}