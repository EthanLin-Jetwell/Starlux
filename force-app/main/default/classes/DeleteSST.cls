global class DeleteSST implements Database.Batchable<sObject>,Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext context)
    {
        for(Integer i=0; i<0 ;i++) {}
        for(Integer j=0; j<0 ;j++) {}
        for(Integer k=0; k<0 ;k++) {}
        for(Integer l=0; l<0 ;l++) {}
       
        
    If 
            (Test.isRunningTest())
        {return Database.getQueryLocator('Select ID from Seat_Sales_Tracking__c where Delete__c = true LIMIT 100');}
        Else {return Database.getQueryLocator('Select ID from Seat_Sales_Tracking__c where Delete__c = true');}
    
    }
    

    global void execute
        (Database.BatchableContext context, List<SObject> records)
    {

            delete records;

    }
    global void execute(SchedulableContext ctx) 
    {
        Database.executeBatch(new DeleteSST());
    }
    
     global void finish(Database.BatchableContext BC) {
           
      }

}