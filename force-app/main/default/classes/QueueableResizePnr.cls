public class QueueableResizePnr implements Queueable, Database.AllowsCallouts {
    private String newSatName;
    private String masterSatName;
    private String pnr;
    private Integer seats;
    private String caseNo;
    //private List<Seat_Allocation_and_Ticketing__c> updateList;

    public QueueableResizePnr(String newSatName, String masterSatName, String pnr, Integer seats, String caseNo) {
        this.newSatName = newSatName;
        this.masterSatName = masterSatName;
        this.pnr = pnr;
        this.seats = seats;
        this.caseNo = caseNo;
        
        /*newSat.Total_Seat_Sales__c = 0;
        
        if (originalSat.Final_Allocated_Seats__c < originalSat.Total_Seat_Sales__c) {
            newSat.Total_Seat_Sales__c = originalSat.Total_Seat_Sales__c - originalSat.Final_Allocated_Seats__c;
            originalSat.Total_Seat_Sales__c = originalSat.Final_Allocated_Seats__c;
        }
        
        this.updateList = new Seat_Allocation_and_Ticketing__c[]{newSat, originalSat};*/
    }

    public void execute(QueueableContext context) {
        MiddlewareUtil.resizePnr(newSatName, masterSatName, pnr, seats, caseNo);

        //update updateList;
    }
}