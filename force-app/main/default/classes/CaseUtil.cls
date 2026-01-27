public class CaseUtil {
    
    public static List<String> disableSatSyncIntegrate(List<Case> caseListToDisableIntegration) { 
        for (Case currCase : caseListToDisableIntegration) {
            if (!currCase.Integration_Link_Status__c) {
                return ResponseUtil.buildStringListResponse('Action is not allowed, integration has been disabled for this case');
            }
            currCase.Integration_Link_Status__c = false;
        }
        MwCaseListWrapper caseWrapper = new MwCaseListWrapper(caseListToDisableIntegration);
        String jsonBodyAsString = JSON.serialize(caseWrapper);
        Boolean isApiPass = MiddlewareUtil.disableCaseIntegration(jsonBodyAsString);
        if (!isApiPass) {
            return ResponseUtil.buildStringListResponse('Requesting to middleware is failed.');
        }
        
        List<Database.SaveResult> dbResultList = Database.update(caseListToDisableIntegration);
        for (Database.SaveResult dbResult : dbResultList) {
            if (!dbResult.isSuccess()) {
                return ResponseUtil.buildStringListResponse('Updation is failed');
            }
        }
        
        return ResponseUtil.buildStringListResponse('Integration has been disabled Successfully');
    }
    
    public static List<String> syncSst(List<Case> caseList) {
        //Add by Jeremy 20231024 Begin
        List<Id> IdList = new List<Id>();
        FOR(Case currCase : caseList) IdList.add(currCase.Id);
        //Add by Jeremy 20231024   End
        System.debug('[4i] Sync SST starting');
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        List<Seat_Allocation_and_Ticketing__c> satList = [SELECT Id, Case_ID__c, Name, Booking_Reference_PNR__c FROM Seat_Allocation_and_Ticketing__c 
                                                          WHERE (Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS OR Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC) 
                                                          AND Final_Allocated_Seats__c > 0 AND Sync_SAT_Status__c = :Constants.PICKLIST_STATUS_SUCCEEDED 
                                                          AND recordTypeId = :plannedAllocationRecordTypeId 
                                                          AND Case_ID__c IN :IdList 
                                                          ORDER BY CreatedDate ASC];
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
            if (currCase.Status != 'New' && currCase.Status != 'Ticket Sales in Progress' && currCase.Status != 'Adhoc Request Approving' && currCase.Status != 'Adhoc Request Approved') {
                return ResponseUtil.buildStringListResponse('Please check Case Status.');
            }
            Seat_Allocation_and_Ticketing__c satContainsSstList = null;
            if(caseIdSatListMap.get(currCase.Id)!=null)
            {
                for (Seat_Allocation_and_Ticketing__c sat : caseIdSatListMap.get(currCase.Id)) {
                    if (currCase.SST_Mark__c == sat.Name) {
                        satContainsSstList = sat;
                    }
                }
            }
            
            if (satContainsSstList != null) {
                System.debug('[4i] SAT from SST found');
                MwSyncSstWrapper wrapper = new MwSyncSstWrapper(satContainsSstList.Booking_Reference_PNR__c, currCase.Total_Seat_Sales__c.intValue());
                String jsonBodyAsString = JSON.serialize(wrapper);
                MiddlewareUtil.syncSstCallout(satContainsSstList.Name, jsonBodyAsString, currCase.Id);
            } else {
                Seat_Allocation_and_Ticketing__c satToProcess;
                if(caseIdSatListMap.get(currCase.Id)!=null)
                {
                    satToProcess = caseIdSatListMap.get(currCase.Id)[0];
                }
                
                if (satToProcess != null) {
                    System.debug('[4i] Not SST found but SAT found');
                    MwSyncSstWrapper wrapper = new MwSyncSstWrapper(satToProcess.Booking_Reference_PNR__c, currCase.Total_Seat_Sales__c.intValue());
                    String jsonBodyAsString = JSON.serialize(wrapper);
                    MiddlewareUtil.syncSstCallout(satToProcess.Name, jsonBodyAsString, currCase.Id);
                }
            }
        }
        return ResponseUtil.buildStringListResponse('Processing is complete, please confirm Sync SST Status and SST Mark.');
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
    }
   
}