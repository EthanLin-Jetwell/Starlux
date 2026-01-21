@isTest
public class ContactTriggerHandler_Test {
    public static testMethod void updateValidContactEmails() {
        //Create Account Record
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        ID accountTravelRecordID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
        Account travelAgency = new Account(RecordTypeId = accountTravelRecordID, Name = 'Test Agency', IATA_MSO_Code__c = '123456', Cash_Payment_Only__c = true);
        insert travelAgency;
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
       
        //Create Contact Record
        Map<String, Object> contactFieldValueMap = new Map<String, Object>();
        
        contactFieldValueMap.put('AccountId', testAccount.Id);
        contactFieldValueMap.put('Alternate_Email_1__c', 'altemail1@email.com');
        contactFieldValueMap.put('Alternate_Email_2__c', 'altemail2@email.com');
        contactFieldValueMap.put('Alternate_Email_3__c', 'altemail3@email.com');
        contactFieldValueMap.put('LastName', 'Contact');
        contactFieldValueMap.put('FirstName', 'Test');
        contactFieldValueMap.put('Email', 'test@email.com');
        TestUtility.createContact(contactFieldValueMap);
		
        List<String> contactFields = new List<String>();
        contactFields.add('Alternate_Email_1__c');
        contactFields.add('Alternate_Email_2__c');
        contactFields.add('Alternate_Email_3__c');
        Contact testContact = (Contact) TestUtility.getContact(contactFields);
        
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
        caseFields.add('Travel_Agent_Alternate_Email_1__c');
        caseFields.add('Travel_Agent_Alternate_Email_2__c');
        caseFields.add('Travel_Agent_Alternate_Email_3__c');        
		Case testCase = (Case) TestUtility.getCase(caseFields);  
        
        //Create Seat Allocation record
        Map<String, Object> seatFieldValueMap = new Map<String, Object>();
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
                
        seatFieldValueMap.put('RecordTypeId', seatAllocationID);
        seatFieldValueMap.put('Case_ID__c', testCase.Id);
        seatFieldValueMap.put('Allocation_Type__c', 'SRS');
        seatFieldValueMap.put('Allocated_Seats__c', 50);
        seatFieldValueMap.put('Booking_Reference_PNR__c', 'PNR123');
        TestUtility.createSeatAllocation(seatFieldValueMap);
        
        List<String> seatAllocationFields = new List<String>();
        seatAllocationFields.add('Travel_Agent_Alternate_Email_1__c');
        seatAllocationFields.add('Travel_Agent_Alternate_Email_2__c');
        seatAllocationFields.add('Travel_Agent_Alternate_Email_3__c');
        Seat_Allocation_and_Ticketing__c testSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        
        //Create Sales Seat record
        Map<String, Object> salesFieldValueMap = new Map<String, Object>();
        salesFieldValueMap.put('Case_ID__c', testCase.Id);
        TestUtility.createSeat(salesFieldValueMap);
        
        List<String> salesAllocationFields = new List<String>();
        salesAllocationFields.add('Travel_Agent_Alternate_Email_1__c');
        salesAllocationFields.add('Travel_Agent_Alternate_Email_2__c');
        salesAllocationFields.add('Travel_Agent_Alternate_Email_3__c');
        Seat_Sales_Tracking__c testSales = (Seat_Sales_Tracking__c) TestUtility.getSeat(salesAllocationFields);
        
        //Assert original values
        system.assertEquals(testContact.Alternate_Email_1__c, 'altemail1@email.com');
        system.assertEquals(testContact.Alternate_Email_2__c, 'altemail2@email.com');
        system.assertEquals(testContact.Alternate_Email_3__c, 'altemail3@email.com');
        system.assertEquals(testSeatAllocation.Travel_Agent_Alternate_Email_1__c, 'altemail1@email.com');
        system.assertEquals(testSeatAllocation.Travel_Agent_Alternate_Email_2__c, 'altemail2@email.com');
        system.assertEquals(testSeatAllocation.Travel_Agent_Alternate_Email_3__c, 'altemail3@email.com');
        system.assertEquals(testSales.Travel_Agent_Alternate_Email_1__c, 'altemail1@email.com');
        system.assertEquals(testSales.Travel_Agent_Alternate_Email_2__c, 'altemail2@email.com');
        system.assertEquals(testSales.Travel_Agent_Alternate_Email_3__c, 'altemail3@email.com');
        system.assertEquals(testCase.Travel_Agent_Alternate_Email_1__c, 'altemail1@email.com');
        system.assertEquals(testCase.Travel_Agent_Alternate_Email_2__c, 'altemail2@email.com');
        system.assertEquals(testCase.Travel_Agent_Alternate_Email_3__c, 'altemail3@email.com');
        
        //Update new email values for Contact record
        testContact.Alternate_Email_1__c = 'newemail1@email.com';
        testContact.Alternate_Email_2__c = 'newemail2@email.com';
        testContact.Alternate_Email_3__c = 'newemail3@email.com';
        
        //Commence test
        Test.startTest();
        Database.SaveResult saveResult = database.update(testContact);
        Test.stopTest();
        
        //Assert update result
        system.assertEquals(True, saveResult.isSuccess());
        
        //Query for new updated Case, Seat and Sales records
        Case updatedCase = (Case) TestUtility.getCase(caseFields);
        Seat_Allocation_and_Ticketing__c updatedSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        Seat_Sales_Tracking__c updatedSales = (Seat_Sales_Tracking__c) TestUtility.getSeat(salesAllocationFields);
        
        //Assert test results
        system.assertEquals(updatedCase.Travel_Agent_Alternate_Email_1__c, testContact.Alternate_Email_1__c);
        system.assertEquals(updatedCase.Travel_Agent_Alternate_Email_2__c, testContact.Alternate_Email_2__c);
        system.assertEquals(updatedCase.Travel_Agent_Alternate_Email_3__c, testContact.Alternate_Email_3__c);
        system.assertEquals(updatedSeatAllocation.Travel_Agent_Alternate_Email_1__c, testContact.Alternate_Email_1__c);
        system.assertEquals(updatedSeatAllocation.Travel_Agent_Alternate_Email_2__c, testContact.Alternate_Email_2__c);
        system.assertEquals(updatedSeatAllocation.Travel_Agent_Alternate_Email_3__c, testContact.Alternate_Email_3__c);
        system.assertEquals(updatedSales.Travel_Agent_Alternate_Email_1__c, testContact.Alternate_Email_1__c);
        system.assertEquals(updatedSales.Travel_Agent_Alternate_Email_2__c, testContact.Alternate_Email_2__c);
        system.assertEquals(updatedSales.Travel_Agent_Alternate_Email_3__c, testContact.Alternate_Email_3__c);
    }
    
