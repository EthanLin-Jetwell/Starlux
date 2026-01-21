/********************************************************************************************************
NAME:			SchedulerPurge_SeatSalesTracking_test
AUTHOR:			Aik Meng (aikmeng@salesforce.com)
PURPOSE:		This is the test class for SchedulerPurge_SeatSalesTracking class

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
16/08/2019      Aik Meng		First version
********************************************************************************************************/
@isTest
private class SchedulerPurge_SeatSalesTracking_Test {
    
    public static testMethod void testBatchScheduler() {
        
        //build cron expression
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 1);
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        // call scheduler
        DateTime currentDateTime = Datetime.now();
        Test.StartTest();
        SchedulerPurge_SeatSalesTracking globalPurgeBatchScheduler = new SchedulerPurge_SeatSalesTracking();
        System.schedule('Global Cases Purge ' + String.valueOf(currentDateTime), nextFireTime, globalPurgeBatchScheduler);
        Test.stopTest();
        
        // making sure job scheduled
        List < CronTrigger > jobs = [
            SELECT Id, CronJobDetail.Name, State, NextFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name = : 'Global Cases Purge ' + String.valueOf(currentDateTime)
        ];
        System.assertNotEquals(null, jobs);
        System.assertEquals(1, jobs.size());
    }
}