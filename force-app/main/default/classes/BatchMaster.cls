global virtual class BatchMaster {
    global String  applicationName ='';
    global Integer totalRecords = 0;
    global Integer succesfulRecords = 0;
    global Integer errorRecords = 0;
    global String processLog = '';
    global Datetime StartTime = DateTime.now();
    global System_Settings__mdt sysSettingMD;
    global List<String> failureRecords;
    global String JobName = '';

    global BatchMaster() {
        failureRecords = new List<String>();
 	}

     global void init(String appName,object cls,System_Settings__mdt sysSettingMD) {
        this.sysSettingMD = sysSettingMD; 
        this.applicationName = appName; 
        this.JobName = String.valueOf(cls).split(':')[0];
    }

/* UNCOMMENT to use additional Constructor    
   global void init(String appName,object cls) {
        
        this.applicationName = 'BatchJob'; 
        this.JobName = String.valueOf(cls).split(':')[0];
        getSetting();
    }
    global void getSetting()
    {
        sysSettingMD = [Select Additional_Filter__c,
                        Date_Field_API_Name__c ,
                        IsOutboundMessageRetry__c ,
                        Log_Purge_Days__c ,
                        Number_Of_Retry__c ,
                        SObject_Api_Name__c ,
                        Interface_Name__c ,
                        Batch_Size__c,
                        Debug__c,Error__c,Info__c,Warning__c 
    					from System_Settings__mdt  
                        where developername    = :JobName];
    }
*/
    
    global void handlerDMLResult(List<Database.DeleteResult> srList) {
        totalRecords += srList.size();
        // Soft delete records
        for (Integer i = 0; i < srList.size(); i++) {
            if (!srList[i].isSuccess()) {
                for (Database.Error err: srList[i].getErrors()) {
                    processLog += 'Unable to Delete Record ID: ' + srList[i].getId() + '\r\n';
                    processLog += 'Root Cause: ' + err.getStatusCode() + ': ' + err.getMessage() + '\r\n';
                    processLog += 'Record fields that affected this error: ' + err.getFields() + '\r\n';
                    errorRecords++;
                    failureRecords.add(srList[i].getId());
                }
            } else {
                succesfulRecords++;
            }
        }        
    }    

    global void handlerDMLResult(List<Database.EmptyRecycleBinResult> srList) {
        // totalRecords += srList.size();  // REMOVE to avoid double-counting right AFTER Delete
        // Hard delete records from recycle bin
        for (Integer i = 0; i < srList.size(); i++) {
            if (!srList[i].isSuccess()) {
                for (Database.Error err: srList[i].getErrors()) {
                    processLog += 'Unable to Permanently Delete Record ID: ' + srList[i].getId() + '\r\n';
                    processLog += 'Root Cause: ' + err.getStatusCode() + ': ' + err.getMessage() + '\r\n';
                    processLog += 'Record fields that affected this error: ' + err.getFields() + '\r\n';
                }
            } // end if
        } // for outer
    }    

    global void handlerDMLResult(List<Database.SaveResult> srList) {
         totalRecords += srList.size();
         for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        succesfulRecords +=1;
                        System.debug('Successfully update ID: ' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors    
                        errorRecords +=1;   
                        failureRecords.add(sr.getId());
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
            }
        
    }
    
/* -- UNCOMMENT for project use    
    global void handlerDMLResult(List<Database.UpsertResult> srList) {
         totalRecords += srList.size();
         for (Database.UpsertResult sr : srList) {
                    if (sr.isSuccess()) {
                        succesfulRecords +=1;
                        System.debug('Successfully update ID: ' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors    
                        errorRecords +=1;   
                        failureRecords.add(sr.getId());
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
            }
        
    }
*/
    
    global void flushProcessResultLog() {
        String failuerIdsStr = (failureRecords != null && failureRecords.size() > 0) ? string.join(failureRecords, ',') : 'NONE';
        succesfulRecords = totalRecords - errorRecords;
        processLog += 
            'Total Processed Records: ' + totalRecords + '\r\n' +
            'Total Successful Records: ' + succesfulRecords + '\r\n' +
            'Total Failed Records: ' + errorRecords + '\r\n' +
            'List of Failed Records: ' + failuerIdsStr + '\r\n';
		totalRecords =0;
        succesfulRecords =0;
        errorRecords =0;
        failureRecords = new List < String >();
        
    }
    global void flushProcessResultLog(String title) {
   
        processLog += title ;
        flushProcessResultLog();
        
    }   
    global void logfinish(Database.BatchableContext bc,Boolean needToflush) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = : bc.getJobId()];
		
        String processLogPrefix = 'Job Id: ' + job.Id + '; Job Status: ' + job.Status + '; Total Job Items: ' + job.TotalJobItems + '\r\n' +
            '------------------------------------------------\r\n' ;  

        String failuerIdsStr = (failureRecords != null && failureRecords.size() > 0) ? string.join(failureRecords, ',') : 'NONE';
        
        processLogPrefix = '################################################\r\n' +
           	'Application Name : ' + applicationName + '\r\n' +
            'Job Name: ' + JobName + '\r\n' +
            'Start Date Time: ' + string.valueof(StartTime) + '\r\n' +
            'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' ;
        if(needToflush) flushProcessResultLog();
        
        processLog = processLogPrefix + processLog;
        // add application log
        boolean isError = false;
        if (errorRecords > 0) {
            isError = true;
        }
        insertApplicationLog(bc.getJobId(), isError);      
    }
    
    
    /* Helper Methods */

//    private void insertApplicationLog(String jobId, boolean isError) {
    global void insertApplicationLog(String jobId, boolean isError) {
        
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        appLogWrapper.logLevel = 'Info';
        
        if (isError) appLogWrapper.logLevel = 'Error';
        
        appLogWrapper.sourceClass =  this.JobName;
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ' + jobId;
        appLogWrapper.logMessage = processLog;
        appLogWrapper.applicationName = this.applicationName;
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = StartTime;
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level
        appLogWrapper.isDebug 	= sysSettingMD.Debug__c;
        appLogWrapper.isInfo 	= sysSettingMD.Info__c;
        appLogWrapper.isError 	= sysSettingMD.Error__c;
        appLogWrapper.isWarning = sysSettingMD.Warning__c;
        
        GlobalUtility.logMessage(appLogWrapper);
    }    
 

}