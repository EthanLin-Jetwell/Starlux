/********************************************************************************************************
NAME:			ContactTriggerHandler
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		Handles the updates of Alternate Emails on the Contact record, and propagates to the related Case, 
				Seat Allocation and Ticketing and Seat Sales Tracking records.
		
UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
04/09/2019      Edmond To		First version
16/12/2019		Edmond To		Updated to handle Batch DML due to APEX CPU Limit
********************************************************************************************************/

public class ContactTriggerHandler extends TriggerHandler{
    
    public ContactTriggerHandler() {
        
    }
    
    /*** Context Overrides ***/
    public override void afterUpdate() {
        processUpdateRecords();
    }
    
    private static void processUpdateRecords() {
        //Application Log 170919
        System_Settings__mdt logLevelCMD = [Select Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Contact Trigger Handler'
                                            limit 1];
        system.debug('DBG made it here');
        //Query for all newly triggered Contacts
        List<Contact> contactList = [SELECT Id, Alternate_Email_1__c, Alternate_Email_2__c, Alternate_Email_3__c FROM Contact WHERE Id IN :trigger.new];

        //Iterate through contact list 
        for (Contact con : (List<Contact>) trigger.new) {
            Contact oldCon = (Contact)Trigger.oldMap.get(con.Id);
            //Check if Alternate Email has changed
            if (con.Alternate_Email_1__c != oldCon.Alternate_Email_1__c || con.Alternate_Email_2__c != oldCon.Alternate_Email_2__c || con.Alternate_Email_3__c != oldCon.Alternate_Email_3__c) {
                system.debug('DBG calling BatchAssistant');
                
                //Calling BatchAssistant to batch update the relevant records, passing following parameters in the constructor:
                //	1) Contact ID
                //	2) sObject to be updated
                //	3) Contact Alternate Email 1
                //	4) Contact Alternate Email 2
                //	5) Contact Alternate Email 3
                //	6) Condition to be included in SOQL for BatchAssistant
                String contactId = String.valueOf(con.Id).substring(0, 15);
                ID BatchId = Database.executeBatch(new BatchAssistant(contactId,'Case',con.Alternate_Email_1__c,con.Alternate_Email_2__c,con.Alternate_Email_3__c, 'Status != \'Closed\''), 100);
            	ID BatchId2 = Database.executeBatch(new BatchAssistant(contactId,'Seat_Allocation_and_Ticketing__c',con.Alternate_Email_1__c,con.Alternate_Email_2__c,con.Alternate_Email_3__c, ''), 100);
            	ID BatchId3 = Database.executeBatch(new BatchAssistant(contactId,'Seat_Sales_Tracking__c',con.Alternate_Email_1__c,con.Alternate_Email_2__c,con.Alternate_Email_3__c, 'Date__c > TODAY'), 100);
            }
        }
        
        
        /*
        //Master list for updating records
       	List<Sobject> seatAllocationRecordsToInsert = new List<Sobject>();
        List<Sobject> seatSalesRecordsToInsert = new List<Sobject>();
        List<Sobject> caseRecordsToInsert = new List<Sobject>();
        
        //Master list of all contact Ids and case Ids and maps of contactMap and caseContactMap
        List<String> allContacts = new List<String>();
        List<String> allCases = new List<String>();
        Map<String, String> caseContactMap = new Map<String, String>();
        Map<String, List<String>> contactMap = new Map<String, List<String>>();
        
        //Query for all newly triggered Contacts
        List<Contact> contactList = [SELECT Id, Alternate_Email_1__c, Alternate_Email_2__c, Alternate_Email_3__c FROM Contact WHERE Id IN :trigger.new];
        
        //Iterate through contact list to update master list of contacts
        for (Contact con : (List<Contact>) trigger.new) {
            Contact oldCon = (Contact)Trigger.oldMap.get(con.Id);
            if (con.Alternate_Email_1__c != oldCon.Alternate_Email_1__c || con.Alternate_Email_2__c != oldCon.Alternate_Email_2__c || con.Alternate_Email_3__c != oldCon.Alternate_Email_3__c) {
                allContacts.add(con.Id);
            }
        }
		
		//Only execute rest of trigger if allContacts != null
        if (allContacts.size() > 0) {
            //Iterate through contactList to populate contactMap
            for (Contact con : contactList) {
                List<String> emailList = new List<String>();
                emailList.add(con.Alternate_Email_1__c);
                emailList.add(con.Alternate_Email_2__c);
                emailList.add(con.Alternate_Email_3__c);
                contactMap.put(con.Id, emailList);
            }
            
            //Query for all Case records with ContactId in allContacts
            List<Case> caseList = [SELECT Id, ContactId, Status, Travel_Agent_Alternate_Email_1__c, Travel_Agent_Alternate_Email_2__c, Travel_Agent_Alternate_Email_3__c
                                   FROM Case WHERE ContactId IN :allContacts AND Status != 'Closed'];
            
            //Iterate through case list to update master list of cases
            for (Case c : caseList) {
                allCases.add(c.Id);
                caseContactMap.put(c.Id, c.ContactId);
            }
            
            //Query for all Seat_Sales_Tracking__c records with Case_Id__c in allCases
            List<Seat_Sales_Tracking__c> seatSalesList = [SELECT Id, Case_ID__c, Date__c, Travel_Agent_Alternate_Email_1__c, Travel_Agent_Alternate_Email_2__c, Travel_Agent_Alternate_Email_3__c
                                                          FROM Seat_Sales_Tracking__c WHERE Case_ID__c IN :allCases AND Date__c > :currentDate];
            
            //Query for all Seat_Allocation_and_Ticketing__c records with Case_Id__c in allCases
            List<Seat_Allocation_and_Ticketing__c> seatAllocationList = [SELECT Id, Case_ID__c, Travel_Agent_Alternate_Email_1__c, Travel_Agent_Alternate_Email_2__c, Travel_Agent_Alternate_Email_3__c
                                                                    FROM Seat_Allocation_and_Ticketing__c WHERE Case_ID__c IN :allCases];
            system.debug('DBG caseList: '+caseList.size());
            system.debug('DBG seatSalesList: '+seatSalesList.size());
            system.debug('DBG seatAllocationList: '+seatAllocationList.size());
            
            //Iterate through all queried Case records to update alternate emails
            for (Case c : caseList) {
                String key = c.Id;
                String contactValue = caseContactMap.get(key);
                if (contactValue != null) {
                    List<String> altEmails = contactMap.get(contactValue);
                    c.Travel_Agent_Alternate_Email_1__c = altEmails[0];
                    c.Travel_Agent_Alternate_Email_2__c = altEmails[1];
                    c.Travel_Agent_Alternate_Email_3__c = altEmails[2];
                    caseRecordsToInsert.add(c);
                    totalRecords++;
                }
            }
            
            //Iterate through all queried Seat Sales records to update alternate emails
            for (Seat_Sales_Tracking__c seatSales : seatSalesList) {
                String key = seatSales.Case_ID__c;
                String contactValue = caseContactMap.get(key);
                if (contactValue != null) {
                    List<String> altEmails = contactMap.get(contactValue);
                    seatSales.Travel_Agent_Alternate_Email_1__c = altEmails[0];
                    seatSales.Travel_Agent_Alternate_Email_2__c = altEmails[1];
                    seatSales.Travel_Agent_Alternate_Email_3__c = altEmails[2];
                    seatSalesRecordsToInsert.add(seatSales);
                    totalRecords++;
                }
            }
            
            //Iterate through all queried Seat Allocation records to update alternate Emails
            for (Seat_Allocation_and_Ticketing__c seatAllocation : seatAllocationList) {
                String key = seatAllocation.Case_ID__c;
                String contactValue = caseContactMap.get(key);
                if (contactValue != null) {
                    List<String> altEmails = contactMap.get(contactValue);
                    seatAllocation.Travel_Agent_Alternate_Email_1__c = altEmails[0];
                    seatAllocation.Travel_Agent_Alternate_Email_2__c = altEmails[1];
                    seatAllocation.Travel_Agent_Alternate_Email_3__c = altEmails[2];
                    seatAllocationRecordsToInsert.add(seatAllocation);
                    totalRecords++;
                }
            }
        }  
        
        //Try catch to update the related records
            try {
                
                Database.SaveResult[] updateResult = database.update(caseRecordsToInsert, false);
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
                
                
                Database.SaveResult[] updateResult2 = database.update(seatAllocationRecordsToInsert, false); 
                for (Integer i = 0; i < updateResult2.size(); i++) {
                    if (!updateResult2[i].isSuccess()) {
                        for (Database.Error err : updateResult2[i].getErrors()) {
                            errorRecords++;
                            failureRecords.add(updateResult2[i].Id);
                            processLog += 'Unable to update Record ID: ' + updateResult2[i].id + '\r\n';
                            processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                            processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                        }
                    } else {
                        successfulRecords++;
                    }
                }
                
                Database.SaveResult[] updateResult3 = database.update(seatSalesRecordsToInsert, false);
                for (Integer i = 0; i < updateResult3.size(); i++) {
                    if (!updateResult3[i].isSuccess()) {
                        for (Database.Error err : updateResult3[i].getErrors()) {
                            errorRecords++;
                            failureRecords.add(updateResult3[i].Id);
                            processLog += 'Unable to update Record ID: ' + updateResult3[i].id + '\r\n';
                            processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                            processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                        }
                    } else {
                        successfulRecords++;
                    }
                }
                
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
                //Application Log 170919
                GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'ContactTriggerHandler', 'processUpdateRecords', null, 'Contact Records Update', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
            
            } catch (DmlException DMLError) {
                
                //Application Log 170919
                GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'ContactTriggerHandler', 'processUpdateRecords', null, 'Contact Records Update', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
            }*/
    }
    
    
}