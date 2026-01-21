/********************************************************************************************************
NAME:			GetBookingsJob_Test
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the test class for the GetBookingJobs class.

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
01/07/2019      Edmond To		First version
********************************************************************************************************/
@isTest
public class GetBookingsJob_Test {
    
    public static testMethod void testGetBookingsJobScheduling() {
        
        //build cron expression
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 1);
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        // call scheduler
        DateTime currentDateTime = Datetime.now();
        Test.StartTest();
        GetBookingsJob recentJobs = new GetBookingsJob();
        System.schedule('Bookings Job' + String.valueOf(currentDateTime), nextFireTime, recentJobs);
        Test.stopTest();
        
        // making sure job scheduled
        List < CronTrigger > jobs = [
            SELECT Id, CronJobDetail.Name, State, NextFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name = : 'Bookings Job' + String.valueOf(currentDateTime)
        ];
        System.assertNotEquals(null, jobs);
        System.assertEquals(1, jobs.size());
    }	
    
    public static testMethod void testLoginCRANE() {
        MockHttpResponseGenerator fakeLoginResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"success":true,"traceId":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","message":{"code":"200","content":"OK","details":["Welcome to STARLUX"]},"data":{"client":{"accessToken":"xxxxxxxxxx","token_type":"bearer","expires_in":86400}},"links":null,"meta":null}',
            null);
        
        Test.setMock(HttpCalloutMock.class, fakeLoginResponse); 
        Test.StartTest();
        Map<String,String> tokenRequestMap = TransportLayer.loginCRANE();
        Test.stopTest();
        
        String sessionToken = tokenRequestMap.get('token');
        system.assertEquals(sessionToken, 'xxxxxxxxxx');
        //Utility.storeOrgCache('CRANESessionId', 'CRANESession', '1234255', 3600);
        
    }

    public static testMethod void testGetBookingsJobWithValidData() { //Account of Passenger Type 'VIP'
        
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
        	'{"success":true,"traceId":"1234567-03bf-4c12-80fc-b02ef6d45368","message":{"code":"200","content":"OK","details":null},"data":{"items":[{"Status":"HK","Services_SSR":null,"Arr_Location":"MFM","Flight_No":"JX100","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900030123","PNR":"AAF8JX","Arrival_Date__c":"2019-07-01","Arrival_Time__c":"09:30:00","Passenger":"NANCY CHEN","Departure_Date__c":"2019-07-01","Departure_Time__c":"08:30:00","Day":"MON","Dep_Location":"TPE"},{"Status":"HL","Services_SSR":null,"Arr_Location":"MFM","Flight_No":"JX100","Date":"2019-07-01","Booking_class":"Y","Ticket_EMD_Number":"180600900030124","PNR":"AAF8JX","Arrival_Date__c":"2019-07-01","Arrival_Time__c":"09:30:00","Passenger":"NANCY CHEN","Departure_Date__c":"2019-07-01","Departure_Time__c":"08:30:00","Day":"MON","Dep_Location":"TPE"}]},"links":{"first":"https://auth-gateway.starlux-airlines.com/crane/api/v1/SSFC/getBookingDetails?page=1","last":"https://auth-gateway.starlux-airlines.com/crane/api/v1/SSFC/getBookingDetails?page=1","prev":null,"next":null},"meta":{"currentPage":1,"from":1,"path":"https://auth-gateway.starlux-airlines.com/crane/api/v1/SSFC/getBookingDetails","perPage":15,"to":2,"total":2,"lastPage":1}}', 
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
        mapCallouts.put('https://auth-gateway.starlux-airlines.com/crane/api/v1/SSFC/getBookingDetails?cemId=testCEMID',fakeResponse);
        mapCallouts.put('https://auth-gateway.starlux-airlines.com/crane/api/v1/SSFC/getAccount?eContactValue=null&phoneNumber=null',fakeAccountResponse);
        HttpCalloutMock multiCalloutMock = new MultiMockHttpResponseGenerator(mapCallouts);
        
        //Create test records
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        accountFieldValueMap.put('Passenger_Type__pc', 'VIP');
        accountFieldValueMap.put('CEM_ID__c', 'testCEMID');
        TestUtility.createAccount(accountFieldValueMap);
        Account[] testAccountList = [SELECT Id, CEM_ID__c, Passenger_Type__pc FROM Account];
        system.debug('DBG Testaccount: '+ testAccountList[0]);
        
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        ID targetCaseRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Feedback').getRecordTypeId();
        caseFieldValueMap.put('AccountId', testAccountList[0].Id);
        caseFieldValueMap.put('RecordTypeId', targetCaseRecordTypeID);
        caseFieldValueMap.put('Status', 'New');
        TestUtility.createCase(caseFieldValueMap);
        
        //Test.setMock(HttpCalloutMock.class, fakeLoginResponse); 
        //Map<String,String> tokenRequestMap = TransportLayer.loginCRANE();
        
        //Cache.SessionPartition partition = Cache.Session.getPartition('CRANESession');
      	//Utility.storeOrgCache('CRANESessionId', 'CRANESession', '1234255', 3600);
        
		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Test.StartTest();
        GetBookingsJob recentJobs = new GetBookingsJob();
        recentJobs.execute(null);
        Test.stopTest();
      
        List<Booking_Details__c> allBookings = [SELECT Id FROM Booking_Details__c];
        System.assertEquals(2, allBookings.size());
    }	
    
    /*
    public static testMethod void testGetRecentBookingsWithValidData1() { //Account with Open Case and Case Record Type = 'Feedback', with Account Passenger Type != 'VIP'
        
        //Create test records
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        accountFieldValueMap.put('Passenger_Type__pc', 'BIP');
        accountFieldValueMap.put('CEM_Id__c', 'testCEMID');
        TestUtility.createAccount(accountFieldValueMap);
        Sobject testAccount = TestUtility.getAccount();
        
        ID targetCaseRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Feedback').getRecordTypeId();
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeID', targetCaseRecordTypeID);
        caseFieldValueMap.put('AccountId', testAccount.Id);
        TestUtility.createCase(caseFieldValueMap);
        
        Test.setMock(HttpCalloutMock.class, new RecentBookingsMockCallout());
        Test.StartTest();
        GetRecentBookings recentBookings = new GetRecentBookings();
        recentBookings.execute(null);
        Test.stopTest();
      
        List<Booking_Details__c> allBookings = [SELECT Id FROM Booking_Details__c];
        System.assertEquals(0, allBookings.size());
    }
    */
    public static testMethod void testGetBookingsJobWithInvalidData() { //Invalid passenger type
        
        //Create test records
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        accountFieldValueMap.put('Passenger_Type__pc', 'BIP');
        accountFieldValueMap.put('CEM_Id__c', 'testCEMID');
        TestUtility.createAccount(accountFieldValueMap);
        Sobject testAccount = TestUtility.getAccount();
        
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
        	'{"executionTime":0.0417752,"result":{"objectType":"GetFlightBookings","status":"Success","totalCount":2,"objects":[{"Status":"Confirmed","Services_SSR":"VIP Service","Arr_Location":"TPE","Flight_No":"JX117","Date":"2019-07-14","Booking_class":"F","Ticket_EMD_Number":"TIC-001","PNR":9876543,"Arr_Time":"14:30:00","Passenger":"Edmond To Cheng Wei","Dep_Time":"10:30:00","Day":"Monday","Dep_Location":"HKD"},{"Status":"Confirmed","Services_SSR":"Normal Service","Arr_Location":"TPE","Flight_No":"JX207","Date":"2019-08-14","Booking_class":"J","Ticket_EMD_Number":"TIC-002","PNR":12345678,"Arr_Time":"18:00:00","Passenger":"Cheong Whye Hoe","Dep_Time":"10:00:00","Day":"Sunday","Dep_Location":"HAN"}]}}', 
            null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
        Test.StartTest();
        GetBookingsJob recentJobs = new GetBookingsJob();
        recentJobs.execute(null);
        Test.stopTest();
      
        List<Booking_Details__c> allBookings = [SELECT Id FROM Booking_Details__c];
        System.assertEquals(0, allBookings.size());
    }
}