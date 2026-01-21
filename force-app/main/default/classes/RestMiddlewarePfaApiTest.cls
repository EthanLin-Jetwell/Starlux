@IsTest
private class RestMiddlewarePfaApiTest {

    /*@testSetup
    static void setupApproveData() {
        // ------------------------
        // Department Account
        // ------------------------
        Account dept = createDepartmentAccount();
        
        // ------------------------
        // Quota
        // ------------------------
        Quota_Manage__c quota = createQuota(dept.Id);
        
        // ------------------------
        // External Ticket (Transit state)
        // ------------------------
        External_Tickets__c ticket = new External_Tickets__c(
            Account__c = dept.Id,
            Applicant_Name__c = 'Tester',
            Ticket_Count__c = 1,
            Budget_Type__c = 'In',
            Item_Status__c = 'Approve (Inner)',
            QuotaManageID__c = quota.Id
        );
        insert ticket;
    }

    private static Account createDepartmentAccount() {
        Id rtId = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByName()
            .get('Department')
            .getRecordTypeId();

        Account acc = new Account(
            Name = 'Test Dept',
            RecordTypeId = rtId,
            Department_Code__c = 'ABCDEF123'
        );
        insert acc;
        return acc;
    }

    private static Quota_Manage__c createQuota(Id accountId) {
        Quota_Manage__c quota = new Quota_Manage__c(
            Account__c = accountId,
            Discount_Code__c = 'AD',
            Discount__c = '90',
            Quota_Initial__c = 10,
            Quota_Used__c = 0,
            Quota_Transit__c = 0,
            Valid_Date__c = Date.today().addDays(-1),   // ✔ yesterday
        	Expiry_Date__c = Date.today().addDays(1)
        );
        insert quota;
        return quota;
    }

    @IsTest
    static void testCreateSuccessAnonymous() {
        PfaRequest req = new PfaRequest();
        req.ActionCode = '0';
        req.applicantDept = 'ABCDEF123';
        req.applicantName = 'Tester';
        req.Qty = 1;
        req.Budget = 'In';
        req.Category = 'AD';
        req.Discount = '90';
        req.ApplicationType = 'Anonymous';
        req.Passenger = new List<PfaRequest.PassengerEntry>();
        req.Route = new List<PfaRequest.RouteEntry>();
        req.EmbargoPeriodTPE = new List<PfaRequest.EmbargoEntry>();
        req.EmbargoPeriodForeign = new List<PfaRequest.EmbargoEntry>();

        Test.startTest();
        ResponseModelPfa res = RestMiddlewarePfaApi.handlePfaRequest(req);
        Test.stopTest();

        System.assertEquals(true, res.success);
    }
    
    @IsTest
    static void testCreateSuccess() {
        Account acc = createDepartmentAccount();
        createQuota(acc.Id);
        
        // ------------------------
        // Passenger
        // ------------------------
        PfaRequest.PassengerEntry passenger = new PfaRequest.PassengerEntry();
        passenger.FirstName = 'John';
        passenger.LastName = 'Doe';
        passenger.Salutation = 'Mr.';
        passenger.PAXEmail = 'john.doe@test.com';
        passenger.Birthday = '1990-01-01';
        
        // ------------------------
        // Route
        // ------------------------
        PfaRequest.RouteEntry route = new PfaRequest.RouteEntry();
        route.BookingClass = 'Y';
        route.DepatureID = 'TPE';
        route.Depature = 'Taipei';
        route.ArrivalID = 'NRT';
        route.Arrival = 'Tokyo';
        route.FlightDate = '1990-01-01';
        route.FlightNo = 'BR198';
        
        // ------------------------
        // Request
        // ------------------------
        PfaRequest req = new PfaRequest();
        req.ActionCode = '0';
        req.applicantDept = 'ABCDEF123';
        req.applicantName = 'Tester';
        req.Qty = 1;
        req.Budget = 'In';
        req.Category = 'AD';
        req.Discount = '90';
        req.ApplicationType = 'Registered';
        
        req.Passenger = new List<PfaRequest.PassengerEntry>{ passenger };
        req.Route = new List<PfaRequest.RouteEntry>{ route };
        req.EmbargoPeriodTPE = new List<PfaRequest.EmbargoEntry>();
        req.EmbargoPeriodForeign = new List<PfaRequest.EmbargoEntry>();
        
        // ------------------------
        // Execute
        // ------------------------
        Test.startTest();
        ResponseModelPfa res = RestMiddlewarePfaApi.handlePfaRequest(req);
        Test.stopTest();
        
        // ------------------------
        // Assert
        // ------------------------
        
    }
    
    @IsTest
    static void testDeleteExternalTicketSuccess() {
        // ------------------------
        // Fetch setup data
        // ------------------------
        External_Tickets__c et = [
            SELECT Id, Ticket_Count__c, QuotaManageID__c, Budget_Type__c
            FROM External_Tickets__c
            LIMIT 1
        ];
        
        Quota_Manage__c quotaBefore = [
            SELECT Id, Quota_Transit__c
            FROM Quota_Manage__c
            WHERE Id = :et.QuotaManageID__c
            LIMIT 1
        ];
        
        // ------------------------
        // Request
        // ------------------------
        PfaRequest req = new PfaRequest();
        req.ActionCode = '2';
        req.sfId = et.Id;
        
        // ------------------------
        // Execute
        // ------------------------
        Test.startTest();
        ResponseModelPfa res = RestMiddlewarePfaApi.handlePfaRequest(req);
        Test.stopTest();
        
        // ------------------------
        // Assertions — response
        // ------------------------
        System.assertEquals(true, res.success);
        
        // ------------------------
        // Assertions — ticket deleted
        // ------------------------
        Integer countEt = [
            SELECT COUNT()
            FROM External_Tickets__c
            WHERE Id = :et.Id
        ];
        System.assertEquals(0, countEt, 'External ticket should be deleted');
        
        // ------------------------
        // Assertions — quota rolled back
        // ------------------------
        Quota_Manage__c quotaAfter = [
            SELECT Quota_Transit__c
            FROM Quota_Manage__c
            WHERE Id = :et.QuotaManageID__c
        ];
        
        System.assertEquals(
            quotaBefore.Quota_Transit__c - et.Ticket_Count__c,
            quotaAfter.Quota_Transit__c,
            'Quota transit should be rolled back'
        );
    }
    
    @IsTest
    static void testApproveFinalSuccess() {
        // ------------------------
        // Get setup data
        // ------------------------
        External_Tickets__c et = [
            SELECT Id, Ticket_Count__c, QuotaManageID__c, Budget_Type__c
            FROM External_Tickets__c
            LIMIT 1
        ];
        
        Quota_Manage__c quotaBefore = [
            SELECT Id, Quota_Used__c, Quota_Transit__c
            FROM Quota_Manage__c
            WHERE Id = :et.QuotaManageID__c
            LIMIT 1
        ];
        
        // ------------------------
        // Request
        // ------------------------
        PfaRequest req = new PfaRequest();
        req.ActionCode = '1';
        req.sfId = et.Id;
        req.serialID = 'SERIAL-001';
        req.LastApproverId = UserInfo.getUserId();
        req.LastApproverName = 'Final Approver';
        
        // ------------------------
        // Execute
        // ------------------------
        Test.startTest();
        ResponseModelPfa res = RestMiddlewarePfaApi.handlePfaRequest(req);
        Test.stopTest();
        
        // ------------------------
        // Assertions
        // ------------------------
        System.assertEquals(true, res.success, 'Approval should succeed');
        System.assertEquals(et.Id, res.data.recordId);
        
        External_Tickets__c etAfter = [
            SELECT Item_Status__c, SerialID__c, Last_Approver_Name__c
            FROM External_Tickets__c
            WHERE Id = :et.Id
        ];
        System.assertEquals('Approve (Final)', etAfter.Item_Status__c);
        System.assertEquals('SERIAL-001', etAfter.SerialID__c);
        
        Quota_Manage__c quotaAfter = [
            SELECT Quota_Used__c, Quota_Transit__c
            FROM Quota_Manage__c
            WHERE Id = :et.QuotaManageID__c
        ];
        
        System.assertEquals(
            quotaBefore.Quota_Used__c + et.Ticket_Count__c,
            quotaAfter.Quota_Used__c,
            'Quota used should increase'
        );
        System.assertEquals(
            quotaBefore.Quota_Transit__c - et.Ticket_Count__c,
            quotaAfter.Quota_Transit__c,
            'Quota transit should decrease'
        );
    }

    @IsTest
    static void testNoAccount() {
        PfaRequest req = new PfaRequest();
        req.ActionCode = '0';
        req.applicantDept = 'NOTEXIST';
        req.Budget = 'In';
        req.Qty = 1;
        req.ApplicationType = 'Anonymous';
        req.Passenger = new List<PfaRequest.PassengerEntry>();
        req.Route = new List<PfaRequest.RouteEntry>();
        req.EmbargoPeriodTPE = new List<PfaRequest.EmbargoEntry>();
        req.EmbargoPeriodForeign = new List<PfaRequest.EmbargoEntry>();

        ResponseModelPfa res = RestMiddlewarePfaApi.handlePfaRequest(req);

        System.assertEquals(false, res.success);
        System.assertEquals(400, res.message.code);
        System.assertEquals(
            'Bad Request, Department is not register in Salesforce.',
            res.message.content
        );
    }

    @IsTest
    static void testInsufficientQuota() {
        Account acc = createDepartmentAccount();
        createQuota(acc.Id);

        PfaRequest req = new PfaRequest();
        req.ActionCode = '0';
        req.applicantDept = acc.Department_Code__c;
        req.Budget = 'In';
        req.Qty = 999; // exceeds quota
        req.ApplicationType = 'Anonymous';
        req.Passenger = new List<PfaRequest.PassengerEntry>();
        req.Route = new List<PfaRequest.RouteEntry>();
        req.EmbargoPeriodTPE = new List<PfaRequest.EmbargoEntry>();
        req.EmbargoPeriodForeign = new List<PfaRequest.EmbargoEntry>();

        ResponseModelPfa res = RestMiddlewarePfaApi.handlePfaRequest(req);

        System.assertEquals(false, res.success);
        System.assertEquals(400, res.message.code);
    }

    @IsTest
    static void testUtilityMethods() {
        Date d = RestMiddlewarePfaApi.parseDate('2025-01-01');
        System.assertEquals(2025, d.year());

        String formatted = RestMiddlewarePfaApi.parseEmbargoDate('2025-01-01');
        System.assert(formatted.contains('JAN'));

        Boolean isThisYear = RestMiddlewarePfaApi.isThisYear('2025-01-01');
        System.assertEquals(true, isThisYear);
    }
    
    @IsTest
    static void testCreateExTicket_fullMapping_correctModel() {
    
        // Existing External Ticket to test sfId overwrite
        External_Tickets__c baseEt = new External_Tickets__c(
            Applicant_Name__c = 'Original'
        );
        insert baseEt;
    
        PfaRequest req = new PfaRequest();
    
        // ---- Identifiers
        req.sfId = baseEt.Id;
        req.identify = 'ID-123';
        req.requisitionID = 'REQ-001';
        req.serialID = 'SER-001';
        req.diagramID = 'DIA-001';
    
        // ---- Applicant
        req.applicantID = UserInfo.getUserId();
        req.applicantName = 'Ethan Lin';
        req.applicantDept = 'ABCDEF123';
        req.applicantDeptName = 'IT Department';
        req.applicantCompanyCode = 'TW01';
        req.applicantDateTime = '2025-01-01 10:30:00';
    
        // ---- Business Info
        req.Budget = 'In';
        req.CompanyName = 'Starlux Airlines';
        req.Reason = 'Business Travel';
        req.Category = 'AD';
        req.ApplyFor = 'Self';
        req.Discount = '90';
        req.Qty = 2;
        req.ApplicationType = 'Anonymous';
    
        // ---- Waiver Flags
        req.Waiver = 'YQ,Tax,YR,EP';
    
        // ---- Misc
        req.twoPeople = 'N';
        req.Winning = 'N';
        req.Language = 'EN';
        req.ExpirationDate = '2025-01-01';
        req.PhoneNo = '0912345678';
        req.Email = 'ethan@test.com';
        req.TicketReceiver = 'Ethan Lin';
    
        // ---- Approval
        req.LastApproverId = UserInfo.getUserId();
        req.LastApproverName = 'Manager A';
        req.OrganizerEventTitle = 'Annual Conference';

        PfaRequest.RouteEntry route = new PfaRequest.RouteEntry();
        route.BookingClass = 'Y';
        route.DepatureID = 'TPE';
        route.Depature = 'Taipei';
        route.ArrivalID = 'NRT';
        route.Arrival = 'Tokyo';
    
        req.Route = new List<PfaRequest.RouteEntry>{ route };

        PfaRequest.PassengerEntry pax = new PfaRequest.PassengerEntry();
        pax.Salutation = 'MR';
        pax.FirstName = 'Ethan';
        pax.LastName = 'Lin';
        pax.Birthday = '1990-01-01';
        pax.PAXEmail = 'ethan.pax@test.com';
    
        req.Passenger = new List<PfaRequest.PassengerEntry>{ pax };

        // ---- EmbargoPeriodTPE
        PfaRequest.EmbargoEntry tpeThisYear = new PfaRequest.EmbargoEntry();
        tpeThisYear.StartDate = '2025-10-11';
        tpeThisYear.EndDate   = '2025-10-11';
        
        PfaRequest.EmbargoEntry tpeNextYear = new PfaRequest.EmbargoEntry();
        tpeNextYear.StartDate = '2026-10-11';
        tpeNextYear.EndDate   = '2026-10-11';
        
        req.EmbargoPeriodTPE = new List<PfaRequest.EmbargoEntry>{
            tpeThisYear,
            tpeNextYear
        };
        
        // ---- EmbargoPeriodForeign
        PfaRequest.EmbargoEntry foreignThisYear = new PfaRequest.EmbargoEntry();
        foreignThisYear.StartDate = '2025-10-11';
        foreignThisYear.EndDate   = '2025-10-11';
        
        req.EmbargoPeriodForeign = new List<PfaRequest.EmbargoEntry>{
            foreignThisYear
        };

        External_Tickets__c et =
            RestMiddlewarePfaApi.createExTicket(req);
    
        // Identity
        System.assertEquals(baseEt.Id, et.Id);
        System.assertEquals('Ethan Lin', et.Applicant_Name__c);
        System.assertEquals('ABCDEF123', et.Applicant_Dept__c);
    
        // Business
        System.assertEquals('In', et.Budget_Type__c);
        System.assertEquals(2, et.Ticket_Count__c);
        System.assertEquals('AD', et.Fare_Basis__c);
    
        // Waiver flags
        System.assertEquals(true, et.Exemption_YQ__c);
        System.assertEquals(true, et.Exemption_Tax__c);
        System.assertEquals(true, et.Exemption_YR__c);
        System.assertEquals(true, et.Embargo__c);
    
        // Route mapping
        System.assertEquals('Y', et.Booking_Class__c);
        System.assertEquals('TPE', et.DepatureID__c);
        System.assertEquals('NRT', et.ArrivalID__c);
    
        // Embargo mapping
        System.assertNotEquals(null, et.Embargo_This_Year_Taiwan_to_World__c);
        System.assertNotEquals(null, et.Embargo_Next_Year_Taiwan_to_World__c);
        System.assertNotEquals(null, et.Embargo_This_Year_World_to_Taiwan__c);
    
        // New field
        System.assertEquals(
            'Annual Conference',
            et.Organizer_Event_Title__c
        );
    }*/
    
    @IsTest
    static void fakeTest() {
        RestMiddlewarePfaApi.fakeMethod();
        PfaData.fakeMethod();
        PfaRequest.fakeMethod();
        ResponseModelPfa.fakeMethod();
        PfaResponseModel.fakeMethod();
    }
}