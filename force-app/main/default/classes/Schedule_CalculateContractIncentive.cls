global class Schedule_CalculateContractIncentive implements Schedulable {
    global void execute(SchedulableContext sc) {
        // 這裡可以設定你要的 batch size，例如 200
        Integer batchSize = 1;
        Batch_CalculateContractIncentive batch = new Batch_CalculateContractIncentive();
        Database.executeBatch(batch, batchSize);
    }
}