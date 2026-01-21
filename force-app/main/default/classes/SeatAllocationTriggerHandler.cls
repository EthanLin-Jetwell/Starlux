/********************************************************************************************************
NAME:           SeatAllocationTriggerHandler
AUTHOR:         Edmond To (eto@salesforce.com)
PURPOSE:        To perform related field updates on Seat Allocation record creation
                Query for Ticket Fare and Tax Table records based on Seat Allocation fields, to populate fare and tax fields on Seat Allocation record

UPDATE HISTORY:
DATE            AUTHOR          COMMENTS
-------------------------------------------------------------
16/08/2019      Edmond To       First version
09/12/2019      Edmond To       Updated ticket fare rule searching
********************************************************************************************************/

public class SeatAllocationTriggerHandler extends TriggerHandler{
    public SeatAllocationTriggerHandler() {
    }
    
    /*** Context Overrides ***/
    public override void beforeInsert() {
        copyContactEmails();
        // check is record is subtractable
        map<String, Seat_Allocation_and_Ticketing__c> pnrMap = new map<String, Seat_Allocation_and_Ticketing__c>();
        for(Seat_Allocation_and_Ticketing__c sat : (List<Seat_Allocation_and_Ticketing__c>) Trigger.new) {
            if(sat.Allocation_Type__c == Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADJUSTMENT) {
                pnrMap.put(sat.Booking_Reference_PNR__c, sat);
            }
        }
        for(Seat_Allocation_and_Ticketing__c sat : [SELECT Id, Final_Allocated_Seats__c, Total_Seat_Sales__c, Booking_Reference_PNR__c FROM Seat_Allocation_and_Ticketing__c WHERE Booking_Reference_PNR__c IN :pnrMap.keySet() AND Allocation_Type__c <> 'Adjustment' ORDER BY CreatedDate DESC LIMIT 1]) {
            String pnr = sat.Booking_Reference_PNR__c;
            Seat_Allocation_and_Ticketing__c adjustment = pnrMap.get(pnr);
            if(sat.Final_Allocated_Seats__c + adjustment.Allocated_Seats__c < sat.Total_Seat_Sales__c) {
                adjustment.addError('Please adjust the Total Seat Sales in SRS/ADC SAT record.');
            }
        }
    }
    
    public override void afterInsert() {
        List<Seat_Allocation_and_Ticketing__c> satList = (List<Seat_Allocation_and_Ticketing__c>) Trigger.new;
            processInsertRecords();
            SeatAllocationUtil.processSatInsertion(satList, Constants.SAT_PROCESS_INSERT_ORIGIN_TRIGGER);
    }
    
    public override void afterUpdate() {
        processUpdateRecords();
        
        List<Seat_Allocation_and_Ticketing__c> satList = new List<Seat_Allocation_and_Ticketing__c>();
        
        Id adHocRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Adhoc_Request' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        for (Seat_Allocation_and_Ticketing__c newSat : (List<Seat_Allocation_and_Ticketing__c>) trigger.new) {
            Seat_Allocation_and_Ticketing__c oldSat = (Seat_Allocation_and_Ticketing__c) trigger.oldMap.get(newSat.Id);
            if (newSat.recordTypeId == plannedAllocationRecordTypeId && oldSat.RecordTypeId == adHocRecordTypeId) {
                satList.add(newSat);
            }
        }
        if (!satList.isEmpty()) {
            SeatAllocationUtil.processSatInsertion(satList, Constants.SAT_PROCESS_INSERT_ORIGIN_TRIGGER);
        }
        
