/********************************************************************************************************
NAME:			CaseTriggerHandler_Test
AUTHOR:			Aik Meng (aikmeng@salesforce.com)
PURPOSE:		This is the test class for CaseTriggerHandler class

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
17/06/2019      Aik Meng		First version
13/08/2019		Aik Meng		Added new test method for generation of SeatSalesTracking records
23/09/2019		Aik Meng		Added AlternateContactEmails to Contact creation for testSeatSalesTrackingCreation
********************************************************************************************************/

@isTest(SeeAllData=FALSE)

public class CaseTriggerHandler_Test {

    static Integer numRecords = 10;  // Max future calls = 50
    static Id caseRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enquiry_and_Request').getRecordTypeId();
    
    @testSetup static void setup() {
        // Account RecordType = Passenger
		Id accountRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();

        //Create test records of PersonAccount type (Passenger)
        Map < String, Object > accountValueMap = new Map < String, Object > ();
        accountValueMap.put('RecordTypeId', accountRecordTypeID);
        accountValueMap.put('FirstName', 'Harry');
        accountValueMap.put('LastName', 'Potter');
        accountValueMap.put('PersonEmail', 'test1@email.com');
        accountValueMap.put('PersonMobilePhone', '1-111-1111');
        TestUtility.createAccounts(accountValueMap, 1);
        
        accountValueMap.clear();
        accountValueMap.put('RecordTypeId', accountRecordTypeID);
        accountValueMap.put('FirstName', 'Robin');
        accountValueMap.put('LastName', 'Hood');
        accountValueMap.put('PersonEmail', 'test2@email.com');
        accountValueMap.put('PersonMobilePhone', '2-222-2222');
        TestUtility.createAccounts(accountValueMap, 1);

        accountValueMap.clear();
        accountValueMap.put('RecordTypeId', accountRecordTypeID);
        accountValueMap.put('FirstName', 'Little');
        accountValueMap.put('LastName', 'John');
        accountValueMap.put('PersonEmail', 'test3@email.com');
        accountValueMap.put('PersonMobilePhone', '3-333-3333');
        TestUtility.createAccounts(accountValueMap, 1);
    }
    
    public static testMethod void testAccountMatchInSF() {

        List<String > accountQueryFieldsList = new List<String> {
            'PersonEmail',
            'PersonMobilePhone',
            'Phone'
        };        
        List<Account> testAccounts = TestUtility.getAccounts(accountQueryFieldsList);

        Test.startTest();
        
        // CREATE Case records with SuppliedEmail matching testAccount[0]
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', caseRecordTypeID);
        caseFieldValueMap.put('AccountId', NULL);        
        caseFieldValueMap.put('SuppliedEmail', testAccounts[0].PersonEmail);        
        caseFieldValueMap.put('SuppliedPhone', testAccounts[0].PersonMobilePhone); 
        TestUtility.createCases(caseFieldValueMap,numRecords);
        
        // CREATE Case records with SuppliedPhone matching testAccount[1] 
        caseFieldValueMap.clear();
        caseFieldValueMap.put('RecordTypeId', caseRecordTypeID);
        caseFieldValueMap.put('AccountId', NULL);               
        caseFieldValueMap.put('SuppliedPhone', testAccounts[1].PersonMobilePhone); 
        TestUtility.createCases(caseFieldValueMap,numRecords);

        // CREATE Case records with SuppliedPhone matching testAccount[2] 
        caseFieldValueMap.clear();
        caseFieldValueMap.put('RecordTypeId', caseRecordTypeID);
        caseFieldValueMap.put('AccountId', NULL);        
		caseFieldValueMap.put('SuppliedEmail', testAccounts[2].PersonEmail);        
        TestUtility.createCases(caseFieldValueMap,numRecords);
        
        Test.stopTest();

        // CHECK that Case records are linked to correct Account
        System.assertEquals(3*numRecords, [SELECT Count() FROM Case]);
        System.assertEquals(numRecords, [SELECT Count() FROM Case WHERE AccountID =:testAccounts[0].Id]);
        System.assertEquals(numRecords, [SELECT Count() FROM Case WHERE AccountID =:testAccounts[1].Id]);
        System.assertEquals(numRecords, [SELECT Count() FROM Case WHERE AccountID =:testAccounts[2].Id]);

    } // End - testAccountMatchInSF()

    
    public static testMethod void testAccountMatchInMDM() {

        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"success":true,"traceId":"978d3e3f-0cd6-4a9f-8853-148d3347b06b","message":{"code":"200","content":"OK","details":null},"data":{"LastName":"Chang","MiddleName":"Helen","FirstName":"YaTing","PersonTitle":"MRS","Gender__pc":"Female","PersonBirthdate":"1992-08-10T00:00:00+08:00","PersonHomePhone":"886227911000","PersonMobilePhone":"886958299789","PersonEmail":"TEST@STARLUX-AIRLINES.COM","CEM_ID__c":"CEM777","MDM_ID__c":"123451234","Member_ID__pc":"100002434","Card_Tier__pc":"TITC","Card_Tier_Expiry_Date__pc":"2020-05-31","Current_Mileages__pc":"10999","Current_Mileages_Expiry_Date__pc":"2022-01-01","Upgrade_Qualifications__pc":"","Renewal_Qualifications__pc":"","Language_Preference__pc":"Mandarin","Meal_Preference__pc":"","Seat_Preference__pc":"","Duty_Free_Preference__pc":"","Passenger_Type__pc":"VIP"},"links":null,"meta":null}',
            null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);        
        Test.startTest();
        
        // CREATE Case records with SuppliedEmail matching testAccount[0]
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', caseRecordTypeID);
        caseFieldValueMap.put('AccountId', NULL);        
        caseFieldValueMap.put('SuppliedEmail', 'test@starlux-airlines.com');    
        TestUtility.createCases(caseFieldValueMap,1);  // Account created through CRANE API callout
                
        Test.stopTest();
        TestUtility.createCases(caseFieldValueMap,numRecords-1);  // Account matched in SF 

        // CHECK that a new Account is created
		List<Account> acctList = [SELECT Id FROM Account WHERE PersonEmail='test@starlux-airlines.com'];
        System.assertEquals(1, acctList.size());
        
        // CHECK that Case records are linked to the new Account
        System.assertEquals(numRecords, [SELECT Count() FROM Case WHERE AccountId=:acctList[0].Id]);

    }  // End - testAccountMatchInMDM()
    
    
    public static testMethod void testAccountNotFoundInSFandMDM() {

        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"success":false,"traceId":"662053b9-e6f1-4120-9fda-d00eb1e86d26","message":{"code":"404","content":"There is no matching data for your query in account details","details":["There is no matching data for your query in account details"]}}',
