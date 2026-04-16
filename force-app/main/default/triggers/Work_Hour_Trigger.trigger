trigger Work_Hour_Trigger on Work_Hour__c (before insert, before update) {
    for(Work_Hour__c workHour : trigger.new) {
        String language = workHour.Language__c;
        DateTime newScheduleTime = DateTime.newInstance(Date.today(), workHour.End_Time__c);
        List<CronTrigger> scheduledJobs = [SELECT Id, CronJobDetail.Name, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE : '%' + language + '%' ORDER BY NextFireTime];
        System.debug(scheduledJobs);
        for(CronTrigger scheduleJob : scheduledJobs) {
            System.abortJob(scheduleJob.Id);
        }
        
        Time endTime = workHour.End_Time__c;
        String dailyCron =
            endTime.second() + ' ' +
            endTime.minute() + ' ' +
            endTime.hour() + ' * * ?';
        
        // Schedule DAILY job
        System.schedule(
            'Schedule EndCalls (' + language + ') - ' + newScheduleTime.format('yyyyMMdd HHmmss'),
            dailyCron,
            new Schedule_SendBusinessHoursMessage(language)
        );
    }
}