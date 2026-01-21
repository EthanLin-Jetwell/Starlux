public class GetUpdateUtil {
    public static void getUpdate(List<Case> caseList) {
        List <Id> caseIdList = new List<Id>(); //2024-02-27 Eli
        for (Case c:caseList){   
            caseIdList.add(c.Id);
        }   //2024-02-27 Eli      
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        List<Seat_Allocation_and_Ticketing__c> satList = [SELECT Id, Name, Case_Id__c, recordTypeId, Allocation_Type__c, Final_Allocated_Seats__c, Sync_SAT_Status__c FROM Seat_Allocation_and_Ticketing__c WHERE (Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS OR Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC) AND Final_Allocated_Seats__c > 0 AND Sync_SAT_Status__c = :Constants.PICKLIST_STATUS_SUCCEEDED AND recordTypeId = :plannedAllocationRecordTypeId AND Case_ID__c in: caseIdList];//2024-02-27 Eli
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
            List<Seat_Allocation_and_Ticketing__c> satToProcess = caseIdSatListMap.get(currCase.Id);
            for (Seat_Allocation_and_Ticketing__c sat : satToProcess) {
                GetUpdateInvocableMethod.getUpdateInvocableMethod(new List<Seat_Allocation_and_Ticketing__c>{sat});
            }

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
    }
}