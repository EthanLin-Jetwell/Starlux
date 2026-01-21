/*******************************************************************
Description: This is the test class for Batch_globalPurgeData class.
*******************************************************************/
@isTest
public class Batch_GlobalPurgeData_Test {
    private static String mooduleName='Batch_GlobalPurgeData';
    
    /** when application log record exist to be deleted.**/
    static testMethod void testAppLogPurgeWhenAppLogExist() {
        
        //create Application log test data
        Map < String, Object > appLogFieldValueMap = new Map < String, Object > ();
        appLogFieldValueMap.put('Start_Date__c', (DateTime.now() - 20));
        appLogFieldValueMap.put('End_Date__c', (DateTime.now() - 20));
        appLogFieldValueMap.put('Module__c', 'Test Class');
        appLogFieldValueMap.put('Source_Function__c', 'Test Function');
        appLogFieldValueMap.put('Description__c', 'test');
        appLogFieldValueMap.put('Debug_Level__c', 'Info');
        appLogFieldValueMap.put('Type__c', 'Job Log');
        appLogFieldValueMap.put('Application_Name__c', 'TestAppName');
        
        TestUtility.createApplicationLogs(appLogFieldValueMap, 10);
        
        List < String > appLogQueryFieldsList = new List < String > {
            'Start_Date__c',
                'End_Date__c',
                'Module__c',
                'Source_Function__c',
                'Description__c',
                'Debug_Level__c',
                'Type__c',
                'Application_Name__c'
                };
                    
        // make sure log created.
        List<Application_Log__c> appLogCreatedList =  (List<Application_Log__c>) TestUtility.getApplicationLogs(appLogQueryFieldsList);
        System.assertEquals(10, appLogCreatedList.size());
        
        // build query
        DateTime StartTime = DateTime.now();
        List < System_Settings__mdt > sysSettingMD = [Select Id, MasterLabel, Label, Date_Field_API_Name__c, Additional_Filter__c,
                                                      Batch_Size__c, SObject_Api_Name__c, Debug__c, Info__c, Warning__c, Error__c, Is_Permanent_Delete__c
                                                      From System_Settings__mdt Where MasterLabel = : 'Application Log Purge Batch'
                                                      limit 1
                                                     ];
        
        DateTime closeDateCriteria = StartTime + 1; // Add 1 day
        String closeDateCriteriaStr = closeDateCriteria.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');

        String dateTime_field = sysSettingMD[0].Date_Field_API_Name__c;
        String sobj_api_name = sysSettingMD[0].SObject_Api_Name__c;
        String query = 'Select Id From ' + sobj_api_name + ' Where ' + dateTime_field + ' <= ' + closeDateCriteriaStr;
        
        // calling batch
        Test.startTest();
        Database.executeBatch(new Batch_GlobalPurgeData(query,sysSettingMD[0]), 10);
        Test.stopTest();
        
        // make sure record deleted   
        List < Application_Log__c >    appLogList = [Select Id, IsDeleted from Application_Log__c where IsDeleted=true ALL ROWS];
        System.assertEquals(10, appLogList.size());
        System.assertEquals(true, appLogList[0].IsDeleted);
    }
    
    /** When there is no app log to be deleted **/
    static testMethod void testAppLogPurgeWhenNoAppLogs() {
        
        // make sure log there is no created APP logs.
        List<Application_Log__c> appLogCreatedList =  (List<Application_Log__c>) TestUtility.getApplicationLogs();
        System.assertEquals(0, appLogCreatedList.size());
        
        // build query
        DateTime StartTime = DateTime.now();
        List < System_Settings__mdt > sysSettingMD = [Select Id, MasterLabel, Label, Date_Field_API_Name__c, Additional_Filter__c,
                                                      Batch_Size__c, SObject_Api_Name__c, Debug__c, Info__c, Warning__c, Error__c, Is_Permanent_Delete__c
                                                      From System_Settings__mdt Where MasterLabel = : 'Application Log Purge Batch'
                                                      limit 1
                                                     ];
        DateTime closeDateCriteria = StartTime;
        String closeDateCriteriaStr = closeDateCriteria.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String dateTime_field = sysSettingMD[0].Date_Field_API_Name__c;
        String sobj_api_name = sysSettingMD[0].SObject_Api_Name__c;
        String query = 'Select Id From ' + sobj_api_name + ' Where ' + dateTime_field + ' <= ' + closeDateCriteriaStr;
        
        // calling batch
        Test.startTest();
        Database.executeBatch(new Batch_GlobalPurgeData(query, sysSettingMD[0]), 10);
        Test.stopTest();
        
        // make sure record deleted   
        List < Application_Log__c >    appLogList = [Select Id, IsDeleted from Application_Log__c where IsDeleted=true ALL ROWS];
        System.assertEquals(0, appLogList.size());
    }
}