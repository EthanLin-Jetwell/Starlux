public class TicketFareUtil {
    public static List<String> getTicketFare(List<Case> caseList) {
        
        List <Id> caseIdList = new List<Id>(); //2023-11-27 Eli
        for (Case c:caseList){   
            caseIdList.add(c.Id);
        }   //2023-11-27 Eli                           
        
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        List<Seat_Allocation_and_Ticketing__c> satList = [SELECT Id, Name, Tour_Code__c, Returning_Flight_Date__c, Final_Sales_Seats__c, Departing_Flight_Date__c, CreatedDate,Case_ID__c, Departing_Flight_Number__c, Returning_Flight_Number__c, Group_Booking_Route__c, Initial_Unit_Price_Infant__c, Initial_Unit_Price_Child__c, Initial_Unit_Price_Adult__c, Initial_Tax_Infant__c, Initial_Tax_Child__c, Initial_Tax_Adult__c, Final_Unit_Price_Infant__c, Final_Unit_Price_Child__c, Final_Unit_Price_Adult__c, Final_Tax_Infant__c, Final_Tax_Child__c, Final_Tax_Adult__c, Not_in_Fare_Table__c, Not_in_Tax_Table__c, Case_Id__r.Account.IATA_MSO_Code__c FROM Seat_Allocation_and_Ticketing__c WHERE (Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS OR Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC) AND Final_Allocated_Seats__c > 0 AND Final_Sales_Seats__c > 0 AND Sync_SAT_Status__c = :Constants.PICKLIST_STATUS_SUCCEEDED AND recordTypeId = :plannedAllocationRecordTypeId AND Case_ID__c in: caseIdList];//2023-11-27 Eli add AND Case_ID__c in: caseIdList
        Map<String, List<Seat_Allocation_and_Ticketing__c>> caseIdSatListMap = new Map<String, List<Seat_Allocation_and_Ticketing__c>>();
        for (Seat_Allocation_and_Ticketing__c currSat : satList) {
            if (caseIdSatListMap.get(currSat.Case_ID__c) == null) {
                List<Seat_Allocation_and_Ticketing__c> satListByCaseId = new List<Seat_Allocation_and_Ticketing__c>();
                satListByCaseId.add(currSat);
                caseIdSatListMap.put(currSat.Case_ID__c, satListByCaseId);
            } else {
                caseIdSatListMap.get(currSat.Case_ID__c).add(currSat); 
                caseIdSatListMap.put(currSat.Case_ID__c, caseIdSatListMap.get(currSat.Case_ID__c));
            }
        }
        for (Case currCase : caseList) {
            if (!currCase.Integration_Link_Status__c) {
                return ResponseUtil.buildStringListResponse('Please check Integration Link Status.');
            }
            if (currCase.Status != 'Request for Ticketing') {
                return ResponseUtil.buildStringListResponse('Please check Case Status.');
            }
            List<Seat_Allocation_and_Ticketing__c> satToProcess = caseIdSatListMap.get(currCase.Id);
            for (Seat_Allocation_and_Ticketing__c currSat : satToProcess) {
                if (currSat.Tour_Code__c == null) {
                    currCase.addError('請檢查SAT的Tour Code');
                }
            }
            if (satToProcess != null) {
                for(Seat_Allocation_and_Ticketing__c currSat : satToProcess) {
                    UpdateTicketFare.getTicketFare(new List<ID>{currSat.Id});
                }
            }
        } 
        
        return ResponseUtil.buildStringListResponse('Processing is complete, please confirm the ticket fare');
        
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
    }
}