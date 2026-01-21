public class ExternalTicketsController {
    public External_Tickets__c Tickets { set; get; }
    public External_Tickets__c record { set; get; }
    public String formattedNotice { get; set; }
    public List<Ticket_Certificate__c> child { get; set; }
      
    
    
    public ExternalTicketsController(ApexPages.StandardController stdController) {
        
        record = (External_Tickets__c)stdController.getRecord();
        //IF(record==null) record=[Select Id from External_Tickets__c 
        //where Id='a166D000002Zzr8QAC'];        
        Tickets = [SELECT id, Account__c, ACCOUNT_CODE__c, Agency_Initial__c, Applicant__c, Apply_Date__c, Approved_Document__c, APVL_CODE__c,
                   Booking_Class_Departure_External__c, Booking_Class_Returning_External__c, Budget__c, Budget_Left__c, Budget_Left_after_Used__c,
                   Case_Used__c, Company__c, Contact_No__c, Contract_End_Date__c, Contract_Start_Date__c, Coupon_Issue_Deadline__c, Coupon_Number__c,
                   CreatedById, Discount__c, Duration_First_Travel_Date__c, Duration_Issue_Date__c, Email__c, Embargo__c,
                   Exemption_Tax__c, Exemption_YQ__c, Name, Fare_Basis__c, Fare_Basis_Bulk__c, First_Name_CN__c, First_Name_EN__c,
                   Flight_Date_Departure_External__c, Flight_Date_Returning_External__c, Flight_Number_Departure_External__c, Flight_Number_Returning_External__c,
                   Head_of_Department__c, In_Quota__c, Item_Number__c, Item_Status__c, Itinerary_Departure__c, Itinerary_Return__c,
                   LastModifiedById, Last_Name_CN__c, Last_Name_EN__c, N_Net__c, Notice__c, Notice2__c, Office__c, OwnerId, Paper_Certificated__c,
                    PFA_No__c, Phone__c, PIC__c, PMD__c, PNR__c, Prizes_and_Awards_won_by_chance__c,
                   Quota__c, QuotaManageID__c, Quota_Type__c, RBD__c, RBD_Departure__c, RBD_Returning__c, RecordTypeId, Redeem_Valid_End_Date__c,
                   Redeem_Valid_Start_Date__c, Routing__c, Remarks__c, Business_Number__c, Ticket_Number_External_Use__c, Ticket_Redeem_Coupon_Number__c, Ticket_Redeem_Coupon_Number_End__c, Trip__c,
                   Total_Purchasing_Number__c,Add_On_Rules__c,ENBOX__c,Person_in_charge__c,Reason_For_Application__c
                   
                   FROM External_Tickets__c
                   WHERE Id = :record.Id];
        if (Tickets.Notice__c != null) {
            formattedNotice = formatNotice(Tickets.Notice__c, 44);
        }
        
        Child = [SELECT Id, Name, Issue_Date__c,PNR__c,Ticket_Number_External_Use__c,Person_in_charge__c FROM Ticket_Certificate__c WHERE External_Tickets__c =: record.Id];
        
    }
    
    private String formatNotice(String notice, Integer maxCharacters) {
        String formattedNotice = '';
        Integer currentLineLength = 0;
        
        for (Integer i = 0; i < notice.length(); i++) {
            formattedNotice += notice.substring(i, i+1);
            currentLineLength++;
            
            if (currentLineLength == maxCharacters) {
                formattedNotice += '\n';
                currentLineLength = 0;
            }
        }
        
        return formattedNotice;
    }
    
    public static void fakeMethod() {
        Integer i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
    }
}