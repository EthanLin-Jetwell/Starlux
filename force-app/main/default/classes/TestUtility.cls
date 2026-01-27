/*********************************************************************************************************************************************************************************************************
Description: This is the Class created to manage the creation of test data from any other test class within the project
			 This class will need to be modified accordingly to remove or add methods to support creation and query 
			 of different objects as required
*********************************************************************************************************************************************************************************************************/
@isTest(SeeAllData = false)
public class TestUtility {
 //=============   Create function ===========
 // ==== Create sObjecr Record ====
 // createObject   : Single record
 // createObjects  : Multiple records
 // ==== Create sObject instance
 // getObject
 // getsObjects
 // ==== Retrieve sObject record
 // getSObjectRecord
 // getSObjectRecords
 // getRecordsWithCondition
 // ==== Create Test user
 // createTestUser
 // 
    public static sobject createsObject(String objName) {
        List<sObject> sobjs=  getSobjectsWithFieldPopulated(objName, null, 1);
        insert sobjs;
        return sobjs[0];
    } 
    public static sobject createsObject(String objName,Map < String, Object > FieldValueMap) {
        List<sObject> sobjs=  getSobjectsWithFieldPopulated(objName, FieldValueMap, 1);
        insert sobjs;
        return sobjs[0];
    } 
    public static List < Sobject > createsObjects(String objName,Integer noOfRecords) {
        List<sObject> sobjs=  getSobjectsWithFieldPopulated(objName, null, noOfRecords);
        insert sobjs;
        return sobjs;
    }    
    public static List < Sobject >  createsObjects(String objName,Map < String, Object > FieldValueMap, Integer noOfRecords) {
        List<sObject> sobjs=  getSobjectsWithFieldPopulated(objName, FieldValueMap, noOfRecords);
        insert sobjs;
        return sobjs;   
    }
    public static List < Sobject > getsObjects(String objName,Integer noOfRecords) {
        return  getSobjectsWithFieldPopulated(objName, null, noOfRecords);
    } 
    public static List < Sobject >  getsObjects(String objName,Map < String, Object > FieldValueMap, Integer noOfRecords) {
        return  getSobjectsWithFieldPopulated(objName, FieldValueMap, noOfRecords);
    }
    public static List < Sobject >  getRecordsWithCondition(String SObject_API_Name,String condition){
        return  getSObjectRecords(SObject_API_Name, null,condition,false);
    }   
    public static List < Sobject >  getRecordsWithCondition(String SObject_API_Name,String condition,List < String > sobjectFieldList){
        return  getSObjectRecords(SObject_API_Name, sobjectFieldList,condition,false);
    }    
    public static Sobject getSObjectRecord(String SObject_API_Name) 
    {
        List < Sobject > recs =  getSObjectRecords(SObject_API_Name, null,null,true);
        if(recs.size() > 0) return recs[0];
        else return null;
    }
    public static Sobject getSObjectRecord(String SObject_API_Name,String Id) 
    {
        List < Sobject > recs =  getSObjectRecords(SObject_API_Name, null,'Id = \'' + Id + '\' ',true);
        if(recs.size() > 0) return recs[0];
        else return null;
    }     
    public static Sobject getSObjectRecord(String SObject_API_Name,List < String > sobjectFieldList) 
    {
        List < Sobject > recs =  getSObjectRecords(SObject_API_Name, sobjectFieldList,null,true);
        if(recs.size() > 0) return recs[0];
        else return null;
    } 
    public static Sobject getSObjectRecord(String SObject_API_Name,String Id,List < String > sobjectFieldList) 
    {
        List < Sobject > recs =  getSObjectRecords(SObject_API_Name, sobjectFieldList,'Id = \'' + Id + '\' ',true);
        if(recs.size() > 0) return recs[0];
        else return null;
    } 
    
 //=========== Create function End   
           
 // 
 	public static void createSeat(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Seat_Sales_Tracking__c', FieldValueMap);
    }
    
