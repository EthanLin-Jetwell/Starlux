/********************************************************************************************************
NAME:			SchedulerPurge_Airport_Operation
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the scheduler class for the purging of Airport Operation Object

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
------------------------------------------------------------- 
10/06/2019      Edmond To		First version
********************************************************************************************************/

global class SchedulerPurge_Airport_Operation implements Schedulable{
    global String metadata_label_name = 'Airport Operation Purge Batch'; 
    global String sobj_api_name;
    global String additionalFilter;
    global Integer batchSize = 200;
    global String requiredOperator = ' <= ';
    global DateTime StartTime = DateTime.now();
    global List < System_Settings__mdt > sysSettingMD;

    global void execute(SchedulableContext ctx) {
        // find record ages from setting
        sysSettingMD = [Select Id, MasterLabel, Date_Field_API_Name__c, Additional_Filter__c, Batch_Size__c,Log_Purge_Days__c,Is_Permanent_Delete__c,
                        SObject_Api_Name__c, Debug__c, Info__c, Warning__c, Error__c From System_Settings__mdt 
                        Where MasterLabel = : metadata_label_name limit 1];
        String dateTime_field = '';
        String query = '';
        
        if (sysSettingMD.size() > 0) {
            if (Integer.valueOf(sysSettingMD[0].Log_Purge_Days__c) > 0) {
                DateTime dateTimeCriteria = (StartTime - Integer.valueof(sysSettingMD[0].Log_Purge_Days__c));
                String dateTimeCriteriaStr = dateTimeCriteria.formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
                
                // Replace time with 00:00:00
                String[] dateTimeCriteriaStrArr = dateTimeCriteriaStr.split('T');
                dateTimeCriteriaStr  = dateTimeCriteriaStrArr[0] + 'T00:00:00Z';
                System.debug(dateTimeCriteriaStr);
                
                dateTime_field = sysSettingMD[0].Date_Field_API_Name__c;
                sobj_api_name = sysSettingMD[0].SObject_Api_Name__c;
                if (sysSettingMD[0].Batch_Size__c>0)
                    batchSize = Integer.valueof(sysSettingMD[0].Batch_Size__c);
                
                // build parent query
                query = 'Select Id From ' + sobj_api_name + ' Where ' + dateTime_field + ' <= ' + dateTimeCriteriaStr;
                
                // add any additional query.
                additionalFilter = sysSettingMD[0].Additional_Filter__c;
                if (String.isNotBlank(additionalFilter)) {
                    query = 'Select Id From ' + sobj_api_name + ' Where ' + dateTime_field + ' <= ' + dateTimeCriteriaStr + ' AND ' + additionalFilter;
                }
            }
        } else {
            query = '';
        }
        System.debug('*** query = ' + query);
        
        // finally call batch   
        ID BatchId = Database.executeBatch(new Batch_GlobalPurgeData(query, sysSettingMD[0]), batchSize);
        System.debug('Job ID = ' + BatchId);
    } // END - execute()
}