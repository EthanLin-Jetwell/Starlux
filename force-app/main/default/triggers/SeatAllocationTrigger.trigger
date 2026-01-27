trigger SeatAllocationTrigger on Seat_Allocation_and_Ticketing__c (before insert, after insert, after update) {
    new SeatAllocationTriggerHandler().run();
}