    public static void createSeat() {
        insert getSobjectWithFieldPopulated('Seat_Sales_Tracking__c', null);
    }
    
    public static void createSeats(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Seat_Sales_Tracking__c', FieldValueMap, noOfRecords);
    }
    
    public static void createSeats(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Seat_Sales_Tracking__c', null, noOfRecords);
    }
    
	public static void createTax(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Tax_Details__c', FieldValueMap);
    }
    
    public static void createTax() {
        insert getSobjectWithFieldPopulated('Tax_Details__c', null);
    }
    
    public static void createTaxes(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Tax_Details__c', FieldValueMap, noOfRecords);
    }
    
    public static void createTaxes(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Tax_Details__c', null, noOfRecords);
    }
    
    public static void createTicketFare(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Ticket_Fare_Rule__c', FieldValueMap);
    }
    
    public static void createTicketFare() {
        insert getSobjectWithFieldPopulated('Ticket_Fare_Rule__c', null);
    }
    
    public static void createTicketFares(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Ticket_Fare_Rule__c', FieldValueMap, noOfRecords);
    }
    
    public static void createTicketFares(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Ticket_Fare_Rule__c', null, noOfRecords);
    }
    
    public static void createSeatAllocation(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Seat_Allocation_and_Ticketing__c', FieldValueMap);
    }
    
    public static void createSeatAllocation() {
        insert getSobjectWithFieldPopulated('Seat_Allocation_and_Ticketing__c', null);
    }
    
    public static void createSeatAllocations(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Seat_Allocation_and_Ticketing__c', FieldValueMap, noOfRecords);
    }
    
    public static void createSeatAllocations(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Seat_Allocation_and_Ticketing__c', null, noOfRecords);
    } 
    
    public static void createSeatAllocationByAgency(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Seat_Allocation_By_Agency__c', FieldValueMap);
    }
    
    public static void createSeatAllocationByAgency() {
        insert getSobjectWithFieldPopulated('Seat_Allocation_By_Agency__c', null);
    }
    
    public static void createSeatAllocationByAgencies(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Seat_Allocation_By_Agency__c', FieldValueMap, noOfRecords);
    }
    
    public static void createSeatAllocationByAgencies(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Seat_Allocation_By_Agency__c', null, noOfRecords);
    }
    
    public static void createAirportOperation(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Airport_Operation__c', FieldValueMap);
    }
    
    public static void createAirportOperation() {
        insert getSobjectWithFieldPopulated('Airport_Operation__c', null);
    }
    
    public static void createAirportOperations(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Airport_Operation__c', FieldValueMap, noOfRecords);
    }
    
    public static void createAirportOperations(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Airport_Operation__c', null, noOfRecords);
    }                                    
    
    public static void createChecklist(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Airport_Operation_Checklist__mdt', FieldValueMap);
    }
    
    public static void createChecklist() {
        insert getSobjectWithFieldPopulated('Airport_Operation_Checklist__mdt', null);
    }
    
    public static void createChecklists(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Airport_Operation_Checklist__mdt', FieldValueMap, noOfRecords);
    }
    
    public static void createChecklists(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Airport_Operation_Checklist__mdt', null, noOfRecords);
    }
    
    public static void createTranscript(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('LiveChatTranscript', FieldValueMap);
    }
    
    public static void createTranscript() {
        insert getSobjectWithFieldPopulated('LiveChatTranscript', null);
    }
    
    public static void createTranscripts(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('LiveChatTranscript', FieldValueMap, noOfRecords);
    }
    
    public static void createTranscripts(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('LiveChatTranscript', null, noOfRecords);
    }
    
    public static void createEmail(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('EmailMessage', FieldValueMap);
    }
    
    public static void createEmail() {
        insert getSobjectWithFieldPopulated('EmailMessage', null);
    }
    
