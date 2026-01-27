/********************************************************************************************************
NAME:			DynamicListCompControllerTest
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the test class for the apex class DynamicListCompController

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
24/06/2019      Edmond To		First version
28/08/2019		Edmond To		Revised based on new CRANE API payload
********************************************************************************************************/
@isTest
private class DynamicListCompControllerTest {

	@isTest static void retrieveBookingsJobOnCaseTest() {
		String testInterfaceParameter = 'CRANE';
         // retrieve test mode status from custom metadata
        List<Interface_Configuration__mdt> retrieveTestModeStatus = [SELECT test_mode__c FROM Interface_Configuration__mdt where DeveloperName = :testInterfaceParameter];
        Boolean testModeStatus = retrieveTestModeStatus[0].test_mode__c;
        
		//Create account record
        ID personAccountID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        accountFieldValueMap.put('RecordTypeId', personAccountID);
        accountFieldValueMap.put('CEM_ID__c', 'testCEMID');
        TestUtility.createAccount(accountFieldValueMap);
        Sobject testAccount = TestUtility.getAccount();
        
		Case cs = new Case(SuppliedEmail='test@email.com', AccountId=testAccount.Id);
		insert cs;
        
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
        	'{"success":true,"traceId":"1234567-03bf-4c12-80fc-b02ef6d45368","message":{"code":"200","content":"OK","details":null},"data":{"items":[{"Status":"HK","Services_SSR":null,"Arr_Location":"MFM","Flight_No":"JX100","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900030123","PNR":"AAF8JX","Arrival_Date__c":"2019-07-01","Arrival_Time__c":"09:30:00","Passenger":"NANCY CHEN","Departure_Date__c":"2019-07-01","Departure_Time__c":"08:30:00","Day":"MON","Dep_Location":"TPE"},{"Status":"HL","Services_SSR":null,"Arr_Location":"MFM","Flight_No":"JX100","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900030124","PNR":"AAF8JX","Arrival_Date__c":"2019-07-01","Arrival_Time__c":"09:30:00","Passenger":"NANCY CHEN","Departure_Date__c":"2019-07-01","Departure_Time__c":"08:30:00","Day":"MON","Dep_Location":"TPE"}]},"links":{"first":"https://auth-gateway.starlux-airlines.com/crane/api/v1/SSFC/getBookingDetails?page=1","last":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails?page=1","prev":null,"next":null},"meta":{"currentPage":1,"from":1,"path":"https://auth-gateway.starlux-airlines.com/crane/api/v1/SSFC/getBookingDetails","perPage":15,"to":2,"total":2,"lastPage":1}}', 
            null);
        MockHttpResponseGenerator fakeLoginResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
			'{"success":true,"traceId":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","message":{"code":"200","content":"OK","details":["Welcome to STARLUX"]},"data":{"access_token":"xxxxxxxxxx","token_type":"bearer","expires_in":86400},"links":null,"meta":null}',
            null);
        MockHttpResponseGenerator fakeAccountResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"success":false,"traceId":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","message":{"code":"422","content":"The given data was invalid.","details":{"eContactValue":["The e contact value field is required when none of phone country cd / phone number are present."],"phoneNumber":["The phone number field is required when e contact value is not present."]}}}',
            null);  
        Map<String,HttpCalloutMock> mapCallouts = new Map<String,HttpCalloutMock>();
        mapCallouts.put('https://auth-gateway.starlux-airlines.com/crane/api/v1/login',fakeLoginResponse);
        mapCallouts.put('https://auth-gateway.starlux-airlines.com/crane/api/v1/SSFC/getAccount?eContactValue=test@email.com&phoneNumber=null',fakeAccountResponse);
        mapCallouts.put('https://auth-gateway.starlux-airlines.com/crane/api/v1/SSFC/getBookingDetails?cemId=testCEMID',fakeResponse);
        HttpCalloutMock multiCalloutMock = new MultiMockHttpResponseGenerator(mapCallouts);
        
		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
		Test.startTest();
		String resultAsString = DynamicListCompController.doContsructWrapper('CRANE', 'data', 'items', 'Get_Bookings_Job', 'None', cs.Id, 1, 'Case'); 
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
        system.debug('DBG result: '+result);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
        
        if (testmodestatus == True) {
            System.assertEquals(2, allRecords.size());
        } else {
            System.assertEquals(2, allRecords.size());
        }
		
	}

    @isTest static void retrieveBookingsJobOnAccountTest() {
		String testInterfaceParameter = 'CRANE';
         // retrieve test mode status from custom metadata
        List<Interface_Configuration__mdt> retrieveTestModeStatus = [SELECT test_mode__c FROM Interface_Configuration__mdt where DeveloperName = :testInterfaceParameter];
        Boolean testModeStatus = retrieveTestModeStatus[0].test_mode__c;
        
		//Create account record
        ID personAccountID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        accountFieldValueMap.put('RecordTypeId', personAccountID);
        TestUtility.createAccount(accountFieldValueMap);
        Sobject testAccount = TestUtility.getAccount();
        
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"success":true,"traceId":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","message":{"code":"200","content":"OK","details":null},"data":{"items":[{"Status":"confirm","Services_SSR":null,"Arr_Location":"MFM","Flight_No":"JX100","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900001","PNR":"9WW7JX","Arr_Time":"2019-07-01 09:30","Passenger":"ELSE LIN","Dep_Time":"2019-07-01 08:30","Day":"MON","Dep_Location":"TPE"},{"Status":"confirm","Services_SSR":null,"Arr_Location":"TPE","Flight_No":"JX101","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900001","PNR":"5KK7JX","Arr_Time":"2019-10-01 11:30","Passenger":"ELSE LIN","Dep_Time":"2019-10-01 10:30","Day":"TUE","Dep_Location":"MFM"}]},"links":{"first":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails?page=1","last":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails?page=1","prev":null,"next":null},"meta":{"currentPage":1,"from":1,"path":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails","perPage":15,"to":2,"total":2,"lastPage":1}}',
            null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Test.startTest();
		String resultAsString = DynamicListCompController.doContsructAccountWrapper('CRANE', 'data', 'items', 'Get_Bookings_Job', 'None', testAccount.Id, 1, 'Account'); 
        //String resultAsString = DynamicListCompController.doContsructWrapper('<External System>', 'result', 'objects', '<Operating Setting>', 'None', cs.Id, 1, 'Active Entitlements'); //Replace parameters in method with desired inputs
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
        
        if (testmodestatus == True) {
            System.assertEquals(2, allRecords.size());
        } else {
            System.assertEquals(2, allRecords.size());
        }
		
	}
    
    @isTest static void showAllBookingsJobOnCaseTest() {
//20190901		String testInterfaceParameter = 'DIH';
		String testInterfaceParameter = 'CRANE';
         // retrieve test mode status from custom metadata
        List<Interface_Configuration__mdt> retrieveTestModeStatus = [SELECT test_mode__c FROM Interface_Configuration__mdt where DeveloperName = :testInterfaceParameter];
        Boolean testModeStatus = retrieveTestModeStatus[0].test_mode__c;
        
		//Create account record
        ID personAccountID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        accountFieldValueMap.put('RecordTypeId', personAccountID);
        accountFieldValueMap.put('CEM_ID__c', 'testCEMID');
        TestUtility.createAccount(accountFieldValueMap);
        Sobject testAccount = TestUtility.getAccount();
        
		Case cs = new Case(SuppliedEmail='test@email.com', AccountId=testAccount.Id);
		insert cs;
        
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
        	'{"success":true,"traceId":"1234567-03bf-4c12-80fc-b02ef6d45368","message":{"code":"200","content":"OK","details":null},"data":{"items":[{"Status":"HK","Services_SSR":null,"Arr_Location":"MFM","Flight_No":"JX100","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900030123","PNR":"AAF8JX","Arrival_Date__c":"2019-07-01","Arrival_Time__c":"09:30:00","Passenger":"NANCY CHEN","Departure_Date__c":"2019-07-01","Departure_Time__c":"08:30:00","Day":"MON","Dep_Location":"TPE"},{"Status":"HL","Services_SSR":null,"Arr_Location":"MFM","Flight_No":"JX100","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900030124","PNR":"AAF8JX","Arrival_Date__c":"2019-07-01","Arrival_Time__c":"09:30:00","Passenger":"NANCY CHEN","Departure_Date__c":"2019-07-01","Departure_Time__c":"08:30:00","Day":"MON","Dep_Location":"TPE"}]},"links":{"first":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails?page=1","last":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails?page=1","prev":null,"next":null},"meta":{"currentPage":1,"from":1,"path":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails","perPage":15,"to":2,"total":2,"lastPage":1}}', 
            null);
        MockHttpResponseGenerator fakeLoginResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
			'{"success":true,"traceId":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","message":{"code":"200","content":"OK","details":["Welcome to STARLUX"]},"data":{"access_token":"xxxxxxxxxx","token_type":"bearer","expires_in":86400},"links":null,"meta":null}',
            null);
        MockHttpResponseGenerator fakeAccountResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"success":false,"traceId":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","message":{"code":"422","content":"The given data was invalid.","details":{"eContactValue":["The e contact value field is required when none of phone country cd / phone number are present."],"phoneNumber":["The phone number field is required when e contact value is not present."]}}}',
            null);  
        Map<String,HttpCalloutMock> mapCallouts = new Map<String,HttpCalloutMock>();
        mapCallouts.put('https://auth-gateway-uat.starlux-airlines.com/crane/api/v1/login',fakeLoginResponse);
        mapCallouts.put('https://auth-gateway-uat.starlux-airlines.com/crane/api/v1/SSFC/getAccount?eContactValue=test@email.com&phoneNumber=null',fakeAccountResponse);
        mapCallouts.put('https://auth-gateway-uat.starlux-airlines.com/crane/api/v1/SSFC/getBookingDetails?cemId=testCEMID',fakeResponse);
        HttpCalloutMock multiCalloutMock = new MultiMockHttpResponseGenerator(mapCallouts);
        
		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
		Test.startTest();
		String resultAsString = DynamicListCompController.doContsructWrapperSubDetails('CRANE', 'data', 'items', 'Get_Bookings_Job', 'None', cs.Id, 'Case'); 
        //String resultAsString = DynamicListCompController.doContsructWrapper('<External System>', 'result', 'objects', '<Operating Setting>', 'None', cs.Id, 1, 'Active Entitlements'); //Replace parameters in method with desired inputs
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
        
        if (testmodestatus == True) {
            System.assertEquals(2, allRecords.size());
        } else {
            System.assertEquals(2, allRecords.size());
        }
		
	}
    
    @isTest static void showAllBookingsJobOnAccountTest() {
		String testInterfaceParameter = 'CRANE';
         // retrieve test mode status from custom metadata
        List<Interface_Configuration__mdt> retrieveTestModeStatus = [SELECT test_mode__c FROM Interface_Configuration__mdt where DeveloperName = :testInterfaceParameter];
        Boolean testModeStatus = retrieveTestModeStatus[0].test_mode__c;
        
		//Create account record
        ID personAccountID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        accountFieldValueMap.put('RecordTypeId', personAccountID);
        TestUtility.createAccount(accountFieldValueMap);
        Sobject testAccount = TestUtility.getAccount();
        
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"success":true,"traceId":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","message":{"code":"200","content":"OK","details":null},"data":{"items":[{"Status":"confirm","Services_SSR":null,"Arr_Location":"MFM","Flight_No":"JX100","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900001","PNR":"9WW7JX","Arr_Time":"2019-07-01 09:30","Passenger":"ELSE LIN","Dep_Time":"2019-07-01 08:30","Day":"MON","Dep_Location":"TPE"},{"Status":"confirm","Services_SSR":null,"Arr_Location":"TPE","Flight_No":"JX101","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900001","PNR":"5KK7JX","Arr_Time":"2019-10-01 11:30","Passenger":"ELSE LIN","Dep_Time":"2019-10-01 10:30","Day":"TUE","Dep_Location":"MFM"}]},"links":{"first":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails?page=1","last":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails?page=1","prev":null,"next":null},"meta":{"currentPage":1,"from":1,"path":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails","perPage":15,"to":2,"total":2,"lastPage":1}}',
            null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Test.startTest();
		String resultAsString = DynamicListCompController.doContsructWrapperSubDetails('CRANE', 'data', 'items', 'Get_Bookings_Job', 'None', testAccount.Id, 'Account'); 
        //String resultAsString = DynamicListCompController.doContsructWrapper('<External System>', 'result', 'objects', '<Operating Setting>', 'None', cs.Id, 1, 'Active Entitlements'); //Replace parameters in method with desired inputs
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
        
        if (testmodestatus == True) {
            System.assertEquals(2, allRecords.size());
        } else {
            System.assertEquals(2, allRecords.size());
        }
		
	}
    
    @isTest static void showAllBookingsJobOnInvalidAccountTest() {
		String testInterfaceParameter = 'CRANE';
         // retrieve test mode status from custom metadata
        List<Interface_Configuration__mdt> retrieveTestModeStatus = [SELECT test_mode__c FROM Interface_Configuration__mdt where DeveloperName = :testInterfaceParameter];
        Boolean testModeStatus = retrieveTestModeStatus[0].test_mode__c;
        
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"success":true,"traceId":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","message":{"code":"200","content":"OK","details":null},"data":{"items":[{"Status":"confirm","Services_SSR":null,"Arr_Location":"MFM","Flight_No":"JX100","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900001","PNR":"9WW7JX","Arr_Time":"2019-07-01 09:30","Passenger":"ELSE LIN","Dep_Time":"2019-07-01 08:30","Day":"MON","Dep_Location":"TPE"},{"Status":"confirm","Services_SSR":null,"Arr_Location":"TPE","Flight_No":"JX101","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900001","PNR":"5KK7JX","Arr_Time":"2019-10-01 11:30","Passenger":"ELSE LIN","Dep_Time":"2019-10-01 10:30","Day":"TUE","Dep_Location":"MFM"}]},"links":{"first":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails?page=1","last":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails?page=1","prev":null,"next":null},"meta":{"currentPage":1,"from":1,"path":"https://crane-uat.starlux-airlines.com/api/v1/SSFC/getBookingDetails","perPage":15,"to":2,"total":2,"lastPage":1}}',
            null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Test.startTest();
        try {
			String resultAsString = DynamicListCompController.doContsructWrapperSubDetails('CRANE', 'data', 'items', 'Get_Bookings_Job', 'None', null, 'Account'); 
        	Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
			List<Object> allrecords = (List<Object>)result.get('AllRecords');
        } catch (Exception e) {
            System.assertEquals('Attempt to de-reference a null object', e.getMessage());
        }
        Test.stopTest();
		
	}


    /*
	@isTest static void retrieveActiveEntitlementsOnExistingAcctTest() {
		//RecordType personAccountRecordType =  [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' and SObjectType = 'Account'];
		String testInterfaceParameter = 'Kaltura';
        // retrieve test mode status from custom metadata
        List<Interface_Configuration__mdt> retrieveTestModeStatus = [SELECT test_mode__c FROM Interface_Configuration__mdt where DeveloperName = :testInterfaceParameter];
        Boolean testModeStatus = retrieveTestModeStatus[0].test_mode__c;
        
		Account acct = new Account(AccountNumber='kelvinkyits@mediacorp.com.sg', Name='Kelvin', Sic='613211');
		insert acct;
		Case cs = new Case(SuppliedEmail='kelvinkyits@mediacorp.com.sg', AccountId=acct.Id);
		insert cs;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new DynamicListCompControllerTest.DynamicListCompMockGenerator());
		String resultAsString = DynamicListCompController.doContsructWrapper('Kaltura', 'result', 'objects', 'Retrieve_Entitlement', 'None', cs.Id, 1, 'Active Entitlements'); 
        //String resultAsString = DynamicListCompController.doContsructWrapper('<External System>', 'result', 'objects', '<Operating Setting>', 'None', cs.Id, 1, 'Active Entitlements'); //Replace parameters in method with desired inputs
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
        
        if (testmodestatus == True) {
            System.assertEquals(2, allRecords.size());
        } else {
            System.assertEquals(0, allRecords.size());
        }
		
	}
	
	@isTest static void retrieveInactiveEntitlementsOnExistingAcctTest() {
		//RecordType personAccountRecordType =  [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' and SObjectType = 'Account'];
		String testInterfaceParameter = 'Kaltura';
         // retrieve test mode status from custom metadata
        List<Interface_Configuration__mdt> retrieveTestModeStatus = [SELECT test_mode__c FROM Interface_Configuration__mdt where DeveloperName = :testInterfaceParameter];
        Boolean testModeStatus = retrieveTestModeStatus[0].test_mode__c;
        
		Account acct = new Account(AccountNumber='kelvinkyits@mediacorp.com.sg', Name='Kelvin', Sic='613211', SicDesc='282163');
		insert acct;
		Case cs = new Case(SuppliedEmail='kelvinkyits@mediacorp.com.sg', AccountId=acct.Id, Origin='Web');
		insert cs;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new DynamicListCompControllerTest.DynamicListCompMockGenerator());

		String resultAsString = DynamicListCompController.doContsructWrapper('Kaltura', 'result', 'objects', 'Retrieve_Entitlement', 'None', cs.Id, 1, 'Inactive Entitlements'); 
		//String resultAsString = DynamicListCompController.doContsructWrapper('<External System>', 'result', 'objects', '<Operating Setting>', 'None', cs.Id, 1, 'Inactive Entitlements'); //Replace parameters in method with desired inputs
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
        
		if (testModeStatus == True) {
            System.assertEquals(2, allRecords.size());
        } else {
            System.assertEquals(0, allRecords.size());
        }
	}

	@isTest static void retrieveTransactionsOnExistingAcctTest() {
		//RecordType personAccountRecordType =  [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' and SObjectType = 'Account'];
		String testInterfaceParameter = 'Kaltura';
         // retrieve test mode status from custom metadata
        List<Interface_Configuration__mdt> retrieveTestModeStatus = [SELECT test_mode__c FROM Interface_Configuration__mdt where DeveloperName = :testInterfaceParameter];
        Boolean testModeStatus = retrieveTestModeStatus[0].test_mode__c;
		
		Account acct = new Account(AccountNumber='kelvinkyits@mediacorp.com.sg', Name='Kelvin', Sic='613211', SicDesc='282163');
		insert acct;
		Case cs = new Case(SuppliedEmail='kelvinkyits@mediacorp.com.sg', AccountId=acct.Id, Origin='Web');
		insert cs;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new DynamicListCompControllerTest.DynamicListCompMockGenerator());

		String resultAsString = DynamicListCompController.doContsructWrapper('Kaltura', 'result', 'objects', 'Retrieve_Transaction', 'None', cs.Id, 1, 'Transactions'); 
		//String resultAsString = DynamicListCompController.doContsructWrapper('<External System>', 'result', 'objects', '<Operating Setting>', 'None', cs.Id, 1, 'Transactions'); //Replace parameters in method with desired inputs
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
        
        if (testModeStatus == True) {
            System.assertEquals(2, allRecords.size());
        } else {
            System.assertEquals(0, allRecords.size());
        }
	}
	
	/* (Kept for reference)
	@isTest static void retrieveActiveEntitlementsOnNonExistingAcctTest() {
		Case cs = new Case(SuppliedEmail='kelvinkyits@mediacorp.com.sg', Origin='Web');
		insert cs;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new DynamicListCompControllerTest.DynamicListCompMockGenerator());

		String resultAsString = DynamicListCompController.doContsructWrapper('Kaltura', 'result', 'objects', 'Retrieve_Entitlement', 'None', cs.Id, 1, 'Active Entitlements'); 
		//String resultAsString = DynamicListCompController.doContsructWrapper('<External System>', 'result', 'objects', '<Operating Setting>', 'None', cs.Id, 1, 'Active Entitlements'); //Replace parameters in method with desired inputs
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
		System.assertEquals(5, allRecords.size());
	}
		*/
		/* (Kept for reference)
	@isTest static void retrieveInactiveEntitlementsOnNonExistingAcctTest() {
		Case cs = new Case(SuppliedEmail='kelvinkyits@mediacorp.com.sg', Origin='Web');
		insert cs;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new DynamicListCompControllerTest.DynamicListCompMockGenerator());

		String resultAsString = DynamicListCompController.doContsructWrapper('Kaltura', 'result', 'objects', 'Retrieve_Entitlement', 'None', cs.Id, 1, 'Inactive Entitlements'); 
		//String resultAsString = DynamicListCompController.doContsructWrapper('<External System>', 'result', 'objects', '<Operating Setting>', 'None', cs.Id, 1, 'Inactive Entitlements'); //Replace parameters in method with desired inputs
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
		System.assertEquals(5, allRecords.size());
	}
		*/
		/* (Kept for reference)
	@isTest static void retrieveTransactionsOnNonExistingAcctTest() {
		Case cs = new Case(SuppliedEmail='kelvinkyits@mediacorp.com.sg', Origin='Web');
		insert cs;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new DynamicListCompControllerTest.DynamicListCompMockGenerator());

		String resultAsString = DynamicListCompController.doContsructWrapper('Kaltura', 'result', 'objects', 'Retrieve_Transaction', 'None', cs.Id, 1, 'Transactions'); 
		//String resultAsString = DynamicListCompController.doContsructWrapper('<External System>', 'result', 'objects', '<Operating Setting>', 'None', cs.Id, 1, 'Transactions'); //Replace parameters in method with desired inputs
		Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(resultAsString);
		List<Object> allrecords = (List<Object>)result.get('AllRecords');
		Test.stopTest();
		System.assertEquals(2, allRecords.size());
	}
		*//*
	@isTest static void cancelEntitlementOnExistingAcct() {
		//RecordType personAccountRecordType =  [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' and SObjectType = 'Account'];
		
		Account acct = new Account(AccountNumber='kelvinkyits@mediacorp.com.sg', Name='Kelvin', Sic='613211', SicDesc='282163');
		insert acct;
		Case cs = new Case(SuppliedEmail='kelvinkyits@mediacorp.com.sg', AccountId=acct.Id, Origin='Web');
		insert cs;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new DynamicListCompControllerTest.DynamicListCompMockGenerator());

		//DynamicListCompController.RSVPWrapper result = new DynamicListCompController.RSVPWrapper();
		String result = DynamicListCompController.cancelEntitlementRenewal('Kaltura', 'Cancel_Renewal', cs.Id, '10666'); 
		//String result = DynamicListCompController.cancelEntitlementRenewal('<External System>', '<Operating_Setting>', cs.Id, '10666'); //Replace parameters in method with desired inputs
		Test.stopTest();
		System.debug('DBG result: ' + JSON.serializePretty(JSON.deserializeUntyped(result)));
		//System.assertEquals(', result.ErrorMessage );
	}
		/* (Kept for reference)
	@isTest static void cancelEntitlementOnNonExistingAcct() {

		Case cs = new Case(SuppliedEmail='kelvinkyits@mediacorp.com.sg', Origin='Web');
		insert cs;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new DynamicListCompControllerTest.DynamicListCompMockGenerator());

		//DynamicListCompController.RSVPWrapper result = new DynamicListCompController.RSVPWrapper();
		String result = DynamicListCompController.cancelEntitlementRenewal('Kaltura', 'Cancel_Renewal', cs.Id, '10666'); 
		//String result = DynamicListCompController.cancelEntitlementRenewal('<External System>', '<Operating Setting>', cs.Id, '10666'); //Replace parameters in method with desired inputs
		Test.stopTest();
		System.debug('DBG result: ' + JSON.serializePretty(JSON.deserializeUntyped(result)));
		//System.assertEquals(', result.ErrorMessage );
	}
		*/
}