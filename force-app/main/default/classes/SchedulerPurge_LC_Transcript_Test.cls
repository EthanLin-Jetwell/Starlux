/********************************************************************************************************
NAME:			SchedulerPurge_LC_Transcript_Test
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the test class for SchedulerPurge_LC_Transcript class

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
10/06/2019      Edmond To		First version
********************************************************************************************************/
@isTest
private class SchedulerPurge_LC_Transcript_Test {
    
    public static testMethod void testGlobalLiveChatTranscriptPurgeBatchScheduler() {
        
        //build cron expression
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 1);
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        // call scheduler
        DateTime currentDateTime = Datetime.now();
        Test.StartTest();
        SchedulerPurge_LC_Transcript globalPurgeBatchScheduler = new SchedulerPurge_LC_Transcript();
        System.schedule('Global Live Chat Transcripts Purge ' + String.valueOf(currentDateTime), nextFireTime, globalPurgeBatchScheduler);
        Test.stopTest();
        
        // making sure job scheduled
        List < CronTrigger > jobs = [
            SELECT Id, CronJobDetail.Name, State, NextFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name = : 'Global Live Chat Transcripts Purge ' + String.valueOf(currentDateTime)
        ];
        System.assertNotEquals(null, jobs);
        System.assertEquals(1, jobs.size());
    }
}