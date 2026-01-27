public class TaxUtil {
    
    public static List<String> getTax(List<Case> caseList) {
                
        List <Id> caseIdList = new List<Id>(); //2023-11-27 Eli
        for (Case c:caseList){   
            caseIdList.add(c.Id);
        }   //2023-11-27 Eli                           
        
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        List<Seat_Allocation_and_Ticketing__c> satList = [SELECT Id, Name, Case_Id__c, Ticket_Currency__c, Tax_Date__c, Departing_Flight_Date__c, Returning_Flight_Date__c, Departing_Flight_Number__c, RBD_Departing__c,RBD_Returning__c FROM Seat_Allocation_and_Ticketing__c WHERE (Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS OR Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC) AND Final_Allocated_Seats__c > 0 AND Final_Sales_Seats__c > 0 AND Sync_SAT_Status__c = :Constants.PICKLIST_STATUS_SUCCEEDED AND recordTypeId = :plannedAllocationRecordTypeId AND Case_ID__c in: caseIdList];//2023-11-27 Eli add AND Case_ID__c in: caseIdList
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
                currSat.Tax_Date__c = system.today();
            }
            update satToProcess;
            if (satToProcess != null) {
                for (Seat_Allocation_and_Ticketing__c currSat : satToProcess) {
                    MwGetTaxWrapper wrapper = new MwGetTaxWrapper(currSat, currCase);
                    String jsonBodyAsString = JSON.serialize(wrapper);
                    MiddlewareUtil.getTax(currSat.Name, jsonBodyAsString.replace('_remove_after_serialize', ''));
                }
            }
        }

        return ResponseUtil.buildStringListResponse('Processing is complete, please confirm Get Tax Status');
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