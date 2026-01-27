public class UserManagementTriggerHandler {
    public static EmailLog__c createEmailLog(UserManagement__c userManagement) {
        EmailLog__c emailLog = new EmailLog__c(Name='Email Log', User__c=userManagement.Id);
        return emailLog;
    }
}