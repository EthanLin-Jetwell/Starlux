/********************************************************************************************************
NAME:			SeatAllocationTriggerHandler_Test
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the test class for SeatAllocationTriggerHandler class

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
21/08/2019      Edmond To		First version
********************************************************************************************************/
@isTest
public class SeatAllocationTriggerHandler_Test {
    
    public static testMethod void testAdjustmentSeatAllocationRecordInsertWithValidPNR() {
        //Create Account Record
        ID accountTravelRecordID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
        Account travelAgency = new Account(RecordTypeId = accountTravelRecordID, Name = 'Test Agency', IATA_MSO_Code__c = '123456', Cash_Payment_Only__c = true);
        insert travelAgency;
        
        Account testAccount = [SELECT Id,IATA_MSO_Code__c FROM Account LIMIT 1];
        system.debug('DBG testAccount:' + testAccount);
        
        //Create Contact Record
        Contact con = new Contact(AccountId = testAccount.Id, LastName = 'Contact', FirstName= 'Test', Email='test@email.com');
        insert con;
        
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        system.debug('DBG testContact:' + testContact);
        
        //Create Case Record
		ID caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        Date departingDate = Date.newInstance(2040,4,4);
        Date returningDate = Date.newInstance(2040,4,10);
        Date currentDate = Date.today();
        String departingFlight = 'JX110';
        String returningFlight = 'JX101';
        String route = 'TPE-MFM-TPE';
        String IATACode = '123456';
        
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', caseRecordID);
        caseFieldValueMap.put('AccountId', testAccount.Id); 
        caseFieldValueMap.put('Departing_Flight_Date__c', departingDate);
        caseFieldValueMap.put('Returning_Flight_Date__c', returningDate); 
        caseFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        caseFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        caseFieldValueMap.put('Route__c', route);
        caseFieldValueMap.put('Status', 'New');
        caseFieldValueMap.put('ContactId', testContact.Id);
        
        TestUtility.createCase(caseFieldValueMap);
        List<String> caseFields = new List<String>();
        caseFields.add('Departing_Flight_Number__c');
        caseFields.add('Returning_Flight_Number__c');
        caseFields.add('Departing_Flight_Date__c');
        caseFields.add('Returning_Flight_Date__c');
        caseFields.add('Route__c');
        
		Case testCase = (Case) TestUtility.getCase(caseFields);       
        system.debug('DBG testCase: '+testCase);
        
        //Create Ticket Fare Record
        Date effectiveStartDate = Date.newInstance(2040,4,3);
        Date effectiveEndDate = Date.newInstance(2040,4,11);
        Date effectiveIssueStartDate = (Date.today())-1;
        Date effectiveIssueEndDate = (Date.today())+1;
        
        Map<String, Object> fareFieldValueMap = new Map<String, Object>();
        fareFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        fareFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        fareFieldValueMap.put('Effective_Flight_Start_Date__c', effectiveStartDate);
        fareFieldValueMap.put('Effective_Flight_End_Date__c', effectiveEndDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_Start_Date__c', effectiveIssueStartDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_End_Date__c', effectiveIssueEndDate);
        fareFieldValueMap.put('Route__c', route);
        fareFieldValueMap.put('IATA_Code__c', IATACode);
        fareFieldValueMap.put('Unit_Price_Adult__c', 100000.00);
        fareFieldValueMap.put('Unit_Price_Child__c', 75000.00);
        fareFieldValueMap.put('Unit_Price_Infant__c', 50000.00);
        fareFieldValueMap.put('Is_Weekend__c', 7500.00);
        fareFieldValueMap.put('Less_than_Minimal_No_of_Pax__c', 5000.00);
        fareFieldValueMap.put('Minimal_No_of_Pax__c', 15);
        
        TestUtility.createTicketFare(fareFieldValueMap);
        List<String> fareFields = new List<String>();
        fareFields.add('Departing_Flight_Number__c');
        fareFields.add('Returning_Flight_Number__c');
        fareFields.add('Effective_Flight_Start_Date__c');
        fareFields.add('Effective_Flight_End_Date__c');
        fareFields.add('Effective_Ticket_Issue_Start_Date__c');
        fareFields.add('Effective_Ticket_Issue_End_Date__c');
        fareFields.add('Route__c');
        fareFields.add('IATA_Code__c');
        
        Ticket_Fare_Rule__c testTicketFare = (Ticket_Fare_Rule__c) TestUtility.getTicketFare(fareFields);
        system.debug('DBG testTicketFare: '+testTicketFare);
        
        //Create Tax Amount Record
        Map<String, Object> taxFieldValueMap = new Map<String, Object>();
        taxFieldValueMap.put('Route__c', route);
        taxFieldValueMap.put('Tax_Date__c', currentDate);
        taxFieldValueMap.put('Tax_Amount_Adult__c', 20000.00);
        taxFieldValueMap.put('Tax_Amount_Child__c', 10000.00);
        taxFieldValueMap.put('Tax_Amount_Infant__c', 5000.00);
        
        TestUtility.createTax(taxFieldValueMap);
        Tax_Details__c testTaxList = (Tax_Details__c) TestUtility.getTax();
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        
        List<String> seatAllocationFields = new List<String>();
        seatAllocationFields.add('Departing_Flight_Number__c');
        seatAllocationFields.add('Returning_Flight_Number__c');
        seatAllocationFields.add('Departing_Flight_Date__c');
        seatAllocationFields.add('Returning_Flight_Date__c');
        seatAllocationFields.add('CreatedDate');
        seatAllocationFields.add('Case_Id__r.Account.IATA_MSO_Code__c');
        seatAllocationFields.add('Group_Booking_Route__c');
        seatAllocationFields.add('Final_Allocated_Seats__c');
        
        Seat_Allocation_and_Ticketing__c seatAllocation = new Seat_Allocation_and_Ticketing__c(RecordTypeId = seatAllocationID, Final_Sales_Seats__c = finalSeats, 
                                                                                                   Case_ID__c = testCase.Id, Allocation_Type__c = 'SRS', 
                                                                                                  Allocated_Seats__c = finalSeats, Booking_Reference_PNR__c = 'PNR123');
        
        //Insert SRS Seat Allocation record and query for it
        insert seatAllocation;
        Seat_Allocation_and_Ticketing__c SRSSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation();
            
        //Create Adjustment Seat Allocation record
        Seat_Allocation_and_Ticketing__c testSeatAllocation = new Seat_Allocation_and_Ticketing__c(RecordTypeId = seatAllocationID, Allocation_Type__c = 'Adjustment',
                                                                                                  Booking_Reference_PNR__c = 'PNR123', Adjust_Type__c = 'Voluntary', Case_ID__c = testCase.Id, 
                                                                                                   Allocated_Seats__c = -5);
            
        //Commence test
        Test.startTest();
        Database.SaveResult SaveResult = database.insert(testSeatAllocation);
        Test.stopTest();
        
        Seat_Allocation_and_Ticketing__c resultSeatAllocation = [SELECT Id,Final_Allocated_Seats__c FROM Seat_Allocation_and_Ticketing__c WHERE Id = :SRSSeatAllocation.Id];
        //Seat_Allocation_and_Ticketing__c resultSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
                
        system.assertEquals(SaveResult.isSuccess(), true);
        //Assert final allocated seats
        system.assertEquals(resultSeatAllocation.Final_Allocated_Seats__c, 5);
        
        
    }
    
