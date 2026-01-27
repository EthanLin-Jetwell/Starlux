/********************************************************************************************************
NAME:			DynamicListCompController
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the apex controller class for the Aura component DynamicListComp

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
24/06/2019      Edmond To		First version
********************************************************************************************************/
public class DynamicListCompController {

    public class RSVPWrapper {
        @AuraEnabled public List<Object> AllRecords { get; set; }
        @AuraEnabled public Account RelatedAccountRecord { get; set; }
        @AuraEnabled public String ErrorMessage { get; set; }
        @AuraEnabled public List<LTC_API_Fields_Map__mdt> FieldsToDisplay { get; set; }
        @AuraEnabled public List<LTC_API_Fields_Map__mdt> SecondFieldsToDisplay { get; set; }
        @AuraEnabled public Map<String,Object> TemporaryData { get ; set; }
        @AuraEnabled public Case RelatedCaseRecord { get; set; }
    }
    
    @AuraEnabled
    public static String doContsructWrapperSubDetails(String APIEndPoint, String ContentBody, String ContentSubBody, String TestChildAPI, String ContentSecondSubBody, Id RecordID, String useCase) {
       
        /*
        system.debug('-------------------------------------------Data-------------------------------------------');
        system.debug('APIEndPoint: ' + APIEndPoint);
        system.debug('ContentBody: ' + ContentBody);
        system.debug('ContentSubBody: '+ ContentSubBody);
        system.debug('TestChildAPI: '+ TestChildAPI);
        system.debug('ContentSecondSubBody: '+ ContentSecondSubBody);
        system.debug('RecordID: '+ RecordID);
        system.debug('useCase: '+ useCase);
        system.debug('-------------------------------------------Data-------------------------------------------');*/
        
        
        //Create the wrapper
        RSVPWrapper returnWrap = new RSVPWrapper();
        if (useCase == 'Case') {
            try {
            returnWrap.FieldsToDisplay = getAllFields(TestChildAPI); 
            returnWrap.RelatedCaseRecord = getCaseRecord(RecordID); 
            
            if (returnWrap.RelatedCaseRecord.AccountId == null) {
                returnWrap.ErrorMessage = 'AccountId is not found on the existing Case record';
                returnWrap.AllRecords = new List<Object>();
                returnWrap.RelatedAccountRecord = new Account();
                returnWrap.SecondFieldsToDisplay = new List<LTC_API_Fields_Map__mdt >();
            }
            else{
					returnWrap.RelatedAccountRecord = getAccountRecord(returnWrap.RelatedCaseRecord.AccountId);
                    returnWrap.TemporaryData = CheckCalloutSubDetails(APIEndPoint, ContentBody, ContentSubBody, TestChildAPI, returnWrap.RelatedCaseRecord, returnWrap.RelatedAccountRecord); 
                    system.debug('DBG TemporaryData: ' + returnWrap.TemporaryData);
            		returnWrap.ErrorMessage = CheckErrorMessages(returnWrap.TemporaryData); 
                    
                    if(returnWrap.ErrorMessage == 'Success'){
                        Object testResponseBody = returnWrap.TemporaryData.get('Response'); 
            			String retrieveTestVerification = JSON.serialize(testResponseBody);
            			Map<String,Object> temp = (Map<String,Object>) JSON.deserializeUntyped(retrieveTestVerification);                        
                        returnWrap.AllRecords = getAllRecords(temp, ContentBody, ContentSubBody);
                    }
                    else{
                        returnWrap.AllRecords = new List<Object>();
                    }
                    
                    if(ContentSecondSubBody !='None'){
                        returnWrap.SecondFieldsToDisplay = getSecondFields(ContentSecondSubBody);  
                    }
                    else{
                        returnWrap.SecondFieldsToDisplay = new List<LTC_API_Fields_Map__mdt >();
                    }
                }
            //}
            //for testing force returning exceptions
            //if (true) {
            //    throw new MyException('this is a custom exception');
            //}
        } catch(Exception e) {
            //insertApplicationLog(e.getCause() + '---' + e.getMessage() + '---' + e.getStackTraceString(), true);
        }
        } else {
            try {
            returnWrap.FieldsToDisplay = getAllFields(TestChildAPI); 
            returnWrap.RelatedAccountRecord = getAccountRecord(RecordID); 
            
            if (returnWrap.RelatedAccountRecord.Id == null) {
                returnWrap.ErrorMessage = 'Account Record not found!';
                returnWrap.AllRecords = new List<Object>();
                returnWrap.RelatedAccountRecord = new Account();
                returnWrap.SecondFieldsToDisplay = new List<LTC_API_Fields_Map__mdt >();
            }
            else{
                    returnWrap.TemporaryData = CheckCalloutSubDetails(APIEndPoint, ContentBody, ContentSubBody, TestChildAPI, null, returnWrap.RelatedAccountRecord); 
                    system.debug('DBG TemporaryData: ' + returnWrap.TemporaryData);
            		returnWrap.ErrorMessage = CheckErrorMessages(returnWrap.TemporaryData); 
                    
                    if(returnWrap.ErrorMessage == 'Success'){
                        Object testResponseBody = returnWrap.TemporaryData.get('Response'); 
            			String retrieveTestVerification = JSON.serialize(testResponseBody);
            			Map<String,Object> temp = (Map<String,Object>) JSON.deserializeUntyped(retrieveTestVerification);                        
                        returnWrap.AllRecords = getAllRecords(temp, ContentBody, ContentSubBody);
                    }
                    else{
                        returnWrap.AllRecords = new List<Object>();
                    }
                    
                    if(ContentSecondSubBody !='None'){
                        returnWrap.SecondFieldsToDisplay = getSecondFields(ContentSecondSubBody);  
                    }
                    else{
                        returnWrap.SecondFieldsToDisplay = new List<LTC_API_Fields_Map__mdt >();
                    }
                }
            //}
            //for testing force returning exceptions
            //if (true) {
            //    throw new MyException('this is a custom exception');
            //}
        } catch(Exception e) {
            //insertApplicationLog(e.getCause() + '---' + e.getMessage() + '---' + e.getStackTraceString(), true);
        }
        }
        
        return JSON.serialize(returnWrap);
	}	

