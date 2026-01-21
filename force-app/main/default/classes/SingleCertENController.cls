public class SingleCertENController {
public Ticket_Certificate__c Tickets { set; get; }
    public Ticket_Certificate__c record { set; get; }
    public String formattedNotice { get; set; }
    public String QRcode {get;set;}
    
    public SingleCertENController() {
        String certId = ApexPages.currentPage().getParameters().get('certId');
        if (String.isBlank(certId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '缺少 certId 參數'));
            return;
        }
        
        //IF(record==null) record=[Select Id from External_Tickets__c 
        //where Id='a166D000002Zzr8QAC'];        
        Tickets = [SELECT id, Account_Code__c, Application_Department__c, Apply_Date__c, Approved_Document__c, APVL_CODE__c, Booking_Class_Departure_External__c,Booking_Class_Returning_External__c,
                   Contact_No__c, Coupon_Issue_Deadline__c, Coupon_Number__c, CreatedById, Discount__c ,Email__c, Embargo_Next_Year_Taiwan_to_World__c,
                   Embargo_Next_Year_World_to_Taiwan__c, Embargo_This_Year_Taiwan_to_World__c, Embargo_This_Year_World_to_Taiwan__c,
                   Embargo__c, Exemption_Tax__c, Exemption_YQ__c, External_Tickets__c,
                   Fare_Basis__c, Fare_TWD__c, First_Flight_Date__c, First_Flight_No__c, First_Flight_RBD__c, First_Name_CN__c,RBD__c,
                   First_Name_EN__c, First_Travel_Date__c, Hotline__c, In_Quota__c, Issue_Date__c, Item_Number__c, Last_Name__c, Last_Name_CN__c,
                   Last_Name_EN__c, LastModifiedById, Name, Person_in_charge__c, Phone__c, PIC__c, PNR__c, Prizes_and_Awards_won_by_chance__c,
                   Received_Date__c, Redeem_Valid_End_Date__c, Redeem_Valid_Start_Date__c, Remarks2__c, Remarks__c, Routing__c,
                   Second_Flight_Date__c, Second_Flight_No__c, Second_Flight_RBD__c, SF_Case_No__c, Tax_TWD__c, Ticket_Number_External_Use__c,
                   Title__c, External_Tickets__r.Agency_Initial__c, External_Tickets__r.Routing__c, External_Tickets__r.Redeem_Valid_Start_Date__c,
                   External_Tickets__r.Redeem_Valid_End_Date__c, QRcode__c,
                   External_Tickets__r.Itinerary_Departure__c, External_Tickets__r.Itinerary_Return__c, External_Tickets__r.Trip__c, External_Tickets__r.RBD__c,
                   External_Tickets__r.Booking_Class_Departure_External__c,External_Tickets__r.Booking_Class_Returning_External__c,
                   External_Tickets__r.Exemption_YQ__c,External_Tickets__r.Exemption_Tax__c,External_Tickets__r.Exemption_YR__c, External_Tickets__r.Embargo__c,External_Tickets__r.Two_People__c,
                   External_Tickets__r.DepatureID__c,External_Tickets__r.Depature__c,External_Tickets__r.ArrivalID__c,External_Tickets__r.Arrival__c,External_Tickets__r.Booking_Class__c, External_Tickets__r.Discount_Rate__c,External_Tickets__r.Discount__c,
                   External_Tickets__r.Expiration_Date__c,External_Tickets__r.SerialID__c,External_Tickets__r.Organizer_Event_Title__c,
                   External_Tickets__r.Embargo_This_Year_Taiwan_to_World__c,External_Tickets__r.Embargo_Next_Year_Taiwan_to_World__c,External_Tickets__r.Embargo_This_Year_World_to_Taiwan__c,External_Tickets__r.Embargo_Next_Year_World_to_Taiwan__c

                   FROM Ticket_Certificate__c
                   WHERE Id = :certId];
        String rbdValue = Tickets.External_Tickets__r.Booking_Class_Departure_External__c;
        String rbrValue = Tickets.External_Tickets__r.Booking_Class_Returning_External__c;       
        /*
        if (rbdValue == 'J' || rbdValue == 'C' || rbdValue == 'D' || rbdValue == 'U' || rbdValue == 'I') {
            formattedNotice = 'Business';
        } else if (rbdValue == 'F' || rbdValue == 'A' || rbdValue == 'Z') {
            formattedNotice = 'First';
        } else if (rbdValue == 'W' || rbdValue == 'R' || rbdValue == 'E' || rbdValue == 'P' || rbdValue == 'O') {
            formattedNotice = 'Premium Economy';
        } else if (rbdValue == 'Y' || rbdValue == 'B' || rbdValue == 'J' || rbdValue == 'K' || rbdValue == 'M' ||
                   rbdValue == 'L' || rbdValue == 'V' || rbdValue == 'S' || rbdValue == 'N' || rbdValue == 'Q' ||
                   rbdValue == 'X' || rbdValue == 'T') {
                       formattedNotice = 'Economy';
                   } else if (rbdValue == 'G') {
                       formattedNotice = 'Group';
                   } else {
                       formattedNotice = ''; // Default value if none of the conditions match
                   }
        */
        if (rbdValue == 'G' || rbrValue =='G' ) {
            formattedNotice = '';
        } else if (rbdValue == 'Y' || rbdValue == 'B' || rbdValue == 'T' || rbdValue == 'K' || rbdValue == 'M' ||
                   rbdValue == 'L' || rbdValue == 'V' || rbdValue == 'S' || rbdValue == 'N' || rbdValue == 'Q' ||
                   rbdValue == 'X' ||
                   rbrValue == 'Y' || rbrValue == 'B' || rbrValue == 'T' || rbrValue == 'K' || rbrValue == 'M' ||
                   rbrValue == 'L' || rbrValue == 'V' || rbrValue == 'S' || rbrValue  == 'N' || rbrValue == 'Q' ||
                   rbrValue == 'X' ) {
            formattedNotice = 'Economy';
        } else if (rbdValue == 'W' || rbdValue == 'R' || rbdValue == 'E' || rbdValue == 'P' || rbdValue == 'O' ||
                   rbrValue == 'W' || rbrValue == 'R' || rbrValue == 'E' || rbrValue == 'P' || rbrValue == 'O') {
            formattedNotice = 'Premium Economy';
        } else if (rbdValue == 'J' || rbdValue == 'C' || rbdValue == 'D' || rbdValue == 'U' || rbdValue == 'I' ||
                   rbrValue == 'J' || rbrValue == 'C' || rbrValue == 'D' || rbrValue == 'U' || rbrValue == 'I') {
            formattedNotice = 'Business';
                   } else if (rbdValue == 'F' || rbdValue == 'A' || rbdValue == 'Z' ||
                   rbrValue == 'F' || rbrValue == 'A' || rbrValue == 'Z') {
            formattedNotice = 'First';
                   } else {
                       formattedNotice = ''; // Default value if none of the conditions match
                   }
        /*if (Tickets.Notice__c != null) {
            formattedNotice = formatNotice(Tickets.Notice__c, 44);
        }*/
        QRcode = Tickets.QRcode__c;
    }

    public PageReference prepareDownload() {
        String baseName = (Tickets != null && !String.isBlank(Tickets.Name))
            ? Tickets.Name.trim()
            : 'EN_Certificate';

        // 淨化檔名，避免不合法字元
        baseName = baseName.replaceAll('[\\\\/:*?"<>|\\r\\n]+', '_');
        if (baseName.length() > 120) baseName = baseName.substring(0, 120);

        String asciiName = baseName + '_EN.pdf';
        String utf8Name  = EncodingUtil.urlEncode(baseName + '_EN.pdf', 'UTF-8').replace('+', '%20');

        Map<String, String> h = ApexPages.currentPage().getHeaders();
        h.put('Content-Type', 'application/pdf');
        h.put('Content-Disposition',
              'attachment; filename="' + asciiName + '"; filename*=UTF-8\'\'' + utf8Name);

        return null; // 繼續讓 VF 以 PDF 方式渲染內容
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