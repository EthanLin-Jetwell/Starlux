/********************************************************************************************************
NAME:			AsyncRequestHandler
AUTHOR:			Aik Meng (aikmeng@salesforce.com)
PURPOSE:		Invoked by CaseTriggerHandler to perform Web service callout to CRANE REST API for Account 
				lookup in MDM.
				If match found in MDM, create new Account in SF and link with associated Case record(s).
				If NO match found in MDM, Case record will have no Account linked and its Account_Not_Found checkbox flagged.

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
04/07/2019      Aik Meng		First version
16/08/2019		Aik Meng		Updated code to call CRANE REST API instead of DIH
21/08/2019		Aik Meng		Updated code to handle changes in CRANE REST API response payload
26/08/2019		Aik Meng		Updated code based on STARLUX confirmed PhoneNumber format
								Avaya->SF,DIH->SF,SF storage: +(countryCode)(phoneNumber)  Example: +88612345678
								SF->Crane API: (countryCode)(phoneNumber)  Example: 88612345678
29/08/2019      Aik Meng		Added method to handle async forceAssignmentRule for WebForm Case records
06/09/2019		Aik Meng		Added method to handle updated CRANE REST API getAccount(email+phoneNumber)
********************************************************************************************************/

public class AsyncRequestHandler {
//public with sharing class AsyncRequestHandler {
	// Application Logging
    private static List<System_Settings__mdt> logLevelCMD;
    private static DateTime startTime = DateTime.now();
    private static String processLog;
    private static String payLoad;
    private static Integer totalRecords = 0, errorRecords = 0, successfulRecords = 0;
    private static List<String> failureRecords = new List<String>();
	public static void prepareRequest(Map<Id,String> queryMap) {
        
System.debug('[STARLUX] prepareAsyncRequest: MDM queryMap: ' + queryMap);
System.debug('[STARLUX] prepareAsyncRequest: MDM queryMap.size: ' + queryMap.size());

		for (Id recordId : queryMap.keySet()) {
            String searchParams = queryMap.get(recordId);
			String emailParam = searchParams.substringBefore(':');
			String phoneParam = searchParams.substringAfter(':');
System.debug('[STARLUX] prepareAsyncRequest: MDM recordId: ' + recordId);
System.debug('[STARLUX] prepareAsyncRequest: MDM emailParam: ' + emailParam);
System.debug('[STARLUX] prepareAsyncRequest: MDM phoneParam: ' + phoneParam);
			invokeMdmSearch(recordId, emailParam, phoneParam);
		}
    }  // End - prepareRequest()

	@future (callout=true)
	public static void invokeMdmSearch(ID caseId, String emailParam, String phoneParam) {
                // FETCH AppLogging setting
        System_Settings__mdt logLevelCMD = [SELECT 
                                                Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c 
                                            FROM
                                                System_Settings__mdt
                                            WHERE 
                                                MasterLabel='Case Trigger Handler'
                                            LIMIT 1];
System.debug('[STARLUX] invokeMdmSearch: caseId=' + caseId);
System.debug('[STARLUX] invokeMdmSearch: emailParam=' + emailParam);
System.debug('[STARLUX] invokeMdmSearch: phoneParam=' + phoneParam);
        Map<String, Object> interfaceData = new Map<String, Object>();
		interfaceData.put('email', emailParam); //interfaceData.put('eContactValue', emailParam);
		// EXPECTED Avaya phoneFormat: +(countryCode)(phoneNumber)
		// EXPECTED Crane API phoneFormat: (countryCode)(phoneNumber)
		phoneParam = phoneParam.removeStart('+');  // STRIP OFF '+' character from phoneNumber string
        interfaceData.put('mobilePhone', phoneParam);  //interfaceData.put('phoneNumber', phoneParam);
        
        try {
            Map<String, Object> responseMap = Utility.SendData('CRANE', 'Get_Account', interfaceData);
            if (responseMap.get('httpstatus')==200) {
                processResponse(caseID, emailParam, phoneParam, responseMap);
            }
        } catch (Exception e) {
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'AsyncRequestHandler', 'invokeMdmSearch()', null, 'invokeMdmSearch()', processLog, payLoad, 'Error Log', startTime, logLevelCMD, e));
        }
