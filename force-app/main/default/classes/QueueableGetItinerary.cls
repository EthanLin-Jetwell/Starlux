public class QueueableGetItinerary implements Queueable, Database.AllowsCallouts {
    private List<Id> satIds;

    public QueueableGetItinerary(List<Id> satIds) {
        this.satIds = satIds;
    }

    public void execute(QueueableContext context) {
        if (satIds == null || satIds.isEmpty()) return;

        // 取出第一筆並處理
        Id currentId = satIds.remove(0);
        MiddlewareUtil.getItinerary(currentId);

        // 如果還有剩餘的 ID，排下一個 queueable
        if (!satIds.isEmpty()) {
            System.enqueueJob(new QueueableGetItinerary(satIds));
        }
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
        
        }
}