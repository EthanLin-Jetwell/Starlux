/********************************************************************************************************
NAME:			UpdateTicketFare_Test
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the test class for UpdateTicketFare class

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
25/08/2019      Edmond To		First version
********************************************************************************************************/
@isTest
public class UpdateTicketFare_Test {
    
    public static testMethod void testUpdateTicketFareWith5ValidNewFaresWithMoreThan6DaysBetween() {
		//Create Account Record
        ID accountTravelRecordID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
        Account travelAgency = new Account(RecordTypeId = accountTravelRecordID, Name = 'Test Agency', IATA_MSO_Code__c = '123456', Cash_Payment_Only__c = true);
        insert travelAgency;
        
        Account testAccount = [SELECT Id,IATA_MSO_Code__c FROM Account LIMIT 1];
        system.debug('DBG testAccount:' + testAccount);
        
        //Create Contact Record
        Contact con = new Contact(AccountId = testAccount.Id, LastName = 'Contact', FirstName= 'Test', Email='test@email.com');
        insert con;
		system.debug('Account inserted');        
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        system.debug('DBG testContact:' + testContact);
        
        //Create Case Record
		ID caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        Date departingDate = Date.newInstance(2040,4,4);
        Date returningDate = Date.newInstance(2040,4,10);
        String departingFlight = 'JX110';
        String departingFlight2 = 'JX210';
        String returningFlight = 'JX101';
        String returningFlight2 = 'JX201';
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
        
        Map<String, Object> fareFieldValueMap2 = new Map<String, Object>();
        fareFieldValueMap2.put('Departing_Flight_Number__c', departingFlight2);
        fareFieldValueMap2.put('Returning_Flight_Number__c', returningFlight2);
        fareFieldValueMap2.put('Effective_Flight_Start_Date__c', effectiveStartDate);
        fareFieldValueMap2.put('Effective_Flight_End_Date__c', effectiveEndDate);
        fareFieldValueMap2.put('Effective_Ticket_Issue_Start_Date__c', effectiveIssueStartDate);
        fareFieldValueMap2.put('Effective_Ticket_Issue_End_Date__c', effectiveIssueEndDate);
        fareFieldValueMap2.put('Route__c', route);
        fareFieldValueMap2.put('IATA_Code__c', IATACode);
        fareFieldValueMap2.put('Unit_Price_Adult__c', 200000.00);
        fareFieldValueMap2.put('Unit_Price_Child__c', 175000.00);
        fareFieldValueMap2.put('Unit_Price_Infant__c', 150000.00);
        fareFieldValueMap2.put('Is_Weekend__c', 7500.00);
        fareFieldValueMap2.put('Less_than_Minimal_No_of_Pax__c', 5000.00);
        fareFieldValueMap2.put('Minimal_No_of_Pax__c', 15);
        
        TestUtility.createTicketFare(fareFieldValueMap);
        TestUtility.createTicketFares(fareFieldValueMap2,5);
        
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
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        String allocationType = 'SRS';
        
        Map<String,Object> seatAllocationValueMap = new Map<String, Object>();
        seatAllocationValueMap.put('RecordTypeId',seatAllocationID);
        seatAllocationValueMap.put('Final_Sales_Seats__c',finalSeats);
        seatAllocationValueMap.put('Allocated_Seats__c',finalSeats);
        seatAllocationValueMap.put('Case_ID__c',testCase.Id);
        seatAllocationValueMap.put('Allocation_Type__c',allocationType);
        
        TestUtility.createSeatAllocation(seatAllocationValueMap);
        
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
        
        Seat_Allocation_and_Ticketing__c testSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
		List<Id> targetId = new List<Id>();
        targetId.add(testSeatAllocation.Id);
		        
        //Assert original fare values
        system.assertEquals(testSeatAllocation.Initial_Unit_Price_Adult__c, 112500);
        system.assertEquals(testSeatAllocation.Initial_Unit_Price_Child__c, 87500);
        system.assertEquals(testSeatAllocation.Initial_Unit_Price_Infant__c, 51250);
        //system.assertEquals(testSeatAllocation.Final_Unit_Price_Adult__c, 112500);
        //system.assertEquals(testSeatAllocation.Final_Unit_Price_Child__c, 87500);
        //system.assertEquals(testSeatAllocation.Final_Unit_Price_Infant__c, 62500);
        
        //Change testCase Departing Flight Number and Returning Flight Number
        testCase.Departing_Flight_Number__c = departingFlight2;
        testCase.Returning_Flight_Number__c = returningFlight2;
        
        //Commence test
        Test.startTest();
        Database.SaveResult UpdateResult = database.update(testCase);
        UpdateTicketFare.getTicketFare(targetId);
        Seat_Allocation_and_Ticketing__c newtestSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        Test.stopTest();
        
        //Assert update succeeded and ticket fare record updated
        system.assertEquals(UpdateResult.isSuccess(), true);
        system.assertEquals(newtestSeatAllocation.Id, testSeatAllocation.Id);
        //Assert new fare values
        system.assertEquals(newtestSeatAllocation.Initial_Unit_Price_Adult__c, 212500);
        system.assertEquals(newtestSeatAllocation.Initial_Unit_Price_Child__c, 187500);
        system.assertEquals(newtestSeatAllocation.Initial_Unit_Price_Infant__c, 151250);
        system.assertEquals(newtestSeatAllocation.Final_Unit_Price_Adult__c, 212500);
        system.assertEquals(newtestSeatAllocation.Final_Unit_Price_Child__c, 187500);
        system.assertEquals(newtestSeatAllocation.Final_Unit_Price_Infant__c, 151250);
    }
    