    public static testMethod void testAdjustmentSeatAllocationRecordInsertWithInvalidPNR() {
        //Create Account Record
        ID accountTravelRecordID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
        Account travelAgency = new Account(RecordTypeId = accountTravelRecordID, Name = 'Test Agency', IATA_MSO_Code__c = '123456', Cash_Payment_Only__c = true);
        insert travelAgency;
        
        Account testAccount = [SELECT Id,IATA_MSO_Code__c FROM Account LIMIT 1];
        system.debug('DBG testAccount:' + testAccount);
        
        //Create Contact Record
        Contact con = new Contact(AccountId = testAccount.Id, LastName = 'Contact', FirstName= 'Test', Email='test@email.com');
        insert con;
        
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        system.debug('DBG testContact:' + testContact);
        
        //Create Case Record
		ID caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        Date departingDate = Date.newInstance(2040,4,4);
        Date returningDate = Date.newInstance(2040,4,10);
        Date currentDate = Date.today();
        String departingFlight = 'JX110';
        String returningFlight = 'JX101';
        String route = 'TPE-MFM-TPE';
        String IATACode = '123456';
        
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', caseRecordID);
        caseFieldValueMap.put('AccountId', testAccount.Id); 
        caseFieldValueMap.put('Departing_Flight_Date__c', departingDate);
        caseFieldValueMap.put('Returning_Flight_Date__c', returningDate); 
        caseFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        caseFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        caseFieldValueMap.put('Route__c', route);
        caseFieldValueMap.put('Status', 'New');
        caseFieldValueMap.put('ContactId', testContact.Id);
        
        TestUtility.createCase(caseFieldValueMap);
        List<String> caseFields = new List<String>();
        caseFields.add('Departing_Flight_Number__c');
        caseFields.add('Returning_Flight_Number__c');
        caseFields.add('Departing_Flight_Date__c');
        caseFields.add('Returning_Flight_Date__c');
        caseFields.add('Route__c');
        
		Case testCase = (Case) TestUtility.getCase(caseFields);       
        system.debug('DBG testCase: '+testCase);
        
        //Create Ticket Fare Record
        Date effectiveStartDate = Date.newInstance(2040,4,3);
        Date effectiveEndDate = Date.newInstance(2040,4,11);
        Date effectiveIssueStartDate = (Date.today())-1;
        Date effectiveIssueEndDate = (Date.today())+1;
        
        Map<String, Object> fareFieldValueMap = new Map<String, Object>();
        fareFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        fareFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        fareFieldValueMap.put('Effective_Flight_Start_Date__c', effectiveStartDate);
        fareFieldValueMap.put('Effective_Flight_End_Date__c', effectiveEndDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_Start_Date__c', effectiveIssueStartDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_End_Date__c', effectiveIssueEndDate);
        fareFieldValueMap.put('Route__c', route);
        fareFieldValueMap.put('IATA_Code__c', IATACode);
        fareFieldValueMap.put('Unit_Price_Adult__c', 100000.00);
        fareFieldValueMap.put('Unit_Price_Child__c', 75000.00);
        fareFieldValueMap.put('Unit_Price_Infant__c', 50000.00);
        fareFieldValueMap.put('Is_Weekend__c', 7500.00);
        fareFieldValueMap.put('Less_than_Minimal_No_of_Pax__c', 5000.00);
        fareFieldValueMap.put('Minimal_No_of_Pax__c', 15);
        
        TestUtility.createTicketFare(fareFieldValueMap);
        List<String> fareFields = new List<String>();
        fareFields.add('Departing_Flight_Number__c');
        fareFields.add('Returning_Flight_Number__c');
        fareFields.add('Effective_Flight_Start_Date__c');
        fareFields.add('Effective_Flight_End_Date__c');
        fareFields.add('Effective_Ticket_Issue_Start_Date__c');
        fareFields.add('Effective_Ticket_Issue_End_Date__c');
        fareFields.add('Route__c');
        fareFields.add('IATA_Code__c');
        
        Ticket_Fare_Rule__c testTicketFare = (Ticket_Fare_Rule__c) TestUtility.getTicketFare(fareFields);
        system.debug('DBG testTicketFare: '+testTicketFare);
        
        //Create Tax Amount Record
        Map<String, Object> taxFieldValueMap = new Map<String, Object>();
        taxFieldValueMap.put('Route__c', route);
        taxFieldValueMap.put('Tax_Date__c', currentDate);
        taxFieldValueMap.put('Tax_Amount_Adult__c', 20000.00);
        taxFieldValueMap.put('Tax_Amount_Child__c', 10000.00);
        taxFieldValueMap.put('Tax_Amount_Infant__c', 5000.00);
        
        TestUtility.createTax(taxFieldValueMap);
        Tax_Details__c testTaxList = (Tax_Details__c) TestUtility.getTax();
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        
        List<String> seatAllocationFields = new List<String>();
        seatAllocationFields.add('Departing_Flight_Number__c');
        seatAllocationFields.add('Returning_Flight_Number__c');
        seatAllocationFields.add('Departing_Flight_Date__c');
        seatAllocationFields.add('Returning_Flight_Date__c');
        seatAllocationFields.add('CreatedDate');
        seatAllocationFields.add('Case_Id__r.Account.IATA_MSO_Code__c');
        seatAllocationFields.add('Group_Booking_Route__c');
        seatAllocationFields.add('Final_Allocated_Seats__c');
        
        Seat_Allocation_and_Ticketing__c seatAllocation = new Seat_Allocation_and_Ticketing__c(RecordTypeId = seatAllocationID, Final_Sales_Seats__c = finalSeats, 
                                                                                                   Case_ID__c = testCase.Id, Allocation_Type__c = 'SRS', 
                                                                                                  Allocated_Seats__c = finalSeats, Booking_Reference_PNR__c = 'PNR234');
        
        //Insert SRS Seat Allocation record and query for it
        insert seatAllocation;
        Seat_Allocation_and_Ticketing__c SRSSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation();
            
        //Create Adjustment Seat Allocation record
        Seat_Allocation_and_Ticketing__c testSeatAllocation = new Seat_Allocation_and_Ticketing__c(RecordTypeId = seatAllocationID, Allocation_Type__c = 'Adjustment',
                                                                                                  Booking_Reference_PNR__c = 'PNR123', Adjust_Type__c = 'Voluntary', Case_ID__c = testCase.Id, 
                                                                                                   Allocated_Seats__c = -5);
            
        //Commence test
        Test.startTest();
        Database.SaveResult SaveResult = database.insert(testSeatAllocation);
        Test.stopTest();
        
        Seat_Allocation_and_Ticketing__c resultSeatAllocation = [SELECT Id,Final_Allocated_Seats__c FROM Seat_Allocation_and_Ticketing__c WHERE Id = :SRSSeatAllocation.Id];
        //Seat_Allocation_and_Ticketing__c resultSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
                
        system.assertEquals(SaveResult.isSuccess(), true);
        //Assert final allocated seats
        system.assertEquals(resultSeatAllocation.Final_Allocated_Seats__c, 10);
        
        
    }

