global class GetPurchaseBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new GetPurchaseBatch(), 1);
    }
}