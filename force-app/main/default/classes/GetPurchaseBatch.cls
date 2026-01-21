// Batch size = 1
global class GetPurchaseBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global List<Id> usedCaseIds = new List<Id>();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Id groupBookingId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        if (Test.isRunningTest()) {
            return Database.getQueryLocator([SELECT Id FROM Case WHERE Status = 'Ticket Issued' AND RecordTypeId = :groupBookingId]);
        } else {
            return Database.getQueryLocator([SELECT Id FROM Case WHERE Last_Payment_Date__c = YESTERDAY AND Status = 'Ticket Issued' AND RecordTypeId = :groupBookingId]);
        }
    }

    // Only one Case per batch
    global void execute(Database.BatchableContext bc, List<Case> scope) {
        Set<Id> caseIds = new Set<Id>();
        
        for (Case c : scope) {
            caseIds.add(c.Id);
        }
        if (caseIds.size() != 0) GetPurchaseInvocableMethod.getPurchase(new List<Id>(caseIds));
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch finished.');
    }
}