    public static testMethod void updateInvalidContactEmails() {
        //Create Account Record
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        ID accountTravelRecordID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
        Account travelAgency = new Account(RecordTypeId = accountTravelRecordID, Name = 'Test Agency', IATA_MSO_Code__c = '123456', Cash_Payment_Only__c = true);
        insert travelAgency;
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
       
        //Create Contact Records
        Map<String, Object> contactFieldValueMap = new Map<String, Object>();
        Map<String, Object> contactFieldValueMap2 = new Map<String, Object>();
        
        contactFieldValueMap.put('AccountId', testAccount.Id);
        contactFieldValueMap.put('Alternate_Email_1__c', 'altemail1@email.com');
        contactFieldValueMap.put('Alternate_Email_2__c', 'altemail2@email.com');
        contactFieldValueMap.put('Alternate_Email_3__c', 'altemail3@email.com');
        contactFieldValueMap.put('LastName', 'Contact');
        contactFieldValueMap.put('FirstName', 'Test');
        contactFieldValueMap.put('Email', 'test@email.com');
        
        contactFieldValueMap2.put('AccountId', testAccount.Id);
        contactFieldValueMap2.put('Alternate_Email_1__c', 'altemail11@email.com');
        contactFieldValueMap2.put('Alternate_Email_2__c', 'altemail22@email.com');
        contactFieldValueMap2.put('Alternate_Email_3__c', 'altemail33@email.com');
        contactFieldValueMap2.put('LastName', 'Contact1');
        contactFieldValueMap2.put('FirstName', 'Test1');
        contactFieldValueMap2.put('Email', 'test1@email.com');
        
        TestUtility.createContact(contactFieldValueMap);
        TestUtility.createContact(contactFieldValueMap2);
		
        List<String> contactFields = new List<String>();
        contactFields.add('Alternate_Email_1__c');
        contactFields.add('Alternate_Email_2__c');
        contactFields.add('Alternate_Email_3__c');
        List<Contact> testContactList = (List<Contact>) TestUtility.getContacts(contactFields);
        Contact testContactValid = testContactList[0];
        Contact testContactInvalid = testContactList[1];
        
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
        Map<String, Object> caseFieldValueMap2 = new Map<String, Object>();
        
        caseFieldValueMap.put('RecordTypeId', caseRecordID);
        caseFieldValueMap.put('AccountId', testAccount.Id); 
        caseFieldValueMap.put('Departing_Flight_Date__c', departingDate);
        caseFieldValueMap.put('Returning_Flight_Date__c', returningDate); 
        caseFieldValueMap.put('Departing_Flight_Number__c', departingFlight);
        caseFieldValueMap.put('Returning_Flight_Number__c', returningFlight);
        caseFieldValueMap.put('Route__c', route);
        caseFieldValueMap.put('Status', 'New');
        caseFieldValueMap.put('ContactId', testContactValid.Id);
        TestUtility.createCase(caseFieldValueMap);
        
        caseFieldValueMap2.put('RecordTypeId', caseRecordID);
        caseFieldValueMap2.put('AccountId', testAccount.Id); 
        caseFieldValueMap2.put('Departing_Flight_Date__c', departingDate);
        caseFieldValueMap2.put('Returning_Flight_Date__c', returningDate); 
        caseFieldValueMap2.put('Departing_Flight_Number__c', departingFlight);
        caseFieldValueMap2.put('Returning_Flight_Number__c', returningFlight);
        caseFieldValueMap2.put('Route__c', route);
        caseFieldValueMap2.put('Status', 'New');
        caseFieldValueMap2.put('ContactId', testContactInvalid.Id);
        TestUtility.createCase(caseFieldValueMap2);
        
        List<String> caseFields = new List<String>();
        caseFields.add('Travel_Agent_Alternate_Email_1__c');
        caseFields.add('Travel_Agent_Alternate_Email_2__c');
        caseFields.add('Travel_Agent_Alternate_Email_3__c');        
		List<Case> testCaseList = (List<Case>) TestUtility.getCases(caseFields);  
        Case testCaseValid = testCaseList[0];
        Case testCaseInvalid = testCaseList[1];
        
        //Create Seat Allocation record
        Map<String, Object> seatFieldValueMap = new Map<String, Object>();
        ID seatAllocationID = Schema.SObjectType.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
                
        seatFieldValueMap.put('RecordTypeId', seatAllocationID);
        seatFieldValueMap.put('Case_ID__c', testCaseValid.Id);
        seatFieldValueMap.put('Allocation_Type__c', 'SRS');
        seatFieldValueMap.put('Allocated_Seats__c', 50);
        seatFieldValueMap.put('Booking_Reference_PNR__c', 'PNR123');
        TestUtility.createSeatAllocation(seatFieldValueMap);
        
        List<String> seatAllocationFields = new List<String>();
        seatAllocationFields.add('Travel_Agent_Alternate_Email_1__c');
        seatAllocationFields.add('Travel_Agent_Alternate_Email_2__c');
        seatAllocationFields.add('Travel_Agent_Alternate_Email_3__c');
        Seat_Allocation_and_Ticketing__c testSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        
        //Create Sales Seat record
        Map<String, Object> salesFieldValueMap = new Map<String, Object>();
        salesFieldValueMap.put('Case_ID__c', testCaseValid.Id);
        TestUtility.createSeat(salesFieldValueMap);
        
        List<String> salesAllocationFields = new List<String>();
        salesAllocationFields.add('Travel_Agent_Alternate_Email_1__c');
        salesAllocationFields.add('Travel_Agent_Alternate_Email_2__c');
        salesAllocationFields.add('Travel_Agent_Alternate_Email_3__c');
        Seat_Sales_Tracking__c testSales = (Seat_Sales_Tracking__c) TestUtility.getSeat(salesAllocationFields);
        
        //Assert original values
        system.assertEquals(testContactValid.Alternate_Email_1__c, 'altemail1@email.com');
        system.assertEquals(testContactValid.Alternate_Email_2__c, 'altemail2@email.com');
        system.assertEquals(testContactValid.Alternate_Email_3__c, 'altemail3@email.com');
        system.assertEquals(testContactInvalid.Alternate_Email_1__c, 'altemail11@email.com');
        system.assertEquals(testContactInvalid.Alternate_Email_2__c, 'altemail22@email.com');
        system.assertEquals(testContactInvalid.Alternate_Email_3__c, 'altemail33@email.com');
        system.assertEquals(testSeatAllocation.Travel_Agent_Alternate_Email_1__c, 'altemail1@email.com');
        system.assertEquals(testSeatAllocation.Travel_Agent_Alternate_Email_2__c, 'altemail2@email.com');
        system.assertEquals(testSeatAllocation.Travel_Agent_Alternate_Email_3__c, 'altemail3@email.com');
        system.assertEquals(testSales.Travel_Agent_Alternate_Email_1__c, 'altemail1@email.com');
        system.assertEquals(testSales.Travel_Agent_Alternate_Email_2__c, 'altemail2@email.com');
        system.assertEquals(testSales.Travel_Agent_Alternate_Email_3__c, 'altemail3@email.com');
        system.assertEquals(testCaseValid.Travel_Agent_Alternate_Email_1__c, 'altemail1@email.com');
        system.assertEquals(testCaseValid.Travel_Agent_Alternate_Email_2__c, 'altemail2@email.com');
        system.assertEquals(testCaseValid.Travel_Agent_Alternate_Email_3__c, 'altemail3@email.com');
        system.assertEquals(testCaseInvalid.Travel_Agent_Alternate_Email_1__c, 'altemail11@email.com');
        system.assertEquals(testCaseInvalid.Travel_Agent_Alternate_Email_2__c, 'altemail22@email.com');
        system.assertEquals(testCaseInvalid.Travel_Agent_Alternate_Email_3__c, 'altemail33@email.com');
        
        //Update new email values for Contact record
        testContactInvalid.Alternate_Email_1__c = 'newemail1@email.com';
        testContactInvalid.Alternate_Email_2__c = 'newemail2@email.com';
        testContactInvalid.Alternate_Email_3__c = 'newemail3@email.com';
        
        //Commence test
        Test.startTest();
        Database.SaveResult saveResult = database.update(testContactInvalid);
        Test.stopTest();
        
        //Assert update result
        system.assertEquals(True, saveResult.isSuccess());
        
        //Query for new updated Case, Seat and Sales records
        List<Case> updatedCaseList = (List<Case>) TestUtility.getCases(caseFields);
        Seat_Allocation_and_Ticketing__c updatedSeatAllocation = (Seat_Allocation_and_Ticketing__c) TestUtility.getSeatAllocation(seatAllocationFields);
        Seat_Sales_Tracking__c updatedSales = (Seat_Sales_Tracking__c) TestUtility.getSeat(salesAllocationFields);
        
        //Assert test results
        for (Case c : updatedCaseList) {
            if (c.Id == testCaseValid.Id) {
                system.assertNotEquals(c.Travel_Agent_Alternate_Email_1__c, 'newemail1@email.com');
        		system.assertNotEquals(c.Travel_Agent_Alternate_Email_2__c, 'newemail2@email.com');
        		system.assertNotEquals(c.Travel_Agent_Alternate_Email_3__c, 'newemail3@email.com');
            } else {
                system.assertEquals(c.Travel_Agent_Alternate_Email_1__c, 'newemail1@email.com');
        		system.assertEquals(c.Travel_Agent_Alternate_Email_2__c, 'newemail2@email.com');
        		system.assertEquals(c.Travel_Agent_Alternate_Email_3__c, 'newemail3@email.com');
            }
        }
        system.assertNotEquals(updatedSeatAllocation.Travel_Agent_Alternate_Email_1__c, 'newemail1@email.com');
        system.assertNotEquals(updatedSeatAllocation.Travel_Agent_Alternate_Email_2__c, 'newemail2@email.com');
        system.assertNotEquals(updatedSeatAllocation.Travel_Agent_Alternate_Email_3__c, 'newemail3@email.com');
        system.assertNotEquals(updatedSales.Travel_Agent_Alternate_Email_1__c, 'newemail1@email.com');
        system.assertNotEquals(updatedSales.Travel_Agent_Alternate_Email_2__c, 'newemail2@email.com');
        system.assertNotEquals(updatedSales.Travel_Agent_Alternate_Email_3__c, 'newemail3@email.com');
    }
}