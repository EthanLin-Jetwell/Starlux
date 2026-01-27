public class SeatSalesTrackingTriggerHandler extends TriggerHandler{
	public SeatSalesTrackingTriggerHandler() {
    }
    
    /*** Context Overrides ***/
    public override void beforeInsert() {
        copyContactEmails();
    }
    
    private static void copyContactEmails() {
        //Master list of Case IDs and Contact IDs
        List<String> allCases = new List<String>();
        List<String> allContacts = new List<String>();
        Map<String, String> caseContactMap = new Map<String, String>();
        Map<String, List<String>> contactMap = new Map<String, List<String>>();
        
        //Iterate through all newly inserted Seat Sales Tracking records to add Case ID to master list of Case IDs
        for (Seat_Sales_Tracking__c seatSales : (List<Seat_Sales_Tracking__c>) trigger.new) {
            if (Trigger.isInsert) {
                allCases.add(seatSales.Case_ID__c);
            }
        }
       	
        //Query for all cases in master list
        List<Case> caseList = [SELECT Id, ContactId FROM Case WHERE Id IN :allCases];
        
        //Iterate through all queried Seat Allocation records to add Contact ID to master list of Contact IDs
        for (Case c : caseList) {
        	allContacts.add(c.ContactId);
            caseContactMap.put(c.Id, c.ContactId);
        }
        
        //Query for 'Passenger' record type ID
        String PassengerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();
        
        //Query for all contacts in master list
        List<Contact> contactList = [SELECT Id, AccountId, Alternate_Email_1__c, Alternate_Email_2__c, Alternate_Email_3__c FROM Contact 
                                     WHERE AccountId IN (SELECT Id FROM Account WHERE RecordTypeId != :PassengerRecordTypeId)
                                     AND Id IN :allContacts];
        
        //Iterate through contactList to populate contactMap
        for (Contact con : contactList) {
            List<String> emailList = new List<String>();
            emailList.add(con.Alternate_Email_1__c);
            emailList.add(con.Alternate_Email_2__c);
            emailList.add(con.Alternate_Email_3__c);
            contactMap.put(con.Id, emailList);
        }
            	
        //Iterate through all queried Seat Allocation records to update Alternate Emails
        for (Seat_Sales_Tracking__c seatSales : (List<Seat_Sales_Tracking__c>) trigger.new) {
        	String key = seatSales.Case_ID__c;
        	String contactValue = caseContactMap.get(key);
            if (contactValue != null) {
                List<String> altEmails = contactMap.get(contactValue);
                seatSales.Travel_Agent_Alternate_Email_1__c = altEmails[0];
                seatSales.Travel_Agent_Alternate_Email_2__c = altEmails[1];
                seatSales.Travel_Agent_Alternate_Email_3__c = altEmails[2];
            }
        }
    }
}