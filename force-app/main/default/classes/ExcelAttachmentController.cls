public class ExcelAttachmentController {
    public AgencyReport__c obj {get;set;}
    private ApexPages.StandardController std;
    public List<String> toAddresses;
    public String body;
    
    public ExcelAttachmentController(ApexPages.StandardController controller){
        std = controller;
        obj = (AgencyReport__c)std.getRecord();
        obj.id = ApexPages.currentPage().getParameters().get('Id');
    }
    
    Public PageReference redirectToMain(){
        // Do lots of interesting stuff  // code to send an email to user
        List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
        getExport(obj);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        Attachment attch = [SELECT id, Body,Name
                            FROM Attachment
                            WHERE ParentId=: obj.id
                            LIMIT 1];
        if(attch !=null){
            efa.setFileName(attch.Name);
            efa.setBody(attch.Body);
            attachmentList.add(efa);
            email.setFileAttachments(attachmentList);
        }
        
        toAddresses = new String[] {'ethan1688.lin@gmail.com'};
            
            email.setToAddresses(toAddresses);
        email.setSubject('Account information Requested');
        email.setPlainTextBody('Information detail present in the attachment');
        Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        PageReference nextPage = new PageReference('/' + obj.Id);
        return nextPage;
    }
    
    public void getExport(AgencyReport__c obj){
        Blob excelData;
        PageReference generateExl = Page.AgencyReport_Excel;
        generateExl.getParameters().put('Id', obj.Id);
        excelData = generateExl.getContent();
        Attachment attach = new Attachment();
        attach.ParentId = obj.Id;
        attach.Name = 'Account Information'+'.xls';
        attach.body=excelData;
        system.debug(obj.Id);
        system.debug(attach.ParentId);
        Insert attach;
    }
}