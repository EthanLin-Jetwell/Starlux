@IsTest
private class GetPurchaseScheduleTest {

    // ─────────────────────────────
    // 1. Mock HTTP Response
    // ─────────────────────────────
    private class MockGetPurchaseResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = JSON.serialize(new Map<String, Object>{
                'success' => true,
                'traceId' => 'trace001',
                'message' => new Map<String, Object>{
                    'code' => '00000',
                    'content' => 'Success',
                    'details' => new List<String>{}
                },
                'data' => new Map<String, Object>{
                    'status' => 'ok',
                    'recordId' => 'rec001'
                }
            });
            res.setBody(body);
            return res;
        }
    }

    // ─────────────────────────────
    // 2. Test Setup — Create Accounts and Cases
    // ─────────────────────────────
    @testSetup
    static void setup() {
        // Account RecordType = Passenger
        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        Id paymentRecordTypeId = Schema.SObjectType.Payment_Deposit_Fine_Details__c.getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId();

        // Create Passenger Account
        Map<String, Object> accMap = new Map<String, Object>{
            'RecordTypeId' => accountRecordTypeId,
            'FirstName' => 'Harry',
            'LastName' => 'Potter',
            'PersonEmail' => 'test@email.com',
            'PersonMobilePhone' => '1-111-1111',
            'Business_Number__c' => '12345678'
        };
        TestUtility.createAccounts(accMap, 1);
        List<String > accountQueryFieldsList = new List<String> {
        };        
        List<Account> testAccounts = TestUtility.getAccounts();
        Account acc = testAccounts[0];

        // Create Case (Yesterday, Ticket Issued)
        Map<String, Object> caseMap = new Map<String, Object>{
            'RecordTypeId' => caseRecordTypeId,
            'Status' => 'Waiting For Payment',
            'AccountId' => acc.Id,
            'Departing_Flight_Date__c' => System.today()
        };
        TestUtility.createCases(caseMap, 1);
        List<String > caseQueryFieldsList = new List<String> {
        };        
        List<Case> testCases = TestUtility.getCases();
        Case c = testCases[0];

        Payment_Deposit_Fine_Details__c pay = new Payment_Deposit_Fine_Details__c(
            RecordTypeId = paymentRecordTypeId,
            Case_ID__c = c.Id,
            Account_ID__c = acc.Id,
            Purpose__c = 'Issue Ticket'
        );
        
        insert pay;
        
        // Create related Seat_Allocation_and_Ticketing__c record
        Seat_Allocation_and_Ticketing__c sat = new Seat_Allocation_and_Ticketing__c(
            Case_ID__c = c.Id,
            Allocation_Type__c = 'ADC',
            Final_Allocated_Seats__c = 2,
            Booking_Reference_PNR__c = 'PNR001'
        );
        //insert sat;
        
        c.Status = 'Ticket Issued';
        update c;
    }

    @IsTest 
    static void testWrapper() {
        // Instantiate the wrapper
        GetPurchaseResponseWrapper wrapper = new GetPurchaseResponseWrapper();

        // Populate inner classes
        wrapper.success = true;
        wrapper.traceId = '12345';
        
        wrapper.data = new GetPurchaseResponseWrapper.Data();
        wrapper.data.status = 'Completed';
        wrapper.data.recordId = 'abc123';
        
        wrapper.message = new GetPurchaseResponseWrapper.Message();
        wrapper.message.code = '200';
        wrapper.message.content = 'OK';
        wrapper.message.details = new List<String>{'Detail1', 'Detail2'};

        wrapper.links = null;
        wrapper.meta = null;

        // Optional: assert values to make it meaningful
        System.assertEquals(true, wrapper.success);
        System.assertEquals('abc123', wrapper.data.recordId);
    }

    @IsTest
    static void testGetPurchaseInvocableMethod() {
        Test.setMock(HttpCalloutMock.class, new MockGetPurchaseResponse());
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        GetPurchaseInvocableMethod.getPurchase(new List<Id>{ testCase.Id });
        Test.stopTest();

        Case updatedCase = [SELECT Get_Purchase_Status__c, Get_Purchase_Error_Message__c FROM Case WHERE Id = :testCase.Id];
        //System.assertEquals('Succeeded', updatedCase.Get_Purchase_Status__c);
        //System.assertEquals('Success', updatedCase.Get_Purchase_Error_Message__c);
    }

    @IsTest
    static void testBatchExecution() {
        Test.setMock(HttpCalloutMock.class, new MockGetPurchaseResponse());
        Test.startTest();
        Database.executeBatch(new GetPurchaseBatch(), 1);
        Test.stopTest();

        Case c = [SELECT Get_Purchase_Status__c FROM Case LIMIT 1];
        //System.assertEquals('Succeeded', c.Get_Purchase_Status__c);
    }

    @IsTest
    static void testScheduler() {
        Test.setMock(HttpCalloutMock.class, new MockGetPurchaseResponse());
        String cronExp = '0 0 0 * * ?'; // Every midnight

        Test.startTest();
        System.schedule('Test GetPurchase Scheduler', cronExp, new GetPurchaseBatchScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE CronJobDetail.Name = 'Test GetPurchase Scheduler' LIMIT 1];
        System.assertNotEquals(null, ct, 'Scheduler should be created');
    }
}