    public static void createEmails(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('EmailMessage', FieldValueMap, noOfRecords);
    }
    
    public static void createEmails(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('EmailMessage', null, noOfRecords);
    }
    
    public static void createTask(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Task', FieldValueMap);
    }
    
    public static void createTask() {
        insert getSobjectWithFieldPopulated('Task', null);
    }
    
    public static void createTasks(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Task', FieldValueMap, noOfRecords);
    }
    
    public static void createTasks(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Task', null, noOfRecords);
    }
    
    public static void createContact(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Contact', FieldValueMap);
    }
    
    public static void createContact() {
        insert getSobjectWithFieldPopulated('Contact', null);
    }
    
    public static void createContacts(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Contact', FieldValueMap, noOfRecords);
    }
    
    public static void createContacts(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Contact', null, noOfRecords);
    }
    
    public static void createCase(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Case', FieldValueMap);
    }
    
    public static void createAccount(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Account', FieldValueMap);
    }
    
    public static void createCase() {
        insert getSobjectWithFieldPopulated('Case', null);
    }
    
    public static void createAccount() {
        insert getSobjectWithFieldPopulated('Account', null);
    }
    
    //START:ADDED//20180130//
    
    //END:ADDED//20180130//
    
    public static void createCases(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Case', FieldValueMap, noOfRecords);
    }
    
    public static void createApplicationLogs(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Application_Log__c', FieldValueMap, noOfRecords);
    }
    
    public static void createOutboundMessage(Map < String, Object > FieldValueMap) {
        insert getSobjectWithFieldPopulated('Outbound_Message__c', FieldValueMap);
    }

    public static void createAccounts(Map < String, Object > FieldValueMap, Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Account', FieldValueMap, noOfRecords);
    }
    
    public static void createCases(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Case', null, noOfRecords);
    }
    
    public static void createAccounts(Integer noOfRecords) {
        insert getSobjectsWithFieldPopulated('Account', null, noOfRecords);
    }
    
    public static Sobject getOutboundMessage() {
        return getSObjectWithRequiredFields('Outbound_Message__c', null, true)[0];
    }
    
    public static Sobject getCase() {
        return getSObjectWithRequiredFields('Case', null, true)[0];
    }

    public static Sobject getAccount() {
        return getSObjectWithRequiredFields('Account', null, true)[0];
    }

    //START:ADDED//20180130//
 	
    //END:ADDED//20180130//
    public static Sobject getSeat() {
        return getSObjectWithRequiredFields('Seat_Sales_Tracking__c', null, true)[0];
    }
    
    public static List < Sobject > getSeats() {
        return getSObjectWithRequiredFields('Seat_Sales_Tracking__c', null, false);
    }
    
    public static List < Sobject > getSeats(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Seat_Sales_Tracking__c', sobjectFieldList, false);
    }
    
    public static Sobject getSeat(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Seat_Sales_Tracking__c', sobjectFieldList, true)[0];
    }
    
    public static Sobject getTax() {
        return getSObjectWithRequiredFields('Tax_Details__c', null, true)[0];
    }
    
    public static List < Sobject > getTaxes() {
        return getSObjectWithRequiredFields('Tax_Details__c', null, false);
    }
    
    public static List < Sobject > getTaxes(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Tax_Details__c', sobjectFieldList, false);
    }
    
    public static Sobject getTax(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Tax_Details__c', sobjectFieldList, true)[0];
    }
    
    public static Sobject getTicketFare() {
        return getSObjectWithRequiredFields('Ticket_Fare_Rule__c', null, true)[0];
    }
    
    public static List < Sobject > getTicketFares() {
        return getSObjectWithRequiredFields('Ticket_Fare_Rule__c', null, false);
    }
    
    public static List < Sobject > getTicketFares(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Ticket_Fare_Rule__c', sobjectFieldList, false);
    }
    
    public static Sobject getTicketFare(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Ticket_Fare_Rule__c', sobjectFieldList, true)[0];
    }
    