    public static testMethod void testSeatAllocationRecordInsertWithSingleValidFareAndSingleValidTaxAndWeekendAndLessThanPAX() {
        //Create Account Record
        ID accountTravelRecordID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
        Account travelAgency = new Account(RecordTypeId = accountTravelRecordID, Name = 'Test Agency', IATA_MSO_Code__c = '123456', Cash_Payment_Only__c = true);
        insert travelAgency;
        
        Account testAccount = [SELECT Id,IATA_MSO_Code__c FROM Account LIMIT 1];
        system.debug('DBG testAccount:' + testAccount);
        
        //Create Contact Record
        Contact con = new Contact(AccountId = testAccount.Id, LastName = 'Contact', FirstName= 'Test', Email='test@email.com');
        insert con;
        
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        system.debug('DBG testContact:' + testContact);
        
        //Create Case Record
		ID caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        Date departingDate = Date.newInstance(2040,4,4);
        Date returningDate = Date.newInstance(2040,4,10);
        Date currentDate = Date.today();
        String departingFlight = 'JX110';
        String returningFlight = 'JX101';
        String route = 'TPE-MFM-TPE';
        String IATACode = '123456';
        
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', caseRecordID);
        caseFieldValueMap.put('AccountId', testAccount.Id); 
        caseFieldValueMap.put('Departing_Flight_Date__c', departingDate);
        caseFieldValueMap.put('Returning_Flight_Date__c', returningDate); 
        caseFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        caseFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        caseFieldValueMap.put('Route__c', route);
        caseFieldValueMap.put('Status', 'New');
        caseFieldValueMap.put('ContactId', testContact.Id);
        
        TestUtility.createCase(caseFieldValueMap);
        List<String> caseFields = new List<String>();
        caseFields.add('Departing_Flight_Number__c');
        caseFields.add('Returning_Flight_Number__c');
        caseFields.add('Departing_Flight_Date__c');
        caseFields.add('Returning_Flight_Date__c');
        caseFields.add('Route__c');
        
		Case testCase = (Case) TestUtility.getCase(caseFields);       
        system.debug('DBG testCase: '+testCase);
        
        //Create Ticket Fare Record
        Date effectiveStartDate = Date.newInstance(2040,4,3);
        Date effectiveEndDate = Date.newInstance(2040,4,11);
        Date effectiveIssueStartDate = (Date.today())-1;
        Date effectiveIssueEndDate = (Date.today())+1;
        
        Map<String, Object> fareFieldValueMap = new Map<String, Object>();
        fareFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        fareFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        fareFieldValueMap.put('Effective_Flight_Start_Date__c', effectiveStartDate);
        fareFieldValueMap.put('Effective_Flight_End_Date__c', effectiveEndDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_Start_Date__c', effectiveIssueStartDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_End_Date__c', effectiveIssueEndDate);
        fareFieldValueMap.put('Route__c', route);
        fareFieldValueMap.put('IATA_Code__c', IATACode);
        fareFieldValueMap.put('Unit_Price_Adult__c', 100000.00);
        fareFieldValueMap.put('Unit_Price_Child__c', 75000.00);
        fareFieldValueMap.put('Unit_Price_Infant__c', 50000.00);
        fareFieldValueMap.put('Is_Weekend__c', 7500.00);
        fareFieldValueMap.put('Less_than_Minimal_No_of_Pax__c', 5000.00);
        fareFieldValueMap.put('Minimal_No_of_Pax__c', 15);
        
        TestUtility.createTicketFare(fareFieldValueMap);
        List<String> fareFields = new List<String>();
        fareFields.add('Departing_Flight_Number__c');
        fareFields.add('Returning_Flight_Number__c');
        fareFields.add('Effective_Flight_Start_Date__c');
        fareFields.add('Effective_Flight_End_Date__c');
        fareFields.add('Effective_Ticket_Issue_Start_Date__c');
        fareFields.add('Effective_Ticket_Issue_End_Date__c');
        fareFields.add('Route__c');
        fareFields.add('IATA_Code__c');
        
        Ticket_Fare_Rule__c testTicketFare = (Ticket_Fare_Rule__c) TestUtility.getTicketFare(fareFields);
        system.debug('DBG testTicketFare: '+testTicketFare);
        
        //Create Tax Amount Record
        Map<String, Object> taxFieldValueMap = new Map<String, Object>();
        taxFieldValueMap.put('Route__c', route);
        taxFieldValueMap.put('Tax_Date__c', currentDate);
        taxFieldValueMap.put('Tax_Amount_Adult__c', 20000.00);
        taxFieldValueMap.put('Tax_Amount_Child__c', 10000.00);
        taxFieldValueMap.put('Tax_Amount_Infant__c', 5000.00);
        
        TestUtility.createTax(taxFieldValueMap);
        Tax_Details__c testTaxList = (Tax_Details__c) TestUtility.getTax();
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        
        List<String> seatAllocationFields = new List<String>();
        seatAllocationFields.add('Departing_Flight_Number__c');
        seatAllocationFields.add('Returning_Flight_Number__c');
        seatAllocationFields.add('Departing_Flight_Date__c');
        seatAllocationFields.add('Returning_Flight_Date__c');
        seatAllocationFields.add('CreatedDate');
        seatAllocationFields.add('Case_Id__r.Account.IATA_MSO_Code__c');
        seatAllocationFields.add('Group_Booking_Route__c');
        seatAllocationFields.add('Initial_Unit_Price_Adult__c');
        seatAllocationFields.add('Initial_Unit_Price_Child__c');
        seatAllocationFields.add('Initial_Unit_Price_Infant__c');
        seatAllocationFields.add('Final_Unit_Price_Adult__c');
        seatAllocationFields.add('Final_Unit_Price_Child__c');
        seatAllocationFields.add('Final_Unit_Price_Infant__c');
        seatAllocationFields.add('Initial_Tax_Adult__c');
        seatAllocationFields.add('Initial_Tax_Child__c');
        seatAllocationFields.add('Initial_Tax_Infant__c');
        seatAllocationFields.add('Final_Tax_Adult__c');
        seatAllocationFields.add('Final_Tax_Child__c');
        seatAllocationFields.add('Final_Tax_Infant__c');
        seatAllocationFields.add('Not_in_Fare_Table__c');
        seatAllocationFields.add('Not_in_Tax_Table__c');
        
        Seat_Allocation_and_Ticketing__c testSeatAllocation = new Seat_Allocation_and_Ticketing__c(RecordTypeId = seatAllocationID, Final_Sales_Seats__c = finalSeats, 
                                                                                                   Case_ID__c = testCase.Id, Allocation_Type__c = 'SRS', Allocated_Seats__c = finalSeats);
        
        //Commence test
        Test.startTest();
        Database.SaveResult SaveResult = database.insert(testSeatAllocation);
        Test.stopTest();
        
        Seat_Allocation_and_Ticketing__c resultSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        
        /*
        system.debug('DBG testTicketFare Departing Flight Number: '+testTicketFare.Departing_Flight_Number__c);
        system.debug('DBG testTicketFare Returning Flight Number: '+testTicketFare.Returning_Flight_Number__c);
        system.debug('DBG testTicketFare Effective Flight Start Date: '+testTicketFare.Effective_Flight_Start_Date__c);
        system.debug('DBG testTicketFare Effective Flight End Date: '+testTicketFare.Effective_Flight_End_Date__c);
        system.debug('DBG testTicketFare Route: '+testTicketFare.Route__c);
        system.debug('DBG testTicketFare Issue Start Date: '+testTicketFare.Effective_Ticket_Issue_Start_Date__c);
        system.debug('DBG testTicketFare Issue End Date: '+testTicketFare.Effective_Ticket_Issue_End_Date__c);
        system.debug('DBG testTicketFare IATA Code: '+testTicketFare.IATA_Code__c);
        
        system.debug('DBG resultSeatAllocation Departing Flight Number: '+resultSeatAllocation.Departing_Flight_Number__c);
        system.debug('DBG resultSeatAllocation Returning Flight Number: '+resultSeatAllocation.Returning_Flight_Number__c);
        system.debug('DBG resultSeatAllocation Departing Flight Date: '+resultSeatAllocation.Departing_Flight_Date__c);
        system.debug('DBG resultSeatAllocation Returning Flight Date: '+resultSeatAllocation.Returning_Flight_Date__c);
        system.debug('DBG resultSeatAllocation Route: '+resultSeatAllocation.Group_Booking_Route__c);
        system.debug('DBG resultSeatAllocation Issue Date: '+resultSeatAllocation.CreatedDate);
        system.debug('DBG resultSeatAllocation IATA Code: '+resultSeatAllocation.Case_Id__r.Account.IATA_MSO_Code__c);
        */
        
        system.assertEquals(SaveResult.isSuccess(), true);
        //Assert fare values
        system.assertEquals(resultSeatAllocation.Initial_Unit_Price_Adult__c, 112500);
        system.assertEquals(resultSeatAllocation.Initial_Unit_Price_Child__c, 87500);
        system.assertEquals(resultSeatAllocation.Initial_Unit_Price_Infant__c, 51250);
        //system.assertEquals(resultSeatAllocation.Final_Unit_Price_Adult__c, 112500);
        //system.assertEquals(resultSeatAllocation.Final_Unit_Price_Child__c, 87500);
        //system.assertEquals(resultSeatAllocation.Final_Unit_Price_Infant__c, 62500);
        //Assert tax values
        system.assertEquals(resultSeatAllocation.Initial_Tax_Adult__c, 20000);
        system.assertEquals(resultSeatAllocation.Initial_Tax_Child__c, 10000);
        system.assertEquals(resultSeatAllocation.Initial_Tax_Infant__c, 5000);
        //system.assertEquals(resultSeatAllocation.Final_Tax_Adult__c, 20000);
        //system.assertEquals(resultSeatAllocation.Final_Tax_Child__c, 10000);
        //system.assertEquals(resultSeatAllocation.Final_Tax_Infant__c, 5000);
        //Assert Not_In_Fare and Not_In_Tax fields
        system.assertEquals(resultSeatAllocation.Not_in_Fare_Table__c, false);
        system.assertEquals(resultSeatAllocation.Not_in_Tax_Table__c, false);
        
    }
    