    @AuraEnabled 
    public static String doContsructWrapper(String APIEndPoint, String ContentBody, String ContentSubBody, String interfaceName, String ContentSecondSubBody, Id RecordID, Integer pageIndex, String useCase) {
        
        /*
        system.debug('-------------------------------------------Data-------------------------------------------');
        system.debug('APIEndPoint: ' + APIEndPoint);
        system.debug('ContentBody: ' + ContentBody);
        system.debug('ContentSubBody: '+ ContentSubBody);
        system.debug('interfaceName: '+ interfaceName);
        system.debug('ContentSecondSubBody: '+ ContentSecondSubBody);
        system.debug('RecordID: '+ RecordID);
        system.debug('-------------------------------------------Data-------------------------------------------');*/
        

        //Create the wrapper
        RSVPWrapper returnWrap = new RSVPWrapper();
        returnWrap.FieldsToDisplay = getAllFields(interfaceName);
        system.debug('DBG FieldsToDisplay:'+returnWrap.FieldsToDisplay);
        returnWrap.RelatedCaseRecord = getCaseRecord(RecordID);

        returnWrap.TemporaryData = CheckCallout(APIEndPoint, ContentBody, ContentSubBody, interfaceName, returnWrap.RelatedCaseRecord, pageIndex, useCase); //Need to check what parameters we wanna pass to CheckCallout for sourceMap purposes
        returnWrap.ErrorMessage = CheckErrorMessages(returnWrap.TemporaryData);

        Map<String, Object> tempMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(returnWrap.TemporaryData.get('Response')));
        
        if (returnWrap.ErrorMessage == 'Success') {
            returnWrap.AllRecords = getAllRecords(tempMap, ContentBody, ContentSubBody);
        } else {
            returnWrap.AllRecords = new List<Object>();
        }

