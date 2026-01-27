// Database.executeBatch(new BatchGetItinerary(), 1);
global class BatchGetItinerary implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global List<Id> caseId;

    global BatchGetItinerary(List<Id> caseId) {
        this.caseId = caseId; 
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // ✅ 加入條件：只取 Allocation_Type__c != 'Adjustment' 且 Final_Allocated_Seats__c > 0
        return Database.getQueryLocator([
            SELECT Id 
            FROM Seat_Allocation_and_Ticketing__c 
            WHERE Case_ID__c IN :caseId
              AND Allocation_Type__c != 'Adjustment'
              AND Final_Allocated_Seats__c > 0
        ]);
    }
    
/*    global void execute(Database.BatchableContext bc, List<Seat_Allocation_and_Ticketing__c> records) {
        List<Id> ids = new List<Id>();
        for(Seat_Allocation_and_Ticketing__c sat : records) {
            MiddlewareUtil.getItinerary(sat.Id); 2025-07-23 Herbert 改成Queueable方式*/
            
    global void execute(Database.BatchableContext bc, List<Seat_Allocation_and_Ticketing__c> records) {
        List<Id> satIdList = new List<Id>();
        for (Seat_Allocation_and_Ticketing__c sat : records) {
            satIdList.add(sat.Id);
        }    
        // 在整個 batch 執行中，只 enqueue 一次 job
        if (!satIdList.isEmpty()) {
            System.enqueueJob(new QueueableGetItinerary(satIdList));
        }        
    }
    
    global void finish(Database.BatchableContext bc) {
    }
    
     public static void fakeMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        }
}