    public static testMethod void testSeatAllocationRecordInsertWith2DifferentValidFaresAndSingleValidTaxAndWeekendAndLessThanPAX() {
        //Create Account Record
        ID accountTravelRecordID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
        Account travelAgency = new Account(RecordTypeId = accountTravelRecordID, Name = 'Test Agency', IATA_MSO_Code__c = '123456', Cash_Payment_Only__c = true);
        insert travelAgency;
        
        Account testAccount = [SELECT Id,IATA_MSO_Code__c FROM Account LIMIT 1];
        system.debug('DBG testAccount:' + testAccount);
        
        //Create Contact Record
        Contact con = new Contact(AccountId = testAccount.Id, LastName = 'Contact', FirstName= 'Test', Email='test@email.com');
        insert con;
        
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        system.debug('DBG testContact:' + testContact);
        
        //Create Case Record
		ID caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        Date departingDate = Date.newInstance(2040,4,4);
        Date returningDate = Date.newInstance(2040,4,8);
        Date currentDate = Date.today();
        String departingFlight = 'JX110';
        String returningFlight = 'JX101';
        String route = 'TPE-MFM-TPE';
        String IATACode = '123456';
        
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', caseRecordID);
        caseFieldValueMap.put('AccountId', testAccount.Id); 
        caseFieldValueMap.put('Departing_Flight_Date__c', departingDate);
        caseFieldValueMap.put('Returning_Flight_Date__c', returningDate); 
        caseFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        caseFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        caseFieldValueMap.put('Route__c', route);
        caseFieldValueMap.put('Status', 'New');
        caseFieldValueMap.put('ContactId', testContact.Id);
        
        TestUtility.createCase(caseFieldValueMap);
        List<String> caseFields = new List<String>();
        caseFields.add('Departing_Flight_Number__c');
        caseFields.add('Returning_Flight_Number__c');
        caseFields.add('Departing_Flight_Date__c');
        caseFields.add('Returning_Flight_Date__c');
        caseFields.add('Route__c');
        
		Case testCase = (Case) TestUtility.getCase(caseFields);       
        system.debug('DBG testCase: '+testCase);
        
        //Create Ticket Fare Record
        Date effectiveStartDate = Date.newInstance(2040,4,3);
        Date effectiveEndDate = Date.newInstance(2040,4,9);
        Date effectiveIssueStartDate = (Date.today())-1;
        Date effectiveIssueEndDate = (Date.today())+1;
        
        Map<String, Object> fareFieldValueMap = new Map<String, Object>();
        fareFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        fareFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        fareFieldValueMap.put('Effective_Flight_Start_Date__c', effectiveStartDate);
        fareFieldValueMap.put('Effective_Flight_End_Date__c', effectiveEndDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_Start_Date__c', effectiveIssueStartDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_End_Date__c', effectiveIssueEndDate);
        fareFieldValueMap.put('Route__c', route);
        fareFieldValueMap.put('IATA_Code__c', IATACode);
        fareFieldValueMap.put('Unit_Price_Adult__c', 100000.00);
        fareFieldValueMap.put('Unit_Price_Child__c', 75000.00);
        fareFieldValueMap.put('Unit_Price_Infant__c', 50000.00);
        fareFieldValueMap.put('Is_Weekend__c', 7500.00);
        fareFieldValueMap.put('Less_than_Minimal_No_of_Pax__c', 5000.00);
        fareFieldValueMap.put('Minimal_No_of_Pax__c', 15);
        
        TestUtility.createTicketFares(fareFieldValueMap,5);
                
        List<String> fareFields = new List<String>();
        fareFields.add('Departing_Flight_Number__c');
        fareFields.add('Returning_Flight_Number__c');
        fareFields.add('Effective_Flight_Start_Date__c');
        fareFields.add('Effective_Flight_End_Date__c');
        fareFields.add('Effective_Ticket_Issue_Start_Date__c');
        fareFields.add('Effective_Ticket_Issue_End_Date__c');
        fareFields.add('Route__c');
        fareFields.add('IATA_Code__c');
        
        List<Ticket_Fare_Rule__c> testTicketFareList = (List<Ticket_Fare_Rule__c>) TestUtility.getTicketFares(fareFields);
        //system.debug('DBG testTicketFare: '+testTicketFare);
        
        //Create Tax Amount Record
        Map<String, Object> taxFieldValueMap = new Map<String, Object>();
        taxFieldValueMap.put('Route__c', route);
        taxFieldValueMap.put('Tax_Date__c', currentDate);
        taxFieldValueMap.put('Tax_Amount_Adult__c', 20000.00);
        taxFieldValueMap.put('Tax_Amount_Child__c', 10000.00);
        taxFieldValueMap.put('Tax_Amount_Infant__c', 5000.00);
        
        TestUtility.createTaxes(taxFieldValueMap,2);
        Tax_Details__c testTaxList = (Tax_Details__c) TestUtility.getTax();
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        
        List<String> seatAllocationFields = new List<String>();
        seatAllocationFields.add('Departing_Flight_Number__c');
        seatAllocationFields.add('Returning_Flight_Number__c');
        seatAllocationFields.add('Departing_Flight_Date__c');
        seatAllocationFields.add('Returning_Flight_Date__c');
        seatAllocationFields.add('CreatedDate');
        seatAllocationFields.add('Case_Id__r.Account.IATA_MSO_Code__c');
        seatAllocationFields.add('Group_Booking_Route__c');
        seatAllocationFields.add('Initial_Unit_Price_Adult__c');
        seatAllocationFields.add('Initial_Unit_Price_Child__c');
        seatAllocationFields.add('Initial_Unit_Price_Infant__c');
        seatAllocationFields.add('Final_Unit_Price_Adult__c');
        seatAllocationFields.add('Final_Unit_Price_Child__c');
        seatAllocationFields.add('Final_Unit_Price_Infant__c');
        seatAllocationFields.add('Initial_Tax_Adult__c');
        seatAllocationFields.add('Initial_Tax_Child__c');
        seatAllocationFields.add('Initial_Tax_Infant__c');
        seatAllocationFields.add('Final_Tax_Adult__c');
        seatAllocationFields.add('Final_Tax_Child__c');
        seatAllocationFields.add('Final_Tax_Infant__c');
        seatAllocationFields.add('Not_in_Fare_Table__c');
        seatAllocationFields.add('Not_in_Tax_Table__c');
        
        Seat_Allocation_and_Ticketing__c testSeatAllocation = new Seat_Allocation_and_Ticketing__c(RecordTypeId = seatAllocationID, Final_Sales_Seats__c = finalSeats, 
                                                                                                   Case_ID__c = testCase.Id, Allocation_Type__c = 'SRS', Allocated_Seats__c = finalSeats);
        
        //Commence test
        Test.startTest();
        Database.SaveResult SaveResult = database.insert(testSeatAllocation);
        Test.stopTest();
        
        Seat_Allocation_and_Ticketing__c resultSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        /*                                                
        system.debug('DBG testTicketFare Departing Flight Number: '+testTicketFare.Departing_Flight_Number__c);
        system.debug('DBG testTicketFare Returning Flight Number: '+testTicketFare.Returning_Flight_Number__c);
        system.debug('DBG testTicketFare Effective Flight Start Date: '+testTicketFare.Effective_Flight_Start_Date__c);
        system.debug('DBG testTicketFare Effective Flight End Date: '+testTicketFare.Effective_Flight_End_Date__c);
        system.debug('DBG testTicketFare Route: '+testTicketFare.Route__c);
        system.debug('DBG testTicketFare Issue Start Date: '+testTicketFare.Effective_Ticket_Issue_Start_Date__c);
        system.debug('DBG testTicketFare Issue End Date: '+testTicketFare.Effective_Ticket_Issue_End_Date__c);
        system.debug('DBG testTicketFare IATA Code: '+testTicketFare.IATA_Code__c);
       
        system.debug('DBG resultSeatAllocation Departing Flight Number: '+resultSeatAllocation.Departing_Flight_Number__c);
        system.debug('DBG resultSeatAllocation Returning Flight Number: '+resultSeatAllocation.Returning_Flight_Number__c);
        system.debug('DBG resultSeatAllocation Departing Flight Date: '+resultSeatAllocation.Departing_Flight_Date__c);
        system.debug('DBG resultSeatAllocation Returning Flight Date: '+resultSeatAllocation.Returning_Flight_Date__c);
        system.debug('DBG resultSeatAllocation Route: '+resultSeatAllocation.Group_Booking_Route__c);
        system.debug('DBG resultSeatAllocation Issue Date: '+resultSeatAllocation.CreatedDate);
        system.debug('DBG resultSeatAllocation IATA Code: '+resultSeatAllocation.Case_Id__r.Account.IATA_MSO_Code__c);
         */
        
        system.assertEquals(SaveResult.isSuccess(), true);
        //Assert fare values
        system.assertEquals(resultSeatAllocation.Initial_Unit_Price_Adult__c, 112500);
        system.assertEquals(resultSeatAllocation.Initial_Unit_Price_Child__c, 87500);
        system.assertEquals(resultSeatAllocation.Initial_Unit_Price_Infant__c, 51250);
        //system.assertEquals(resultSeatAllocation.Final_Unit_Price_Adult__c, 112500);
        //system.assertEquals(resultSeatAllocation.Final_Unit_Price_Child__c, 87500);
        //system.assertEquals(resultSeatAllocation.Final_Unit_Price_Infant__c, 62500);
        //Assert tax values
        system.assertEquals(resultSeatAllocation.Initial_Tax_Adult__c, 20000);
        system.assertEquals(resultSeatAllocation.Initial_Tax_Child__c, 10000);
        system.assertEquals(resultSeatAllocation.Initial_Tax_Infant__c, 5000);
        //system.assertEquals(resultSeatAllocation.Final_Tax_Adult__c, 20000);
        //system.assertEquals(resultSeatAllocation.Final_Tax_Child__c, 10000);
        //system.assertEquals(resultSeatAllocation.Final_Tax_Infant__c, 5000);
        //Assert Not_In_Fare and Not_In_Tax fields
        system.assertEquals(resultSeatAllocation.Not_in_Fare_Table__c, false);
        system.assertEquals(resultSeatAllocation.Not_in_Tax_Table__c, false);
    }
    
