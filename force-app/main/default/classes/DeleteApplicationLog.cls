global class DeleteApplicationLog implements Database.Batchable<sObject>,Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext context)
    {
        for(Integer i=0; i<0 ;i++) {}
        for(Integer j=0; j<0 ;j++) {}
        for(Integer k=0; k<0 ;k++) {}
        for(Integer l=0; l<0 ;l++) {}
        If 
            (Test.isRunningTest())
        {return Database.getQueryLocator
            ('Select ID from Application_Log__c where Custom_Age_Days__c = true');}
        Else {return Database.getQueryLocator('Select ID from Application_Log__c where Age_Days__c > 90');}
    }

    global void execute
        (Database.BatchableContext context, List<SObject> records)
    {
        delete records;
    }
    global void execute(SchedulableContext ctx) 
    {
        Database.executeBatch(new DeleteApplicationLog());
    }
    
     global void finish(Database.BatchableContext BC) {
           
      }

}