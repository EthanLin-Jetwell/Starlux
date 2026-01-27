/*******************************************************************
Description: This class is used to calculate Contract Incentive.
Database.executeBatch(new Batch_CalculateContractIncentive(), 1);
*******************************************************************/
global class Batch_CalculateContractIncentive extends BatchMaster implements Database.Batchable < sObject > , Database.Stateful {
    global String query;
    public Id contractRecordTypeId = Schema.SObjectType.CGD_Contract__c.getRecordTypeInfosByDeveloperName().get('Global_Region_Incentive').getRecordTypeId();
    public Id subRecordTypeId = Schema.SObjectType.CGD_Sub_Contract__c.getRecordTypeInfosByDeveloperName().get('Sub_Contract_Incentive').getRecordTypeId();
    
    global Batch_CalculateContractIncentive() {
        this.query = 'SELECT Id, Account_Code__r.Name, ' +
            '(SELECT Id, Incentive_Origin_Airport__c, Incentive_Destination_Airport__c, Target_Year__c, Target_Month__c ' +
            'FROM Sub_Contracts__r WHERE RecordTypeId = :subRecordTypeId), ' +
            '(SELECT Id, Account_Code__r.Name ' +
            'FROM Join_Accounts__r) ' +
            'FROM CGD_Contract__c ' +
            'WHERE Id IN (SELECT Contract__c FROM CGD_Sub_Contract__c WHERE RecordTypeId = :subRecordTypeId) AND RecordTypeId = :contractRecordTypeId';
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List <CGD_Contract__c> records) {
        for (CGD_Contract__c contract : records) {
            List<CGD_Sub_Contract__c> subs = contract.Sub_Contracts__r;
            List<CGD_Join_Account__c> joins = contract.Join_Accounts__r;
            
            if (subs == null || joins == null) continue;
            
            List<String> joinNames = new List<String>();
            if (contract.Account_Code__r.Name != null) joinNames.add(contract.Account_Code__r.Name);
            
            for (CGD_Join_Account__c joinAcc : joins) {
                if (joinAcc.Account_Code__r != null) joinNames.add(joinAcc.Account_Code__r.Name);
            }

            System.enqueueJob(new Queue_CalculateContractIncentive(subs, joinNames));
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
    
 
}