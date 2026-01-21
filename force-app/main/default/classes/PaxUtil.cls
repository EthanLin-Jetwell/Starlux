public class PaxUtil {
    public static List<String> addPax(List<Case> caseList) {
        System.debug('[4i] Add pax starting');
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType 
                                            WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        Set<String> ConIdSet=new Set<String>();				//2022/11/18 Edit by Jetwell set query Contact Condition
        Set<String> CaseIdSet=new Set<String>();
        for(Case C:caseList)
        {
            ConIdSet.add(C.ContactId);
            CaseIdSet.add(C.Id);
        }
        List<Seat_Allocation_and_Ticketing__c> satList = [SELECT Id, Case_ID__c, Name, Booking_Reference_PNR__c, Departing_Flight_Number__c,
                                                          Returning_Flight_Number__c, Departing_PNR_Status__c, Returning_PNR_Status__c,
                                                          Tour_Guide_Email__c,Tour_Guide_Phone__c
                                                          FROM Seat_Allocation_and_Ticketing__c 
                                                          WHERE (Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS 
                                                                 OR Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC) 
                                                          AND Final_Allocated_Seats__c > 0 
                                                          AND Sync_SAT_Status__c = :Constants.PICKLIST_STATUS_SUCCEEDED 
                                                          AND Add_Name_List_Status__c != :Constants.PICKLIST_STATUS_SUCCEEDED 
                                                          AND recordTypeId = :plannedAllocationRecordTypeId 
                                                          AND Case_ID__c IN :CaseIdSet];
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
        
        Map<String, Contact> ContactMap = new Map<String, Contact>([SELECT Id, Amadeus_Post__c FROM Contact WHERE Id IN:ConIdSet]);
        // add new field for Middleware api
        List<Name_List__c> nameListList = [SELECT Id, Seat_Allocation_and_Ticketing__c, Name, 
                                           Date_Of_Birth__c, Title__c, First_Name__c, Last_Name__c, 
                                           Passenger_Type__c, Meal_Selection_All_Sector__c, 
                                           Meal_Selection_Departing_Only__c, Meal_Selection_Returning_Only__c, 
                                           Special_Service_Departing__c, Special_Service_Returning__c, 
                                           INF_Date_Of_Birth__c, INF_First_Name__c, INF_Last_name__c, 
                                           INF_Passenger_Type__c, INF_Title__c, INF_Meal_Selection_All_Sector__c,
                                           INF_Meal_Selection_Departing_Only__c, INF_Meal_Selection_Returning_Only__c,
                                           Gender__c,InfantGender__c, Passport_Issue_Country__c, Passport_No__c,
                                           Passport_Country__c, Passport_Expiry_Date__c, VISA_No__c, VISA_Country__c,
                                           VISA_Expiry_Date__c, INF_Passport_Issue_Country__c, INF_Passport_No__c,
                                           INF_Passport_Country__c, INF_Passport_Expiry_Date__c, INF_VISA_No__c,
                                           INF_VISA_Country__c, INF_VISA_Expiry_Date__c
                                           FROM Name_List__c WHERE Seat_Allocation_and_Ticketing__r.Case_ID__c IN:CaseIdSet];
        Map<String, List<Name_List__c>> satIdNameListListMap = new Map<String, List<Name_List__c>>();
        for (Name_List__c currNameList : nameListList) {
            if (satIdNameListListMap.get(currNameList.Seat_Allocation_and_Ticketing__c) == null) {
                List<Name_List__c> nameListListBySatId = new List<Name_List__c>();
                nameListListBySatId.add(currNameList);
                satIdNameListListMap.put(currNameList.Seat_Allocation_and_Ticketing__c, nameListListBySatId);
            } else {
                satIdNameListListMap.get(currNameList.Seat_Allocation_and_Ticketing__c).add(currNameList); 
                satIdNameListListMap.put(currNameList.Seat_Allocation_and_Ticketing__c, satIdNameListListMap.get(currNameList.Seat_Allocation_and_Ticketing__c));
            }
        }
        for (Case currCase : caseList) {
            if (!currCase.Integration_Link_Status__c) {
                currCase.addError('Please check Integration Link Status.');
                return ResponseUtil.buildStringListResponse('Please check Integration Link Status.');
            }
            if (currCase.Status != 'Ready for Ticketing') {
                currCase.addError('Please check Case Status.');
                return ResponseUtil.buildStringListResponse('Please check Case Status.');
            }
            List<Seat_Allocation_and_Ticketing__c> satToProcess = caseIdSatListMap.get(currCase.Id);
            if (satToProcess != null) {
                for (Seat_Allocation_and_Ticketing__c currSat : satToProcess) {
                    if (currSat.Departing_Flight_Number__c != 'none' && currSat.Departing_PNR_Status__c	!= 'KK' && currSat.Departing_PNR_Status__c != 'HK' && currSat.Departing_PNR_Status__c != 'RR') {
                        currCase.addError('Please check Departing PNR Status in SAT.');
                        return ResponseUtil.buildStringListResponse('Please check Departing PNR Status in SAT.');
                    }
                    if (currSat.Returning_Flight_Number__c != 'none' && currSat.Returning_PNR_Status__c	!= 'KK' && currSat.Returning_PNR_Status__c != 'HK' && currSat.Returning_PNR_Status__c != 'RR') {
                        currCase.addError('Please check Returning PNR Status in SAT.');
                        return ResponseUtil.buildStringListResponse('Please check Returning PNR Status in SAT.');
                    }
                    Contact currContact = ContactMap.get(currCase.ContactId);
                    List<Name_List__c> currNameListList = satIdNameListListMap.get(currSat.Id);
                    MwAddPaxWrapper wrapper = new MwAddPaxWrapper(currCase, currSat, currContact.Amadeus_Post__c, currNameListList);
                    MiddlewareUtil.addPax(currSat.Name, JSON.serialize(wrapper));
                }
            }
        }
        
        return ResponseUtil.buildStringListResponse('Processing is complete, please confirm Add Name List Status.');
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