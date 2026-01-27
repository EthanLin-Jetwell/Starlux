@isTest
private class QueueableGetItinerary_Test {
    
    @isTest static void testExecute_singleId() {
        Account acc = new Account(Name = 'Test Account', IATA_MSO_Code__c = 'TST');
        insert acc;

        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            AccountId = acc.Id
        );
        insert testCase;

        // 找一個不是 Planned_Allocation 的 RecordType
        Id otherRtId = [SELECT Id FROM RecordType 
                        WHERE SObjectType = 'Seat_Allocation_and_Ticketing__c' 
                        AND DeveloperName != 'Planned_Allocation'
                        LIMIT 1].Id;

        Seat_Allocation_and_Ticketing__c sat = new Seat_Allocation_and_Ticketing__c(
            RecordTypeId = otherRtId,
            Allocation_Type__c = 'TEST_BYPASS',
            Final_Allocated_Seats__c = 1,
            Case_ID__c = testCase.Id,
            Booking_Reference_PNR__c = 'PNR123',
            Allocated_Seats__c = 1
        );
        insert sat;

        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());

        Test.startTest();
        System.enqueueJob(new QueueableGetItinerary(new List<Id>{ sat.Id }));
        Test.stopTest();
    }

    @isTest static void testExecute_multipleIds() {
        Account acc = new Account(Name = 'Test Account', IATA_MSO_Code__c = 'TST');
        insert acc;

        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            AccountId = acc.Id
        );
        insert testCase;

        Id otherRtId = [SELECT Id FROM RecordType 
                        WHERE SObjectType = 'Seat_Allocation_and_Ticketing__c' 
                        AND DeveloperName != 'Planned_Allocation'
                        LIMIT 1].Id;

        List<Seat_Allocation_and_Ticketing__c> sats = new List<Seat_Allocation_and_Ticketing__c>();
        for (Integer i = 0; i < 3; i++) {
            sats.add(new Seat_Allocation_and_Ticketing__c(
                RecordTypeId = otherRtId,
                Allocation_Type__c = 'TEST_BYPASS',
                Final_Allocated_Seats__c = 1,
                Case_ID__c = testCase.Id,
                Booking_Reference_PNR__c = 'PNR' + i,
                Allocated_Seats__c = 1
            ));
        }
        insert sats;

        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());

        Test.startTest();
        System.enqueueJob(new QueueableGetItinerary(
            new List<Id>{ sats[0].Id, sats[1].Id, sats[2].Id }
        ));
        Test.stopTest();
    }

    private class DummyHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"ok"}');
            res.setStatusCode(200);
            return res;
        }
    }
}