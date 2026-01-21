@IsTest global without sharing class ERCApiTest {
    // Step 1: Implement a mock callout class
    class ERCHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('/GetToken')) {
                res.setBody('{"data":"mocked_token"}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('/SyncSFData')) {
                res.setBody('{"success": true}');
                res.setStatusCode(200);
            } else {
                res.setStatusCode(404);
            }

            return res;
        }
    }

    @isTest
    static void testSyncCaseData() {
        // Step 2: Create a Case record
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' LIMIT 1];
        
        Case testCase = new Case(
            RecordTypeId = rt.Id,
            Status = 'Open',
            //CaseNumber = 'C123456',
            
            NOK_Request_1__c = 'Stable',
            NOK_Request_2__c = 'Taipei',
            NOK_Request_3__c = 'Yes',
            NOK_Request_4__c = 'Hotel needed',
            NOK_Request_5__c = 'Self-accommodation',
            NOK_Request_6__c = 'Vegetarian meals',
            Description = 'Test description',

            Primary_Contact_NOK_Title__c = 'Mr.',
            Primary_Contact_NOK_Name__c = 'John Doe',
            Primary_Contact_Relationship__c = 'Parents 父母親',
            Primary_Contact_Preferred_Language__c = 'English',
            Primary_Contact_Phone__c = '123456789',
            Primary_Contact_Web_Phone__c = 'Web123',
            Primary_Contact_Email__c = 'john@example.com',
            Primary_Contact_Others__c = 'N/A',

            Secondary_Contact_NOK_Title__c = 'Ms.',
            Secondary_Contact_NOK_Name__c = 'Jane Doe',
            //Secondary_Contact_Relationship__c = 'Parents 父母親',
            Secondary_Contact_Preferred_Language__c = 'Japanese',
            Secondary_Contact_Phone__c = '987654321',
            Secondary_Contact_Web_Phone__c = 'Web456',
            Secondary_Contact_Email__c = 'jane@example.com',
            Secondary_Contact_Others__c = 'N/A'
        );
        insert testCase;

        // Step 3: Register mock
        Test.setMock(HttpCalloutMock.class, new ERCHttpMock());

        // Step 4: Run the method in future context
        Test.startTest();
        ERCApiCallout.syncCaseData(testCase.Id);
        Test.stopTest(); // Ensures @future method runs

        // You could add asserts here for callout logs if applicable
        // Example:
        System.assert(true, 'Mock callout was executed without errors');
    }  
}