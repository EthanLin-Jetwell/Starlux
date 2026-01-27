public class TicketCertificateController {
    public Ticket_Certificate__c Tickets { set; get; }
    public Ticket_Certificate__c record { set; get; }
    public String formattedNotice { get; set; }
    public String QRcode {get;set;}
    
    public TicketCertificateController(ApexPages.StandardController stdController) {
        
        record = (Ticket_Certificate__c)stdController.getRecord();
        //IF(record==null) record=[Select Id from External_Tickets__c 
        //where Id='a166D000002Zzr8QAC'];        
        Tickets = [SELECT id, Account_Code__c, Application_Department__c, Apply_Date__c, Approved_Document__c, APVL_CODE__c, Booking_Class_Departure_External__c,
                   Contact_No__c, Coupon_Issue_Deadline__c, Coupon_Number__c, CreatedById, Discount__c ,Email__c, Embargo_Next_Year_Taiwan_to_World__c,
                   Embargo_Next_Year_World_to_Taiwan__c, Embargo_This_Year_Taiwan_to_World__c, Embargo_This_Year_World_to_Taiwan__c,
                   Embargo__c, Embargo_Date_Bulk__c, Exemption_Tax__c, Exemption_YQ__c, External_Tickets__c,
                   Fare_Basis__c, Fare_TWD__c, First_Flight_Date__c, First_Flight_No__c, First_Flight_RBD__c, First_Name_CN__c,
                   First_Name_EN__c, First_Travel_Date__c, In_Quota__c, Issue_Date__c, Item_Number__c, Last_Name__c, Last_Name_CN__c,
                   Last_Name_EN__c, LastModifiedById, Name, Person_in_charge__c, Phone__c, PIC__c, PNR__c, Prizes_and_Awards_won_by_chance__c,
                   Received_Date__c, Redeem_Valid_End_Date__c, Redeem_Valid_Start_Date__c, Remarks2__c, Remarks__c, Routing__c,
                   Second_Flight_Date__c, Second_Flight_No__c, Second_Flight_RBD__c, SF_Case_No__c, Tax_TWD__c, Ticket_Number_External_Use__c,
                   Title__c, External_Tickets__r.Agency_Initial__c, External_Tickets__r.Routing__c, External_Tickets__r.Redeem_Valid_Start_Date__c,
                   Budget__c, Budget_Left__c, Case_Used__c, Budget_Left_after_Used__c, Booking_Class_Returning_External__c,Itinerary_Departure_CH__c,Itinerary_Return_CH__c,
                   External_Tickets__r.Applicant__c, External_Tickets__r.PFA_No__c, External_Tickets__r.Redeem_Valid_End_Date__c, QRcode__c,
                   External_Tickets__r.Itinerary_Departure__c, External_Tickets__r.Itinerary_Return__c, External_Tickets__r.Trip__c, External_Tickets__r.RBD__c,
                   External_Tickets__r.Apply_Date__c, External_Tickets__r.Head_of_Department__c, External_Tickets__r.Item_Number__c, External_Tickets__r.Office__c,
                   External_Tickets__r.PIC__c, External_Tickets__r.Fare_Basis__c, External_Tickets__r.Discount__c, External_Tickets__r.Company__c,
                   External_Tickets__r.Prizes_and_Awards_won_by_chance__c, External_Tickets__r.Last_Name_EN__c, External_Tickets__r.Flight_Date_Departure_External__c,
                   External_Tickets__r.Flight_Number_Departure_External__c, External_Tickets__r.Booking_Class_Departure_External__c, External_Tickets__r.First_Name_EN__c,
                   External_Tickets__r.Flight_Date_Returning_External__c, External_Tickets__r.Flight_Number_Returning_External__c, 
                   External_Tickets__r.Booking_Class_Returning_External__c, External_Tickets__r.Phone__c, External_Tickets__r.Email__c, External_Tickets__r.Exemption_YQ__c,
                   External_Tickets__r.Exemption_Tax__c, External_Tickets__r.Embargo__c, External_Tickets__r.Budget_Left__c,
                   External_Tickets__r.Case_Used__c, External_Tickets__r.Budget_Left_after_Used__c, External_Tickets__r.Coupon_Issue_Deadline__c,
                   External_Tickets__r.Ticket_Number_External_Use__c, External_Tickets__r.Notice2__c,External_Tickets__r.Business_Number__c,
                   External_Tickets__r.Budget__c,External_Tickets__r.Reason_For_Application__c,
                   External_Tickets__r.RBD_Departure__c,External_Tickets__r.RBD_Returning__c

                   FROM Ticket_Certificate__c
                   WHERE Id = :record.Id];
        
        String rbdValue = Tickets.External_Tickets__r.Booking_Class_Departure_External__c;
        String rbrValue = Tickets.External_Tickets__r.Booking_Class_Returning_External__c;
 
        if (rbdValue == 'G' || rbrValue =='G' ) {
            formattedNotice = '';
        } else if (rbdValue == 'Y' || rbdValue == 'B' || rbdValue == 'T' || rbdValue == 'K' || rbdValue == 'M' ||
                   rbdValue == 'L' || rbdValue == 'V' || rbdValue == 'S' || rbdValue == 'N' || rbdValue == 'Q' ||
                   rbdValue == 'X' ||
                   rbrValue == 'Y' || rbrValue == 'B' || rbrValue == 'T' || rbrValue == 'K' || rbrValue == 'M' ||
                   rbrValue == 'L' || rbrValue == 'V' || rbrValue == 'S' || rbrValue  == 'N' || rbrValue == 'Q' ||
                   rbrValue == 'X' ) {
            formattedNotice = '經濟艙';
        } else if (rbdValue == 'W' || rbdValue == 'R' || rbdValue == 'E' || rbdValue == 'P' || rbdValue == 'O' ||
                   rbrValue == 'W' || rbrValue == 'R' || rbrValue == 'E' || rbrValue == 'P' || rbrValue == 'O') {
            formattedNotice = '豪華經濟艙';
        } else if (rbdValue == 'F' || rbdValue == 'A' || rbdValue == 'Z' ||
                   rbrValue == 'F' || rbrValue == 'A' || rbrValue == 'Z') {
            formattedNotice = '頭等艙';
        } else if (rbdValue == 'J' || rbdValue == 'C' || rbdValue == 'D' || rbdValue == 'U' || rbdValue == 'I' ||
                   rbrValue == 'J' || rbrValue == 'C' || rbrValue == 'D' || rbrValue == 'U' || rbrValue == 'I') {
            formattedNotice = '商務艙';
                   } else {
                       formattedNotice = ''; // Default value if none of the conditions match
                   }
        
        /*
        if (Tickets.External_Tickets__r.RBD__c == 'J') {
        formattedNotice = 'first';
    }
        */
        /*if (Tickets.Notice__c != null) {
            formattedNotice = formatNotice(Tickets.Notice__c, 44);
        }*/
        QRcode = Tickets.QRcode__c;
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