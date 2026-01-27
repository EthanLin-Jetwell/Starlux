/********************************************************************************************************
NAME:			BatchAssistant
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		Handles the updates of Alternate Emails on the Case, Seat Allocation and Ticketing and Seat Sales Tracking records.
				Operates in batches of 100 size.
		
UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
16/12/2019      Edmond To		First version
********************************************************************************************************/

global class BatchAssistant extends BatchMaster implements Database.Batchable<Sobject>, Database.Stateful{
    global final String recordID;
    global final String objectType;
    global final String altEmail1;
    global final String altEmail2;
    global final String altEmail3;
    global final String queryCondition;
    
    //Application Log 171219
    global List<System_Settings__mdt> logLevelCMD;
    global DateTime startTime = DateTime.now();
    global Date currentDate = Date.today();
    global String processLog;
    global String payLoad;
    global Integer totalRecords = 0, errorRecords = 0, successfulRecords = 0;
    global List<String> failureRecords = new List<String>();
    
    
    //Constructor
    global BatchAssistant() {
        
    }
    
    //Constructor to take in various variables from ContactTriggerHandler
    global BatchAssistant(String recID, String objectName, String email1, String email2, String email3, String condition) {
        objectType = objectName;
        recordID = recID;
        altEmail1 = email1;
        altEmail2 = email2;
        altEmail3 = email3;
        queryCondition = condition;
    }
    
    //Start METHOD
	global Database.QueryLocator start(Database.BatchableContext BC) {
		system.debug('DBG Querying');
        
        //Construct dynamic query statement based on parameters provided from ContactTriggerHandler 
        String query = 'SELECT Id, Travel_Agent_Alternate_Email_1__c, Travel_Agent_Alternate_Email_2__c, Travel_Agent_Alternate_Email_3__c,Contact_Id__c FROM ' + objectType + ' WHERE Contact_Id__c = \''+ recordID + '\'';
        if (queryCondition != '') {
            query += ' AND ' + queryCondition;
        }
        system.debug('DBG query: '+query);
        return Database.getQueryLocator(query);
    }
    
    
    //Execute METHOD
    global void execute(Database.BatchableContext BC, List<sObject> objectList) {
        //Application Log 171219
        System_Settings__mdt logLevelCMD = [Select Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Contact Trigger Handler'
                                            limit 1];
        
        system.debug('DBG executing');
        
        //Master list for updating records
       	List<sObject> recordToUpdate = new List<sObject>();
        String field1 = 'Travel_Agent_Alternate_Email_1__c';
        String field2 = 'Travel_Agent_Alternate_Email_2__c';
        String field3 = 'Travel_Agent_Alternate_Email_3__c';
        
        //Iterating through all records to be updated and updating the alternate emails
        for (sObject rec : objectList) {
            rec.put(field1,altEmail1);
            rec.put(field2,altEmail2);
            rec.put(field3,altEmail3);
            recordToUpdate.add(rec);
            totalRecords++;
        }
      
        //Try catch to update
        try {
                Database.SaveResult[] updateResult = database.update(recordToUpdate, false);
                for (Integer i = 0; i < updateResult.size(); i++) {
                    if (!updateResult[i].isSuccess()) {
                        for (Database.Error err : updateResult[i].getErrors()) {
                            errorRecords++;
                            failureRecords.add(updateResult[i].Id);
                            processLog += 'Unable to update Record ID: ' + updateResult[i].id + '\r\n';
                            processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                            processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                        }
                    } else {
                        successfulRecords++;
                    }
                }
        } catch (DmlException DMLError) {
                //Application Log 171219
                GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'ContactTriggerHandler', 'processUpdateRecords', null, 'Contact Records Update', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
        }
    }
    
    
    //Finish METHOD
    global void finish(Database.BatchableContext BC) {
        //Application Log 171219
        System_Settings__mdt logLevelCMD = [Select Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Contact Trigger Handler'
                                            limit 1];
        system.debug('DBG total records:' + totalRecords);
        processLog = '#########################\r\n' +
                'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
                'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
                'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
                'Total Processed Records: ' + totalRecords + '\r\n' +
                'Total Successful Updated Records: ' + successfulRecords + '\r\n' +
                'Total Failed Records: ' + errorRecords + '\r\n' + 
                'List of Failed Records: ' + failureRecords + '\r\n' +
                '#########################\r\n' + processLog;
                
                system.debug('DBG ProcessLog: '+processLog);
                //Application Log 171219
                GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'ContactTriggerHandler', 'processUpdateRecords', null, 'Contact Records Update', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
    }
}