/********************************************************************************************************
NAME:			UpdateTaxAmount_Test
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the test class for UpdateTaxAmount class

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
25/08/2019      Edmond To		First version
********************************************************************************************************/
@isTest
public class UpdateTaxAmount_Test {
    public static testMethod void testUpdateTaxAmountWith5ValidTaxes() {
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
        Date departingDate = Date.today();
        Date departingDate2 = Date.newInstance(2040,4,5);
        Date returningDate = Date.newInstance(2040,4,10);
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
        
        //Create Tax Amount Records
        Map<String, Object> taxFieldValueMap = new Map<String, Object>();
        taxFieldValueMap.put('Route__c', route);
        taxFieldValueMap.put('Tax_Date__c', departingDate);
        taxFieldValueMap.put('Tax_Amount_Adult__c', 20000.00);
        taxFieldValueMap.put('Tax_Amount_Child__c', 10000.00);
        taxFieldValueMap.put('Tax_Amount_Infant__c', 5000.00);
        
        Map<String, Object> taxFieldValueMap2 = new Map<String, Object>();
        taxFieldValueMap2.put('Route__c', route);
        taxFieldValueMap2.put('Tax_Date__c', departingDate2);
        taxFieldValueMap2.put('Tax_Amount_Adult__c', 40000.00);
        taxFieldValueMap2.put('Tax_Amount_Child__c', 20000.00);
        taxFieldValueMap2.put('Tax_Amount_Infant__c', 10000.00);
        
        TestUtility.createTax(taxFieldValueMap);
        TestUtility.createTax(taxFieldValueMap2);
        //Tax_Details__c testTaxList = (Tax_Details__c) TestUtility.getTax();
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        String allocationType = 'SRS';
        
        Map<String,Object> seatAllocationValueMap = new Map<String, Object>();
        seatAllocationValueMap.put('RecordTypeId',seatAllocationID);
        seatAllocationValueMap.put('Final_Allocated_Seats__c',finalSeats);
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
        
        testSeatAllocation.Tax_Date__c = departingDate2;
        
        //Assert tax values
        system.assertEquals(testSeatAllocation.Initial_Tax_Adult__c, 20000);
        system.assertEquals(testSeatAllocation.Initial_Tax_Child__c, 10000);
        system.assertEquals(testSeatAllocation.Initial_Tax_Infant__c, 5000);
        
        //Commence test
        Test.startTest();
        Database.SaveResult UpdateResult = database.update(testSeatAllocation);
        UpdateTaxAmount.getTaxAmount(targetId);
        Seat_Allocation_and_Ticketing__c newtestSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        Test.stopTest();
        
        //Assert update succeeded and ticket fare record updated
        system.assertEquals(UpdateResult.isSuccess(), true);
        system.assertEquals(newtestSeatAllocation.Id, testSeatAllocation.Id);
        
        //Assert new tax values
        system.assertEquals(newtestSeatAllocation.Initial_Tax_Adult__c, 20000);
        system.assertEquals(newtestSeatAllocation.Initial_Tax_Child__c, 10000);
        system.assertEquals(newtestSeatAllocation.Initial_Tax_Infant__c, 5000);
        system.assertEquals(newtestSeatAllocation.Final_Tax_Adult__c, 40000);
        system.assertEquals(newtestSeatAllocation.Final_Tax_Child__c, 20000);
        system.assertEquals(newtestSeatAllocation.Final_Tax_Infant__c, 10000);
       
    }
    