    public static testMethod void testUpdateTicketFareWith1ValidNewFaresWithLessThan6DaysBetween() {
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
        String departingFlight = 'JX110';
        String departingFlight2 = 'JX210';
        String returningFlight = 'JX101';
        String returningFlight2 = 'JX201';
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
        
        Map<String, Object> fareFieldValueMap2 = new Map<String, Object>();
        fareFieldValueMap2.put('Departing_Flight_Number__c', departingFlight2);
        fareFieldValueMap2.put('Returning_Flight_Number__c', returningFlight2);
        fareFieldValueMap2.put('Effective_Flight_Start_Date__c', effectiveStartDate);
        fareFieldValueMap2.put('Effective_Flight_End_Date__c', effectiveEndDate);
        fareFieldValueMap2.put('Effective_Ticket_Issue_Start_Date__c', effectiveIssueStartDate);
        fareFieldValueMap2.put('Effective_Ticket_Issue_End_Date__c', effectiveIssueEndDate);
        fareFieldValueMap2.put('Route__c', route);
        fareFieldValueMap2.put('IATA_Code__c', IATACode);
        fareFieldValueMap2.put('Unit_Price_Adult__c', 200000.00);
        fareFieldValueMap2.put('Unit_Price_Child__c', 175000.00);
        fareFieldValueMap2.put('Unit_Price_Infant__c', 150000.00);
        fareFieldValueMap2.put('Is_Weekend__c', 7500.00);
        fareFieldValueMap2.put('Less_than_Minimal_No_of_Pax__c', 5000.00);
        fareFieldValueMap2.put('Minimal_No_of_Pax__c', 15);
        
        TestUtility.createTicketFare(fareFieldValueMap);
        TestUtility.createTicketFare(fareFieldValueMap2);
        
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
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        String allocationType = 'SRS';
        
        Map<String,Object> seatAllocationValueMap = new Map<String, Object>();
        seatAllocationValueMap.put('RecordTypeId',seatAllocationID);
        seatAllocationValueMap.put('Final_Sales_Seats__c',finalSeats);
        seatAllocationValueMap.put('Allocated_Seats__c',finalSeats);
        seatAllocationValueMap.put('Case_ID__c',testCase.Id);
        seatAllocationValueMap.put('Allocation_Type__c',allocationType);
        
        TestUtility.createSeatAllocation(seatAllocationValueMap);
        
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
        
        Seat_Allocation_and_Ticketing__c testSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
		List<Id> targetId = new List<Id>();
        targetId.add(testSeatAllocation.Id);
		        
        //Assert original fare values
        system.assertEquals(testSeatAllocation.Initial_Unit_Price_Adult__c, 112500);
        system.assertEquals(testSeatAllocation.Initial_Unit_Price_Child__c, 87500);
        system.assertEquals(testSeatAllocation.Initial_Unit_Price_Infant__c, 51250);
        //system.assertEquals(testSeatAllocation.Final_Unit_Price_Adult__c, 112500);
        //system.assertEquals(testSeatAllocation.Final_Unit_Price_Child__c, 87500);
        //system.assertEquals(testSeatAllocation.Final_Unit_Price_Infant__c, 62500);
        
        //Change testCase Departing Flight Number and Returning Flight Number
        testCase.Departing_Flight_Number__c = departingFlight2;
        testCase.Returning_Flight_Number__c = returningFlight2;
        
        //Commence test
        Test.startTest();
        Database.SaveResult UpdateResult = database.update(testCase);
        UpdateTicketFare.getTicketFare(targetId);
        Seat_Allocation_and_Ticketing__c newtestSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        Test.stopTest();
        
        //Assert update succeeded and ticket fare record updated
        system.assertEquals(UpdateResult.isSuccess(), true);
        system.assertEquals(newtestSeatAllocation.Id, testSeatAllocation.Id);
        //Assert new fare values
        system.assertEquals(newtestSeatAllocation.Initial_Unit_Price_Adult__c, 212500);
        system.assertEquals(newtestSeatAllocation.Initial_Unit_Price_Child__c, 187500);
        system.assertEquals(newtestSeatAllocation.Initial_Unit_Price_Infant__c, 151250);
        system.assertEquals(newtestSeatAllocation.Final_Unit_Price_Adult__c, 212500);
        system.assertEquals(newtestSeatAllocation.Final_Unit_Price_Child__c, 187500);
        system.assertEquals(newtestSeatAllocation.Final_Unit_Price_Infant__c, 151250);
    }
    
