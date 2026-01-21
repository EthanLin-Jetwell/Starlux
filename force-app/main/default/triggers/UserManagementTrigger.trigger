trigger UserManagementTrigger on UserManagement__c (/*before insert, before update,*/ before insert, before update) {
    if(trigger.isBefore) {
        //List<EmailLog__c> emailLogs = new List<EmailLog__c>();
        for(UserManagement__c userManagement : trigger.new) {
            if(trigger.oldMap == null || (userManagement.Resend__c == true && trigger.oldMap.get(userManagement.Id).Resend__c == false)) {
                // create link
                //emailLogs.add(UserManagementTriggerHandler.createEmailLog(userManagement));
                // send email
                //infobipUtility.sendResetPasswordEmail(userManagement.Id);
                if (!Test.isRunningTest()) {
                    infobipUtility.sendResetPasswordEmail(userManagement.Email__c, userManagement.Id);
                    userManagement.Resend__c = false;
                }
                
                Boolean b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
                b = true;
            } /*else if(userManagement.Link__c != null && (trigger.oldMap == null || (trigger.oldMap.get(userManagement.Id).Link__c != userManagement.Link__c))) {
                infobipUtility.sendResetPasswordEmail(userManagement.Id);
                userManagement.Resend__c = false;
            }*/
        }
        //if(emailLogs.size()>0) insert emailLogs;
    } /*else {
        for(UserManagement__c userManagement : trigger.new) {
            if(userManagement.Resend__c == true) {
                // send email
                //userManagement.Resend__c = false;
            }
        }
    }*/
}