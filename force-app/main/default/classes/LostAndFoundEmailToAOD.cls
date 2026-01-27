public class LostAndFoundEmailToAOD {
    @InvocableMethod(label='Send Lost and Found Email to AOD')
    public static void SendAnEmail(List <Case> caseList) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Case currCase = caseList.get(0);
        
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        List<EmailMessage> mailList = [SELECT Id FROM EmailMessage WHERE RelatedToId =: currCase.id];
		List<Id> emailAndCaseId = new List<Id>();
        List<Id> mailListId = new List<Id>();                
        for (EmailMessage eM : mailList){
            emailAndCaseId.add(eM.Id);
            mailListId.add(eM.Id);}      
      
        List<Attachment> inEmailAttachment = [SELECT Id FROM Attachment WHERE ParentId =: mailListId];
        List<Id> inEmailAttachmentId = new List<Id>();
        for (Attachment a: inEmailAttachment){
            inEmailAttachmentId.add(a.Id);}
       
        emailAndCaseId.add(currCase.Id);
        
        
        List<ContentDocumentLink> cDL = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: emailAndCaseId];
    	List<Id> contentDocumentId = new List<Id>();
        for (ContentDocumentLink cD :cDL){
            contentDocumentId.add(cD.ContentDocumentId);}
        

        
        if (contentDocumentId!= null) {
            List <ContentVersion> cV = [SELECT Id, ContentDocumentId, Islatest, Title, FileType, VersionData, PathOnClient FROM ContentVersion WHERE ContentDocumentId =:contentDocumentId and Islatest = true];

            for (ContentVersion eachcV:cV){
				Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                efa.setFileName(eachcV.PathOnClient);
                efa.setBody(eachcV.VersionData);
                fileAttachments.add(efa);}
            mail.setFileAttachments(fileAttachments);}
           

        
        String emailContentBody = 'Hello team, \n \n' + 'This is a lost and found case from Salesforce. Case Number is: ' + currCase.CaseNumber + '.' + '\n' + 'Belows are case information' + '\n' + '\n';
        String emailAddress = 'Email Address: ' + currCase.SuppliedEmail + '\n';
        String phone = 'Phone: ' + currCase.SuppliedPhone + '\n';
        String description = 'Description: ' + '\n' + '----------------------' + '\n' + currCase.Description + '\n' + '----------------------';
        String passengerName = 'Passenger Name: ' + currCase.Passenger_Name__c + '\n';
        String flightDate = 'Flight Date: ' + currCase.Flight_Date__c;
        String flightNumber = 'Flight Number: ' + currCase.Flight_Number__c + '\n';
        String departureLocation = 'Departure Location: '+currCase.Departure_Location__c + '\n';
        String ticketEMDNumber = 'Ticket/EMD Number: '+currCase.Ticket_EMD_Number__c + '\n';
        String pNR = 'PNR: '+currCase.Booking_Reference_PNR__c + '\n';
        String mailSubject = 'LNF case (SF case no. '  + currCase.CaseNumber + ')';
        
        
        Boolean isSandboxOrg = [Select IsSandbox from Organization limit 1].IsSandbox;
        List<String> lostNFoundEmail = new List<String>();
        if(isSandboxOrg){
            lostNFoundEmail.add('svs@starlux-airlines.com');
        	OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply_test@cs.starlux-airlines.com'];
        	If (owea.size() >0) {mail.setOrgWideEmailAddressId(owea.get(0).Id);}
        } //測試區Lost and Found Email Address: svs@starlux-airlines.com
                
        else {
            lostNFoundEmail.add('JXLNF@starlux-airlines.com');
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@cs.starlux-airlines.com'];
        	If (owea.size() >0) {mail.setOrgWideEmailAddressId(owea.get(0).Id);}
        
        } //正式區Lost and Found Email Address: JXLNF@starlux-airlines.com
        

        mail.setToAddresses(lostNFoundEmail);
        mail.setSubject(mailSubject);
	    mail.setEntityAttachments(inEmailAttachmentId);
        mail.setPlainTextBody(emailContentBody + emailAddress + phone + passengerName + flightDate.left(23) + '\n' + flightNumber + departureLocation + ticketEMDNumber + pNR + description);
		//使用Email Template
        //EmailTemplate template = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE Name =''];
        //mail.setTemplateId(template.Id);
        //mail.setHtmlBody(template.HtmlValue);
        //mail.setTreatBodiesAsTemplate(true);
        //mail.setWhatId(currCase.Id);
        //mail.setTargetObjectId(currCase.id);
        //mail.setHtmlBody(template.HtmlValue);
        //mail.setTreatBodiesAsTemplate(true);
        //mail.setWhatId(currCase.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{Mail});

        
    }


}