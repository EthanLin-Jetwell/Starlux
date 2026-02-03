@IsTest
public class CalculateContractIncentive_Test {
	@IsTest
    static void testScheduleExecution() {
        // Create the schedulable instance
        Schedule_CalculateContractIncentive schedulableJob =
            new Schedule_CalculateContractIncentive();

        // Cron expression: run once in the future
        String cronExp = '0 0 0 1 1 ? 2099';

        Test.startTest();
        // Schedule the job
        System.schedule(
            'Test Contract Incentive Scheduler',
            cronExp,
            schedulableJob
        );
        Test.stopTest();

        // Verify the job was scheduled
        List<CronTrigger> triggers = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Test Contract Incentive Scheduler'
        ];

        System.assertEquals(1, triggers.size(), 'Scheduler should be created');
        System.assertEquals('WAITING', triggers[0].State);
    }
    
    @IsTest
    static void testBatchExecution() {

        // --- Record Types ---
        Id contractRT = Schema.SObjectType.CGD_Contract__c
            .getRecordTypeInfosByDeveloperName()
            .get('Global_Region_Incentive')
            .getRecordTypeId();

        Id subContractRT = Schema.SObjectType.CGD_Sub_Contract__c
            .getRecordTypeInfosByDeveloperName()
            .get('Sub_Contract_Incentive')
            .getRecordTypeId();

        // --- Account ---
        Account mainAcc = new Account(
            Name = 'Main Account',
            CGD_Account_For__c = 'Customer Account'
        );
        insert mainAcc;

        // --- Contract ---
        CGD_Contract__c contract = new CGD_Contract__c(
            Name = 'Test Contract',
            RecordTypeId = contractRT,
            Account_Code__c = mainAcc.Id
        );
        insert contract;

        // --- Sub Contract ---
        CGD_Sub_Contract__c sub = new CGD_Sub_Contract__c(
            Name = 'Test Sub Contract',
            Contract__c = contract.Id,
            RecordTypeId = subContractRT,
            Incentive_Origin_Airport__c = 'TPE',
            Incentive_Destination_Airport__c = 'NRT',
            Target_Year__c = '2025',
            Target_Month__c = '1',
            All_in_Rate__c = true
        );
        insert sub;

        // --- Join Account ---
        Account acc = new Account(
            Name = 'Join Account'
        );
        insert acc;

        CGD_Join_Account__c joinAcc = new CGD_Join_Account__c(
            Contract__c = contract.Id,
            Account_Code__c = acc.Id
        );
        insert joinAcc;

        Test.startTest();
        // Execute batch (size = 1 as in your scheduler)
        Database.executeBatch(new Batch_CalculateContractIncentive(), 1);
        Test.stopTest();

        // --- Assert batch ran ---
        List<AsyncApexJob> batchJobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
        ];
        System.assert(!batchJobs.isEmpty(), 'Batch job should exist');

        // --- Assert queueable was enqueued ---
        List<AsyncApexJob> queueJobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
        ];
        System.assert(!queueJobs.isEmpty(), 'Queueable job should be enqueued');
    }
}