/********************************************************************************************************
NAME:			SchedulerPurge_LC_Transcript_Event_Test
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the test class for SchedulerPurge_LC_Transcript_Event class

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
10/06/2019      Edmond To		First version
********************************************************************************************************/
@isTest
private class SchedulerPurge_LC_Transcript_Event_Test {
    
    public static testMethod void testGlobalLiveChatTranscriptEventPurgeBatchScheduler() {
        
        //build cron expression
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 1);
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        // call scheduler
        DateTime currentDateTime = Datetime.now();
        Test.StartTest();
        SchedulerPurge_LC_Transcript_Event globalPurgeBatchScheduler = new SchedulerPurge_LC_Transcript_Event();
        System.schedule('Global Live Chat Transcript Events Purge ' + String.valueOf(currentDateTime), nextFireTime, globalPurgeBatchScheduler);
        Test.stopTest();
        
        // making sure job scheduled
        List < CronTrigger > jobs = [
            SELECT Id, CronJobDetail.Name, State, NextFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name = : 'Global Live Chat Transcript Events Purge ' + String.valueOf(currentDateTime)
        ];
        System.assertNotEquals(null, jobs);
        System.assertEquals(1, jobs.size());
    }
}