    public static testMethod void testSeatAllocationRecordInsertWithInvalidFaresAndInvalidTax() {
        //Create Account Record
        ID accountTravelRecordID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
        Account travelAgency = new Account(RecordTypeId = accountTravelRecordID, Name = 'Test Agency', IATA_MSO_Code__c = '123456', Cash_Payment_Only__c = true);
        insert travelAgency;
        
        Account testAccount = [SELECT Id,IATA_MSO_Code__c FROM Account LIMIT 1];
        system.debug('DBG testAccount:' + testAccount);
        
        //Create Contact Record
        Contact con = new Contact(AccountId = testAccount.Id, LastName = 'Contact', FirstName= 'Test', Email='test@email.com');
        insert con;
        
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        system.debug('DBG testContact:' + testContact);
        
        //Create Case Record
		ID caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        Date departingDate = Date.newInstance(2040,4,4);
        Date returningDate = Date.newInstance(2040,4,8);
        Date currentDate = Date.today();
        String departingFlight = 'JX110';
        String returningFlight = 'JX101';
        String route = 'TPE-MFM-TPE';
        String IATACode = '123456';
        
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', caseRecordID);
        caseFieldValueMap.put('AccountId', testAccount.Id); 
        caseFieldValueMap.put('Departing_Flight_Date__c', departingDate);
        caseFieldValueMap.put('Returning_Flight_Date__c', returningDate); 
        caseFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        caseFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        caseFieldValueMap.put('Route__c', route);
        caseFieldValueMap.put('Status', 'New');
        caseFieldValueMap.put('ContactId', testContact.Id);
        
        TestUtility.createCase(caseFieldValueMap);
        List<String> caseFields = new List<String>();
        caseFields.add('Departing_Flight_Number__c');
        caseFields.add('Returning_Flight_Number__c');
        caseFields.add('Departing_Flight_Date__c');
        caseFields.add('Returning_Flight_Date__c');
        caseFields.add('Route__c');
        
		Case testCase = (Case) TestUtility.getCase(caseFields);       
        system.debug('DBG testCase: '+testCase);
        
        //Create Ticket Fare Record
        String departingFareFlight = 'JX111';
        String returningFareFlight = 'JX121';
        Date effectiveStartDate = Date.newInstance(2040,4,3);
        Date effectiveEndDate = Date.newInstance(2040,4,9);
        Date effectiveIssueStartDate = (Date.today())-1;
        Date effectiveIssueEndDate = (Date.today())+1;
        
        Map<String, Object> fareFieldValueMap = new Map<String, Object>();
        fareFieldValueMap.put('Departing_Flight_Number__c', departingFareFlight);
        fareFieldValueMap.put('Returning_Flight_Number__c', returningFareFlight);
        fareFieldValueMap.put('Effective_Flight_Start_Date__c', effectiveStartDate);
        fareFieldValueMap.put('Effective_Flight_End_Date__c', effectiveEndDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_Start_Date__c', effectiveIssueStartDate);
        fareFieldValueMap.put('Effective_Ticket_Issue_End_Date__c', effectiveIssueEndDate);
        fareFieldValueMap.put('Route__c', route);
        fareFieldValueMap.put('IATA_Code__c', IATACode);
        fareFieldValueMap.put('Unit_Price_Adult__c', 100000.00);
        fareFieldValueMap.put('Unit_Price_Child__c', 75000.00);
        fareFieldValueMap.put('Unit_Price_Infant__c', 50000.00);
        fareFieldValueMap.put('Is_Weekend__c', 7500.00);
        fareFieldValueMap.put('Less_than_Minimal_No_of_Pax__c', 5000.00);
        fareFieldValueMap.put('Minimal_No_of_Pax__c', 15);
        
        TestUtility.createTicketFare(fareFieldValueMap);
                
        List<String> fareFields = new List<String>();
        fareFields.add('Departing_Flight_Number__c');
        fareFields.add('Returning_Flight_Number__c');
        fareFields.add('Effective_Flight_Start_Date__c');
        fareFields.add('Effective_Flight_End_Date__c');
        fareFields.add('Effective_Ticket_Issue_Start_Date__c');
        fareFields.add('Effective_Ticket_Issue_End_Date__c');
        fareFields.add('Route__c');
        fareFields.add('IATA_Code__c');
        
        List<Ticket_Fare_Rule__c> testTicketFareList = (List<Ticket_Fare_Rule__c>) TestUtility.getTicketFares(fareFields);
        //system.debug('DBG testTicketFare: '+testTicketFare);
        
        //Create Tax Amount Record
        String taxRoute = 'TPE-KIX-TPE';
        
        Map<String, Object> taxFieldValueMap = new Map<String, Object>();
        taxFieldValueMap.put('Route__c', taxRoute);
        taxFieldValueMap.put('Tax_Date__c', currentDate);
        taxFieldValueMap.put('Tax_Amount_Adult__c', 20000.00);
        taxFieldValueMap.put('Tax_Amount_Child__c', 10000.00);
        taxFieldValueMap.put('Tax_Amount_Infant__c', 5000.00);
        
        TestUtility.createTaxes(taxFieldValueMap,2);
        Tax_Details__c testTaxList = (Tax_Details__c) TestUtility.getTax();
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        
        List<String> seatAllocationFields = new List<String>();
        seatAllocationFields.add('Departing_Flight_Number__c');
        seatAllocationFields.add('Returning_Flight_Number__c');
        seatAllocationFields.add('Departing_Flight_Date__c');
        seatAllocationFields.add('Returning_Flight_Date__c');
        seatAllocationFields.add('CreatedDate');
        seatAllocationFields.add('Case_Id__r.Account.IATA_MSO_Code__c');
        seatAllocationFields.add('Group_Booking_Route__c');
        seatAllocationFields.add('Initial_Unit_Price_Adult__c');
        seatAllocationFields.add('Initial_Unit_Price_Child__c');
        seatAllocationFields.add('Initial_Unit_Price_Infant__c');
        seatAllocationFields.add('Final_Unit_Price_Adult__c');
        seatAllocationFields.add('Final_Unit_Price_Child__c');
        seatAllocationFields.add('Final_Unit_Price_Infant__c');
        seatAllocationFields.add('Initial_Tax_Adult__c');
        seatAllocationFields.add('Initial_Tax_Child__c');
        seatAllocationFields.add('Initial_Tax_Infant__c');
        seatAllocationFields.add('Final_Tax_Adult__c');
        seatAllocationFields.add('Final_Tax_Child__c');
        seatAllocationFields.add('Final_Tax_Infant__c');
        seatAllocationFields.add('Not_in_Fare_Table__c');
        seatAllocationFields.add('Not_in_Tax_Table__c');
        
        Seat_Allocation_and_Ticketing__c testSeatAllocation = new Seat_Allocation_and_Ticketing__c(RecordTypeId = seatAllocationID, Final_Sales_Seats__c = finalSeats, 
                                                                                                   Case_ID__c = testCase.Id, Allocation_Type__c = 'SRS', Allocated_Seats__c = finalSeats);
        
        //Commence test
        Test.startTest();
        Database.SaveResult SaveResult = database.insert(testSeatAllocation);
        Test.stopTest();
        
        Seat_Allocation_and_Ticketing__c resultSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        /*                                                
        system.debug('DBG testTicketFare Departing Flight Number: '+testTicketFare.Departing_Flight_Number__c);
        system.debug('DBG testTicketFare Returning Flight Number: '+testTicketFare.Returning_Flight_Number__c);
        system.debug('DBG testTicketFare Effective Flight Start Date: '+testTicketFare.Effective_Flight_Start_Date__c);
        system.debug('DBG testTicketFare Effective Flight End Date: '+testTicketFare.Effective_Flight_End_Date__c);
        system.debug('DBG testTicketFare Route: '+testTicketFare.Route__c);
        system.debug('DBG testTicketFare Issue Start Date: '+testTicketFare.Effective_Ticket_Issue_Start_Date__c);
        system.debug('DBG testTicketFare Issue End Date: '+testTicketFare.Effective_Ticket_Issue_End_Date__c);
        system.debug('DBG testTicketFare IATA Code: '+testTicketFare.IATA_Code__c);
        
        system.debug('DBG resultSeatAllocation Departing Flight Number: '+resultSeatAllocation.Departing_Flight_Number__c);
        system.debug('DBG resultSeatAllocation Returning Flight Number: '+resultSeatAllocation.Returning_Flight_Number__c);
        system.debug('DBG resultSeatAllocation Departing Flight Date: '+resultSeatAllocation.Departing_Flight_Date__c);
        system.debug('DBG resultSeatAllocation Returning Flight Date: '+resultSeatAllocation.Returning_Flight_Date__c);
        system.debug('DBG resultSeatAllocation Route: '+resultSeatAllocation.Group_Booking_Route__c);
        system.debug('DBG resultSeatAllocation Issue Date: '+resultSeatAllocation.CreatedDate);
        system.debug('DBG resultSeatAllocation IATA Code: '+resultSeatAllocation.Case_Id__r.Account.IATA_MSO_Code__c);
        */
        
        system.assertEquals(SaveResult.isSuccess(), true);
        //Assert fare values
        system.assertEquals(resultSeatAllocation.Initial_Unit_Price_Adult__c, null);
        system.assertEquals(resultSeatAllocation.Initial_Unit_Price_Child__c, null);
        system.assertEquals(resultSeatAllocation.Initial_Unit_Price_Infant__c, null);
        //system.assertEquals(resultSeatAllocation.Final_Unit_Price_Adult__c, null);
        //system.assertEquals(resultSeatAllocation.Final_Unit_Price_Child__c, null);
        //system.assertEquals(resultSeatAllocation.Final_Unit_Price_Infant__c, null);
        //Assert tax values
        system.assertEquals(resultSeatAllocation.Initial_Tax_Adult__c, null);
        system.assertEquals(resultSeatAllocation.Initial_Tax_Child__c, null);
        system.assertEquals(resultSeatAllocation.Initial_Tax_Infant__c, null);
        //system.assertEquals(resultSeatAllocation.Final_Tax_Adult__c, null);
        //system.assertEquals(resultSeatAllocation.Final_Tax_Child__c, null);
        //system.assertEquals(resultSeatAllocation.Final_Tax_Infant__c, null);
        //Assert Not_In_Fare and Not_In_Tax fields
        system.assertEquals(resultSeatAllocation.Not_in_Fare_Table__c, true);
        system.assertEquals(resultSeatAllocation.Not_in_Tax_Table__c, true);
    }
}