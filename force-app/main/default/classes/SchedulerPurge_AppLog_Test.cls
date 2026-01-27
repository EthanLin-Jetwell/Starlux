/*******************************************************************
Description: This is the test class for SchedulerPurge_AppLog class
*******************************************************************/
@isTest
private class SchedulerPurge_AppLog_Test {
    
    public static testMethod void testGlobalAppLogPurgeBatchScheduler() {
        
        //build cron expression
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 1);
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        // call scheduler
        DateTime currentDateTime = Datetime.now();
        Test.StartTest();
        SchedulerPurge_AppLog globalPurgeBatchScheduler = new SchedulerPurge_AppLog();
        System.schedule('Global App Logs Purge ' + String.valueOf(currentDateTime), nextFireTime, globalPurgeBatchScheduler);
        Test.stopTest();
        
        // making sure job scheduled
        List < CronTrigger > jobs = [
            SELECT Id, CronJobDetail.Name, State, NextFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name = : 'Global App Logs Purge ' + String.valueOf(currentDateTime)
        ];
        System.assertNotEquals(null, jobs);
        System.assertEquals(1, jobs.size());
    }
}