//            '{"version":"20190129","status":false,"message":{"code":"404","content":"There is no matching data for your query in account details","details":["There is no matching data for your query in account details"]},"traceId":"e22cb112-727f-487f-b1d4-45861fdf2fd2","result":{"data":[],"count":0,"page":1,"rowPerPage":10,"links":[],"meta":null},"error":{"message":"There is no matching data for your query in account details"},"warning":{"message":null}}',
            null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);        
        Test.startTest();
        
        // CREATE Case records with SuppliedEmail matching testAccount[0]
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', caseRecordTypeID);
        caseFieldValueMap.put('AccountId', NULL);        
        caseFieldValueMap.put('SuppliedPhone', '998877665');
        TestUtility.createCases(caseFieldValueMap,numRecords);
                
        Test.stopTest();

        // CHECK that Case records are NOT linked to Account and also flagged with NO Account match
        System.assertEquals(numRecords, [SELECT Count() FROM Case WHERE AccountId=NULL]);
        System.assertEquals(numRecords, [SELECT Count() FROM Case WHERE Account_Not_Found__c=TRUE]);

    }  // End - testAccountNotFoundInSFandMDM()


    public static testMethod void testSeatSalesTrackingCreation() {
        
        // CREATE test record: Account type (Travel Agency)
		Id accountRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
        Account travelAgency = new Account(
            RecordTypeId=accountRecordTypeID,
            Name='ABC Travel Agency',
            IATA_MSO_Code__c='MSO123456',
            Cash_Payment_Only__c = TRUE
        );
        insert travelAgency;
        List<Account> thisAccount = [SELECT Id FROM Account WHERE recordTypeId=:accountRecordTypeID];
        System.assertEquals(1, thisAccount.size());  // VERIFY record created

        // CREATE test record: Contact of Travel Agency
        Map<String,Object > contactValueMap = new Map<String,Object> ();
        contactValueMap.put('FirstName', 'Kate');
        contactValueMap.put('LastName', 'Tan');
        contactValueMap.put('AccountID', thisAccount[0].Id);  // Link Contact to Travel Agency
        contactValueMap.put('Email', 'kate.tan@test.com');
        contactValueMap.put('Phone', '12228888');
        contactValueMap.put('Alternate_Email_1__c', 'kate1.tan@test.com');  // Alternate contact email
        TestUtility.createContact(contactValueMap);
        List<Contact> thisContact = [SELECT Id FROM Contact WHERE AccountID=:thisAccount[0].Id];
        System.assertEquals(1, thisContact.size());  // VERIFY record created
        
        Test.startTest();
        
        // CREATE GroupBooking Case record
        Id recordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        Date departDate = date.newinstance(2019,6,30);
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', recordTypeID);
        caseFieldValueMap.put('AccountId', thisAccount[0].Id);        
        caseFieldValueMap.put('ContactId', thisContact[0].Id);        
        caseFieldValueMap.put('Origin', 'B2B Portal');        
        caseFieldValueMap.put('Departing_Flight_Date__c', departDate);
        caseFieldValueMap.put('Route__c', 'TPE-MFM-TPE');
        TestUtility.createCases(caseFieldValueMap,numRecords);
        
        Test.stopTest();

        // FETCH App Settings
        /*Application_Setting__mdt appSetting1 = [SELECT
                                            	 Id, MasterLabel, Key__c, Value__c 
                                               FROM 
                                            	 Application_Setting__mdt
											   WHERE 
                                            	 MasterLabel='CaseTrigger_SeatSalesTracking_numOfWeeks' AND Key__c='NumberOfWeeks'  
                                               LIMIT 1];
        Integer numOfWeeks = Integer.valueOf(appSetting1.Value__c);*/
        //Chris 20200415
        Group_Booking_Case_Num_of_Weeks__mdt nWeeks = [SELECT
                                            	 Id, Number_of_Weeks__c 
                                               FROM 
                                            	 Group_Booking_Case_Num_of_Weeks__mdt
											   WHERE 
                                            	 Route__c='TPE-MFM-TPE'  
                                               LIMIT 1];
        
        Integer numOfWeeks = Integer.valueOf(nWeeks.Number_of_Weeks__c);
        
        // CHECK that Case records are linked to correct Account
        System.assertEquals(numRecords, [SELECT Count() FROM Case]);        
        System.assertEquals(numOfWeeks*numRecords, [SELECT Count() FROM Seat_Sales_Tracking__c]);
        // CHECK that alternate contact emails are copied to Case record
        List<Case> caseList = [SELECT Travel_Agent_Alternate_Email_1__c FROM Case LIMIT 1];
        System.assertEquals('kate1.tan@test.com', caseList[0].Travel_Agent_Alternate_Email_1__c);    
    } // End - testSeatSalesTrackingCreation()
}