    public static Sobject getChecklist() {
        return getSObjectWithRequiredFields('Airport_Operation_Checklist__mdt', null, true)[0];
    }
    
    public static List < Sobject > getChecklists() {
        return getSObjectWithRequiredFields('Airport_Operation_Checklist__mdt', null, false);
    }
    
    public static List < Sobject > getChecklists(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Airport_Operation_Checklist__mdt', sobjectFieldList, false);
    }
    
    public static Sobject getChecklist(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Airport_Operation_Checklist__mdt', sobjectFieldList, true)[0];
    }
    
    public static Sobject getSeatAllocation() {
        return getSObjectWithRequiredFields('Seat_Allocation_and_Ticketing__c', null, true)[0];
    }
    
    public static List < Sobject > getSeatAllocations() {
        return getSObjectWithRequiredFields('Seat_Allocation_and_Ticketing__c', null, false);
    }
    
    public static List < Sobject > getSeatAllocations(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Seat_Allocation_and_Ticketing__c', sobjectFieldList, false);
    }
    
    public static Sobject getSeatAllocation(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Seat_Allocation_and_Ticketing__c', sobjectFieldList, true)[0];
    }
    
    public static Sobject getAirportOperation() {
        return getSObjectWithRequiredFields('Airport_Operation__c', null, true)[0];
    }
    
    public static List < Sobject > getAirportOperations() {
        return getSObjectWithRequiredFields('Airport_Operation__c', null, false);
    }
    
    public static List < Sobject > getAirportOperations(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Airport_Operation__c', sobjectFieldList, false);
    }
    
    public static Sobject getAirportOperation(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Airport_Operation__c', sobjectFieldList, true)[0];
    }
    
    public static Sobject getTranscript() {
        return getSObjectWithRequiredFields('LiveChatTranscript', null, true)[0];
    }
    
    public static List < Sobject > getTranscripts() {
        return getSObjectWithRequiredFields('LiveChatTranscript', null, false);
    }
    
    public static List < Sobject > getTranscripts(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('LiveChatTranscript', sobjectFieldList, false);
    }
    
    public static Sobject getTranscript(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('LiveChatTranscript', sobjectFieldList, true)[0];
    }
    
    public static Sobject getEmail() {
        return getSObjectWithRequiredFields('EmailMessage', null, true)[0];
    }
    
    public static List < Sobject > getEmails() {
        return getSObjectWithRequiredFields('EmailMessage', null, false);
    }
    
    public static List < Sobject > getEmails(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('EmailMessage', sobjectFieldList, false);
    }
    
    public static Sobject getEmail(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('EmailMessage', sobjectFieldList, true)[0];
    }
    
    public static Sobject getTask() {
        return getSObjectWithRequiredFields('Task', null, true)[0];
    }
    
    public static List < Sobject > getTasks() {
        return getSObjectWithRequiredFields('Task', null, false);
    }
    
    public static List < Sobject > getTasks(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Task', sobjectFieldList, false);
    }
    
    public static Sobject getTask(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Task', sobjectFieldList, true)[0];
    }
    
    public static Sobject getContact() {
        return getSObjectWithRequiredFields('Contact', null, true)[0];
    }
    
    public static List < Sobject > getContacts() {
        return getSObjectWithRequiredFields('Contact', null, false);
    }
    
    public static List < Sobject > getContacts(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Contact', sobjectFieldList, false);
    }
    
    public static Sobject getContact(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Contact', sobjectFieldList, true)[0];
    }
    
    public static Sobject getCase(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Case', sobjectFieldList, true)[0];
    }
    
    public static List < Sobject > getOutboundMessages(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Outbound_Message__c', sobjectFieldList, true);
    }
    
    
    public static Sobject getAccount(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Account', sobjectFieldList, true)[0];
    }
    
    public static List < Sobject > getCases() {
        return getSObjectWithRequiredFields('Case', null, false);
    }
    
