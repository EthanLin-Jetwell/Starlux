/*******************************************************************
Description: This class is used to perform purging of data from any object 
			 based on the query passed from the scheduler.
*******************************************************************/
global class Batch_GlobalPurgeData extends BatchMaster
implements Database.Batchable < sObject > , Database.Stateful {
    global String query;
    
    global Batch_GlobalPurgeData(String query,System_Settings__mdt sysSettingMD) {
        this.query = query;
        system.debug('DBG Masterlabel: '+sysSettingMD.MasterLabel);
        init(sysSettingMD.MasterLabel,(Object)this,sysSettingMD); 
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List < SObject > records) {
        System.debug('execute() - START');
        
        // total records
        totalRecords += records.size();
        
        // below code just to cover error block - delete
        /* 	
        if (Test.isRunningTest()) {
			Application_Log__c appLog = new Application_Log__c(Id = 'a0E0l000000L5ll');
			appLog.Module__c = 'Already Deleted Record';
			records.add(appLog);
		}*/
        
        // soft delete records
        Database.DeleteResult[] srDeleteList = Database.delete(records, false);
        handlerDMLResult(srDeleteList);
        
        // below code just to cover error block - delete
        /*
		if (Test.isRunningTest()) {
			Application_Log__c appLog = new Application_Log__c(Id = 'a0E0l000000L5ll');
			appLog.Module__c = 'Already Not Deleted Record';
			records.add(appLog);
		}*/
        
        // Hard delete records from recycle bin
        if (sysSettingMD.Is_Permanent_Delete__c) {
            Database.EmptyRecycleBinResult[] srEmptyRecBinList = Database.emptyRecycleBin(records);
            handlerDMLResult(srEmptyRecBinList);

        } // end if 
        
        System.debug('execute() - END');
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('finish() - START');
      
        String logTxt = query + '\r\n';
     	flushProcessResultLog(logTxt);
        logfinish(bc,false);
        System.debug('finish() - END');
    }
    
 
}