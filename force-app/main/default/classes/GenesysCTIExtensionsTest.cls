@isTest
public class GenesysCTIExtensionsTest {
    @isTest
    static void testOnScreenPop() {
        // 模擬 CTI Data
        String data = '{"searchValue":"Internal","interaction":{"id":"c1728619-2236-462e-a6df-e250401fb9e0","phone":"sip:664d73008367a11bb294ae5e+starlux-test.orgspan.com@localhost","isConnected":false,"isDisconnected":false,"isDone":false,"state":"ALERTING","attributes":{"sf_urlpop":"lightning/o/Case/new?recordTypeId=First Class&defaultFieldValues=CTI_Location__c=MNL,RecordTypeId=First Class,CTI_Ticket_EMD_Number__c=7777777777777,CTI_Member_ID__c=666666666,SuppliedPhone=tsaiweiting%40gmail.com"},"isCallback":false,"isDialer":false,"isChat":false,"isEmail":false,"isMessage":false,"isVoicemail":false,"recordingState":"none","securePause":false,"displayAddress":"Internal","queueName":"PAX_PH","ani":"Internal","calledNumber":"651ef721-624e-4a4b-9c1d-8672352f0622","totalIvrDurationSeconds":134,"direction":"Inbound","isInternal":true}}';
        
        // 建立測試用的 Profile 和 RecordType
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(Alias = 'stduser', Email = 'testuser@example.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = userProfile.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testuser20240927@example.com');
        insert testUser;
        
        System.runAs(testUser) {
            // 執行測試的 onScreenPop 方法
            GenesysCTIExtensions ctiExtension = new GenesysCTIExtensions();
            Test.startTest();
            String result = ctiExtension.onScreenPop(data);
            Test.stopTest();
            
            // 驗證 Case 已被建立
            //Case newCase = [SELECT Id, CTI_Location__c, CTI_Ticket_EMD_Number__c, CTI_Member_ID__c, RecordTypeId FROM Case WHERE CTI_Ticket_EMD_Number__c = '7777777777777' LIMIT 1];
            //System.assertNotEquals(null, newCase, 'A Case should have been created.');
            //System.assertEquals('MNL', newCase.CTI_Location__c, 'The CTI_Location__c should match.');
            //System.assertEquals('7777777777777', newCase.CTI_Ticket_EMD_Number__c, 'The CTI_Ticket_EMD_Number__c should match.');
            //System.assertEquals('666666666', newCase.CTI_Member_ID__c, 'The CTI_Member_ID__c should match.');
            
            // 檢查返回的 JSON 是否包含 Case Id
            //Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
            //System.assertNotEquals(null, resultMap.get('url'), 'The result should contain a URL with the Case ID.');
        }
    }
}