    public static testMethod void testUpdateTicketFareWith1InvalidNewFare() {
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
        String departingFlight = 'JX110';
        String departingFlight2 = 'JX210';
        String departingFlight3 = 'JX310';
        String returningFlight = 'JX101';
        String returningFlight2 = 'JX201';
        String returningFlight3 = 'JX301';
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
        
        Map<String, Object> fareFieldValueMap2 = new Map<String, Object>();
        fareFieldValueMap2.put('Departing_Flight_Number__c', departingFlight2);
        fareFieldValueMap2.put('Returning_Flight_Number__c', returningFlight2);
        fareFieldValueMap2.put('Effective_Flight_Start_Date__c', effectiveStartDate);
        fareFieldValueMap2.put('Effective_Flight_End_Date__c', effectiveEndDate);
        fareFieldValueMap2.put('Effective_Ticket_Issue_Start_Date__c', effectiveIssueStartDate);
        fareFieldValueMap2.put('Effective_Ticket_Issue_End_Date__c', effectiveIssueEndDate);
        fareFieldValueMap2.put('Route__c', route);
        fareFieldValueMap2.put('IATA_Code__c', IATACode);
        fareFieldValueMap2.put('Unit_Price_Adult__c', 200000.00);
        fareFieldValueMap2.put('Unit_Price_Child__c', 175000.00);
        fareFieldValueMap2.put('Unit_Price_Infant__c', 150000.00);
        fareFieldValueMap2.put('Is_Weekend__c', 7500.00);
        fareFieldValueMap2.put('Less_than_Minimal_No_of_Pax__c', 5000.00);
        fareFieldValueMap2.put('Minimal_No_of_Pax__c', 15);
        
        TestUtility.createTicketFare(fareFieldValueMap);
        TestUtility.createTicketFare(fareFieldValueMap2);
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
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        String allocationType = 'SRS';
        
        Map<String,Object> seatAllocationValueMap = new Map<String, Object>();
        seatAllocationValueMap.put('RecordTypeId',seatAllocationID);
        seatAllocationValueMap.put('Final_Sales_Seats__c',finalSeats);
        seatAllocationValueMap.put('Allocated_Seats__c',finalSeats);
        seatAllocationValueMap.put('Case_ID__c',testCase.Id);
        seatAllocationValueMap.put('Allocation_Type__c',allocationType);
        
        TestUtility.createSeatAllocation(seatAllocationValueMap);
        
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
        
        Seat_Allocation_and_Ticketing__c testSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
		List<Id> targetId = new List<Id>();
        targetId.add(testSeatAllocation.Id);
		        
        //Assert original fare values
        system.assertEquals(testSeatAllocation.Initial_Unit_Price_Adult__c, 112500);
        system.assertEquals(testSeatAllocation.Initial_Unit_Price_Child__c, 87500);
        system.assertEquals(testSeatAllocation.Initial_Unit_Price_Infant__c, 51250);
        //system.assertEquals(testSeatAllocation.Final_Unit_Price_Adult__c, 112500);
        //system.assertEquals(testSeatAllocation.Final_Unit_Price_Child__c, 87500);
        //system.assertEquals(testSeatAllocation.Final_Unit_Price_Infant__c, 62500);
        
        //Change testCase Departing Flight Number and Returning Flight Number
        testCase.Departing_Flight_Number__c = departingFlight3;
        testCase.Returning_Flight_Number__c = returningFlight3;
        
        //Commence test
        Test.startTest();
        Database.SaveResult UpdateResult = database.update(testCase);
        UpdateTicketFare.getTicketFare(targetId);
        Seat_Allocation_and_Ticketing__c newtestSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        Test.stopTest();
        
        //Assert update succeeded and ticket fare record updated
        system.assertEquals(UpdateResult.isSuccess(), true);
        system.assertEquals(newtestSeatAllocation.Id, testSeatAllocation.Id);
        //Assert new fare values
        system.assertEquals(newtestSeatAllocation.Initial_Unit_Price_Adult__c, 112500);
        system.assertEquals(newtestSeatAllocation.Initial_Unit_Price_Child__c, 87500);
        system.assertEquals(newtestSeatAllocation.Initial_Unit_Price_Infant__c, 51250);
        system.assertEquals(newtestSeatAllocation.Final_Unit_Price_Adult__c, null);
        system.assertEquals(newtestSeatAllocation.Final_Unit_Price_Child__c, null);
        system.assertEquals(newtestSeatAllocation.Final_Unit_Price_Infant__c, null);
    }
}