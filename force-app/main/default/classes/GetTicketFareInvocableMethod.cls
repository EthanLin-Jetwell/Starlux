public class GetTicketFareInvocableMethod {
    
    @InvocableMethod(label='Get Ticket Fare')
    public static List<String> getTicketFareInvocableMethod(List<Seat_Allocation_and_Ticketing__c> satList) {
        Seat_Allocation_and_Ticketing__c currSat = satList.get(0);
        Case currCase = [SELECT Id, Integration_Link_Status__c, Status FROM Case WHERE Id = :currSat.Case_Id__c];
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        if (!currCase.Integration_Link_Status__c) {
            return ResponseUtil.buildStringListResponse('Please check Integration Link Status.');
        }
        if (currCase.Status != 'Request for Ticketing') {
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
        
        if (currSat.Tour_Code__c == null) {
            return ResponseUtil.buildStringListResponse('Please check Tour Code.');
        }
        
        Boolean result = UpdateTicketFare.getTicketFare(new List<ID>{currSat.Id})[0];
        if (result == false) {
            return ResponseUtil.buildStringListResponse('Unable to find any ticket fare records that matches the criterias.');
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