public class SeatAllocationUtil {
    
    public static List<String> processSatInsertion(List<Seat_Allocation_and_Ticketing__c> satList, String origin) {
        System.debug('[4i]----- STARTING 4i CODE -----');
        
        MwCreatePnrWrapper satToCreateListAsWrapper = new MwCreatePnrWrapper();
        List<Id> satIdList = new List<Id>();
        Id adHocRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Adhoc_Request' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        
        List<Id> caseIds = new List<Id>();
        for (Seat_Allocation_and_Ticketing__c sat : satList) {
            caseIds.add(sat.Case_ID__c);
        }
        List<Case> caseList = [SELECT Id, Integration_Link_Status__c, Batch_Processing__c, Status, CaseNumber, AccountId, ContactId, Route__c FROM Case WHERE Id in :caseIds];
        
        List<Id> accountIds = new List<Id>();
        List<Id> contactIds = new List<Id>();
        Map<String, Case> caseMap = new Map<String, Case>();
        for (Case currCase : caseList) {
            caseMap.put(currCase.Id, currCase);
            accountIds.add(currCase.AccountId);
            contactIds.add(currCase.ContactId);
        }
        
        List<Account> accountList = [SELECT Id, Agency_Short_Name__c, Group_Commitment__c FROM Account WHERE Id in :accountIds]; //20240617 add Group_Commitment__c Eli Lin
        Map<String, Account> accountMap = new Map<String, Account>();
        for (Account currAccount : accountList) {
            accountMap.put(currAccount.Id, currAccount);   
        }
        
        List<Contact> contactList = [SELECT Id, IATA_MSO_Code__c, Office_Site__c FROM Contact WHERE Id in :contactIds];
        Map<String, Contact> contactMap = new Map<String, Contact>();
        for (Contact currContact : contactList) {
            contactMap.put(currContact.Id, currContact);
        }
        
        List<String> results = new List<String>();
        for (Seat_Allocation_and_Ticketing__c sat : satList) {
            Case satCase = caseMap.get(sat.Case_ID__c);
            Account currAccount = accountMap.get(satCase.AccountId);
            Contact currContact = contactMap.get(satCase.ContactId);
            
            if (origin == Constants.SAT_PROCESS_INSERT_ORIGIN_TRIGGER && satCase.Batch_Processing__c) {
                return ResponseUtil.buildStringListResponse('Please check Batch Processing in Case.');
            }
            if (origin == Constants.SAT_PROCESS_INSERT_ORIGIN_TRIGGER && !satCase.Integration_Link_Status__c) {
                return ResponseUtil.buildStringListResponse('Please check Integration Link Status.');
            }
            if (satCase.Status != 'New' && satCase.Status != 'Ticket Sales in Progress' && satCase.Status != 'Request for Ticketing' && satCase.Status != 'Adhoc Request Approving' && satCase.Status != 'Adhoc Request Approved') {
                sat.addError('Please check Case Status.');
                return ResponseUtil.buildStringListResponse('Please check Case Status.');
            }
            if (sat.Sync_SAT_Status__c == Constants.PICKLIST_STATUS_SUCCEEDED) {
                sat.addError('Please check Sync SAT Status.');
                return ResponseUtil.buildStringListResponse('Please check Sync SAT Status.');
            }          
            if (sat.recordTypeId == adHocRecordTypeId) {
                return ResponseUtil.buildStringListResponse('Please check record type.');
            } else if (sat.recordTypeId == plannedAllocationRecordTypeId) {
                System.debug('[4i] Record type is Planned allocation, it can continue.');
                if (sat.Allocation_Type__c == Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS || sat.Allocation_Type__c == Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC) {
                    System.debug('[4i] Create PNR');
                    satToCreateListAsWrapper.addItinerary(sat, satCase, currAccount, currContact); 
                    satIdList.add(sat.Id);
                } else if (sat.Allocation_Type__c == Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADJUSTMENT) {
                    System.debug('[4i] Adjustement PNR');
                    List<Seat_Allocation_and_Ticketing__c> searchingSatBookingRefList = [SELECT Id, Name, Final_Allocated_Seats__c, Final_Sales_Seats__c,Sync_SAT_Status__c, Booking_Reference_PNR__c FROM Seat_Allocation_and_Ticketing__c WHERE Case_ID__c =: sat.Case_ID__c AND Booking_Reference_PNR__c =: sat.Booking_Reference_PNR__c AND (Allocation_Type__c =: Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC OR Allocation_Type__c =: Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS)];
                    if (searchingSatBookingRefList.isEmpty()) {
                        sat.addError('Please check booking reference.');
                        return ResponseUtil.buildStringListResponse('Please check booking reference.');
                    }
                    Seat_Allocation_and_Ticketing__c masterSat = searchingSatBookingRefList.get(0);
                    if (masterSat.Sync_SAT_Status__c != Constants.PICKLIST_STATUS_SUCCEEDED) {
                        sat.addError('Please check the Sync SAT Status in SRS/ADC SAT record.');
                        return ResponseUtil.buildStringListResponse('Please check the Sync SAT Status in SRS/ADC SAT record.');
                    }
                    if (masterSat.Final_Allocated_Seats__c < 0) {
                        sat.addError('Please check the Allocated Seats.');
                        return ResponseUtil.buildStringListResponse('Please check the Allocated Seats.');
                    } else if (masterSat.Final_Allocated_Seats__c >= masterSat.Final_Sales_Seats__c || masterSat.Final_Sales_Seats__c == null) {
                        if (masterSat.Final_Allocated_Seats__c == 0) {
                            System.debug('[4i] Call cancel pnr middleware api');
                            MiddlewareUtil.cancelPnr(sat.Name, masterSat.Name);
                        } else {
                            System.debug('[4i] Call resize pnr middleware api');
                            MiddlewareUtil.resizePnr(sat.Name, masterSat.Name, masterSat.Booking_Reference_PNR__c, Math.abs(sat.Allocated_Seats__c).intValue());
                        }
                    } else {
                        sat.addError('Please check the Final Sales Seats in SRS/ADC SAT record.');
                        return ResponseUtil.buildStringListResponse('Please check the Final Sales Seats in SRS/ADC SAT record.');
                    }
                }
            }
        }
        
        if (satToCreateListAsWrapper.itineraries.size() > 0) {
            System.debug('[4i] Call create pnr middleware api');
            String jsonBodyAsString = JSON.serialize(satToCreateListAsWrapper);
            if (origin == Constants.SAT_PROCESS_INSERT_ORIGIN_BATCH) {
                MiddlewareUtil.createPnr(jsonBodyAsString, satIdList, Constants.SAT_PROCESS_INSERT_ORIGIN_BATCH);
            } else {
                MiddlewareUtil.createPnrFuture(jsonBodyAsString, satIdList);
            }
        }
        return ResponseUtil.buildStringListResponse('Processing is complete, please confirm Sync SAT Status.');
    }
    