    public static List < Sobject > getOutboundMessages() {
        return getSObjectWithRequiredFields('Outbound_Message__c', null, false);
    }
    
    public static List < Sobject > getAccounts() {
        return getSObjectWithRequiredFields('Account', null, false);
    }
    
    public static List < Sobject > getApplicationLogs() {
        return getSObjectWithRequiredFields('Application_Log__c', null, false);
    }

    public static List < Sobject > getCases(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Case', sobjectFieldList, false);
    }
    
    public static List < Sobject > getApplicationLogs(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Application_Log__c', sobjectFieldList, false);
    }

    public static List < Sobject > getAccounts(List < String > sobjectFieldList) {
        return getSObjectWithRequiredFields('Account', sobjectFieldList, false);
    }

    public static SObject getNewSobject(String objectApiName) {
        Map < String, Schema.SObjectType > gd = Schema.getGlobalDescribe();
        Schema.SObjectType st = gd.get(objectApiName);
        System.assert(st != null, 'Type provided: "' + objectApiName + '" doesnt exist in this ORG.');
        Sobject newlyCreatedObject = st.newSobject();
        return newlyCreatedObject;
    }
  
    public static List < Object_Mandatory_Field__mdt > getMandatoryFields(String sobjectApiName) {
                    // Chanaged 20-Mar-2018 @sung.park
                    // Add is_Key_Field__c for key field
        List < Object_Mandatory_Field__mdt > mandatoryFieldsList = [Select SObjectField_Api_Name__c, SObjectField_Data_Type__c,Reference_Object__c,
                                                                    Possible_Values__c,is_Key_Field__c  from Object_Mandatory_Field__mdt where SObject_Api_Name__c = : sobjectApiName
                                                                   ];
    //    System.debug('mandatoryFieldsList: '+mandatoryFieldsList);
        return mandatoryFieldsList;
    }
    public static SObject getSobjectWithFieldPopulated(String SObject_API_Name, Map < String, Object > FieldValueMap) {
        Sobject newSobject = getNewSobject(SObject_API_Name);
        Map < String, Object > newSobjectFieldValueMap = createNewSobjectFieldValueMap(SObject_API_Name);
        if (FieldValueMap != null) {
            // Added 26-Sep-2017 @jit.lim
            // Clone custom metadata setup field for comparison
            Map < String, Object > cloneNewSobject = newSobjectFieldValueMap.clone();
            // End Added 26-Sep-2017 @jit.lim
            
            for (String fieldApiName: FieldValueMap.keySet()) {
                // Added 26-Sep-2017 @jit.lim
                // Clone custom metadata setup field for comparison
                cloneNewSobject.remove(fieldApiName);
                // End Added 26-Sep-2017 @jit.lim
                    
                newSobject.put(fieldApiName, FieldValueMap.get(fieldApiName));
            }
     //       System.debug('newSobject before: '+newSobject);
            
            // Added 26-Sep-2017 @jit.lim
            // Add mandatory field that are missing from mapping field
            if (cloneNewSobject != null && !cloneNewSobject.isEmpty()) {
                for (String fieldApiName: cloneNewSobject.keySet()) {
                    newSobject.put(fieldApiName, cloneNewSobject.get(fieldApiName));
                }
            }
            // End Added 26-Sep-2017 @jit.lim
   //         System.debug('newSobject after: '+newSobject);
            
        } else {
            for (String fieldApiName: newSobjectFieldValueMap.keySet()) {
                newSobject.put(fieldApiName, newSobjectFieldValueMap.get(fieldApiName));
            }
        }
        
        return newSobject;
    }
    
