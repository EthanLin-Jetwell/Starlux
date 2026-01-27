trigger AirportOperationTrigger on Airport_Operation__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new AirportOperationTriggerHandler().run();
}