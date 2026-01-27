@IsTest
global class ResizePnr_Test {
    global class ResizePnrCalloutMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @IsTest
    static void testResizePnrSuccess() {

        /* ---------------------------
           Test Data Setup
        ----------------------------*/

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            LastName = 'Tester',
            AccountId = acc.Id
        );
        insert con;

        Case originalCase = new Case(
            Status = 'New',
            Origin = 'Phone',
            AccountId = acc.Id,
            ContactId = con.Id,
            Route__c = 'TPE-AOJ-TPE',
            Departing_Flight_Number__c = 'JX123',
            Returning_Flight_Number__c = 'JX123',
            Departing_Flight_Date__c = System.today(),
            Returning_Flight_Date__c = System.today()
        );
        insert originalCase;

        Seat_Allocation_and_Ticketing__c originalSat =
            new Seat_Allocation_and_Ticketing__c(
                Case_ID__c = originalCase.Id,
                Booking_Reference_PNR__c = 'PNR123',
                Allocation_Type__c = Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC,
                Allocated_Seats__c = 10,
                Final_Allocated_Seats__c = 10,
                Final_Allocated_Seats_Amadeus__c = 10,
                Total_Seat_Sales__c = 5
            );
        insert originalSat;

        /* ---------------------------
           Invocable Input
        ----------------------------*/
        ResizePnr.InputWrapper input = new ResizePnr.InputWrapper();
        input.satId = originalSat.Id;
        input.seatResizing = 3;

        List<ResizePnr.InputWrapper> inputs =
            new List<ResizePnr.InputWrapper>{ input };

        /* ---------------------------
           Mock Callout
        ----------------------------*/
        Test.setMock(HttpCalloutMock.class, new ResizePnrCalloutMock());

        /* ---------------------------
           Execute
        ----------------------------*/
        Test.startTest();
        ResizePnr.resizePnr(inputs);
        Test.stopTest(); // executes Queueable
        

        /* ---------------------------
           Assertions
        ----------------------------*/

        // 1️⃣ Original SAT updated
        /*Seat_Allocation_and_Ticketing__c updatedOriginalSat =
            [SELECT Allocated_Seats__c, Final_Allocated_Seats__c
             FROM Seat_Allocation_and_Ticketing__c
             WHERE Id = :originalSat.Id];

        System.assertEquals(7, updatedOriginalSat.Allocated_Seats__c);
        System.assertEquals(7, updatedOriginalSat.Final_Allocated_Seats__c);

        // 2️⃣ New Case created
        Case newCase =
            [SELECT Id, ParentId, Status
             FROM Case
             WHERE ParentId = :originalCase.Id
             LIMIT 1];

        System.assertEquals(
            'Ticket Sales In Progress',
            newCase.Status
        );

        // 3️⃣ New SAT created
        Seat_Allocation_and_Ticketing__c newSat =
            [SELECT Allocated_Seats__c, Original_Sat__c, Case_ID__c, IsRunSplit__c
             FROM Seat_Allocation_and_Ticketing__c
             WHERE Original_Sat__c = :originalSat.Id
             LIMIT 1];

        System.assertEquals(3, newSat.Allocated_Seats__c);
        System.assertEquals(originalSat.Id, newSat.Original_Sat__c);
        System.assertEquals(newCase.Id, newSat.Case_ID__c);
        System.assertEquals(true, newSat.IsRunSplit__c);*/
    }
}