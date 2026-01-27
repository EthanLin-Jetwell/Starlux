public class CaseControllerExt {
    private final Case acase;
    public Blob afile {get; set;}
    public String contentType {get; set;}
    public String fileName {get; set;}
    public CaseControllerExt(ApexPages.StandardController stdController){
        this.acase=(Case)stdController.getRecord();
        acase.Status = 'Open';
        acase.Origin = 'WebFrom';
        //Asign Case Record type
        String FeedbackRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Feedback').getRecordTypeId();
        acase.RecordTypeId = FeedbackRecordTypeId;
    }
    public PageReference createCaseWithAttachment() {
        try{
            insert(acase);
        }catch(System.DMLException e){
            ApexPages.addMessages(e);
        }
        if(afile!=null){
            Attachment attach=new Attachment();
            attach.Body=afile;
            attach.Name=filename;
            attach.ContentType=contentType;
            attach.ParentID=acase.id;
            try {
                insert(attach);
            } catch(System.DMLException e) {
                ApexPages.addMessages(e);
                return null;
            }
        }
        PageReference p = Page.testpage;
        p.setRedirect(true);
        return p;                    
    }        
}