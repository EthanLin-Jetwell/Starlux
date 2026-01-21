public class RetryJob implements Finalizer, Queueable {
    public void execute(QueueableContext ctx) {
        Finalizer finalizer = new RetryJob();                                      
        // instantiate the finalizer   
        System.attachFinalizer(finalizer); 
        // attach the finalizer to the current queueable job   
        // perform some operations here   
        // and then ...
        /*while (true) {
            
        }*/
    }

    public void execute(FinalizerContext ctx) {
        String parentJobId = '' + ctx.getAsyncApexJobId(); 
        // get Apex job Id    
        System.debug('Begin: executing finalizer attached to queueable job: ' + parentJobId);
        // if the job was not successful, re-enqueue the job that the finalizer is attached to
        if (ctx.getResult() == ParentJobResult.SUCCESS) {        
            System.debug('Parent queueable job ' + parentJobId + ' completed successfully.');    
        } else {        
            System.debug('Parent queueable job [' + parentJobId + '] failed due to: ' + ctx.getException().getMessage());
            String newJobId = '' + System.enqueueJob(new RetryJob()); // retry fails after 5 times when it hits the chaining limit    
        }  
    }
}