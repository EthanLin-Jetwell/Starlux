@IsTest
private class Schedule_SendBusinessHoursMessage_Test {

    @IsTest
    static void testScheduleTodayAndAbortOldJobs() {

        // Existing job to be aborted
        Datetime oldRunTime = Datetime.now().addMinutes(10);
        String oldCron = oldRunTime.format('s m H d M ? yyyy');

        System.schedule(
            'Schedule EndCalls (English) - OLD',
            oldCron,
            new Schedule_SendBusinessHoursMessage('English')
        );

        // Work hour ending later today
        Work_Hour__c wh = new Work_Hour__c(
            Language__c = 'English',
            Start_Time__c = Time.newInstance(
                Datetime.now().addHours(-8).hour(),
                Datetime.now().addHours(-8).minute(),
                0,
                0
            ),
            End_Time__c = Time.newInstance(
                Datetime.now().addMinutes(30).hour(),
                Datetime.now().addMinutes(30).minute(),
                0,
                0
            )
        );

        Test.startTest();
        insert wh;
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, State
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE '%(English)%'
        ];

        System.assertEquals(1, jobs.size());
        System.assertEquals('WAITING', jobs[0].State);
    }

    @IsTest
    static void testScheduleTomorrowWhenTimePassed() {

        Work_Hour__c wh = new Work_Hour__c(
            Language__c = 'Japanese',
            Start_Time__c = Time.newInstance(12, 0, 0, 0),
            End_Time__c = Time.newInstance(1, 0, 0, 0) // already passed
        );

        Test.startTest();
        insert wh;
        Test.stopTest();

        CronTrigger job = [
            SELECT NextFireTime, State
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE '%(Japanese)%'
            LIMIT 1
        ];

        System.assertEquals('WAITING', job.State);
        System.assertEquals(
            Date.today().addDays(1),
            job.NextFireTime.date()
        );
    }

    @IsTest
    static void testUpdateReschedulesJob() {

        Work_Hour__c wh = new Work_Hour__c(
            Language__c = 'Chinese',
            Start_Time__c = Time.newInstance(12, 0, 0, 0),
            End_Time__c = Time.newInstance(23, 0, 0, 0)
        );
        insert wh;

        wh.End_Time__c = Time.newInstance(22, 0, 0, 0);

        Test.startTest();
        update wh;
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, State
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE '%(Chinese)%'
        ];

        System.assertEquals(1, jobs.size());
        System.assertEquals('WAITING', jobs[0].State);
    }
}