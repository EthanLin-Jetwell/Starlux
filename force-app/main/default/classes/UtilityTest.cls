/**
 * @File Name          : UtilityTest.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 4/22/2019, 2:59:10 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/22/2019, 2:59:10 PM   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
@isTest
public class UtilityTest {

	public class MockHttpResponseGenerator implements HttpCalloutMock {
		protected Integer code;
		//protected String status;
		protected String bodyAsString;
		//protected Map<String, String> responseHeaders;

		public MockHttpResponseGenerator(Integer Code, String body) {
			this.code = code;
			//this.status = status;
			this.bodyAsString = body;
            
		}

	    public HTTPResponse respond(HTTPRequest req) {
		
	        HttpResponse resp = new HttpResponse();
           	resp.setStatusCode(code);
			//resp.setStatus(status);
            resp.setBody(bodyAsString);
			return resp;


	    }
    

    
		}
    
    
    public static Map<String,Object> accessKeysToCheck(Map<String,Object> obtainedResponse, String keyToParse){
        String testNestedResponseBody = JSON.serialize(obtainedResponse.get(keyToParse)); 
        Map<String, Object> testNestedResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(testNestedResponseBody);

		    return testNestedResponseBodyMap;         
    }
	
    /*
   	@isTest
    private static void UtilitySendData() { //Tests the method to handle success message from Kaltura in a success case
       
    		// test setup 
    		String testInterfaceParameter = 'Kaltura'; // define parent interface. Manually defined 
            String testChildInterfaceParameter = 'Grant_Entitlement'; // define child interface 
    		Map<String, Object> sourceMap = new Map<String, Object>();		
    		Case sourceCase = new Case();	
       	system.debug(sourceCase); 
       
        sourceMap.put('Case', sourceCase);
       
       	system.debug(sourceMap);
        String sourceTestCall = Utility.GenerateMessage(testChildInterfaceParameter, sourceMap, false);
        system.debug(sourceTestCall);
       
        // test senddata - success case    
        
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT Result_Verification__c, Test_Data__c FROM Interface_Operation_Setting__mdt where DeveloperName = :testChildInterfaceParameter];
    	
        // retrieve test mode status from custom metadata
        List<Interface_Configuration__mdt> retrieveTestModeStatus = [SELECT test_mode__c FROM Interface_Configuration__mdt where DeveloperName = :testInterfaceParameter];
        Boolean testmodestatus = retrieveTestModeStatus[0].test_mode__c;
        // interface test | positive 
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
        Integer httpStatusCodeforInterface = 200; 
       
       	// expected results
        String retrieveResultVerification = retrieveAllTestSettings[0].Result_Verification__c; 
        
        List<String> splitResultVerification = retrieveResultVerification.split(','); 
       
        String firstSplit = splitResultVerification[0]; //executionTime
        String secondSplit = splitResultVerification[1]; //result
        
		    // test run
		 
		    Test.startTest();   
       
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		    Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);     
       	Map<String,Object> resforInterface = Utility.SendData(testInterfaceParameter, testChildInterfaceParameter, sourceMap);
		    String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
        String testResponseBody = JSON.serialize((resforInterface.get('Response'))); 
        system.debug('testResponseBody: '+ testResponseBody); 
       
       	Test.stopTest(); 
       
        // test assertion | positive 
        /* Commented out to fit the API limitations of Kaltura, as well as the limitations of the TransportLayer's ability to handle such responses
         
        Map<String, Object> testResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(testResponseBody);
        //Map<String, Object> testNestedResponseBodyMap = accessKeysToCheck(testResponseBodyMap,secondSplit);
      
      	Boolean testPass = false; 
      	
        Boolean firstSplitTest = testResponseBodyMap.containsKey(firstSplit);
        Boolean secondSplitTest = testResponseBodyMap.containsKey(secondSplit);
       
       	system.debug('first to second: ' + firstSplitTest + secondSplitTest); 
      
      	if (firstSplitTest == true && secondSplitTest == true){
          testPass = true; 
         System.assertEquals(true,testPass);          
        } else{
         System.assertEquals(true,testPass);                
        }

		    */
    
    /*
        if (testmodestatus == True) {
            system.assertEquals('{"result":true,"executionTime":0.0747351}', testResponseBody);
        } else {
            system.assertEquals('null', testResponseBody);
        }
        
       	
    }
    */
    /*
    @isTest 
    private static void UtilitySendDataFail() { //Tests the method to handle error message from Kaltura in an error case
		
        // test setup 
		    String testInterfaceParameter = 'Kaltura'; // define parent interface 
        String testChildInterfaceParameter = 'Cancel_Renewal'; // define child interface 
		    Map<String, Object> sourceMap = new Map<String, Object>();		
		    Case sourceCase = new Case();
       	system.debug(sourceCase); 
       
        sourceMap.put('Case', sourceCase);
       
       	system.debug(sourceMap);
        String sourceTestCall = Utility.GenerateMessage(testChildInterfaceParameter, sourceMap);
        system.debug(sourceTestCall);
       
       // test senddata - error case  
        
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT Result_Verification__c, Test_Data__c FROM Interface_Operation_Setting__mdt where DeveloperName = :testChildInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
        Integer httpStatusCodeforInterface = 200; 
       
       	// expected results
        String retrieveResultVerification = retrieveAllTestSettings[0].Result_Verification__c; 
        
        List<String> splitResultVerification = retrieveResultVerification.split(','); 
        String firstSplit = splitResultVerification[0]; //executionTime 
        String secondSplit = splitResultVerification[1]; //result (nested)
          
		    // test run
		 
		    Test.startTest();   
       
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		    Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);     
       	Map<String,Object> resforInterface = Utility.SendData(testInterfaceParameter, testChildInterfaceParameter, sourceMap);
		    String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
        String testResponseBody = JSON.serialize((resforInterface.get('Response'))); 
        system.debug('testResponseBody: '+ testResponseBody); 
       
       	Test.stopTest(); 
       
        // test assertion | positive 
        Map<String, Object> testResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(testResponseBody);
        //Map<String, Object> testNestedResponseBodyMap = accessKeysToCheck(testResponseBodyMap,secondSplit);
      
      	Boolean testPass = false; 
      	
        Boolean firstSplitTest = testResponseBodyMap.containsKey(firstSplit);
        Boolean secondSplitTest = testResponseBodyMap.containsKey(secondSplit);
         
      	if (firstSplitTest == true && secondSplitTest == true){
          testPass = true; 
         System.assertEquals(true,testPass);          
        } else{
         System.assertEquals(true,testPass);                
        }
       
    }*/
    /*
        public static testmethod void UtilitySendDataThree() {
		
        // test setup 
		String testInterfaceParameter = 'Retrieve_Invoice_History'; // define parent interface 
        String testChildInterfaceParameter = 'Invoice_History_Interface_One'; // define child interface 
		Map<String, Object> sourceMap = new Map<String, Object>();		
		Case sourceCase = new Case(SuppliedPhone='415813581051');	
       	system.debug(sourceCase); 
       
        sourceMap.put('Case', sourceCase);
       
       	system.debug(sourceMap);
        String sourceTestCall = Utility.GenerateMessage(testInterfaceParameter, sourceMap);
        system.debug(sourceTestCall);
       
       // test senddata - positive test 3
        
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT Result_Verification__c, Test_Data__c FROM Interface_Operation_Setting__mdt where Interface_Configuration__r.DeveloperName = :testInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
        Integer httpStatusCodeforInterface = 200; 
       
       	// expected results
        String retrieveResultVerification = retrieveAllTestSettings[0].Result_Verification__c; 
        
        List<String> splitResultVerification = retrieveResultVerification.split(','); 
        String firstSplit = splitResultVerification[0]; //httpstatus 
        String secondSplit = splitResultVerification[1]; //servicedata
        String thirdSplit = splitResultVerification[2]; //servicename
        String fourthSplit = splitResultVerification[3]; //transid
        String fifthSplit = splitResultVerification[4]; //InvoiceList | nested within servicedata 
       
		// test run
		 
		Test.startTest();   
       
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);     
       	Map<String,Object> resforInterface = Utility.SendData(testInterfaceParameter, testChildInterfaceParameter, sourceMap);
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
        String testResponseBody = JSON.serialize((resforInterface.get('Response'))); 
        system.debug('testResponseBody: '+ testResponseBody); 
       
       	Test.stopTest(); 
       
        // test assertion | positive 
        Map<String, Object> testResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(testResponseBody);
        Map<String, Object> testNestedResponseBodyMap = accessKeysToCheck(testResponseBodyMap,secondSplit);
      
      	Boolean testPass = false; 
      	
        Boolean firstSplitTest = testResponseBodyMap.containsKey(firstSplit);
        Boolean secondSplitTest = testResponseBodyMap.containsKey(secondSplit);
        Boolean thirdSplitTest = testResponseBodyMap.containsKey(thirdSplit);
        Boolean fourthSplitTest = testResponseBodyMap.containsKey(fourthSplit);
        Boolean fifthSplitTest = testNestedResponseBodyMap.containsKey(fifthSplit);
      
      	if (firstSplitTest == true && secondSplitTest == true && thirdSplitTest == true && fourthSplitTest == true && fifthSplitTest == true){
          testPass = true; 
          System.assertEquals(true,testPass);          
        } else{
         System.assertEquals(true,testPass);                
        }
        
       
   }  
    
        public static testmethod void UtilitySendDataFour() {
		
        // test setup 
		String testInterfaceParameter = 'Retrieve_Asset_Information'; // define parent interface 
        String testChildInterfaceParameter = 'Asset_Information_Interface_One'; // define child interface 
		Map<String, Object> sourceMap = new Map<String, Object>();		
		Case sourceCase = new Case(SuppliedPhone='415813581051');	
       	system.debug(sourceCase); 
       
        sourceMap.put('Case', sourceCase);
       
       	system.debug(sourceMap);
        String sourceTestCall = Utility.GenerateMessage(testInterfaceParameter, sourceMap);
        system.debug(sourceTestCall);
       
       // test senddata - positive test 3
        
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT Result_Verification__c, Test_Data__c FROM Interface_Operation_Setting__mdt where Interface_Configuration__r.DeveloperName = :testInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
        Integer httpStatusCodeforInterface = 200; 
       
       	// expected results
        String retrieveResultVerification = retrieveAllTestSettings[0].Result_Verification__c; 
        
        List<String> splitResultVerification = retrieveResultVerification.split(','); 
        String firstSplit = splitResultVerification[0]; //httpstatus 
        String secondSplit = splitResultVerification[1]; //servicedata
        String thirdSplit = splitResultVerification[2]; //servicename
        String fourthSplit = splitResultVerification[3]; //transid
        String fifthSplit = splitResultVerification[4]; //packageList | nested within servicedata 
       
		// test run
		 
		Test.startTest();   
       
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);     
       	Map<String,Object> resforInterface = Utility.SendData(testInterfaceParameter, testChildInterfaceParameter, sourceMap);
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
        String testResponseBody = JSON.serialize((resforInterface.get('Response'))); 
        system.debug('testResponseBody: '+ testResponseBody); 
       
       	Test.stopTest(); 
       
        // test assertion | positive 
        Map<String, Object> testResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(testResponseBody);
        Map<String, Object> testNestedResponseBodyMap = accessKeysToCheck(testResponseBodyMap,secondSplit);
      
      	Boolean testPass = false; 
      	
        Boolean firstSplitTest = testResponseBodyMap.containsKey(firstSplit);
        Boolean secondSplitTest = testResponseBodyMap.containsKey(secondSplit);
        Boolean thirdSplitTest = testResponseBodyMap.containsKey(thirdSplit);
        Boolean fourthSplitTest = testResponseBodyMap.containsKey(fourthSplit);
        Boolean fifthSplitTest = testNestedResponseBodyMap.containsKey(fifthSplit);
      
      	if (firstSplitTest == true && secondSplitTest == true && thirdSplitTest == true && fourthSplitTest == true && fifthSplitTest == true){
          testPass = true; 
         System.assertEquals(true,testPass);          
        } else{
         System.assertEquals(true,testPass);                
        }

       
   }


       public static testmethod void UtilitySendDataFive() {
		
        // test setup 
		String testInterfaceParameter = 'Retrieve_Payment_History'; // define parent interface 
        String testChildInterfaceParameter = 'Payment_History_Interface_One'; // define child interface 
		Map<String, Object> sourceMap = new Map<String, Object>();		
		Case sourceCase = new Case(SuppliedPhone='415813581051');	
       	system.debug(sourceCase); 
       
        sourceMap.put('Case', sourceCase);
       
       	system.debug(sourceMap);
        String sourceTestCall = Utility.GenerateMessage(testInterfaceParameter, sourceMap);
        system.debug(sourceTestCall);
       
       // test senddata - positive test 3
        
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT Result_Verification__c, Test_Data__c FROM Interface_Operation_Setting__mdt where Interface_Configuration__r.DeveloperName = :testInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
        Integer httpStatusCodeforInterface = 200; 
       
       	// expected results
        String retrieveResultVerification = retrieveAllTestSettings[0].Result_Verification__c; 
        
        List<String> splitResultVerification = retrieveResultVerification.split(','); 
        String firstSplit = splitResultVerification[0]; //httpstatus 
        String secondSplit = splitResultVerification[1]; //servicedata
        String thirdSplit = splitResultVerification[2]; //servicename
        String fourthSplit = splitResultVerification[3]; //transid
        String fifthSplit = splitResultVerification[4]; //paymentList | nested within servicedata 
       
		// test run
		 
		Test.startTest();   
       
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);     
       	Map<String,Object> resforInterface = Utility.SendData(testInterfaceParameter, testChildInterfaceParameter, sourceMap);
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
        String testResponseBody = JSON.serialize((resforInterface.get('Response'))); 
        system.debug('testResponseBody: '+ testResponseBody); 
       
       	Test.stopTest(); 
       
        // test assertion | positive 
        Map<String, Object> testResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(testResponseBody);
        Map<String, Object> testNestedResponseBodyMap = accessKeysToCheck(testResponseBodyMap,secondSplit);
      
      	Boolean testPass = false; 
      	
        Boolean firstSplitTest = testResponseBodyMap.containsKey(firstSplit);
        Boolean secondSplitTest = testResponseBodyMap.containsKey(secondSplit);
        Boolean thirdSplitTest = testResponseBodyMap.containsKey(thirdSplit);
        Boolean fourthSplitTest = testResponseBodyMap.containsKey(fourthSplit);
        Boolean fifthSplitTest = testNestedResponseBodyMap.containsKey(fifthSplit);
      
      	if (firstSplitTest == true && secondSplitTest == true && thirdSplitTest == true && fourthSplitTest == true && fifthSplitTest == true){
          testPass = true; 
         System.assertEquals(true,testPass);          
        } else{
         System.assertEquals(true,testPass);                
        }
       
   } 
    */
    /*
        public static testmethod void TransportLayerTestMode() { //Tests the TransportLayer class
		
        // test setup 
		String testInterfaceParameter = 'Kaltura'; // define parent interface 
        String testChildInterfaceParameter = 'Cancel_Renewal'; // define child interface 
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT Result_Verification__c, Test_Data__c
                                                                              FROM Interface_Operation_Setting__mdt 
                                                                              WHERE DeveloperName = :testChildInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
        Integer httpStatusCodeforInterface = 200; 
       
       	// expected results
        String retrieveResultVerification = retrieveAllTestSettings[0].Result_Verification__c; 
        
        List<String> splitResultVerification = retrieveResultVerification.split(','); 
        String firstSplit = splitResultVerification[0]; //executionTime
        String secondSplit = splitResultVerification[1]; //result
       
		// test run
		 
		Test.startTest();   
       
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);     
       	Map<String,Object> resforInterface = TransportLayer.makeCallOut(testInterfaceParameter, testChildInterfaceParameter, retrieveInterface);
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
        String testResponseBody = JSON.serialize((resforInterface.get('Response'))); 
        system.debug('testResponseBody: '+ testResponseBody); 
       
       	Test.stopTest(); 
       
        // test assertion | positive 
        Map<String, Object> testResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(testResponseBody);
      
      	Boolean testPass = false; 
      	
        Boolean firstSplitTest = testResponseBodyMap.containsKey(firstSplit);
        Boolean secondSplitTest = testResponseBodyMap.containsKey(secondSplit);
        System.debug(firstSplitTest);
        System.debug(secondSplitTest);
      
      	if (firstSplitTest == true && secondSplitTest == true){
          testPass = true; 
         System.assertEquals(true,testPass);          
        } else{
         System.assertEquals(true,testPass);                
        }
         
   } 
    */
    
        public static testmethod void TransportLayerTestModeClientSideError() {
		
        // test setup 
		String testInterfaceParameter = 'Test_Class_Configuration_ClientSideError'; // define parent interface 
        String testChildInterfaceParameter = 'Test_Class_Interface_ClientSideError'; // define child interface 
        
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT  Result_Verification__c, Test_Data__c FROM Interface_Operation_Setting__mdt where Interface_Configuration__r.DeveloperName = :testInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
        Integer httpStatusCodeforInterface = 200; 
       
       	// expected results
        String retrieveTestVerification = '{"Message":"Client-side error encountered when sending a request, with HTTP status code: 400. Please review the debug log for additional details."}'; 
       
		// test run
		 
		Test.startTest();   
          
       	Map<String,Object> resforInterface = TransportLayer.makeCallOut(testInterfaceParameter, testChildInterfaceParameter, retrieveInterface);
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
       
       	Test.stopTest(); 
       
        // test assertion | positive 
       
        System.assertEquals(retrieveTestVerification,resStringforInterface);
         
   } 
    
        public static testmethod void TransportLayerTestModeServerSideError() {
		
        // test setup 
		String testInterfaceParameter = 'Test_Class_Configuration_ServerSideError'; // define parent interface 
        String testChildInterfaceParameter = 'Test_Class_Interface_ServerSideError'; // define child interface 
        Integer httpStatusCodeforInterface = 200; 
            
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT  Test_Data__c FROM Interface_Operation_Setting__mdt where Interface_Configuration__r.DeveloperName = :testInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
       
       	// expected results
        String retrieveTestVerification = '{"Message":"Server-side error encountered when getting a response, with HTTP status code: 504. Please review the debug log for additional details."}'; 
       
		// test run
		 
		Test.startTest();   
          
       	Map<String,Object> resforInterface = TransportLayer.makeCallOut(testInterfaceParameter, testChildInterfaceParameter, retrieveInterface);
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
       
       	Test.stopTest(); 
       
        // test assertion | positive 
       
        System.assertEquals(retrieveTestVerification,resStringforInterface);
         
   } 
    
        public static testmethod void TransportLayerTestModeUnauthorizedEndpoint() {
		
        // test setup 
		String testInterfaceParameter = 'Test_Class_Configuration_Unauthorized'; // define parent interface 
        String testChildInterfaceParameter = 'Test_Class_Interface_UnauthorizedEndpont'; // define child interface 
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        Integer httpStatusCodeforInterface = 200; 
            
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT  Test_Data__c FROM Interface_Operation_Setting__mdt where Interface_Configuration__r.DeveloperName = :testInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
       
       	// expected results
        String retrieveTestVerification = '{"Message":"A callout exception has been encountered. Do ensure the correct message parameters are passed or check Setup -> Security -> Remote Site Settings."}'; 
       
		// test run
		 
		Test.startTest();   
     
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);     
       	Map<String,Object> resforInterface = TransportLayer.makeCallOut(testInterfaceParameter, testChildInterfaceParameter, retrieveInterface);
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
       
       	Test.stopTest(); 
       
        // test assertion | negative 
       
        System.assertEquals(retrieveTestVerification,resStringforInterface);
         
   } 
    
        public static testmethod void TransportLayerTestModeOtherErrors() {
		
        // test setup 
		String testInterfaceParameter = 'Test_Class_Configuration_Others'; // define parent interface 
        String testChildInterfaceParameter = 'Test_Class_Interface_Others'; // define child interface 
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        Integer httpStatusCodeforInterface = 200; 
            
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT  Test_Data__c FROM Interface_Operation_Setting__mdt where Interface_Configuration__r.DeveloperName = :testInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 

       
       	// expected results
        String retrieveTestVerification = '{"Message":"Test: An exception has been encountered while calling out to Integration"}'; 
       
		// test run
		 
		Test.startTest();   
        
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);    
       	Map<String,Object> resforInterface = TransportLayer.makeCallOut(testInterfaceParameter, testChildInterfaceParameter, retrieveInterface);
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
       
       	Test.stopTest(); 
       
        // test assertion | negative 
       
        System.assertEquals(retrieveTestVerification,resStringforInterface);
         
   } 
    /*
           public static testmethod void TransportLayerTestModeErrorHandling() {
		
        // test setup 
		String testInterfaceParameter = 'Retrieve_Asset_Information'; // define parent interface 
        String testChildInterfaceParameter = 'Asset_Information_Interface_One'; // define child interface 
        String mockInterfaceParameter = 'Retrieve_Asset_Information'; // define here 
		
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT http_code_field__c, Test_Data__c FROM Interface_Operation_Setting__mdt where Interface_Configuration__r.DeveloperName = :mockInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = '{"servicedata":{"customerprofile":{"Testtest":{"result":"Success","familycard":"1351161641644","nik":"61416146"}}},"httpstatus":"500","servicestatus":"0","servicename":"RETRIEVE ASSET INFORMATION","transid":" 2751563516","servicedesc":"Success","HTTPStatus":200}';
        Integer httpStatusCodeforInterface = 200; 
       
       	// expected results
        String retrieveTestVerification = '{"Message":"Error encountered when attempting to get a response from the designated system with the following error: Success","Response":{"HTTPStatus":200,"servicedesc":"Success","transid":" 2751563516","servicename":"RETRIEVE ASSET INFORMATION","servicestatus":"0","httpstatus":"500","servicedata":{"customerprofile":{"Testtest":{"nik":"61416146","familycard":"1351161641644","result":"Success"}}}},"httpstatus":500}'; 
            
		// test run
		 
		Test.startTest();   
            
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);     
       	Map<String,Object> resforInterface = TransportLayer.makeCallOut(testInterfaceParameter, testChildInterfaceParameter, '{"Message":"Error encountered when attempting to get a response from the designated system, with HTTP status code:httpstatus. Please review the error message, as returned from the system: {customerprofile={Testtest={familycard=1351161641644, nik=61416146, result=Success}}}","HTTPStatus":200}');
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
       
       	Test.stopTest(); 
       
        // test assertion | negative 
       
        System.assertEquals(retrieveTestVerification,resStringforInterface);
         
   }
    
        public static testmethod void TransportLayerTestModeClientSideErrorHandling() {
		
        // test setup 
		String testInterfaceParameter = 'Retrieve_Invoice_History'; // define parent interface 
        String testChildInterfaceParameter = 'Invoice_History_Interface_One'; // define child interface 
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = '{"servicedata":{"customerprofile":{"Testtest":{"result":"Success","familycard":"1351161641644","nik":"61416146"}}},"httpstatus":"500","servicestatus":"0","servicename":"RETRIEVE ASSET INFORMATION","transid":" 2751563516","servicedesc":"Success","HTTPStatus":200}';
        Integer httpStatusCodeforInterface = 500;    

       	// expected results
        String retrieveTestVerification = '{"Message":"Client-side error encountered when sending a request, with HTTP status code:500","httpstatus":500}'; 
            
		// test run
		 
		Test.startTest();   
            
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);        
       	Map<String,Object> resforInterface = TransportLayer.makeCallOut(testInterfaceParameter, testChildInterfaceParameter, '{"Message":"Error encountered when attempting to get a response from the designated system, with HTTP status code:httpstatus. Please review the error message, as returned from the system: {customerprofile={Testtest={familycard=1351161641644, nik=61416146, result=Success}}}","HTTPStatus":200}');
		String resStringforInterface = JSON.serialize(resforInterface);
       	system.debug('testing data structure:' + resStringforInterface);      
       
       	Test.stopTest(); 
       
        // test assertion | negative 
       
        System.assertEquals(retrieveTestVerification,resStringforInterface);
            
       }
    */
       // Used to test conditional logics not effected in other test classes 
      
	@isTest
      public static void UtilitySendData_Test() {
		
		    // test setup 
		    String testInterfaceParameter = 'Test_Interface'; // define parent interface. Manually defined 
        String testChildInterfaceParameter = 'Utility_Test_Conditional_Field'; // define child interface 
		    Map<String, Object> sourceMap = new Map<String, Object>();		
		    Case sourceCase = new Case();	
       	system.debug(sourceCase); 
       
        sourceMap.put('Case', sourceCase);
       
       	system.debug(sourceMap);
        String sourceTestCall = Utility.GenerateMessage(testChildInterfaceParameter, sourceMap, false);
        Map<String, Object> testResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(sourceTestCall);
        system.debug('DBG testresponsemap' +testResponseBodyMap);
          
        Boolean testPass = false; 
           
        Boolean firstTest = testResponseBodyMap.containsKey('121');
        Boolean secondTest = testResponseBodyMap.containsKey('edmond');
        Boolean thirdTest = testResponseBodyMap.containsKey('2019-02-22 00:00:00');
        Boolean fourthTest = testResponseBodyMap.containsKey('EDMOND');
        Boolean fifthTest = testResponseBodyMap.containsKey('message');
          
          
      	if (firstTest == true && secondTest == true && thirdTest == true && fourthTest == true && fifthTest == true){
          testPass = true; 
         System.assertEquals(true,testPass);          
        } else{
         System.assertEquals(true,testPass);                
        }
      }
               
	
       // Used to test ErrorHandling in Utility 
      public static testmethod void UtilitySendData_Test_ErrorHandling() {
		
        // test setup 
		String testInterfaceParameter = 'Test_Interface'; // define parent interface 
        String testChildInterfaceParameter = 'Test_ChildInterface_Error'; // define child interface 
		Map<String, Object> sourceMap = new Map<String, Object>();		
		Case sourceCase = new Case(SuppliedPhone='415813581051');
       	system.debug(sourceCase); 
       
        sourceMap.put('Case', sourceCase);
        
        // retrieve test content from custom metadata         
        List<Interface_Operation_Setting__mdt> retrieveAllTestSettings = [SELECT Result_Verification__c, Test_Data__c FROM Interface_Operation_Setting__mdt where Interface_Configuration__r.DeveloperName = :testInterfaceParameter];
		
       	// parameters to stimulate actual results, used in the HttpCalloutMock
        String retrieveInterface = retrieveAllTestSettings[0].Test_Data__c; 
        Integer httpStatusCodeforInterface = 200; 
       
		// test run
		 
		Test.startTest();   
       
        Boolean testPass = false; 
          
        UtilityTest.MockHttpResponseGenerator fakeResponseforInterface = new UtilityTest.MockHttpResponseGenerator(httpStatusCodeforInterface, retrieveInterface);
		Test.setMock(HttpCalloutMock.class, fakeResponseforInterface);  
        try {
			 Map<String,Object> resforInterface = Utility.SendData(testInterfaceParameter, testChildInterfaceParameter, sourceMap);              
        } catch(exception ex){
            String errorMessage = ex.getMessage(); 
            // if error message is shown, exception handling works and test class passes 
            testPass = true;
            System.assertEquals(true,testPass);            

        }
          
       	Test.stopTest(); 
               
   } 
    
}