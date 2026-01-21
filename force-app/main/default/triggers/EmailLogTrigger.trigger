trigger EmailLogTrigger on EmailLog__c (after insert) {
    /*List<UserManagement__c> userManagements = new List<UserManagement__c>();
    for(EmailLog__c emailLog : trigger.new) {
        userManagements.add(new UserManagement__c(Id=emailLog.User__c, Resend__c=false, Link__c='https://starlux--starluxtrn--c.sandbox.vf.force.com/apex/ResetPassword?emailLogId='+emailLog.Id));
    }
    if(userManagements.size()>0) update userManagements;*/
}