/********************************************************************************************************
NAME:			AccountTriggerHandler
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		To perform related records deletion on Account record deletion  
				Deletion of Account record initiates from DIH.
                Related records from Case, Contact, Live Chat Transcript, EmailMessage and Task to be deleted

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
11/06/2019      Edmond To		First version
********************************************************************************************************/

public class AccountTriggerHandler extends TriggerHandler {

    public AccountTriggerHandler() {
    }
	
    //Application Log 0612019
    private static List<System_Settings__mdt> logLevelCMD;
    private static DateTime startTime = DateTime.now();
    private static String processLog;
    private static String payLoad;
    private static Integer totalRecords = 0, errorRecords = 0, successfulRecords = 0;
    private static List<String> failureRecords = new List<String>();
    
    /*** Context Overrides ***/
	
	public override void beforeDelete() {
        
        deleteRelatedRecords();
    }
    
    private static void deleteRelatedRecords() {
    	
        //Application Log 0612019
        System_Settings__mdt logLevelCMD = [Select Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Account Trigger Handler'
                                            limit 1];
        
        //Create empty list to hold all records to be deleted
        List<Sobject> recordsToDeleteFirst = new List<Sobject>();
        List<Sobject> recordsToDeleteSecond = new List<Sobject>();
        List<Sobject> recordsToDeleteThird = new List<Sobject>();

        //Query for all Account records from Trigger.old, and the corresponding related records from each Account record
        List<Account> accountsDeleted = [SELECT Id, (SELECT Id FROM Cases), 
        (SELECT Id FROM Contacts), (SELECT Id FROM LiveChatTranscripts), (SELECT Id FROM Tasks), (SELECT Id FROM Emails) FROM Account WHERE Id IN :Trigger.old]; //(SELECT Id FROM EmailMessages),
        
        //Iterate over the list of deleted Account records 
		for (Account acc: accountsDeleted) {
            Case[] delCases = acc.Cases;
            LiveChatTranscript[] delChats = acc.LiveChatTranscripts;
            Task[] delTasks = acc.Tasks;
            Contact[] delContacts = acc.Contacts;
            EmailMessage[] delEmails = acc.Emails;
            
            if (accountsDeleted.size() > 0) {
                //Condition to check for account record deletion
                if (Trigger.isDelete) {
                    //Add related records from each object to master delete list, except for Case
                    if (delCases.size() > 0) {
                        for (Case c : delCases) {
                            totalRecords++;
                            recordsToDeleteFirst.add(c);
                    	}
                    }
                    if (delChats.size() > 0) {
                        for (LiveChatTranscript c : delChats) {
                            totalRecords++;
                        	recordsToDeleteSecond.add(c);
                    	}
                    }
                    if (delTasks.size() > 0) {
                        for (Task c : delTasks) {
                            system.debug('DBG Task Looping: '+c);
                            totalRecords++;
                        	recordsToDeleteThird.add(c);
                    	}
                    }
                    if (delContacts.size() > 0) {
                        for (Contact c : delContacts) {
                            totalRecords++;
                            recordsToDeleteFirst.add(c);
                        }
                    }
                    if (delEmails.size() > 0) {
                        for (EmailMessage c : delEmails) {
                            totalRecords++;
                            recordsToDeleteSecond.add(c);
                        }
                    }
            	}
            }
        }
         
       	/* 
        //Query for Email Message records associated with Case delete list
        List<EmailMessage> messageRecordsToDelete = [SELECT Id FROM EmailMessage WHERE ParentId IN :caseRecordsToDelete];
        if (messageRecordsToDelete.size() > 0) {
            for (EmailMessage e : messageRecordsToDelete) {
                totalRecords++;
                recordsToDelete.add(e);
            }
        }
        */
        
        //Try catch to delete the related records
        try {
            Database.DeleteResult[] deleteResult = database.delete(recordsToDeleteFirst, false);
            for (Integer i = 0; i < deleteResult.size(); i++) {
                if (!deleteResult[i].isSuccess()) {
                    for (Database.Error err : deleteResult[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(deleteResult[i].Id);
                        processLog += 'Unable to delete Record ID: ' + deleteResult[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    //system.debug('DBG DeleteResult[i]: '+deleteResult[i]);
                    successfulRecords++;
                }
            }
            
            Database.DeleteResult[] deleteResultSecond = database.delete(recordsToDeleteSecond, false);
            for (Integer i = 0; i < deleteResultSecond.size(); i++) {
                if (!deleteResultSecond[i].isSuccess()) {
                    for (Database.Error err : deleteResultSecond[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(deleteResultSecond[i].Id);
                        processLog += 'Unable to delete Record ID: ' + deleteResultSecond[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    //system.debug('DBG DeleteResult[i]: '+deleteResultSecond[i]);
                    successfulRecords++;
                }
            }
            
            Database.DeleteResult[] deleteResultThird = database.delete(recordsToDeleteThird, false);
            for (Integer i = 0; i < deleteResultThird.size(); i++) {
                if (!deleteResultThird[i].isSuccess()) {
                    for (Database.Error err : deleteResultThird[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(deleteResultThird[i].Id);
                        processLog += 'Unable to delete Record ID: ' + deleteResultThird[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    //system.debug('DBG DeleteResult[i]: '+deleteResultThird[i]);
                    successfulRecords++;
                }
            }
            
            processLog = '#########################\r\n' +
            'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
            'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
            'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
            'Total Processed Records: ' + totalRecords + '\r\n' +
            'Total Successful Deleted Records: ' + successfulRecords + '\r\n' +
            'Total Failed Records: ' + errorRecords + '\r\n' + 
            'List of Failed Records: ' + failureRecords + '\r\n' +
            '#########################\r\n' + processLog;
            
            system.debug('DBG ProcessLog: '+processLog);
            //Application Log 0612019
            GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'AccountTriggerHandler', 'deleteRelatedRecords', null, 'Account Related Records Deletion', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
        
        } catch (DmlException DMLError) {
            
            //Application Log 0612019
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'AccountTriggerHandler', 'deleteRelatedRecords', null, 'Account Related Records Deletion', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
        }
        
    }
}