public class ErrorMessageController {
    public Account account {get; set;}
    
    public ErrorMessageController() {
        account = [SELECT Id, Name FROM Account LIMIT 1];
    }
    
    public PageReference save() {
        ApexPages.addMessage(
        new ApexPages.Message(ApexPages.Severity.ERROR, 'HI')
        );
        return null;
    }
}