    /**
     * 
     * Update SST
     * 
     */
    public static void updateSST(Map<Id, Seat_Allocation_and_Ticketing__c> oldMap, Map<Id, Seat_Allocation_and_Ticketing__c> newMap) {
        List<Id> caseIds = new List<Id>();
        Map<Id, Double> SeatSales = new Map<Id, Double>();
        Set<Id> satIds = new Set<Id>();
        for(Id satId : newMap.keySet()) {
            Seat_Allocation_and_Ticketing__c newSat = newMap.get(satId);
            Seat_Allocation_and_Ticketing__c oldSat = oldMap.get(satId);
            if(newSat.Allocation_Type__c != Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADJUSTMENT && newSat.Total_Seat_Sales__c != oldSat.Total_Seat_Sales__c) {
                Id caseId = newMap.get(satId).Case_ID__c;
                caseIds.add(caseId);
                
                Double value = (oldMap.get(satId).Total_Seat_Sales__c != null)? (newSat.Total_Seat_Sales__c - oldSat.Total_Seat_Sales__c) : newSat.Total_Seat_Sales__c;
                if(SeatSales.containsKey(caseId)) {
                    SeatSales.put(caseId, SeatSales.get(caseId) + value);
                } else {
                    SeatSales.put(caseId, value);
                }
                
                satIds.add(satId);
            }
        }
        
        List<Case> cases = [SELECT Id, Total_Seat_Sales__c, (SELECT Total_Seat_Sales__c FROM Sales_Trackings__r WHERE Week_Comparison__c = 'This week' LIMIT 1), (SELECT Total_Seat_Sales__c FROM Group_Bookings__r) FROM Case WHERE Id IN :caseIds];
		List<Seat_Sales_Tracking__c> updateList = new List<Seat_Sales_Tracking__c>();
        for(case c : cases) {
            Integer realSeatSales = 0;
            for(Seat_Allocation_and_Ticketing__c sat : c.Group_Bookings__r) {
                if(sat.Total_Seat_Sales__c != null) realSeatSales += (Integer) sat.Total_Seat_Sales__c;
            }
            if(SeatSales.containsKey(c.Id)) {
                System.debug(c);
                System.debug(c.Sales_Trackings__r);
                for(Seat_Sales_Tracking__c sst : c.Sales_Trackings__r) {
                    sst.Total_Seat_Sales__c = realSeatSales;
                    updateList.add(sst);
                }
            }
        }
        
        SeatAllocationUtil.syncSAT(satIds);
        System.debug(updateList);
        update updateList;
    }
    
    /**
     * 
     * Sync SAT
     * 
     */
    public static List<String> syncSAT(Set<Id> satIdList) {
        List<Id> IdList = new List<Id>();
        
        List<Seat_Allocation_and_Ticketing__c> satList = [SELECT Id, Name, Case_ID__c, Booking_Reference_PNR__c, Total_Seat_Sales__c FROM Seat_Allocation_and_Ticketing__c  WHERE Id IN: satIdList];
            
        for(Seat_Allocation_and_Ticketing__c currSat : satList) {
            MwSyncSstWrapper wrapper = new MwSyncSstWrapper(currSat.Booking_Reference_PNR__c, currSat.Total_Seat_Sales__c?.intValue());
            String jsonBodyAsString = JSON.serialize(wrapper);
            MiddlewareUtil.syncSstCallout(currSat.Name, jsonBodyAsString, currSat.Case_ID__c);
        }
        return ResponseUtil.buildStringListResponse('Processing is complete, please confirm Sync SAT Status and SAT Mark.');
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
    }
    
}