    public static testMethod void testUpdateTaxAmountWithInvalidDateTax() {
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
        Date departingDate = Date.today();
        Date departingDate2 = Date.newInstance(2040,4,5);
        Date departingDate3 = Date.newInstance(2040,4,6);
        Date returningDate = Date.newInstance(2040,4,10);
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
        
        //Create Tax Amount Records
        Map<String, Object> taxFieldValueMap = new Map<String, Object>();
        taxFieldValueMap.put('Route__c', route);
        taxFieldValueMap.put('Tax_Date__c', departingDate);
        taxFieldValueMap.put('Tax_Amount_Adult__c', 20000.00);
        taxFieldValueMap.put('Tax_Amount_Child__c', 10000.00);
        taxFieldValueMap.put('Tax_Amount_Infant__c', 5000.00);
        
        Map<String, Object> taxFieldValueMap2 = new Map<String, Object>();
        taxFieldValueMap2.put('Route__c', route);
        taxFieldValueMap2.put('Tax_Date__c', departingDate3);
        taxFieldValueMap2.put('Tax_Amount_Adult__c', 40000.00);
        taxFieldValueMap2.put('Tax_Amount_Child__c', 20000.00);
        taxFieldValueMap2.put('Tax_Amount_Infant__c', 10000.00);
        
        TestUtility.createTaxes(taxFieldValueMap,5);
        TestUtility.createTax(taxFieldValueMap2);
        //Tax_Details__c testTaxList = (Tax_Details__c) TestUtility.getTax();
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        String allocationType = 'SRS';
        
        Map<String,Object> seatAllocationValueMap = new Map<String, Object>();
        seatAllocationValueMap.put('RecordTypeId',seatAllocationID);
        seatAllocationValueMap.put('Final_Allocated_Seats__c',finalSeats);
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
        
        testSeatAllocation.Tax_Date__c = departingDate2;
        
        //Assert tax values
        system.assertEquals(testSeatAllocation.Initial_Tax_Adult__c, 20000);
        system.assertEquals(testSeatAllocation.Initial_Tax_Child__c, 10000);
        system.assertEquals(testSeatAllocation.Initial_Tax_Infant__c, 5000);
        
        //Commence test
        Test.startTest();
        Database.SaveResult UpdateResult = database.update(testSeatAllocation);
        UpdateTaxAmount.getTaxAmount(targetId);
        Seat_Allocation_and_Ticketing__c newtestSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        Test.stopTest();
        
        //Assert update succeeded and ticket fare record updated
        system.assertEquals(UpdateResult.isSuccess(), true);
        system.assertEquals(newtestSeatAllocation.Id, testSeatAllocation.Id);
        
        //Assert new tax values
        system.assertEquals(newtestSeatAllocation.Initial_Tax_Adult__c, 20000);
        system.assertEquals(newtestSeatAllocation.Initial_Tax_Child__c, 10000);
        system.assertEquals(newtestSeatAllocation.Initial_Tax_Infant__c, 5000);
        system.assertEquals(newtestSeatAllocation.Final_Tax_Adult__c, null);
        system.assertEquals(newtestSeatAllocation.Final_Tax_Child__c, null);
        system.assertEquals(newtestSeatAllocation.Final_Tax_Infant__c, null);
        
    }
    
    public static testMethod void testUpdateTaxAmountWithMultipleValidTaxes() {
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
        Date departingDate = Date.today();
        Date departingDate2 = Date.newInstance(2040,4,5);
        Date returningDate = Date.newInstance(2040,4,10);
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
        
        //Create Tax Amount Records
        Map<String, Object> taxFieldValueMap = new Map<String, Object>();
        taxFieldValueMap.put('Route__c', route);
        taxFieldValueMap.put('Tax_Date__c', departingDate);
        taxFieldValueMap.put('Tax_Amount_Adult__c', 20000.00);
        taxFieldValueMap.put('Tax_Amount_Child__c', 10000.00);
        taxFieldValueMap.put('Tax_Amount_Infant__c', 5000.00);
        
        Map<String, Object> taxFieldValueMap2 = new Map<String, Object>();
        taxFieldValueMap2.put('Route__c', route);
        taxFieldValueMap2.put('Tax_Date__c', departingDate2);
        taxFieldValueMap2.put('Tax_Amount_Adult__c', 40000.00);
        taxFieldValueMap2.put('Tax_Amount_Child__c', 20000.00);
        taxFieldValueMap2.put('Tax_Amount_Infant__c', 10000.00);
        
        TestUtility.createTax(taxFieldValueMap);
        TestUtility.createTaxes(taxFieldValueMap2, 5);
        //Tax_Details__c testTaxList = (Tax_Details__c) TestUtility.getTax();
        
        //Create Seat Allocation Record
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        Decimal finalSeats = 10;
        String allocationType = 'SRS';
        
        Map<String,Object> seatAllocationValueMap = new Map<String, Object>();
        seatAllocationValueMap.put('RecordTypeId',seatAllocationID);
        seatAllocationValueMap.put('Final_Allocated_Seats__c',finalSeats);
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
        
        testSeatAllocation.Tax_Date__c = departingDate2;
        
        //Assert tax values
        system.assertEquals(testSeatAllocation.Initial_Tax_Adult__c, 20000);
        system.assertEquals(testSeatAllocation.Initial_Tax_Child__c, 10000);
        system.assertEquals(testSeatAllocation.Initial_Tax_Infant__c, 5000);
        
        //Commence test
        Test.startTest();
        Database.SaveResult UpdateResult = database.update(testSeatAllocation);
        UpdateTaxAmount.getTaxAmount(targetId);
        Seat_Allocation_and_Ticketing__c newtestSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        Test.stopTest();
        
        //Assert update succeeded and ticket fare record updated
        system.assertEquals(UpdateResult.isSuccess(), true);
        system.assertEquals(newtestSeatAllocation.Id, testSeatAllocation.Id);
        
        //Assert new tax values
        system.assertEquals(newtestSeatAllocation.Initial_Tax_Adult__c, 20000);
        system.assertEquals(newtestSeatAllocation.Initial_Tax_Child__c, 10000);
        system.assertEquals(newtestSeatAllocation.Initial_Tax_Infant__c, 5000);
        system.assertEquals(newtestSeatAllocation.Final_Tax_Adult__c, 40000);
        system.assertEquals(newtestSeatAllocation.Final_Tax_Child__c, 20000);
        system.assertEquals(newtestSeatAllocation.Final_Tax_Infant__c, 10000);
       
    }
}