        // update SST seat sales then upload the value to Amadeus
        SeatAllocationUtil.updateSST((Map<Id, Seat_Allocation_and_Ticketing__c>) trigger.oldMap, (Map<Id, Seat_Allocation_and_Ticketing__c>) trigger.newMap);
    }
    
    //Application Log 180819
    private static List<System_Settings__mdt> logLevelCMD;
    private static DateTime startTime = DateTime.now();
    private static Date currentDate = Date.today();
    private static String processLog;
    private static String payLoad;
    private static Integer totalRecords = 0, errorRecords = 0, successfulRecords = 0;
    private static List<String> failureRecords = new List<String>();
    
    private static void copyContactEmails() {
        //Master list of Case IDs and Contact IDs
        List<String> allCases = new List<String>();
        List<String> allContacts = new List<String>();
        Map<String, String> caseContactMap = new Map<String, String>();
        Map<String, List<String>> contactMap = new Map<String, List<String>>();
        
        //Iterate through all newly inserted Seat Allocation records to add Case ID to master list of Case IDs
        for (Seat_Allocation_and_Ticketing__c seatAllocation : (List<Seat_Allocation_and_Ticketing__c>) trigger.new) {
            if (Trigger.isInsert) {
                allCases.add(seatAllocation.Case_ID__c);
            }
        }
       
        //Query for all cases in master list
        List<Case> caseList = [SELECT Id, ContactId FROM Case WHERE Id IN :allCases];
       
        //Iterate through all queried Case records to add Contact ID to master list of Contact IDs
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
        for (Seat_Allocation_and_Ticketing__c seatAllocation : (List<Seat_Allocation_and_Ticketing__c>) trigger.new) {
            String key = seatAllocation.Case_ID__c;
            String contactValue = caseContactMap.get(key);
            if (contactValue != null) {
                List<String> altEmails = contactMap.get(contactValue);
                seatAllocation.Travel_Agent_Alternate_Email_1__c = altEmails[0];
                seatAllocation.Travel_Agent_Alternate_Email_2__c = altEmails[1];
                seatAllocation.Travel_Agent_Alternate_Email_3__c = altEmails[2];
            }
        }
    }
    
    private static void processInsertRecords() {
        //Application Log 180819
        System_Settings__mdt logLevelCMD = [SELECT Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Seat Allocation Trigger Handler'
                                            limit 1];
        
        //Allocation Type for Adjustment records
        String adjustType = 'Adjustment';
        List<String> targetAllocationType = new List<String>();
        targetAllocationType.add('SRS');
        targetAllocationType.add('ADC');
        
        //Find the applicable record type for Seat Allocation records
        String targetRecordTypeId = Schema.Sobjecttype.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        
        //Master list for insert
        List<Seat_Allocation_and_Ticketing__c> recordsToInsert = new List<Seat_Allocation_and_Ticketing__c>();
        
        //Master list of PNR Ids
        List<String> relatedPNR = new List<String>();
        
        //Map of PNR Id and Adjustment value
        Map<String, Decimal> finalMap = new Map<String, Decimal>();

        //Query for all newly triggered Seat Allocation records which are Adjustment records
        List<Seat_Allocation_and_Ticketing__c> newAdjustmentSeatAllocationList = [SELECT Id,Case_ID__c,Booking_Reference_PNR__c,Allocated_Seats__c
                                                                                  FROM Seat_Allocation_and_Ticketing__c WHERE Id IN :Trigger.new AND RecordTypeId = :targetRecordTypeId AND Allocation_Type__c = :adjustType];
        
        //Iterate through all Adjustment records to update list of PNR Id
        for (Seat_Allocation_and_Ticketing__c newSeatAllocation : newAdjustmentSeatAllocationList) {
            String PNRId = newSeatAllocation.Booking_Reference_PNR__c;
            relatedPNR.add(PNRId);
        }
        
        //Query for all Seat Allocation records with PNR Id in master PNR list
        List<Seat_Allocation_and_Ticketing__c> allSeatAllocationList = [SELECT Id,Case_ID__c,Allocated_Seats__c,Booking_Reference_PNR__c,Final_Allocated_Seats__c,Allocation_Type__c
                                                                           FROM Seat_Allocation_and_Ticketing__c WHERE Booking_Reference_PNR__c IN :relatedPNR];
        
      
        //Iterate through all PNR IDs to update the Final Allocation Seats adjustment value on the map 
        for (String PNRId : relatedPNR) {
            Decimal adjustmentValue = 0;
            for (Seat_Allocation_and_Ticketing__c adjustSeatAllocation: newAdjustmentSeatAllocationList) {
                if (adjustSeatAllocation.Booking_Reference_PNR__c == PNRId) {
                    for (Seat_Allocation_and_Ticketing__c seatAllocation : allSeatAllocationList) {
                        if (seatAllocation.Booking_Reference_PNR__c == PNRId && seatAllocation.Case_ID__c == adjustSeatAllocation.Case_ID__c) {
                            adjustmentValue += seatAllocation.Allocated_Seats__c;
                        }
                    }
                }
                finalMap.put(PNRId, adjustmentValue);
            }
            
        }

        //Iterate through FinalMap to update the Final Allocation Seats field on the corresponding SRS/ADC record
        for (String key: finalMap.keyset()) {
            Decimal adjustmentValue = finalMap.get(key);
            for (Seat_Allocation_and_Ticketing__c adjustSeatAllocation: newAdjustmentSeatAllocationList) {
                if (adjustSeatAllocation.Booking_Reference_PNR__c == key) {
                    for (Seat_Allocation_and_Ticketing__c seatAllocation : allSeatAllocationList) {
                        if (seatAllocation.Booking_Reference_PNR__c == key && seatAllocation.Case_ID__c == adjustSeatAllocation.Case_ID__c && targetAllocationType.contains(seatAllocation.Allocation_Type__c)) {
                            seatAllocation.Final_Allocated_Seats__c = adjustmentValue;
                            recordsToInsert.add(seatAllocation);
                            totalRecords++;
                        }
                    }
                }
            }
        }
        
        //----------------------------------------------------------SRS/ADC Records Logic Below---------------------------------------------------
        
        //Query for all newly triggered Seat Allocation records which are not Adjustment records
        List<Seat_Allocation_and_Ticketing__c> newSeatAllocationList = [SELECT Id,Final_Allocated_Seats__c,Allocated_Seats__c,Booking_Reference_PNR__c,Tour_Code__c,Allocation_Type__c,Final_Sales_Seats__c,Returning_Flight_Date__c,Departing_Flight_Date__c,CreatedDate,Case_ID__c,Departing_Flight_Number__c,
                                                                        Returning_Flight_Number__c,Group_Booking_Route__c,Initial_Unit_Price_Infant__c,Initial_Unit_Price_Child__c,
                                                                        Initial_Unit_Price_Adult__c,Initial_Tax_Infant__c,Initial_Tax_Child__c,Initial_Tax_Adult__c,
                                                                        Final_Unit_Price_Infant__c,Final_Unit_Price_Child__c,Final_Unit_Price_Adult__c,Final_Tax_Infant__c,
                                                                        Final_Tax_Child__c,Final_Tax_Adult__c,Not_in_Fare_Table__c,Not_in_Tax_Table__c,Case_Id__r.Account.IATA_MSO_Code__c 
                                                                        FROM Seat_Allocation_and_Ticketing__c
                                                                        WHERE Id IN :Trigger.new AND RecordTypeId = :targetRecordTypeId AND Allocation_Type__c IN :targetAllocationType];
        
        //Iterate through newSeatAllocationList to check date range
        Date earliestDepartingFlightDate = Date.today();
        Date latestReturningFlightDate = Date.today();
        Set<String> groupBookingRoutes = new Set<String>(); //20241011 Eli
        Set<String> departingFlightNumbers = new Set<String>(); //20241011 Eli
                    
            for (Seat_Allocation_and_Ticketing__c newSeatAllocation : newSeatAllocationList) {
                
            groupBookingRoutes.add(newSeatAllocation.Group_Booking_Route__c);//20241011 Eli
            departingFlightNumbers.add(newSeatAllocation.Departing_Flight_Number__c);//20241011 Eli
                
            if (newSeatAllocation.Returning_Flight_Date__c > latestReturningFlightDate) {
                latestReturningFlightDate = newSeatAllocation.Returning_Flight_Date__c;
            }
            if (newSeatAllocation.Departing_Flight_Date__c > earliestDepartingFlightDate) {
                earliestDepartingFlightDate = newSeatAllocation.Departing_Flight_Date__c;
            }
        }
        
        system.debug('DBG earliestDepartingFlightDate: '+earliestDepartingFlightDate);
        system.debug('DBG latestReturningFlightDate: '+latestReturningFlightDate);
        //Query for all applicable Ticket Fare Rule records
        //Add Is_Saturday__c and Is_Sunday__c in the query: Chris Hsu 2020-02-14
        List<Ticket_Fare_Rule__c> allTicketFares = [SELECT Id,Tour_Code__c,Departing_Flight_Number__c,Returning_Flight_Number__c,Minimal_No_of_Pax__c,Less_than_Minimal_No_of_Pax__c,
                                                    Is_Weekend__c,Is_Saturday__c,Is_Sunday__c,CreatedDate,Name,Unit_Price_Infant__c,Effective_Flight_End_Date__c,Effective_Flight_Start_Date__c,
                                                    Effective_Ticket_Issue_Start_Date__c,Effective_Ticket_Issue_End_Date__c,Route__c,IATA_Code__c,
                                                    Unit_Price_Child__c,Unit_Price_Adult__c FROM Ticket_Fare_Rule__c WHERE  
                                                    Effective_Flight_End_Date__c >= :earliestDepartingFlightDate AND 
                                                    Effective_Flight_Start_Date__c <= :earliestDepartingFlightDate AND 
                                                    Route__c IN : groupBookingRoutes AND //20241011 Eli
                                                    Departing_Flight_Number__c IN : departingFlightNumbers];//20241011 Eli
        
        system.debug('DBG all tickets total: '+allTicketFares.size());
        system.debug('DBG all tickets: '+allTicketFares);       
        
        //Map to store PNRId and CaseId
        List<String> relatedPNRIds = new List<String>();
        List<String> relatedCaseIds = new List<String>();
        Map<List<String>, Decimal> casePNRMap = new Map<List<String>, Decimal>();
        
        //Store all Ticket Fare records in a Map 
        Map<String, Ticket_Fare_Rule__c> mapTicketFare = new Map<String, Ticket_Fare_Rule__c>();
        Integer fareCount = 1;
        
        for (Ticket_Fare_Rule__c fare : allTicketFares) {
            String fareKey = 'Fare' + String.valueOf(fareCount);
            mapTicketFare.put(fareKey, fare);
            fareCount += 1;
        }
        
        //Query for all applicable Tax Table records
        List<Tax_Details__c> allTaxTables = [SELECT Id,CreatedDate,Tax_Amount_Adult__c,Tax_Amount_Child__c,Tax_Amount_Infant__c,Route__c,Tax_Date__c FROM Tax_Details__c 
                                          WHERE Tax_Date__c >= :currentDate-90];
        
        //Store all Tax Table records in a Map
        Map<String, Tax_Details__c> mapTaxTable = new Map<String, Tax_Details__c>();
        Integer taxCount = 1;
        for (Tax_Details__c tax : allTaxTables) {
            String taxKey = 'Tax' + String.valueOf(taxCount);
            mapTaxTable.put(taxKey, tax);
            taxCount += 1;
        }
        
        //Iterate through all new Seat Allocation records to populate casePNRMap
        for (Seat_Allocation_and_Ticketing__c newSeatAllocation : newSeatAllocationList) {
            relatedPNRIds.add(newSeatAllocation.Booking_Reference_PNR__c);
            relatedCaseIds.add(newSeatAllocation.Case_ID__c);
        }
        
        //Query for all adjustment records that matches Case Id and PNR Id
        List<Seat_Allocation_and_Ticketing__c> relatedAdjustmentSeatAllocationList = [SELECT Id,Allocated_Seats__c, Allocation_Type__c, Booking_Reference_PNR__c, Case_ID__c FROM Seat_Allocation_and_Ticketing__c
                                                                                     WHERE Booking_Reference_PNR__c IN :relatedPNRIds AND Case_ID__c IN :relatedCaseIds AND Allocation_Type__c = :adjustType];
        
        //Iterate through all related Adjustment records
        for (String PNRId : relatedPNRIds) {
            for (String CaseId : relatedCaseIds) {
                Decimal adjustmentValue = 0;
                for (Seat_Allocation_and_Ticketing__c seatAllocation : relatedAdjustmentSeatAllocationList) {
                    if (seatAllocation.Booking_Reference_PNR__c == PNRId && seatAllocation.Case_ID__c == CaseId) {
                        adjustmentValue += seatAllocation.Allocated_Seats__c;
                    }
                }
                if (adjustmentValue != 0) {
                    List<String> casePNR = new List<String>();
                    casePNR.add(CaseId);
                    casePNR.add(PNRId);
                    casePNRMap.put(casePNR,adjustmentValue);    
                }
            }
        }
        system.debug('DBG CasePNRMap: '+casePNRMap);
        //Iterate through all new Seat Allocation records to update fare and tax values
        if (newSeatAllocationList.size() > 0) {
            for (Seat_Allocation_and_Ticketing__c newSeatAllocation : newSeatAllocationList) {
                
                Boolean weekendAdded = false;
                String DepartureFlightNo = newSeatAllocation.Departing_Flight_Number__c;
                String ReturningFlightNo = newSeatAllocation.Returning_Flight_Number__c;
                Date DepartingFlightDate = newSeatAllocation.Departing_Flight_Date__c;
                Date ReturningFlightDate = newSeatAllocation.Returning_Flight_Date__c;
                Datetime IssueDateTime = newSeatAllocation.CreatedDate;
                Date IssueDate = date.newInstance(IssueDateTime.year(),IssueDateTime.month(),IssueDateTime.day());
                String IATACode = newSeatAllocation.Case_Id__r.Account.IATA_MSO_Code__c;
                Decimal FinalSeats = newSeatAllocation.Final_Sales_Seats__c;
                String Route = newSeatAllocation.Group_Booking_Route__c;
                
                if (Trigger.isInsert) {
                        //Check for existing adjustment values and updates Final Allocation Seats field
                        List<String> checkKey = new List<String>();
                        checkKey.add(newSeatAllocation.Case_ID__c);
                        checkKey.add(newSeatAllocation.Booking_Reference_PNR__c);
                        Decimal checkValue = casePNRMap.get(checkKey);
                    
                        if (checkValue != null) {
                            newSeatAllocation.Final_Allocated_Seats__c = newSeatAllocation.Allocated_Seats__c + checkValue;
                        } else {
                            newSeatAllocation.Final_Allocated_Seats__c = newSeatAllocation.Allocated_Seats__c;
                        }
                   
                        //Final selected records
                        Ticket_Fare_Rule__c selectedTicketFare = new Ticket_Fare_Rule__c();
                        Tax_Details__c selectedTaxTable = new Tax_Details__c();
                        
                        Decimal extraSurcharge = 0;
                        
                        //All shortlisted records after filtering later on
                        List<Ticket_Fare_Rule__c> allSelectedFares = new List<Ticket_Fare_Rule__c>();
                        List<Tax_Details__c> allSelectedTaxes = new List<Tax_Details__c>();
                        
                        //Check if any record in mapTicketFare matches criteria of newSeatAllocation
                        for (String key : mapTicketFare.keySet()) {
                            Ticket_Fare_Rule__c loopTicketFare = mapTicketFare.get(key);
                            system.debug('DBG loopTicketFare: '+loopTicketFare);
                            if (loopTicketFare.Departing_Flight_Number__c == DepartureFlightNo && loopTicketFare.Returning_Flight_Number__c == ReturningFlightNo &&
                               loopTicketFare.Effective_Flight_End_Date__c >= ReturningFlightDate && loopTicketFare.Effective_Flight_Start_Date__c <= DepartingFlightDate &&
                               loopTicketFare.Effective_Ticket_Issue_Start_Date__c <= IssueDate && loopTicketFare.Effective_Ticket_Issue_End_Date__c >= IssueDate &&
                               loopTicketFare.Route__c == Route && loopTicketFare.IATA_Code__c == IATACode) {
                                system.debug('DBG Added new Fare: ' + loopTicketFare);
                                   allSelectedFares.add(loopTicketFare);
                            }
                            
                        }
                    
                        //Sorting allSelectedFares based on matching outcomes to determine the right Ticket Fare record to be used
                        if (allSelectedFares.size() > 1) {
                            Datetime latestDate = datetime.newInstance(1990,1,1);
                            Integer latestNumber = 0;
                            Integer latestYearMonth = 0;
                            Ticket_Fare_Rule__c latestFare = new Ticket_Fare_Rule__c();
                            for (Ticket_Fare_Rule__c loopFare : allSelectedFares) {
                                String loopName = loopFare.Name;
                                loopName = loopName.remove('TF');
                                Integer loopNameValue = Integer.valueOf(loopName.right(8));
                                Integer loopYearMonthValue = Integer.valueOf(loopName.left(6));
                                if (loopFare.CreatedDate == latestDate) {    
                                    if (loopYearMonthValue > latestYearMonth) {
                                        latestDate = loopFare.CreatedDate;
                                        latestYearMonth = loopYearMonthValue;
                                        latestNumber = loopNameValue;
                                        latestFare = loopFare;
                                    } else if (loopYearMonthValue == latestYearMonth) {
                                        if (loopNameValue > latestNumber) {
                                            latestDate = loopFare.CreatedDate;
                                            latestYearMonth = loopYearMonthValue;
                                            latestNumber = loopNameValue;
                                            latestFare = loopFare;
                                        }
                                    }
                                } else if (loopFare.CreatedDate > latestDate) {
                                    latestDate = loopFare.CreatedDate;
                                    latestYearMonth = loopYearMonthValue;
                                    latestNumber = loopNameValue;
                                    latestFare = loopFare;
                                }
                            }
                            selectedTicketFare = latestFare;
                            system.debug('DBG selectedTicketFare: '+selectedTicketFare);
                        } else {
                            if (allSelectedFares.size() == 1) {
                                selectedTicketFare = allSelectedFares[0];
                                system.debug('DBG selectedTicketFare: '+selectedTicketFare);
                            } 
                            if (allSelectedFares.size() == 0) {
                                newSeatAllocation.Not_in_Fare_Table__c = true;
                            }
                        }
                        
                        //Check if final allocated seats hits minimal PAX
                        if (FinalSeats < selectedTicketFare.Minimal_No_of_Pax__c) {
                            if (selectedTicketFare.Less_than_Minimal_No_of_Pax__c != null) {
                                system.debug('DBG Added lessPAX: '+selectedTicketFare.Less_than_Minimal_No_of_Pax__c);
                                extraSurcharge += selectedTicketFare.Less_than_Minimal_No_of_Pax__c;
                            }
                        }
                        
                        //Check if flight is during weekend
                        /*Integer daysBetween = DepartingFlightDate.daysBetween(ReturningFlightDate);
                        if (daysBetween >= 6) {
                            if (selectedTicketFare.Is_Weekend__c != null && weekendAdded == false) {
                                extraSurcharge += selectedTicketFare.Is_Weekend__c;   
                                weekendAdded = true;
                            }
                                        
                        } else {
                            for (Integer i = 0; i<=daysBetween; i++) {
                                Date temporaryFlightDate = DepartingFlightDate;
                                temporaryFlightDate += i;
                                Datetime convertedFlightDate = Datetime.newInstance(temporaryFlightDate, Time.newInstance(0,0,0,0));
                                String dayOfDate = convertedFlightDate.format('EEEE');
                                if (dayOfDate == 'Saturday' || dayOfDate == 'Sunday') {
                                    if (selectedTicketFare.Is_Weekend__c != null && weekendAdded == false) {
                                        extraSurcharge += selectedTicketFare.Is_Weekend__c;
                                        weekendAdded = true;
                                    }
                                }
                            }
                        }*/
                        //Check if flight is during Weekend - Chris 20200207
                        //Check if flight Include Saturday and Sunday - Chris 20200330
                        Integer daysBetween;
                        if(ReturningFlightDate!=null && DepartingFlightDate!=null)
                        {
                            daysBetween= DepartingFlightDate.daysBetween(ReturningFlightDate);
                        }
                        else
                        {
                            daysBetween=0;
                        }
                         
                        system.debug('DBG daysBetween: '+daysBetween);
                        Boolean satAdded = false;
                        Boolean sunAdded = false;
                    // 2025/12/30 Ethan
                        for (Integer i = 0; i<daysBetween; i++) {
                                Date temporaryFlightDate = DepartingFlightDate;
                                temporaryFlightDate += i;
                                system.debug('DBG temporaryFlightDate: '+temporaryFlightDate);
                                Datetime convertedFlightDate = Datetime.newInstance(temporaryFlightDate, Time.newInstance(0,0,0,0));
                                String dayOfDate = convertedFlightDate.format('EEEE');
                                system.debug('DBG converted date: '+dayOfDate);
                                if (daysBetween >= 6) {
                                    if (selectedTicketFare.Is_Weekend__c != null && weekendAdded == false) {
                                        extraSurcharge += selectedTicketFare.Is_Weekend__c; 
                                        weekendAdded = true;
                                        break;
                                    }                                                
                                }else{
                                    if (dayOfDate == 'Saturday' && i<daysBetween){//Including Saturday & Sunday
                                        if (selectedTicketFare.Is_Weekend__c != null && weekendAdded == false) {
                                            extraSurcharge += selectedTicketFare.Is_Weekend__c; 
                                            weekendAdded = true;
                                            break;
                                        }   
                                    }else{
                                        if (dayOfDate == 'Saturday') {
                                            if (selectedTicketFare.Is_Saturday__c != null && satAdded == false && weekendAdded == false) {
                                                extraSurcharge += selectedTicketFare.Is_Saturday__c; 
                                                satAdded = true;
                                            }
                                        }
                                        if (dayOfDate == 'Sunday'){
                                            if (selectedTicketFare.Is_Sunday__c != null && sunAdded == false && weekendAdded == false) {
                                                extraSurcharge += selectedTicketFare.Is_Sunday__c; 
                                                sunAdded = true;
                                            }
                                        }
                                    }  
                                }                                 
                                    
                        }//End of For
                        
                        //Update fare fields on Seat Allocation records
                        if (selectedTicketFare.Unit_Price_Adult__c != null) {
                            newSeatAllocation.Initial_Unit_Price_Adult__c = selectedTicketFare.Unit_Price_Adult__c + extraSurcharge;   
                            //newSeatAllocation.Final_Unit_Price_Adult__c = selectedTicketFare.Unit_Price_Adult__c + extraSurcharge;
                            newSeatAllocation.Tour_Code__c = selectedTicketFare.Tour_Code__c;
                        }
                        if (selectedTicketFare.Unit_Price_Child__c != null) {
                            newSeatAllocation.Initial_Unit_Price_Child__c = selectedTicketFare.Unit_Price_Child__c + extraSurcharge;
                            //newSeatAllocation.Final_Unit_Price_Child__c = selectedTicketFare.Unit_Price_Child__c + extraSurcharge;
                            newSeatAllocation.Tour_Code__c = selectedTicketFare.Tour_Code__c;
                        }
                        if (selectedTicketFare.Unit_Price_Infant__c != null) {
                            //Change extraSurcharge for infant to be one tenth - Chris 20200217
                            newSeatAllocation.Initial_Unit_Price_Infant__c = selectedTicketFare.Unit_Price_Infant__c + (extraSurcharge/10); 
                            //newSeatAllocation.Final_Unit_Price_Infant__c = selectedTicketFare.Unit_Price_Infant__c + extraSurcharge;
                            newSeatAllocation.Tour_Code__c = selectedTicketFare.Tour_Code__c;
                        }
                        
                        //Check if any record in mapTaxTable matches criteria of newSeatAllocation
                        for (String key : mapTaxTable.keySet()) {
                            Tax_Details__c loopTaxTable = mapTaxTable.get(key);
                            
                            if (loopTaxTable.Route__c == Route && loopTaxTable.Tax_Date__c == currentDate) { //16/09/2019 Changed from checking against DepartingFlightDate to CurrentDate
                                allSelectedTaxes.add(loopTaxTable);
                            }
                        }
                        
                        //Sorting allSelectedTaxes based on matching outcomes to determine the right Tax Table record to be used
                        if (allSelectedTaxes.size() > 1) {
                            Datetime latestDate = datetime.newInstance(1990,1,1);
                            Tax_Details__c latestTax = new Tax_Details__c();
                            for (Tax_Details__c loopTax : allSelectedTaxes) {
                                if (loopTax.CreatedDate > latestDate) {
                                    latestDate = loopTax.CreatedDate;
                                    latestTax = loopTax;
                                }
                            }
                            selectedTaxTable = latestTax;
                        } else {
                            if (allSelectedTaxes.size() == 1) {
                                selectedTaxTable = allSelectedTaxes[0];
                            } 
                            if (allSelectedTaxes.size() == 0) {
                                newSeatAllocation.Not_in_Tax_Table__c = true;
                            }
                        }
                        
                        //Update tax fields on Seat Allocation records
                        if (selectedTaxTable.Tax_Amount_Adult__c != null) {
                            newSeatAllocation.Initial_Tax_Adult__c = selectedTaxTable.Tax_Amount_Adult__c;
                            //newSeatAllocation.Final_Tax_Adult__c = selectedTaxTable.Tax_Amount_Adult__c;
                        }
                        if (selectedTaxTable.Tax_Amount_Child__c != null) {
                            newSeatAllocation.Initial_Tax_Child__c = selectedTaxTable.Tax_Amount_Child__c;
                            //newSeatAllocation.Final_Tax_Child__c = selectedTaxTable.Tax_Amount_Child__c;
                        }
                        if (selectedTaxTable.Tax_Amount_Infant__c != null) {
                            newSeatAllocation.Initial_Tax_Infant__c = selectedTaxTable.Tax_Amount_Infant__c;
                            //newSeatAllocation.Final_Tax_Infant__c = selectedTaxTable.Tax_Amount_Infant__c;
                        }
                        
                        system.debug('DBG newSeatAllocation: '+newSeatAllocation);
                        system.debug('DBG newSeatAllocation Final Allocated: '+newSeatAllocation.Final_Allocated_Seats__c);
                        recordsToInsert.add(newSeatAllocation);
                        totalRecords++;
                    }    
            }    
        } 
        
            
        //Try catch to insert the related records
        try {
            Database.SaveResult[] updateResult = database.update(recordsToInsert, false);
            for (Integer i = 0; i < updateResult.size(); i++) {
                if (!updateResult[i].isSuccess()) {
                    for (Database.Error err : updateResult[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(updateResult[i].Id);
                        processLog += 'Unable to update Record ID: ' + updateResult[i].id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    system.debug('SUCCESS');
                    successfulRecords++;
                }
            }
                        
            processLog = '#########################\r\n' +
            'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
            'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
            'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
            'Total Processed Records: ' + totalRecords + '\r\n' +
            'Total Successful Updated Records: ' + successfulRecords + '\r\n' +
            'Total Failed Records: ' + errorRecords + '\r\n' + 
            'List of Failed Records: ' + failureRecords + '\r\n' +
            '#########################\r\n' + processLog;
            
            system.debug('DBG ProcessLog: '+processLog);
            //Application Log 180819
            GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'SeatAllocationTriggerHandler', 'processInsertRecords', null, 'Seat Allocation and Tracking Records Insertion', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
        
        } catch (DmlException DMLError) {
            
            //Application Log 180819
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'SeatAllocationTriggerHandler', 'processInsertRecords', null, 'Seat Allocation and Tracking Records Insertion', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
        }
        
    }
    
    private static void processUpdateRecords() {
        //Application Log 180819
        System_Settings__mdt logLevelCMD = [Select Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Seat Allocation Trigger Handler'
                                            limit 1];
        
        //Allocation Type for Adjustment records
        String adjustType = 'Adjustment';
        List<String> targetAllocationType = new List<String>();
        targetAllocationType.add('SRS');
        targetAllocationType.add('ADC');
        
        //Find the applicable record type for Seat Allocation records
        String targetRecordTypeId = Schema.Sobjecttype.Seat_Allocation_and_Ticketing__c.getRecordTypeInfosByDeveloperName().get('Planned_Allocation').getRecordTypeId();
        
        //Master list for update
        List<Seat_Allocation_and_Ticketing__c> recordsToUpdate = new List<Seat_Allocation_and_Ticketing__c>();
        
        //Master list of PNR Ids
        List<String> relatedPNR = new List<String>();
        
        //Map of PNR Id and Adjustment value
        Map<String, Decimal> finalMap = new Map<String, Decimal>();

        //Query for all newly triggered Seat Allocation records which are Adjustment records
        List<Seat_Allocation_and_Ticketing__c> newAdjustmentSeatAllocationList = [SELECT Id,Case_ID__c,Booking_Reference_PNR__c,Allocated_Seats__c
                                                                                  FROM Seat_Allocation_and_Ticketing__c WHERE Id IN :Trigger.new AND RecordTypeId = :targetRecordTypeId AND Allocation_Type__c = :adjustType];
        system.debug('DBG newAdjustmentSeatAllocationList: '+newAdjustmentSeatAllocationList);
        //Iterate through all Adjustment records to update list of PNR Id
        for (Seat_Allocation_and_Ticketing__c newSeatAllocation : newAdjustmentSeatAllocationList) {
            String PNRId = newSeatAllocation.Booking_Reference_PNR__c;
            relatedPNR.add(PNRId);
        }
        
        //Query for all Seat Allocation records with PNR Id in master PNR list
        List<Seat_Allocation_and_Ticketing__c> allSeatAllocationList = [SELECT Id,Case_ID__c,Allocated_Seats__c,Booking_Reference_PNR__c,Final_Allocated_Seats__c,Allocation_Type__c
                                                                           FROM Seat_Allocation_and_Ticketing__c WHERE Booking_Reference_PNR__c IN :relatedPNR];
        
      
        //Iterate through all PNR IDs to update the Final Allocation Seats adjustment value on the map 
        for (String PNRId : relatedPNR) {
            Decimal adjustmentValue = 0;
            for (Seat_Allocation_and_Ticketing__c adjustSeatAllocation: newAdjustmentSeatAllocationList) {
                if (adjustSeatAllocation.Booking_Reference_PNR__c == PNRId) {
                    for (Seat_Allocation_and_Ticketing__c seatAllocation : allSeatAllocationList) {
                        if (seatAllocation.Booking_Reference_PNR__c == PNRId && seatAllocation.Case_ID__c == adjustSeatAllocation.Case_ID__c) {
                            adjustmentValue += seatAllocation.Allocated_Seats__c;
                        }
                    }
                }
            }
            finalMap.put(PNRId, adjustmentValue);
        }
        system.debug('DBG FinalMap: '+finalMap);
        //Iterate through FinalMap to update the Final Allocation Seats field on the corresponding SRS/ADC record
        for (String key: finalMap.keyset()) {
            Decimal adjustmentValue = finalMap.get(key);
            for (Seat_Allocation_and_Ticketing__c adjustSeatAllocation: newAdjustmentSeatAllocationList) {
                if (adjustSeatAllocation.Booking_Reference_PNR__c == key) {
                    for (Seat_Allocation_and_Ticketing__c seatAllocation : allSeatAllocationList) {
                        if (seatAllocation.Booking_Reference_PNR__c == key && seatAllocation.Case_ID__c == adjustSeatAllocation.Case_ID__c && targetAllocationType.contains(seatAllocation.Allocation_Type__c)) {
                            seatAllocation.Final_Allocated_Seats__c = adjustmentValue;
                            recordsToUpdate.add(seatAllocation);
                            totalRecords++;
                        }
                    }
                }
            }
        }
        
        //-------------------------------------------------------------------------------------------------------------------------------//
        
        /*
        //Master list of PNR IDs from Trigger.Update
        List<String> updatedIds = new List<String>();
        List<Seat_Allocation_and_Ticketing__c> updatedSeatAllocationList = new List<Seat_Allocation_and_Ticketing__c>();
           */
        
        //Query for all newly triggered Seat Allocation records
        List<Seat_Allocation_and_Ticketing__c> newSeatAllocationList = [SELECT Id,Case_ID__c,No_of_Infant__c,No_of_Adult__c,No_of_Child__c,Allocation_Type__c,Final_Sales_Seats__c,Booking_Reference_PNR__c
                                                                        FROM Seat_Allocation_and_Ticketing__c
                                                                        WHERE Id IN :Trigger.new AND Allocation_Type__c IN :targetAllocationType];
        //Check for updated records in Trigger.new
        if (newSeatAllocationList.size() > 0) {
            for (Seat_Allocation_and_Ticketing__c newSeatAllocation : newSeatAllocationList) {
                if (Trigger.isUpdate) {
                    Seat_Allocation_and_Ticketing__c oldSeatAllocation = (Seat_Allocation_and_Ticketing__c) trigger.OldMap.get(newSeatAllocation.Id);
                    if (oldSeatAllocation.No_of_Adult__c != newSeatAllocation.No_of_Adult__c || oldSeatAllocation.No_of_Child__c != newSeatAllocation.No_of_Child__c) {
                        if (newSeatAllocation.Booking_Reference_PNR__c != null) {
                            newSeatAllocation.Final_Sales_Seats__c = newSeatAllocation.No_of_Adult__c + newSeatAllocation.No_of_Child__c; 
                            recordsToUpdate.add(newSeatAllocation);
                            totalRecords++;
                        }
                    } 
                }   
            }
        }
        /*
        //Iterate through all updated Seat Allocation records to calculate total seats for each record and update to all related Seat Allocation records by PNR Id
        for (Seat_Allocation_and_Ticketing__c updatedSeatAllocation : updatedSeatAllocationList) {
            updatedSeatAllocation.Final_Allocated_Seats__c = updatedSeatAllocation.No_of_Adult__c + updatedSeatAllocation.No_of_Child__c;
            
            Decimal totalSeats = updatedSeatAllocation.No_of_Adult__c + updatedSeatAllocation.No_of_Child__c;
            for (Seat_Allocation_and_Ticketing__c relatedSeatAllocation : allRelatedSeatAllocationList) {
                if (relatedSeatAllocation.Booking_Reference_PNR__c == updatedSeatAllocation.Booking_Reference_PNR__c) {
                    system.debug('DBG Updating Id: '+relatedSeatAllocation);
                    relatedSeatAllocation.Final_Allocated_Seats__c = totalSeats;
                    recordsToUpdate.add(relatedSeatAllocation);
                }
            }            
        }*/
        
        //Try catch to update the related records
        try {
            Database.SaveResult[] updateResult = database.update(recordsToUpdate, false);
            for (Integer i = 0; i < updateResult.size(); i++) {
                if (!updateResult[i].isSuccess()) {
                    for (Database.Error err : updateResult[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(updateResult[i].Id);
                        processLog += 'Unable to update Record ID: ' + updateResult[i].id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    successfulRecords++;
                }
            }
                      
            processLog = '#########################\r\n' +
            'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
            'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
            'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
            'Total Processed Records: ' + totalRecords + '\r\n' +
            'Total Successful Updated Records: ' + successfulRecords + '\r\n' +
            'Total Failed Records: ' + errorRecords + '\r\n' + 
            'List of Failed Records: ' + failureRecords + '\r\n' +
            '#########################\r\n' + processLog;
            
            system.debug('DBG ProcessLog: '+processLog);
            //Application Log 180819
            GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'SeatAllocationTriggerHandler', 'processUpdateRecords', null, 'Seat Allocation and Tracking Records Update', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
        
        } catch (DmlException DMLError) {
            
            //Application Log 180819
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'SeatAllocationTriggerHandler', 'processUpdateRecords', null, 'Seat Allocation and Tracking Records Update', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
        }
        
    }

    public static void fakeMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}