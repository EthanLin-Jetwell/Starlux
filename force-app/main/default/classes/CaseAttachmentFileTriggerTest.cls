@isTest
public class CaseAttachmentFileTriggerTest {
    @isTest
    static void testCaseFileTriggerWithGroupBookingAndApiUser() {
        // 建立 RecordType
        Id rtId = [SELECT Id FROM RecordType WHERE SObjectType='Case' AND DeveloperName='Group_Booking' LIMIT 1].Id;

        // 建立 Case
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            RecordTypeId = rtId
        );
        insert c;

        // 模擬 API User（用 System.runAs）
        User apiUser = [SELECT Id FROM User WHERE Username LIKE 'apiuser@starlux-airlines.com%' LIMIT 1];
        System.runAs(apiUser) {
            ContentVersion cv = new ContentVersion(
                Title = 'Test File',
                PathOnClient = 'TestFile.txt',
                VersionData = Blob.valueOf('Sample file body')
            );
            insert cv;

            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId = c.Id,
                ShareType = 'V'
            );
            insert cdl;
        }

        Test.startTest();
        // 重新查詢 Case，觸發後應該有更新
        Case updated = [SELECT Id, Has_Attachment__c FROM Case WHERE Id = :c.Id];
        Test.stopTest();

        System.assertEquals(true, updated.Has_Attachment__c, 'Has_Attachment__c should be true');
    }
}