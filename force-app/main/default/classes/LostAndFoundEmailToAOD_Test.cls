@isTest
public class LostAndFoundEmailToAOD_Test {
 @isTest static void createTestRecord(){
    Case newCase = new Case(
        Origin = 'Web Form',
        RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Enquiry_and_Request'].id,
        SuppliedEmail = '123@123.com',
        SuppliedPhone = '886',
        Passenger_Name__c = 'ABC',
        Flight_Date__c = Date.today(),
        Flight_Number__c = 'JX800',
        Departure_Location__c = 'Taiwan',
        Ticket_EMD_Number__c = '189-1234567890',
        Booking_Reference_PNR__c = '6F5E5Q',
        Case_Sub_type__c = 'COSMILE',
        Case_Sub_type_Details__c = 'Personal Information Change',
        Agents_Conclusion__c = '123',
        Description = 'QWEASD');
        Insert newCase;
        List<Case> caseRecord = new List<Case>();
        caseRecord.add(newCase);
        
        Test.startTest();
        // Call the invocable method
        LostAndFoundEmailToAOD.SendAnEmail(new List<Case>{newCase});
        Test.stopTest();
        }
}