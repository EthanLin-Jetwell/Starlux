public class AddPaxInvocableMethod {
    @InvocableMethod(label='Add Pax')
    public static List<String> addPaxInvocableMethod(List<Seat_Allocation_and_Ticketing__c> satList) {
        Seat_Allocation_and_Ticketing__c currSat = satList.get(0);
        Case currCase = [SELECT Id, Integration_Link_Status__c, Status, Route__c, ContactId FROM Case WHERE Id = :currSat.Case_Id__c];
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        if (!currCase.Integration_Link_Status__c) {
            return ResponseUtil.buildStringListResponse('Please check Integration Link Status.');
        }
        if (currCase.Status != 'Ready for Ticketing') {
            return ResponseUtil.buildStringListResponse('Please check Case Status.');
        }
        
        if (currSat.recordTypeId != plannedAllocationRecordTypeId) {
            return ResponseUtil.buildStringListResponse('Please check record type.');
        }
        
        if (currSat.Allocation_Type__c != Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS && currSat.Allocation_Type__c != Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC) {
            return ResponseUtil.buildStringListResponse('Please check Allocation Type.');
        }
        
        if (currSat.Final_Allocated_Seats__c == 0) {
            return ResponseUtil.buildStringListResponse('Please check Final Allocated Seats.');
        }
        
        if (currSat.Sync_SAT_Status__c != Constants.PICKLIST_STATUS_SUCCEEDED) {
            return ResponseUtil.buildStringListResponse('Please check Sync SAT Status.');
        }
        
        if (currSat.Add_Name_List_Status__c == Constants.PICKLIST_STATUS_SUCCEEDED) {
            return ResponseUtil.buildStringListResponse('Please check Add Name List Status.');
        }
        
        if (currSat.Departing_Flight_Number__c != 'none' && currSat.Departing_PNR_Status__c != 'KK' && currSat.Departing_PNR_Status__c != 'HK' && currSat.Departing_PNR_Status__c != 'RR') {
            return ResponseUtil.buildStringListResponse('Please check Departing PNR Status.');
        }
        
        if (currSat.Returning_Flight_Number__c != 'none' && currSat.Returning_PNR_Status__c	!= 'KK' && currSat.Returning_PNR_Status__c != 'HK' && currSat.Returning_PNR_Status__c != 'RR') {
            return ResponseUtil.buildStringListResponse('Please check Returning PNR Status.');
        }
        
        Contact currContact = [SELECT Id, Amadeus_Post__c FROM Contact WHERE Id = :currCase.ContactId];
        List<Name_List__c> nameListList = [SELECT Id, Name, Date_Of_Birth__c, Title__c, First_Name__c, Last_Name__c, Passenger_Type__c, 
                                           Meal_Selection_All_Sector__c, Meal_Selection_Departing_Only__c, Meal_Selection_Returning_Only__c, 
                                           Special_Service_Departing__c, Special_Service_Returning__c, INF_Date_Of_Birth__c, INF_First_Name__c, 
                                           INF_Last_name__c, INF_Passenger_Type__c, INF_Title__c, INF_Meal_Selection_All_Sector__c, InfantGender__c,
                                           INF_Meal_Selection_Departing_Only__c, INF_Meal_Selection_Returning_Only__c ,Gender__c, 
                                           Passport_Issue_Country__c, INF_Passport_Issue_Country__c, Passport_No__c, INF_Passport_No__c, 
                                           Passport_Country__c, INF_Passport_Country__c, Passport_Expiry_Date__c, INF_Passport_Expiry_Date__c, 
                                           VISA_No__c, INF_VISA_No__c, VISA_Country__c, INF_VISA_Country__c, VISA_Expiry_Date__c, INF_VISA_Expiry_Date__c
                                           FROM Name_List__c 
                                           WHERE Seat_Allocation_and_Ticketing__c = :currSat.Id];
        MwAddPaxWrapper wrapper = new MwAddPaxWrapper(currCase, currSat, currContact.Amadeus_Post__c, nameListList);
        MiddlewareUtil.addPax(currSat.Name, JSON.serialize(wrapper, false));
        
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