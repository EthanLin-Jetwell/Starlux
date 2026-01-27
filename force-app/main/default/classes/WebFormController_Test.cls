@isTest
public class WebFormController_Test {
	
    public static testMethod void testRecordTypeIds() {
        //Assert for getEnquiryRecordTypeId()
        String enquiryRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Enquiry_and_Request').getRecordTypeId();
        String testRecordTypeId = WebFormController.getEnquiryRecordTypeId();
        system.assertEquals(enquiryRecordTypeId,testRecordTypeId);
        
        //Assert for getFeedbackRecordTypeId()
        String feedbackRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Feedback').getRecordTypeId();
        String testRecordTypeId1 = WebFormController.getFeedbackRecordTypeId();
        system.assertEquals(feedbackRecordTypeId,testRecordTypeId1);
        
        //Assert for getRefundRecordTypeId()
        String refundRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Reservation_and_Ticketing').getRecordTypeId();
        String testRecordTypeId2 = WebFormController.getRefundRecordTypeId();
        system.assertEquals(refundRecordTypeId,testRecordTypeId2);     
    }
}