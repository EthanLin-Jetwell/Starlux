public without sharing class WebFormController {
	
    @AuraEnabled
    public static String getEnquiryRecordTypeId() {
        String EnquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enquiry_and_Request').getRecordTypeId();
        return EnquiryRecordTypeId;
        
    }
    
    @AuraEnabled
    public static String getFeedbackRecordTypeId() {
        String FeedbackRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Feedback').getRecordTypeId();
        return FeedbackRecordTypeId;
        
    }
    
    @AuraEnabled
    public static String getRefundRecordTypeId() {
        String RefundRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Reservation_and_Ticketing').getRecordTypeId();
        return RefundRecordTypeId;
        
    }
}