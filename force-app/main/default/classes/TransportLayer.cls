/********************************************************************************************************
NAME:			TransportLayer
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		Handles REST callout
		
UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
16/09/2019      Edmond To		First version
18/12/2019		Edmond To		Updated the timeout limit from 5000ms to 10000ms
********************************************************************************************************/
public inherited sharing class TransportLayer {

    public static final String CRANESessionIdCacheName = 'CRANESessionId';
    public static final String CRANESessionOrgCachePartitionName = 'CRANESession';
    public static final String CRANEAnonymousLoginSettingName = 'CRANELogin';
    //public static final String kalturaStartSessionSettingName = 'kalturaStartSession';
    public static final String CRANEOrgCacheCompleteName = 'local.CRANESession.CRANESessionId';

    // AppLogging: 20190309
    public static System_Settings__mdt logLevelCMD;
    public static DateTime startTime = DateTime.now();
    public static String processLog = '';
    public static List<ApplicationLogWrapper> appWrapperLogList;  // = new List<ApplicationLogWrapper>();
    
    public class RequestResult {
        public String message {get; set;}
        public Map<String,Object> payload {get; set;}
    }

    // Returns the Session Id for login to CRANE. Returns a Map of:
    // 1) key 'message' => 'any Success or error message'
    // 2) key 'token' => actual session token value
    public static Map<String, String> loginCRANE() {

        // define a response to caller
        Map<String, String> tokenRequestMap = new Map<String,String>();
        Map<String, String> loginRequestPayloadMap = new Map<String, String>();

        String CRANESessionToken = null;

        CRANESessionToken = Utility.fetchOrgCache(CRANESessionOrgCachePartitionName, CRANESessionIdCacheName);
        System.debug('DBG CRANESessionToken: ' + CRANESessionToken);
        String rawBody;

        // AppLogging: 20190309
        logLevelCMD=Utilities.getLogLevel('Transport Layer Logging');         
		appWrapperLogList = new List<ApplicationLogWrapper>();
        
        String username;
        String password;
        Integer cacheExpiry;

        String endPoint;
        Integer timeOutInMs = 10000; // default is 5s, set to 10s temporarily to accommodate MDM/CRANE speed
        String httpMethod = 'POST';
        String contentType;

        if (CRANESessionToken != null) {
            System.debug('DBG CRANESessionToken inside if');
            // if session Id is existing on cache, return it to requestor and no need to re-login yet
            tokenRequestMap.put('message', 'Success');
            tokenRequestMap.put('token', CRANESessionToken);
            return tokenRequestMap;

        } else {
            // make callout for login

            for (CRANE_Integration_Setting__mdt integSettMdt : [SELECT Id, Label, MasterLabel, DeveloperName, Value__c FROM CRANE_Integration_Setting__mdt]) {
				if (integSettMdt.DeveloperName == 'clientId') {
					username = integSettMdt.Value__c;
                    loginRequestPayloadMap.put(integSettMdt.DeveloperName, integSettMdt.Value__c);
				}	
                if (integSettMdt.DeveloperName == 'clientSecret') {
					password = integSettMdt.Value__c;
                    loginRequestPayloadMap.put(integSettMdt.DeveloperName, integSettMdt.Value__c);
				}
                if (integSettMdt.DeveloperName == 'cacheExpiry') {
					cacheExpiry = Integer.valueOf(integSettMdt.Value__c);
				}
				/*
                if (integSettMdt.DeveloperName == 'PartnerId') {
                    partnerIdValue = integSettMdt.Value__c;
                    loginRequestPayloadMap.put(integSettMdt.DeveloperName, integSettMdt.Value__c);
                }
                if (integSettMdt.DeveloperName == 'udid') {
                    udIdValue = integSettMdt.Value__c;
                    loginRequestPayloadMap.put(integSettMdt.DeveloperName, integSettMdt.Value__c);
                }
                if (integSettMdt.DeveloperName == 'token') {
                    tokenValue = integSettMdt.Value__c;
                }
                if (integSettMdt.DeveloperName == 'id') {
                    idValue = integSettMdt.Value__c;
                }
				*/
            }
            System.debug('DBG loginRequestPayloadMap: ' + JSON.serializePretty(loginRequestPayloadMap));


            Interface_Operation_Setting__mdt CRANELoginSetting = [SELECT Id, MasterLabel, DeveloperName, Call_With_Retry__c, Client_Key_Header_Name_Overwrite__c, 
                Create_Sub_URL__c, http_code_field__c, Interface_Configuration__c, Interface_Configuration__r.Main_URL__c, Key__c, Language, Msg_Mapping__c,
                Named_Credential_Overwrite__c, NameSpacePrefix, Pass_Key_Header_Name_overwrite__c, QualifiedApiName, response_message_field__c,
                Sub_URL__c, Test_Data_Verification__c, Test_Data__c, test_http_code__c, Update_Method_overwrite__c, Upgrade_Indication_Field__c,
                Interface_Configuration__r.Set_Timeout__c, Interface_Configuration__r.Content_Type__c
                 FROM Interface_Operation_Setting__mdt WHERE DeveloperName =: CRANEAnonymousLoginSettingName];

            endPoint = CRANELoginSetting.Interface_Configuration__r.Main_URL__c + CRANELoginSetting.Sub_URL__c;
            timeOutInMs = (Integer) CRANELoginSetting.Interface_Configuration__r.Set_Timeout__c;
            contentType = CRANELoginSetting.Interface_Configuration__r.Content_Type__c;
			
            
            System.debug('DBG endPoint: ' + endPoint);
            System.debug('DBG timeOut: ' + timeOutInMs);
            System.debug('DBG contentType: ' + contentType);

        }


        // instantiate a new http object
        Http h = new Http();

        // instantiate a new HTTP request and response
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        // configure the request
        req.setEndpoint(endpoint);
        req.setMethod(httpMethod);
        req.setTimeout(timeOutInMs);
        
        // configure standard headers
        //req.setHeader('Accept', '*/*');
        
        // tell the API to send and receive the data as a JSON object
        req.setHeader('Content-Type', contentType);

        // set the body json with the message; basically a string with a key-value pair construction.
        rawBody = JSON.serialize(loginRequestPayloadMap);
        //system.debug('RawBody=' + rawBody);
        req.setBody(rawbody);

		// AppLogging: 20190309
		processLog = 'REQUEST PAYLOAD: ' + rawBody + '\r\n*****\r\n';

        
        // Attempt the callout - create return error on exception
        try {

            // perform callout and set response
            res = h.send(req);

            //Integer statusCode = res.getStatusCode();
            Integer statusCode = res.getStatusCode();
            //system.debug(statusCode);
            rawBody = res.getBody();
            system.debug('This is the Response Raw body: ' + rawBody);
            ////returnResult.put('httpstatus', statusCode);

            // AppLogging: 20190309
            processLog += 'RESPONSE PAYLOAD: ' + rawBody + '\r\n*****\r\n';
            
            if ((statusCode == 200 || statusCode == 201) && rawBody != null) {


                // deserialize the response untyped
                Map<String, Object> untypedMap = (Map<String, Object>)JSON.deserializeUntyped(rawBody);
                System.debug('DBG This is the response body' + JSON.serializePretty(untypedMap));


                // get real value
                //Integer httpstatusInteger = Integer.valueof(untypedMap.get(httpStatus));
                //System.debug('httpstatus: ' + httpstatusInteger);
                //returnResult.put('httpstatus', httpstatusInteger);

                // check Success of deserialization
                //if (httpstatusInteger == 200 || httpstatusInteger == 201){



                //}  else {

                //}
                Object firstResultObj = untypedMap.get('data');
                String firstResultStr = JSON.serialize(firstResultObj);
                Map<String, Object> resultObj = (Map<String, Object>)JSON.deserializeUntyped(firstResultStr);
                String sessionToken = (String) Utility.getVariableValue(resultObj, 'client.accessToken'); 
                system.debug('DBG Sessiontoken: '+sessionToken);
                Utility.storeOrgCache(CRANESessionOrgCachePartitionName, CRANESessionIdCacheName, sessionToken, cacheExpiry);
                tokenRequestMap.put('message', 'Success');
                tokenRequestMap.put('token', sessionToken);

                /* //Used for Kaltura's second phase login, not required for CRANE
                loginRequestPayloadMap.clear();
                System.debug('DBG idValue---tempToken---loginRequestPayloadMap: ' + idValue + '---' + tempToken + '---' + loginRequestPayloadMap);
                
                loginRequestPayloadMap.put('ks', tempToken);
                loginRequestPayloadMap.put('id', idValue);

                System.debug('DBG tempToken---tokenValue: ' + tempToken +'---' + tokenValue);

                String combinedStr = tempToken + tokenValue;

                System.debug('DBG combinedStr: ' + combinedStr);

                Blob targetBlob = Blob.valueOf(combinedStr);

                Blob hashValue = Crypto.generateDigest('MD5', targetBlob);

                //String hashedString = EncodingUtil.base64Encode(hashValue);

                System.debug('DBG hashedString: ' + hashValue);

                loginRequestPayloadMap.put('tokenHash', EncodingUtil.convertToHex(hashValue));

                System.debug('DBG 2nd request map: ' + JSON.serializePretty(loginRequestPayloadMap));

                Interface_Operation_Setting__mdt kalturaStartSessionSetting = [SELECT Id, MasterLabel, DeveloperName, Call_With_Retry__c, Client_Key_Header_Name_Overwrite__c, 
                    Create_Sub_URL__c, http_code_field__c, Interface_Configuration__c, Interface_Configuration__r.Main_URL__c, Key__c, Language, Msg_Mapping__c,
                    Named_Credential_Overwrite__c, NameSpacePrefix, Pass_Key_Header_Name_overwrite__c, QualifiedApiName, response_message_field__c,
                    Sub_URL__c, Test_Data_Verification__c, Test_Data__c, test_http_code__c, Update_Method_overwrite__c, Upgrade_Indication_Field__c,
                    Interface_Configuration__r.Set_Timeout__c, Interface_Configuration__r.Content_Type__c
                     FROM Interface_Operation_Setting__mdt WHERE DeveloperName =: kalturaStartSessionSettingName];


                String startSessionEndPoint = kalturaStartSessionSetting.Interface_Configuration__r.Main_URL__c + kalturaStartSessionSetting.Sub_URL__c;
                System.debug('DBG startSessionEndPoint: ' + startSessionEndPoint);

                // check to ensure a callout can be performed using the Limits class
                if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
                    System.debug('The maximum number of callouts has been reached.');
                    return null;
                }

                // instantiate a new http object
                Http h2 = new Http();

                // instantiate a new HTTP request and response
                HttpRequest req2 = new HttpRequest();
                HttpResponse res2 = new HttpResponse();

                // configure the request
                req2.setEndpoint(startSessionEndPoint);
                req2.setMethod(httpMethod);
                req2.setTimeout(timeOutInMs);
                */
                // configure standard headers
                //req2.setHeader('Accept', '*/*');
                /*
                // tell the API to send and receive the data as a JSON object
                req2.setHeader('Content-Type', contentType);

                // set the body json with the message; basically a string with a key-value pair construction.
                String secondRawBody = JSON.serialize(loginRequestPayloadMap);
                System.debug('DBG 2nd RawBody=' + secondRawBody);
                req2.setBody(secondRawBody);

                // AppLogging: 20190309
                processLog += '2nd REQUEST PAYLOAD: ' + secondRawBody + '\r\n*****\r\n';

                // perform callout and set response
                res2 = h2.send(req2);

                //Integer statusCode = res.getStatusCode();
                Integer secondStatusCode = res2.getStatusCode();
                //system.debug(statusCode);
                secondRawBody = res2.getBody();
                untypedMap.clear();
                untypedMap = (Map<String, Object>)JSON.deserializeUntyped(secondRawBody);

                System.debug('This is the second Response Raw body: ' + JSON.serializePretty(untypedMap));
                ////returnResult.put('httpstatus', statusCode);

                // AppLogging: 20190309
                processLog += '2nd RESPONSE PAYLOAD: ' + secondRawBody + '\r\n*****\r\n';
                
                if ((secondStatusCode == 200 || secondStatusCode == 201) && secondRawBody != null) {
                    Map<String, Object> resultObjMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(untypedMap.get('result')));
                    String sessionToken = String.valueOf(resultObjMap.get('ks'));
                    System.debug('DBG sessionToken before storing to cache: ' + sessionToken);
                    Utility.storeOrgCache(kalturaSessionOrgCachePartitionName, kalturaSessionIdCacheName, sessionToken, 86400);
                    tokenRequestMap.put('message', 'Success');
                    tokenRequestMap.put('token', sessionToken);
                    System.debug('DBG storedCache: ' + Utility.fetchOrgCache(kalturaSessionOrgCachePartitionName, kalturaSessionIdCacheName));
                    
                    // AppLogging: 20190309
                    processLog += 'CALLOUT RESULT: Success \r\n*****\r\n';
                    appWrapperLogList.add(Utilities.createApplicationLog('Info','TransportLayerLogging','loginKaltura()','','TransportLayer',processLog,null,'Integration Log',startTime,logLevelCMD,null));
                    
                } else {
                    tokenRequestMap.put('message', 'ERROR: ' + statusCode);
                    tokenRequestMap.put('token', null);

                    // AppLogging: 20190309
                    processLog += 'CALLOUT RESULT: ERROR\r\n';
                    processLog += 'STATUS CODE: ' + statusCode + '\r\n*****\r\n';
		            appWrapperLogList.add(Utilities.createApplicationLog('Error','TransportLayerLogging','loginKaltura()','','TransportLayer',processLog,null,'Error Log',startTime,logLevelCMD,null));

                }
				*/
            } else {
                System.debug('DBG CRANELogin failed with error code and response: ' + statusCode + '---' + rawBody);
                tokenRequestMap.put('message', 'ERROR: ' + statusCode);
                tokenRequestMap.put('token', null);

                // AppLogging: 20190309
                processLog += 'CALLOUT RESULT: ERROR\r\n';
                processLog += 'STATUS CODE: ' + statusCode + '\r\n';
                processLog += 'RESPONSE PAYLOAD: ' + rawBody + '\r\n*****\r\n';
                appWrapperLogList.add(Utilities.createApplicationLog('Error','TransportLayerLogging','loginCRANE()','','TransportLayer',processLog,null,'Error Log',startTime,logLevelCMD,null));

            }



        } catch (Exception e) {
            System.debug('DBG loginCRANE exception: ' + e.getMessage());
            tokenRequestMap.put('message', 'ERROR: ' + e.getMessage());
            tokenRequestMap.put('token', null);

            // AppLogging: 20190309
            processLog += 'CALLOUT EXCEPTION: ' + e.getMessage() + '\r\n*****\r\n';
            appWrapperLogList.add(Utilities.createApplicationLog('Error','TransportLayerLogging','loginCRANE()','','TransportLayer',processLog,null,'Error Log',startTime,logLevelCMD,e));

        }

        // AppLogging: 20190309
//    	GlobalUtility.logMessage(appWrapperLogList);  // Commented off as it causes TEST class failures
        system.debug('DBG TokenRequestMap: '+tokenRequestMap);
        return tokenRequestMap;
    }
    
    
    // method to perform callouts
    // interfaceName is the developername of the interface_configuration__mdt
    // childinterfacename is the developername of the Interface_Operation_Setting__mdt
    // actualMessage is parameters to be passed to the endpoint
    public static Map<String,Object> makeCallout(final String interfaceName, final string childInterfaceName, final String actualMessage) {
        //system.debug('InterfaceName: ' + interfaceName);
        //system.debug('ChildInterfaceName: ' + childinterfaceName);
        String rawBody;
        // define a response to caller
        Map<String,Object> returnResult = new Map<String,Object>();

        // to encapsulate error message
        RequestResult result = new RequestResult();

        // define mapping table for interface setting, configured in Custom Metadata
        Map<String,Object> intSetting = new Map<String,Object>();
        
        // AppLogging: 20190309
        logLevelCMD=Utilities.getLogLevel('Transport Layer Logging'); 
		appWrapperLogList = new List<ApplicationLogWrapper>();
        
        List<Interface_Operation_Setting__mdt> retrieveAllInterfaceSettings = [SELECT Interface_Configuration__r.DeveloperName, Interface_Configuration__r.Main_URL__c,
                                                                                   Interface_Configuration__r.Set_Timeout__c, Interface_Configuration__r.Content_Type__c, response_message_field__c,
                                                                                   Interface_Configuration__r.test_mode__c, Enable_URL_Param__c, Interface_Configuration__r.test_exception__c,
                                                                                   DeveloperName, http_code_field__c, Sub_URL__c, Test_Data__c, Update_Method_overwrite__c
                                                                     			   FROM Interface_Operation_Setting__mdt WHERE Interface_Operation_Setting__mdt.DeveloperName = :childInterfaceName
                                                                                   AND Interface_Configuration__r.DeveloperName = :interfaceName];

        // allow the interface parameter to determine output of data from Custom Metadata

        for (Interface_Operation_Setting__mdt interfaceSetting : retrieveAllInterfaceSettings) {
			intSetting.put('mainURLMap', interfaceSetting.Interface_Configuration__r.Main_URL__c);
            intSetting.put('subURLMap', interfaceSetting.Sub_URL__c);
            intSetting.put('testmodeMap', interfaceSetting.Interface_Configuration__r.test_mode__c);
            intSetting.put('testExceptionMap', interfaceSetting.Interface_Configuration__r.test_exception__c);
            intSetting.put('httpCodeMap', interfaceSetting.http_code_field__c);
            intSetting.put('timeoutMap',Integer.valueof(interfaceSetting.Interface_Configuration__r.Set_Timeout__c));
            intSetting.put('requestMethod',interfaceSetting.Update_Method_overwrite__c);
            intSetting.put('contentTypeMap',interfaceSetting.Interface_Configuration__r.Content_Type__c);
            intSetting.put('errorResponseMessageMap',interfaceSetting.response_message_field__c);
            intSetting.put('testDataMap',interfaceSetting.Test_Data__c);
            intSetting.put('URLPayload',interfaceSetting.Enable_URL_Param__c);
		}
        for (String objKey : intSetting.keySet()) {
            System.debug('DBG intSettingMap: ' + objKey + '---' + intSetting.get(objKey));
        }
        system.debug('is test mode correct: ' + intSetting.get('testmodeMap'));
        system.debug('is test exception correct: ' + intSetting.get('testExceptionMap'));

        // determine test mode and/or test exception is on
        // test mode is 'true' then URL endpoint will use dummy data from within Custom Metadata; to be called from test class
		
        // Commented on 3/7/19 for Code Coverage
        if (intSetting.get('testmodeMap') == true){

            String testExceptionValue = String.valueof(intSetting.get('testExceptionMap'));

            // test mode is true while not testing exception
            if (testExceptionValue == 'Not Testing Exception'){

               String testDataString = String.valueOf(intSetting.get('testDataMap'));

               // deserialize the response untyped
               Map<String, Object> testDataObject = (Map<String, Object>)JSON.deserializeUntyped(testDataString);

               Result.message = 'Test Success!';
               Result.payload = testDataObject;
               system.debug(result);

               returnResult.put('Response', result.payload);
               returnResult.put('Message', result.message);
               returnResult.put('httpstatus', 200);
             }
             // test mode can be true or false while testing exception
            	else if (testExceptionValue == 'Client-Side HTTP Error - Salesforce') {

                 result.message = 'Client-side error encountered when sending a request, with HTTP status code: 400. Please review the debug log for additional details.';
                 returnResult.put('Message', result.message);

             } else if (testExceptionValue == 'Server-Side HTTP Error - External') {

                 result.message = 'Server-side error encountered when getting a response, with HTTP status code: 504. Please review the debug log for additional details.';
                 returnResult.put('Message', result.message);

             } else if (testExceptionValue == 'Unauthorized Endpoint') {

                 result.message = 'A callout exception has been encountered. Do ensure the correct message parameters are passed or check Setup -> Security -> Remote Site Settings.' ;
                 returnResult.put('Message', result.message);

             } else {

                 // catch all other exceptions
                 result.message = 'Test: An exception has been encountered while calling out to Integration';
                 returnResult.put('Message', result.message);
             }

        } else { //
           // start of actual http callout if testMode is off
            
            String urlEndpoint;

            if (intSetting.get('subURLMap') == null){
               String urlEndpointwithoutsubURL = String.valueOf(intSetting.get('mainURLMap'));
               urlEndpoint = urlEndpointwithoutsubURL;
               system.debug('withoutsubURL: ' + urlEndpointwithoutsubURL);
            } else {
               String urlEndpointwithsubURL = string.valueOf(intSetting.get('mainURLMap')) + string.valueOf(intSetting.get('subURLMap'));
               urlEndpoint = urlEndpointwithsubURL;
               system.debug('withsubURL: ' + urlEndpointwithsubURL);
            }

        // define basic information
        String endpoint = '' + urlEndpoint + '';
        system.debug('End Point: ' + endpoint);
        String method = '' + intSetting.get('requestMethod') + '';

        // check to ensure a callout can be performed using the Limits class
        if (Limits.getCallouts() >= Limits.getLimitCallouts()){
            result.message = 'The maximum number of callouts has been reached.';
        }

        // instantiate a new http object
        Http h = new Http();

        // instantiate a new HTTP request and response
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        // configure the request
        req.setMethod(method);
        req.setTimeout(Integer.valueOf(intSetting.get('timeoutMap')));

        // configure standard headers
        //req.setHeader('Accept', '*/*');

        // calling content type e.g. application/json or text/xml from custom metadata to allow easy edits in org setup for different API data format
        String contentType = String.valueOf(intSetting.get('contentTypeMap'));
        //system.debug(contentType);
		
        // get the token from loginCRANE method
                Map<String, String> tokenRequestMap;
                tokenRequestMap = loginCRANE();
            	system.debug('DBG TokenRequestMap2 : '+ tokenRequestMap);
                if (tokenRequestMap.get('message') == 'Success') {
                    //requestPayloadMap.put('', tokenRequestMap.get('token'));
                   	req.setHeader('Authorization', 'Bearer ' + tokenRequestMap.get('token'));
                    system.debug('DBG SuccessToken: '+tokenRequestMap.get('token'));
                } else {
                    if (Cache.Org.remove(CRANEOrgCacheCompleteName) == true) {
                        System.debug('DBG cache after removal: ' + Utility.fetchOrgCache(CRANESessionOrgCachePartitionName, CRANESessionIdCacheName));
                    } else {
                        result.message = 'Error clearing old cache from Org. Contact your System Administrator';
                    }
                    tokenRequestMap = loginCRANE();
                    if (tokenRequestMap.get('message') == 'Success') {
                        //requestPayloadMap.put('access_token', tokenRequestMap.get('token'));
                        req.setHeader('Authorization', 'Bearer ' + tokenRequestMap.get('token'));
                        system.debug('DBG Success2Token: '+tokenRequestMap.get('token'));
                    } else {
                        result.message = 'Error in re-Logging. Contact your System Administrator: ' + tokenRequestMap.get('message');
                    }
                }
    
            
                
            
            
        // tell the API to send and receive the data as a JSON object
        req.setHeader('Content-Type', '' + contentType + '');
            
        if (intSetting.get('URLPayload') == true) {
            rawBody = urlEndpoint + actualMessage; 
            req.setEndpoint(rawBody);
            System.debug('DBG ACTUAL Endpoint: ' + endPoint);
            System.debug('DBG ACTUAL REQUEST RawBody=' + rawBody);
            //req.setBody(rawbody);
            
            // AppLogging: 20190309
			processLog = 'REQUEST PAYLOAD: ' + rawBody + '\r\n*****\r\n';
            
        } else {
            Map<String, Object> requestPayloadMap = (Map<String, Object>)JSON.deserializeUntyped(actualMessage);
            
            
            
            // set the body json with the message; basically a string with a key-value pair construction.
            rawBody = JSON.serialize(requestPayloadMap);
            System.debug('DBG ACTUAL Endpoint: ' + endPoint);
            System.debug('DBG ACTUAL REQUEST RawBody=' + JSON.serializePretty(requestPayloadMap));
            req.setBody(rawbody);
            req.setEndpoint(endpoint);
            
            // AppLogging: 20190309
			processLog = 'REQUEST PAYLOAD: ' + rawBody + '\r\n*****\r\n';
        }
                
        // Attempt the callout - create return error on exception
       	try {
			system.debug('DBG REQ: '+req);
            // perform callout and set response
            res = h.send(req);
            //system.debug('@@@@');
            system.debug('DBG res: '+res);
			System.debug(res.getBody());
            //Integer statusCode = res.getStatusCode();
            Integer statusCode = res.getStatusCode();
            system.debug('DBG StatusCode: '+statusCode);
            rawBody = res.getBody();
            system.debug('DBG This is the Response Raw body: ' + rawBody);
            returnResult.put('httpstatus', statusCode);

            // check if client-side HTTP is Successful
            if ((statusCode == 200 || statusCode == 201) && rawBody != null) {
                // retrieve httpstatus field in response data from custom metadata
           		String httpStatus = (String) intSetting.get('httpCodeMap');
                system.debug('httpstatus: ' + httpStatus);

                // deserialize the response untyped
                Map<String, Object> untypedMap = (Map<String, Object>)JSON.deserializeUntyped(rawBody);
                //system.debug('This is the response body' + untypedMap);


                // get real value
                Integer httpstatusInteger;
                System.debug('httpstatus: ' + httpstatusInteger);
                
                httpStatus = getElementValue(untypedMap, httpStatus);
                if (httpStatus == null)
                    httpstatusInteger = 200;
                else
                    httpstatusInteger = Integer.valueOf(httpStatus);
                
                returnResult.put('httpstatus', httpstatusInteger);

                // check Success of deserialization
                if (httpstatusInteger == 200 || httpstatusInteger == 201){

                    	// the deserialized response contains the expected key
                        result.message = 'Success';
                        result.payload = untypedMap; //JSON.serialize(untypedMap.get(responseKey));
                    	system.debug(result);
                    	returnResult.put('Response', result.payload);

                }  else {
                    //String errorResponseMessage = String.valueof(untypedMap.get(String.valueOf(intSetting.get('errorResponseMessageMap'))));
                    String errorResponseMessage = getElementValue(untypedMap, String.valueOf(intSetting.get('errorResponseMessageMap')));
                    system.debug('Error Message: ' + errorResponseMessage);
                    result.payload = untypedMap; //JSON.serialize(untypedMap.get(responseKey));
                    returnResult.put('Response', result.payload);
                    result.message = 'Error encountered when attempting to get a response from the designated system with the following error: ' + errorResponseMessage;
                }
                
            } else {
                // errors with HTTP status code for review
                result.message = 'Client-side error encountered when sending a request, with HTTP status code:' + statusCode;
            }

            // AppLogging: 20190309
            processLog += 'CALLOUT RESULT: ' + result.message + '\r\n*****\r\n';
            processLog += 'RESPONSE PAYLOAD: ' + rawBody + '\r\n*****\r\n';
            appWrapperLogList.add(Utilities.createApplicationLog('Info','TransportLayerLogging','makeCallout()','','TransportLayer',processLog,null,'Integration Log',startTime,logLevelCMD,null));
            
        } catch (CalloutException e) {
            // catch any problem with a web service operation e.g. unauthorized endpoint
            ReturnResult.put('httpstatus', 500);
            result.message = 'A callout exception has been encountered:  ' + e.getMessage() +
                			 '. Do ensure the correct message parameters are passed or check Setup -> Security -> Remote Site Settings.' ;
            
            // AppLogging: 20190309
            processLog += 'CALLOUT EXCEPTION: ' + result.message + '\r\n';
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'TransportLayerLogging', 'makeCallout()', '', 'TransportLayer', processLog, null, 'Error Log', startTime, logLevelCMD, e));
            //appWrapperLogList.add(Utilities.createApplicationLog('Error','TransportLayerLogging','makeCallout()','','TransportLayer',processLog,null,'Error Log',startTime,logLevelCMD,e));

        } catch (Exception e) {
        	// other unexpected exceptions will be caught here
        	ReturnResult.put('httpstatus', 500);
            result.message = 'An exception has been encountered while calling out to Integration:  ' + e.getMessage();

            // AppLogging: 20190309
            processLog += 'CALLOUT EXCEPTION: ' + result.message + '\r\n';
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'TransportLayerLogging', 'makeCallout()', null, 'TransportLayer', processLog, null, 'Error Log', startTime, logLevelCMD, e));
            //appWrapperLogList.add(Utilities.createApplicationLog('Error','TransportLayerLogging','makeCallout()','','TransportLayer',processLog,null,'Error Log',startTime,logLevelCMD,e));
        }

        returnResult.put('Message', result.message);

        // end of actual http callout
      	}
        
        system.debug('returnResult: ' + returnResult);

        // AppLogging: 20190309
//    	GlobalUtility.logMessage(appWrapperLogList);
        
        // return the response
        return returnResult;
        
    }
    
    //This is a method to get element from JSON based on .notation passed as a string
    public Static String getElementValue(Map<String, Object> jsonData, String element){
        String strValue;
        List<String> stringPath = element.split('\\.');
        Map<String, Object> tempMap = jsonData;
        for(Integer i=0; i < stringPath.size(); i++){
            if(i != (stringPath.size()-1)){                        
                if (tempMap.get(stringPath[i]) == null){
                    break;
                }
                else{
                    tempMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(tempMap.get(stringPath[i])));
                }
            }
            if(i == (stringPath.size()-1)){                        
                strValue = String.valueOf(tempMap.get(stringPath[i]));                
            } 
            system.debug(tempMap);
        } 
        return strValue;
        
    }
    
}