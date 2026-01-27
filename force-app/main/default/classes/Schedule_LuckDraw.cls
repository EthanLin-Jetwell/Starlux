global class Schedule_LuckDraw implements Schedulable{
    public Id recordId {get; set;}
    
    global Schedule_LuckDraw(Id recordId) {
        this.recordId = recordId;
    }
    
	global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_LuckyDraw(recordId, 'assign'));
    }
}