        if (ContentSecondSubBody !='None') {
            returnWrap.SecondFieldsToDisplay = getSecondFields(ContentSecondSubBody);
        }
        else{
            returnWrap.SecondFieldsToDisplay = new List<LTC_API_Fields_Map__mdt >();
        }
		system.debug('DBG returnWrap: '+JSON.serialize(returnWrap));
        return JSON.serialize(returnWrap);
    }
    
    @AuraEnabled 
    public static String doContsructAccountWrapper(String APIEndPoint, String ContentBody, String ContentSubBody, String interfaceName, String ContentSecondSubBody, Id RecordID, Integer pageIndex, String useCase) {
        
        /*system.debug('-------------------------------------------Data-------------------------------------------');
        system.debug('APIEndPoint: ' + APIEndPoint);
        system.debug('ContentBody: ' + ContentBody);
        system.debug('ContentSubBody: '+ ContentSubBody);
        system.debug('interfaceName: '+ interfaceName);
        system.debug('ContentSecondSubBody: '+ ContentSecondSubBody);
        system.debug('RecordID: '+ RecordID);
        system.debug('-------------------------------------------Data-------------------------------------------');*/

        //Create the wrapper
        RSVPWrapper returnWrap = new RSVPWrapper();
        returnWrap.FieldsToDisplay = getAllFields(interfaceName);
        system.debug('DBG FieldsToDisplay:'+returnWrap.FieldsToDisplay);
        returnWrap.RelatedAccountRecord = getAccountRecord(RecordID);
        
        returnWrap.TemporaryData = CheckAccountCallout(APIEndPoint, ContentBody, ContentSubBody, interfaceName, returnWrap.RelatedAccountRecord, pageIndex, useCase); //Need to check what parameters we wanna pass to CheckCallout for sourceMap purposes
        returnWrap.ErrorMessage = CheckErrorMessages(returnWrap.TemporaryData);

        Map<String, Object> tempMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(returnWrap.TemporaryData.get('Response')));
        system.debug('DBG tempMap: '+ tempMap);
        if (returnWrap.ErrorMessage == 'Success') {
            returnWrap.AllRecords = getAllRecords(tempMap, ContentBody, ContentSubBody);
        } else {
            returnWrap.AllRecords = new List<Object>();
        }

        if (ContentSecondSubBody !='None') {
            returnWrap.SecondFieldsToDisplay = getSecondFields(ContentSecondSubBody);
        }
        else{
            returnWrap.SecondFieldsToDisplay = new List<LTC_API_Fields_Map__mdt >();
        }
		system.debug('DBG resultserialize: '+JSON.serialize(returnWrap));
        return JSON.serialize(returnWrap);
    }
    /*
    @AuraEnabled (cacheable=true)
    public static String cancelEntitlementRenewal(String apiEndPoint, String interfaceName, String recordId, String productId) {
        //System.debug('DBG cancelEntitlementRenewal start: ' + apiEndpoint +'---'+interfaceName+'---'+recordId+'---'+productId);
        Map<String, Object> resultMap = new Map<String, Object>();
        Case caseData = getCaseRecord(recordId);
        Account acct = [SELECT Sic FROM Account WHERE Id=:caseData.AccountId];

        Map<String, Object> sourceMap = new Map<String, Object>();
        sourceMap.put('user_id', acct.Sic);
        sourceMap.put('subscriptionId', productId);

        Map<String,Object> resforInterface = Utility.SendData(apiEndpoint, interfaceName, sourceMap);
        Object testhttpsstatusBody = resforInterface.get('httpstatus');

        if (String.valueOf(testhttpsstatusBody) != '200'){
            Object testMessageBody = resforInterface.get('Message');
            resultMap = resforInterface;
        } else {
            resultMap = resforInterface;
        }

        //System.debug('DBG cancelEntitlementRenewal responseMap: ' + JSON.serializePretty(resultMap));
        return JSON.serialize(resultMap);

    }
	*/
     //Get the related Account record
    private static Account getAccountRecord(String AccountId){
        //String StatusAsset1 = 'Active';
        //String StatusAsset2 = 'Pending';
        String MainQueryCondition = 'Id = ' + '\'' + AccountId + '\''; //+ ' AND (Status = ' + '\'' + StatusAsset1 + '\''+ ' OR Status = ' + '\'' + StatusAsset2 + '\'' + ') '
        List<Account> AccountData = lib_UtilityHelper.getSObjectRecords('Account', MainQueryCondition, false);
        return AccountData[0];
    }
    
    private static Case getCaseRecord(String RecordID){
        String MainQueryCondition = 'Id = ' + '\'' + RecordID + '\'';
        List<Case> CaseData = new List<Case>();
        caseData = lib_UtilityHelper.getSObjectRecords('Case', MainQueryCondition, false);
        return caseData.size() > 0 ? caseData[0] : null;
    }

    //Get the list of the fields for display
    private static List<LTC_API_Fields_Map__mdt> getAllFields(String apiEndpoint){
        // Will use the standard 'Language' field as safeguard instead of the custom because we are deprecating the Interface Field Display
        //String mainQueryCondition = 'Language__c = ' + '\'' + UserInfo.getLanguage() + '\'' + ' AND DeveloperName = ' + '\'' + apiEndpoint + '\'';
        String mainQueryCondition = /*'Language = ' + '\'' + UserInfo.getLanguage() + '\'' + ' AND */'DeveloperName = ' + '\'' + apiEndpoint + '\'';
        // Deprecating the Integration Field Display custom metadata object from Mediacorp and merging its details withg Interface Operation Setting
        //List<Integration_Field_Display__mdt> customMetadataList = lib_UtilityHelper.getSObjectRecords('Integration_Field_Display__mdt', mainQueryCondition, false); TODO
        List<Interface_Operation_Setting__mdt> customMetadataList = new List<Interface_Operation_Setting__mdt>();
        customMetadataList = lib_UtilityHelper.getSObjectRecords('Interface_Operation_Setting__mdt', mainQueryCondition, false);

        String CustomMetadataObjectID = customMetadataList[0].Id;//customMetadataList.size() > 0 ? customMetadataList[0].Id : null;
        String subQueryCondition = /*'Language = ' + '\'' + UserInfo.getLanguage() + '\'' + ' AND*/ 'Interface_Operation_Setting__c = ' + '\'' + CustomMetadataObjectID + '\'';
		List<LTC_API_Fields_Map__mdt> FinalList = lib_UtilityHelper.getSObjectRecords('LTC_API_Fields_Map__mdt', subQueryCondition, false);

        return FinalList;
    }

    //Get the list of the fields for display
    private static List<LTC_API_Fields_Map__mdt> getSecondFields(String ContentSecondSubBody){
        String MainQueryCondition = 'Language__c = ' + '\'' + UserInfo.getLanguage() + '\'' + ' AND DeveloperName = ' + '\'' + ContentSecondSubBody + '\'';
        //List<Integration_Field_Display__mdt> customMetadataList = lib_UtilityHelper.getSObjectRecords('Integration_Field_Display__mdt', MainQueryCondition, false); TODO
        List<Interface_Operation_Setting__mdt> customMetadataList = new List<Interface_Operation_Setting__mdt>();
        customMetadataList = lib_UtilityHelper.getSObjectRecords('Interface_Operation_Setting__mdt', mainQueryCondition, false);

        String CustomMetadataObjectID = customMetadataList.size() > 0 ? customMetadataList[0].Id : null;
        String SubQueryCondition = 'Language = ' + '\'' + UserInfo.getLanguage() + '\'' + ' AND Interface_Operation_Setting__c = ' + '\'' + CustomMetadataObjectID + '\'';
        List<LTC_API_Fields_Map__mdt> FinalList = lib_UtilityHelper.getSObjectRecords('LTC_API_Fields_Map__mdt', SubQueryCondition, false);

        return FinalList;
    }

    //Get the records to display
    private static Map<String,Object> CheckCallout(String apiEndPoint, String contentBody, String contentSubBody, String interfaceName, Case caseData, Integer pageIndex, String useCase){
        System.debug('DBG CheckCallout: APIEndPoint:' + APIEndPoint + '---ContentBody: ' + ContentBody + '---ContentSecondSubBody: ' + ContentSubBody + '---interfaceName: ' + interfaceName + '---CaseData: ' + CaseData);
        
        Map<String,Object> resultMap = new Map<String,Object>();
        Map<String, Object> subscriberResponseMap = new Map<String,Object>();

        String testInterfaceParameter = APIEndPoint; // define parent interface
        String testChildInterfaceParameter = interfaceName; // define child interface
		
        Account acct = [SELECT Id, CEM_ID__c FROM Account WHERE Id =:caseData.AccountId];
        
        Map<String, Object> sourceMap = new Map<String, Object>();
        sourceMap.put('CEM_Id', acct.CEM_ID__c);
        /*sourceMap.put('Case', CaseData);
		*/
        
        System.debug('DBG parent acct: ' + acct);
        Boolean hasError = false;
        Boolean isAccountUpdateNeeded = false;
		
        /*
        if (acct.Id == null) { //REPLACE THIS WITH CEM ID IF REQUIREMENT TO RETRIEVE CEM ID EXISTS LATER
            subscriberResponseMap = InterfaceHandler.syncSend(acct.Id, 'DIH', 'Retrieve_Subscriber_Id', false); 
            //subscriberResponseMap = InterfaceHandler.syncSend(acct.Id, '<External System>', '<Operating Setting>', false); //Replace parameters in method with desired inputs
            
            if (subscriberResponseMap.get('httpstatus') == 200) {
                //System.debug('DBG SUBSCRIBERRESPONSEMAP 200: ' + subscriberResponseMap);
                Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(subscriberResponseMap.get('Response')));
                Map<String, Object> resultObjMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payloadMap.get('result')));
                List<Object> objList = (List<Object>) JSON.deserializeUntyped(JSON.serialize(resultObjMap.get('objects')));
                Map<String, Object> personMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(objList[0])); // kaltura always sends 1 count
                
                String subId = String.valueOf(personMap.get('id'));

                System.debug('DBG subId: ' + subId);
                if (useCase == 'Active Entitlements') {
                    sourceMap.put('user_id', subId);
                    sourceMap.put('isExpiredEqual', false);
                    sourceMap.put('pageIndex', pageIndex);
                }

                if (useCase == 'Inactive Entitlements') {
                    sourceMap.put('user_id', subId);
                    sourceMap.put('isExpiredEqual', true);
                    sourceMap.put('pageIndex', pageIndex);
                }

                if (useCase == 'Transactions') {
                    sourceMap.put('user_id', subId);
                    sourceMap.put('pageIndex', pageIndex);
                }
                isAccountUpdateNeeded = true;
            } else {
                //System.debug('DBG SUBSCRIBERRESPONSEMAP 400: ' + subscriberResponseMap);
                resultMap = subscriberResponseMap;
                hasError = true;
            }

        } else {
            if (useCase == 'Active Entitlements') {
                sourceMap.put('user_id', acct.Sic);
                sourceMap.put('isExpiredEqual', false);
                sourceMap.put('pageIndex', pageIndex);
            }

            if (useCase == 'Inactive Entitlements') {
                sourceMap.put('user_id', acct.Sic);
                sourceMap.put('isExpiredEqual', true);
                sourceMap.put('pageIndex', pageIndex);
            }

            if (useCase == 'Transactions') {
                sourceMap.put('user_id', acct.Sic);
                sourceMap.put('pageIndex', pageIndex);
            }
        }
		*/
        //System.debug('DBG hasError: ' + hasError);
        //System.debug('DBG isAccountUpdateNeeded: ' + isAccountUpdateNeeded);
        if (!hasError) {
            System.debug('DBG SOURCEMAP: ' + JSON.serializePretty(sourceMap));
            Map<String,Object> resforInterface = Utility.SendData(testInterfaceParameter, testChildInterfaceParameter, sourceMap); 
            //Map<String,Object> resforInterface = Utility.SendData('<External System>', testChildInterfaceParameter, sourceMap); //Replace parameters in method with desired inputs
            String resStringforInterface = JSON.serialize(resforInterface);
            
            Object testhttpsstatusBody = resforInterface.get('httpstatus');

            if (String.valueOf(testhttpsstatusBody) != '200'){
                Object testMessageBody = resforInterface.get('Message');
                resultMap = resforInterface;
            } else {
                resultMap = resforInterface;
            }
			/*
            if (isAccountUpdateNeeded) {
                InterfaceHandler.processSubscriberUpdate(subscriberResponseMap);
            }*/
        }
        System.debug('DBG CheckCallout resultMap: ' + JSON.serialize(resultMap));
        return resultMap;
    }
    
    //Get the records to display
    private static Map<String,Object> CheckAccountCallout(String apiEndPoint, String contentBody, String contentSubBody, String interfaceName, Account accountData, Integer pageIndex, String useCase){
        //System.debug('DBG TGL_CaseListActiveEntitlementsController CheckCallout: APIEndPoint:' + APIEndPoint + '---ContentBody: ' + ContentBody + '---ContentSecondSubBody: ' + ContentSubBody + '---interfaceName: ' + interfaceName + '---CaseData: ' + CaseData);
        
        Map<String,Object> resultMap = new Map<String,Object>();
        Map<String, Object> subscriberResponseMap = new Map<String,Object>();

        String testInterfaceParameter = APIEndPoint; // define parent interface
        String testChildInterfaceParameter = interfaceName; // define child interface

        Map<String, Object> sourceMap = new Map<String, Object>();
        sourceMap.put('CEM_Id', accountData.CEM_ID__c);
        //sourceMap.put('Account', AccountData);
        
        Boolean hasError = false;
        Boolean isAccountUpdateNeeded = false;

        /*
        if (accountData.Id == null) { //REPLACE THIS WITH CEM ID IF REQUIREMENT TO RETRIEVE CEM ID EXISTS LATER
            subscriberResponseMap = InterfaceHandler.syncSend(accountData.Id, 'DIH', 'Retrieve_Subscriber_Id', false); 
            //subscriberResponseMap = InterfaceHandler.syncSend(acct.Id, '<External System>', '<Operating Setting>', false); //Replace parameters in method with desired inputs
            
            if (subscriberResponseMap.get('httpstatus') == 200) {
                //System.debug('DBG SUBSCRIBERRESPONSEMAP 200: ' + subscriberResponseMap);
                Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(subscriberResponseMap.get('Response')));
                Map<String, Object> resultObjMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payloadMap.get('result')));
                List<Object> objList = (List<Object>) JSON.deserializeUntyped(JSON.serialize(resultObjMap.get('objects')));
                Map<String, Object> personMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(objList[0])); // kaltura always sends 1 count
                
                String subId = String.valueOf(personMap.get('id'));

                System.debug('DBG subId: ' + subId);
                if (useCase == 'Active Entitlements') {
                    sourceMap.put('user_id', subId);
                    sourceMap.put('isExpiredEqual', false);
                    sourceMap.put('pageIndex', pageIndex);
                }

                if (useCase == 'Inactive Entitlements') {
                    sourceMap.put('user_id', subId);
                    sourceMap.put('isExpiredEqual', true);
                    sourceMap.put('pageIndex', pageIndex);
                }

                if (useCase == 'Transactions') {
                    sourceMap.put('user_id', subId);
                    sourceMap.put('pageIndex', pageIndex);
                }
                isAccountUpdateNeeded = true;
            } else {
                //System.debug('DBG SUBSCRIBERRESPONSEMAP 400: ' + subscriberResponseMap);
                resultMap = subscriberResponseMap;
                hasError = true;
            }

        } else {
            if (useCase == 'Active Entitlements') {
                sourceMap.put('user_id', accountData.Sic);
                sourceMap.put('isExpiredEqual', false);
                sourceMap.put('pageIndex', pageIndex);
            }

            if (useCase == 'Inactive Entitlements') {
                sourceMap.put('user_id', accountData.Sic);
                sourceMap.put('isExpiredEqual', true);
                sourceMap.put('pageIndex', pageIndex);
            }

            if (useCase == 'Transactions') {
                sourceMap.put('user_id', accountData.Sic);
                sourceMap.put('pageIndex', pageIndex);
            }
        }
		*/
        //System.debug('DBG hasError: ' + hasError);
        //System.debug('DBG isAccountUpdateNeeded: ' + isAccountUpdateNeeded);
        if (!hasError) {
            System.debug('DBG SOURCEMAP: ' + JSON.serializePretty(sourceMap));
            Map<String,Object> resforInterface = Utility.SendData(testInterfaceParameter, testChildInterfaceParameter, sourceMap); 
            //Map<String,Object> resforInterface = Utility.SendData('<External System>', testChildInterfaceParameter, sourceMap); //Replace parameters in method with desired inputs
            String resStringforInterface = JSON.serialize(resforInterface);
            
            Object testhttpsstatusBody = resforInterface.get('httpstatus');

            if (String.valueOf(testhttpsstatusBody) != '200'){
                Object testMessageBody = resforInterface.get('Message');
                resultMap = resforInterface;
            } else {
                resultMap = resforInterface;
            }

            /*	
            if (isAccountUpdateNeeded) {
                InterfaceHandler.processSubscriberUpdate(subscriberResponseMap);
            }*/
        }
        //System.debug('DBG CheckCallout resultMap: ' + JSON.serialize(resultMap));
        return resultMap;
    }
    
    //Get the records to display
    private static Map<String,Object> CheckCalloutSubDetails(String APIEndPoint, String ContentBody, String ContentSubBody, String TestChildAPI, Case CaseData, Account AccountData){
        String testInterfaceParameter = APIEndPoint; // define parent interface 
        String testChildInterfaceParameter = TestChildAPI; // define child interface
       
        Map<String, Object> sourceMap = new Map<String, Object>();		
        sourceMap.put('CEM_Id', accountData.CEM_ID__c);
        
        Map<String,Object> resforInterface = Utility.SendData(testInterfaceParameter, testChildInterfaceParameter, sourceMap);
        System.debug('DBG resforInterface: ' + JSON.serializePretty(resforInterface));
        String resStringforInterface = JSON.serialize(resforInterface);
        Map<String,Object> temp = new Map<String,Object>();
        temp = resforInterface;
        /*
        Object testhttpsstatusBody = resforInterface.get('httpstatus'); 
        
        if(String.valueOf(testhttpsstatusBody) != '200'){
            Object testMessageBody = resforInterface.get('Message'); 
            //String retrieveTestVerification = JSON.serialize(testMessageBody);
            //temp = (Map<String,Object>) JSON.deserializeUntyped(retrieveTestVerification);
            temp = resforInterface;
        }
        else{
            Object testResponseBody = resforInterface.get('Response'); 
            String retrieveTestVerification = JSON.serialize(testResponseBody);
            temp = (Map<String,Object>) JSON.deserializeUntyped(retrieveTestVerification); 
        }
		*/
        system.debug('DBG Temp message'+temp);
        return temp;
    }
    

    //Check Error Message
    private static String CheckErrorMessages(Map<String,Object> temp){
        //Check if there is an error in the callout by checking httpstatus ='200' & servicedesc
        //If httpstatus == '200', there is no error and proceed as per normal
        //If httpstatus != '200', there is an error and take the value servicedesc
        String message;
        String statuscheck = String.valueOf(temp.get('httpstatus'));

        system.debug(statuscheck);

        if (statuscheck == '200') {
            message = 'Success';
        } else {
            message = (String)temp.get('Message');
            system.debug('Error in callout: message');
        }
        return message;
    }

    //Get the records to display
    private static List<Object> getAllRecords(Map<String,Object> temp, String ContentBody, String ContentSubBody) {
        System.debug('DBG getAllRecords start: ' + JSON.serializePretty(temp) + '---' + contentBody + '---' + contentSubBody);
        Map<String,Object> posts = (Map<String,Object>)temp.get(ContentBody);
        String DataProcessing = JSON.serialize(posts); //All JSON values are changed to string data type

        Map<String,Object> temp2 = (Map<String,Object>) JSON.deserializeUntyped(DataProcessing);
        List<Object> posts2 = new List<Object>();
        
        posts2 =  (List<Object>)temp2.get(ContentSubBody);
        System.debug('DBG getAllRecords posts2: ' + JSON.serializePretty(posts2));
        return posts2;
    }


}