    public static List < SObject > getSobjectsWithFieldPopulated(String SObject_API_Name, Map < String, Object > FieldValueMap, Integer noOfRecords) {
        List < SObject > newSobjectList = new List < SObject > ();
        Map < String, Object > newSobjectFieldValueMap = createNewSobjectFieldValueMap(SObject_API_Name);
        
        if (FieldValueMap != null) {
            // Added 26-Sep-2017 @jit.lim
            // Clone custom metadata setup field for comparison
            Map < String, Object > cloneNewSobject = newSobjectFieldValueMap.clone();
            // End Added 26-Sep-2017 @jit.lim
            
            for (Integer i = 0; i < noOfRecords; i++) {
                Sobject newSobject = getNewSobject(SObject_API_Name);
                for (String fieldApiName: FieldValueMap.keySet()) {
                    // Added 26-Sep-2017 @jit.lim
            		// Clone custom metadata setup field for comparison
                    cloneNewSobject.remove(fieldApiName);
                    // End Added 26-Sep-2017 @jit.lim
                    
                    if(cloneNewSobject.get('KEY:' +fieldApiName )== null)
                    {
                    	newSobject.put(fieldApiName, FieldValueMap.get(fieldApiName));
                    }else
                    {
                        newSobject.put(fieldApiName, FieldValueMap.get(fieldApiName) + String.valueOf(i));
                        cloneNewSobject.remove('KEY:' +fieldApiName);
                    }
                    
                } // for inner
                //System.debug('cloneNewSobject' + cloneNewSobject);
              //  System.debug('newSobject before: '+newSobject);
                
                // Added 26-Sep-2017 @jit.lim
                // Add mandatory field that are missing from mapping field
                if (cloneNewSobject != null && !cloneNewSobject.isEmpty()) {
                    for (String fieldApiName: cloneNewSobject.keySet()) {
                       // Added 20-Mar-2018 @sung.park
                     	// Add sequence for key field
                        if(fieldApiName.left(4)=='KEY:')
                        {
                            newSobject.put(fieldApiName.substring(4), cloneNewSobject.get(fieldApiName) + String.valueOf(i));
                        }else
                        {
                            newSobject.put(fieldApiName, cloneNewSobject.get(fieldApiName));
                        }
                    }
                }
                // End Added 26-Sep-2017 @jit.lim
                System.debug('newSobject after: '+newSobject);
                
                newSobjectList.add(newSobject);
            } // for outer
        } else {
            
            for (Integer i = 0; i < noOfRecords; i++) {
                Sobject newSobject = getNewSobject(SObject_API_Name);
                
                for (String fieldApiName: newSobjectFieldValueMap.keySet()) {
                     // Added 20-Mar-2018 @sung.park
                     // Add sequence for key field
                    if(fieldApiName.left(4)=='KEY:')
                    {
                        newSobject.put(fieldApiName.substring(4), newSobjectFieldValueMap.get(fieldApiName) +  String.valueOf(i));
                    }else
                    {
                    	newSobject.put(fieldApiName, newSobjectFieldValueMap.get(fieldApiName));
                    }
                } // for inner
                
                newSobjectList.add(newSobject);
            } // for outer
        }
        
        return newSobjectList;
    }    

    /*  Added by PSR  */
    public static List < Sobject > getSObjectRecords(String SObject_API_Name, List < String > sobjectFieldList,String condition,Boolean isOnlyOne) {
        List < Object_Mandatory_Field__mdt > mandFieldsList = getMandatoryFields(SObject_API_Name);
        if (sobjectFieldList == null) {
            sobjectFieldList = new List < String > ();
        }
        
        Set < String > fieldsSet = new Set < String > ();

        Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(SObject_API_Name).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
                schema.describefieldresult dfield = sfield.getDescribe();
                fieldsSet.add(dfield.getname());
        }

        String query = 'Select ';
 
        if(fieldsSet.size() > 0)  
        {
            query += String.join(new List<String>(fieldsSet), ',');
            if(!fieldsSet.contains('Id'))query += ',Id';
        }else
        {
            query += 'Id';
        }
        