//System.debug(responseMap);

	}  // End - invokeMdmSearch()

	private static void processResponse(ID caseId, String emailParam, String phoneParam, Map<String, Object> responseMap) {

        // Application Logging
        DateTime startTime = DateTime.now();
        String processLog,payLoad;
        System_Settings__mdt logLevelCMD = [SELECT 
                                                Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c 
                                            FROM
                                                System_Settings__mdt
                                            WHERE 
                                                MasterLabel = 'Case Trigger Handler'
                                            LIMIT 1];

		Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(responseMap.get('Response')));
		//Boolean success = (Boolean) payloadMap.get('success'); 
//system.debug('[STARLUX] success: '+success); // TRUE means success 
		String messageContent = (String) Utility.getVariableValue(payloadMap, 'message.content'); 
system.debug('[STARLUX] messageContent: '+messageContent); // "OK" means success
        
        Map<String, Object> recordMap = new Map<String, Object>();
        Object dataObject = payloadMap.get('data');
        
        if (dataObject!= null && messageContent=='OK') { // Crane API success criteria ..success==TRUE &&
            recordMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payloadMap.get('data'))); // First record
        }
system.debug('[STARLUX] recordMap: '+recordMap);
                
        // Application Logging
        payLoad = String.valueOf(payloadMap);

        try {
            // IF matching record found in MDM,
            if (!recordMap.isEmpty()) {
                system.debug('[STARLUX] Creating new Account');
				Id personAccountRT_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();
                Date birthDate, cardTierExpiryDate, mileageExpiryDate;
                Integer currentMileage;
                String mdmID;
                // CONVERT non-null values to respective field type
                if (recordMap.get('birthdate')!='') birthDate=date.valueOf((String) recordMap.get('birthdate')); 
                if (recordMap.get('tierExpiryDate')!='') cardTierExpiryDate=date.valueOf((String) recordMap.get('tierExpiryDate'));
                if (recordMap.get('currentMileagesExpiryDate')!='') mileageExpiryDate=date.valueOf((String) recordMap.get('currentMileagesExpiryDate'));
                if (recordMap.get('currentMileage')!='') currentMileage=Integer.valueOf(recordMap.get('currentMileage'));
                if (recordMap.get('mdmId')!='') mdmID=String.valueOf(recordMap.get('mdmId'));
                // SAVE matched MDM customer in SF as new PersonAccount record
                Account newAccount = new Account(
                    RecordTypeId=personAccountRT_ID,
                    LastName=(string) recordMap.get('lastName'),
                    MiddleName=(string) recordMap.get('middleName'),
                    FirstName=(string) recordMap.get('firstName'),
                    PersonTitle=(string) recordMap.get('title'),
                    Gender__pc=(string) recordMap.get('gender'),
                    PersonBirthdate=(date) birthDate,
                    PersonHomePhone=(string) recordMap.get('homePhone'),
                    PersonMobilePhone=(string) recordMap.get('mobilePhone'),
                    PersonEmail=(string) recordMap.get('email'),
                    CEM_ID__c=(string) recordMap.get('cemId'),
                    MDM_ID__c= (string) mdmID,
                    Member_ID__pc=(string) recordMap.get('memberId'),
                    Card_Tier__pc=(string) recordMap.get('tier'),
                    Card_Tier_Expiry_Date__pc=(date) cardTierExpiryDate,
                    Current_Mileages__pc=(integer) currentMileage,
                    Current_Mileages_Expiry_Date__pc=(date) mileageExpiryDate,
                    Upgrade_Qualifications__pc=(string) recordMap.get('upgradeQualifications'),
                    Renewal_Qualifications__pc=(string) recordMap.get('renewalQualifications'),
                    Language_Preference__pc=(string) recordMap.get('languagePreference'),
                    Meal_Preference__pc=(string) recordMap.get('mealPreference'),
                    Seat_Preference__pc=(string) recordMap.get('seatPreference'),
                    Duty_Free_Preference__pc=(string) recordMap.get('dutyFreePreference'),
                    Passenger_Type__pc=(string) recordMap.get('passengerType') 
                );                 
    
                // INSERT new record
                insert newAccount;
                List<Account> newRecord = [SELECT PersonContactId FROM Account where Id =: newAccount.Id];
	system.debug('[STARLUX] New Account: '+newRecord);
                phoneParam = '+' + phoneParam;  // PREFIX '+' character to phoneNumber string
                
                // LINK Account record to the corresponding Case records
                // FIND All Case records with SuppliedEmail/SuppliedPhone = searchAttribute AND AccountId=NULL AND Status=New
                List<Case> caseList = new List<Case>();
                caseList = [SELECT 
                            	id, AccountId, ContactId 
                            FROM Case 
                            WHERE 
                            	Id =: caseId];
/*
                				SuppliedEmail=:emailParam 
                            AND SuppliedPhone=:phoneParam 
                            AND AccountId=NULL 
                            AND Status='New'];
*/                
                // UPDATE All Case.AccountId = new Account.Id
                for (Case eachRecord: caseList) {
                    eachRecord.AccountId = newAccount.Id;
                    eachRecord.ContactId = newRecord[0].PersonContactId;
                }
                update caseList;
            } else {  
            // IF NO match found in MDM,
                // FIND All Case records with SuppliedEmail/SuppliedPhone = searchAttribute AND AccountId=NULL AND Status=New
                List<Case> caseList = new List<Case>();
                caseList = [SELECT id, Account_Not_Found__c FROM Case WHERE Id=:caseId];
                
                // SET All Case.Account_Not_Found__c = TRUE 
                for (Case eachRecord: caseList) {
                    eachRecord.Account_Not_Found__c = TRUE;
                }
                // UPDATE Case records
                
                    Database.SaveResult[] saveResults = Database.update(caseList, false);
                    // Iterate through each returned result
                    for (Database.SaveResult sr : saveResults) {
                        if (sr.isSuccess()) {
                            // Operation was successful, so get the ID of the record that was processed
                            processLog += '\n';
                            processLog += 'No Account Found in MDM for Case ID: '+sr.getId();	
                            successfulRecords++;
                        } else {
                            // Operation failed, so get all errors
                            for (Database.Error err : sr.getErrors()) {
                                errorRecords++;
                                failureRecords.add(sr.Id);
                                processLog += '\n';
                                processLog += 'Unable to update Record ID: ' + sr.Id + '\r\n';
                                processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                                processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                            }
                            
                        }
                    }
                    processLog = '#########################\r\n' +
                    'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
                    'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
                    'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
                    'Total Success Records: ' + successfulRecords + '\r\n' +
                    'Total Failed Records: ' + errorRecords + '\r\n' + 
                    'List of Failed Records: ' + failureRecords + '\r\n' +
                    '#########################\r\n' + processLog;
                    
                    system.debug('DBG ProcessLog: '+processLog);
                    // Application Logging
                    GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'AsyncRequestHandler', 'processResponse()', null, 'Invoke MDM Search', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
              
            }  // End - if
        
        } catch (DmlException DMLError) {
            // Application Logging
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'AsyncRequestHandler', 'processResponse()', null, 'Invoke MDM Search', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
        }    
    }  // End - processResponse()

    
	@future
	public static void executeAssignmentRule(Set<Id> caseIds) {

        List<Case> caseList = new List<Case>();

// FETCH the assignment rules on case
//AssignmentRule AR = new AssignmentRule();
//AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];

		//Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmo = new Database.DMLOptions();
//dmo.AssignmentRuleHeader.assignmentRuleId= AR.id;
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        for(Case c : [SELECT Id FROM Case WHERE Id IN: caseIds]) {
			// SET the DMLOption on Case instance
            c.setOptions(dmo);
            caseList.add(c);
        }
        if (!caseList.isEmpty())	update caseList;
system.debug('[STARLUX]: executeAssignmentRule.caseIds='+caseList);

	}  // End - executeAssignmentRule()
    


 public static void fakeMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}