        query += ' From ' + SObject_API_Name;
        if(! String.isEmpty(condition))
        {
            query += ' where ' + condition ;
        }
        // only one record
        if (isOnlyOne) {
            query += ' LIMIT 1';
        }
        System.debug(query);
        return Database.query(query);
    }    
   public static List < Sobject > getSObjectWithRequiredFields(String SObject_API_Name, List < String > sobjectFieldList, Boolean isOnlyOne) {
        List < Object_Mandatory_Field__mdt > mandFieldsList = getMandatoryFields(SObject_API_Name);
        if (sobjectFieldList == null) {
            //    if (sobjectFieldList.isEmpty()) {
            sobjectFieldList = new List < String > ();
        }
        
        Set < String > fieldsSet = new Set < String > (sobjectFieldList);
        
        for (Object_Mandatory_Field__mdt eachManFields: mandFieldsList) {
            //sobjectFieldList.add(eachManFields.SObjectField_Api_Name__c);
            fieldsSet.add(eachManFields.SObjectField_Api_Name__c);
        }
        
        String query = 'Select Id';
        //  for (String eachField: sobjectFieldList) {
        for (String eachField: fieldsSet) {
            query += ', ' + eachField;
        }
        query += ' From ' + SObject_API_Name;
        
        // only one record
        if (isOnlyOne) {
            query += ' LIMIT 1';
        }
        System.debug(query);
        return Database.query(query);
    }
    public static List<String> GetPickListValues(String pObjName, String FieldName){
       List<String> objResults = new List<String>();
       Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
       if (!objGlobalMap.containsKey(pObjName))
            return objResults;
       Schema.SObjectType pType = objGlobalMap.get(pObjName);
       Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
        //verify field names
       if (!objFieldMap.containsKey(FieldName)) return objResults;     
        //get the picklist values   
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(FieldName).getDescribe().getPicklistValues();
       
		for(Integer pPickIndex=0; pPickIndex<ctrl_ple.size(); pPickIndex++){        	

            objResults.add(ctrl_ple[pPickIndex].getValue());
        }
       return objResults;
       
   	} 
   	public static Map < String, Object > createNewSobjectFieldValueMap(String SObject_API_Name)
    {
   
        Map < String, Object > newSobjectFieldValueMap = new Map < String, Object > ();
        List < Object_Mandatory_Field__mdt > mandFieldsList = null;
        try {
            mandFieldsList = getMandatoryFields(SObject_API_Name);
        }
        Catch(Exception e) {
            System.debug(e);
        }
           if (!mandFieldsList.isEmpty()) {
            
            for (Object_Mandatory_Field__mdt eachMandFields: mandFieldsList) {
                System.debug('eachMandFields: '+eachMandFields);
                if ((eachMandFields.SObjectField_Data_Type__c).equals('Text') ||
                    (eachMandFields.SObjectField_Data_Type__c).equals('Text Area') ||
                    (eachMandFields.SObjectField_Data_Type__c).equals('Text Area (Long)'))
                    // Chanaged 20-Mar-2018 @sung.park
                    // Add sequence for key field
                {  
					String txtVal = '';
                    if (eachMandFields.Possible_Values__c ==null || eachMandFields.Possible_Values__c =='')
                    {
                        txtVal ='TEST';
                    }else
                    {
                        txtVal =(eachMandFields.Possible_Values__c);
                    	if(eachMandFields.is_Key_Field__c ) newSobjectFieldValueMap.put('KEY:' +eachMandFields.SObjectField_Api_Name__c, txtVal);
                		else newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,txtVal);
                    }
                }
                if ((eachMandFields.SObjectField_Data_Type__c).equals('Reference'))
                {
                    
                    String queryStr = 'Select Id from '+eachMandFields.Reference_Object__c + ' limit 1';
                    List<sObject> refObjs = Database.query(queryStr);
                    if(refObjs.size() == 0) refObjs = TestUtility.createsObjects(eachMandFields.Reference_Object__c ,1);
                    if(refObjs.size()> 0)
                    {
                    	newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,refObjs[0].get('Id'));
                    }
                }
                if ((eachMandFields.SObjectField_Data_Type__c).equals('Picklist'))
                {
                    if(String.isEmpty(eachMandFields.Possible_Values__c)) 
                    {
                        List<String> pickValues =  TestUtility.GetPickListValues(SObject_API_Name,eachMandFields.SObjectField_Api_Name__c);
                     	newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c, pickValues[0]);    
                    }else
                    {
                        newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,eachMandFields.Possible_Values__c);
                    }
                
                }
                if ((eachMandFields.SObjectField_Data_Type__c).equals('Date'))
                {
                    if(String.isEmpty(eachMandFields.Possible_Values__c)) newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,Date.today());
                    else newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,Date.parse(eachMandFields.Possible_Values__c));
                    
                }
                if ((eachMandFields.SObjectField_Data_Type__c).equals('Date/Time'))
                    if(String.isEmpty(eachMandFields.Possible_Values__c)) newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,DateTime.now());
                    else newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,DateTime.parse(eachMandFields.Possible_Values__c));

                
                if ((eachMandFields.SObjectField_Data_Type__c).equals('Number'))
                    if(String.isEmpty(eachMandFields.Possible_Values__c)) newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c, 123);
                    else newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,Decimal.valueOf(eachMandFields.Possible_Values__c));
                    //newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c, 123);
                
                if ((eachMandFields.SObjectField_Data_Type__c).equals('Email'))
                    if(String.isEmpty(eachMandFields.Possible_Values__c)) newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c, 'xyzsampleemail@mytestemail.com');
                    else newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,eachMandFields.Possible_Values__c);
                
                if ((eachMandFields.SObjectField_Data_Type__c).equals('Time'))
                    if(String.isEmpty(eachMandFields.Possible_Values__c)) newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c, '07:30:00.000Z');
                    else newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,eachMandFields.Possible_Values__c);

                
                if ((eachMandFields.SObjectField_Data_Type__c).equals('URL'))
                    if(String.isEmpty(eachMandFields.Possible_Values__c)) newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c, 'https://mysampledomain.my.salesforce.com');
                    else newSobjectFieldValueMap.put(eachMandFields.SObjectField_Api_Name__c,eachMandFields.Possible_Values__c);
            }
            // Object specific handling
            if (SObject_API_Name.equalsIgnoreCase('Opportunity') && newSobjectFieldValueMap.get('Pricebook2Id') == null )
            {
                newSobjectFieldValueMap.put('Pricebook2Id',Test.getStandardPricebookId());
            }
        }
        System.debug('newSobjectFieldValueMap: '+newSobjectFieldValueMap);
        return newSobjectFieldValueMap;

    }
	public static User createTestUser( Profile p ) {
    	String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
		User curUser = (User)TestUtility.getSObjectRecord('User',UserInfo.getUserId()) ;
    	
    	User testUser = new User();
    	testUser.Email 				= curUser.Email;
    	testUser.Username 			= uniqueUserName;
    	testUser.LastName 			= 'test';
    	testUser.Alias 				= 'test';
    	testUser.ProfileId 			=  p.Id;
    	testUser.LanguageLocaleKey 	= curUser.LanguageLocaleKey;
    	testUser.LocaleSidKey 		= curUser.LocaleSidKey;
    	testUser.TimeZoneSidKey 	= curUser.TimeZoneSidKey;
    	testUser.EmailEncodingKey 	= curUser.EmailEncodingKey;
    	
    	insert testUser;
        return testUser;
    
  	} 
    public static User createTestUser(String ProflieName) {
 		Profile p = [SELECT Id FROM Profile WHERE Name=:ProflieName];
        return TestUtility.createTestUser(p);
  	}
	public static User createTestUser() {
 		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        return TestUtility.createTestUser(p);
  	}
    
} //TestUtility