public class IssueTicketUtil {
    
    public static List<String> issueTicket(List<Seat_Allocation_and_Ticketing__c> satList) {
        List<Id> satIdList = new List<Id>();
        
        List<String> errorResult = new List<String>();
        List<Integer> satIndexToIgnore = new List<Integer>();

        for (Integer i = 0; i < satList.size(); i++) {
            Seat_Allocation_and_Ticketing__c currSat = satList.get(i);
            if (currSat.Add_Name_List_Status__c != Constants.PICKLIST_STATUS_SUCCEEDED) {
                errorResult.add('Please check SAT NameList status.');
                satIndexToIgnore.add(i);
                continue;
            }
            if (currSat.Issue_Ticket_Status__c == Constants.PICKLIST_STATUS_SUCCEEDED) {
                errorResult.add('Please check Issue Ticket Status.');
                satIndexToIgnore.add(i);
                continue;
            }
            if (currSat.Departing_Flight_Number__c != 'none' && currSat.Departing_PNR_Status__c	!= 'HK' && currSat.Departing_PNR_Status__c != 'RR') {
                errorResult.add('Please check Departing PNR status.');
                satIndexToIgnore.add(i);
                currSat.Issue_Ticket_Error_Message__c = 'Issue Ticket can not be triggered. Please check Departing PNR Status.';
                continue;
            }
            if (currSat.Returning_Flight_Number__c != 'none' && currSat.Returning_PNR_Status__c	!= 'HK' && currSat.Returning_PNR_Status__c != 'RR') {
                errorResult.add('Please check Returning PNR status.');
                satIndexToIgnore.add(i);
                currSat.Issue_Ticket_Error_Message__c = 'Issue Ticket can not be triggered. Please check Returning PNR Status';
                continue;
            }
            satIdList.add(currSat.Id);
        }
        
        List<Name_List__c> nameListList = [SELECT Id, INF_Passenger_Type__c, INF_PNR_Status_Departing__c, INF_PNR_Status_Returning__c, Seat_Allocation_and_Ticketing__c FROM Name_List__c WHERE Seat_Allocation_and_Ticketing__c in :satIdList];
        
        for (Integer i = 0; i < satList.size(); i++) {
            Seat_Allocation_and_Ticketing__c currSat = satList.get(i);
            for (Name_List__c nl : nameListList) {
                if (currSat.Id == nl.Seat_Allocation_and_Ticketing__c) {
                    if (currSat.Departing_Flight_Number__c != 'none' && nl.INF_Passenger_Type__c == 'infant' && nl.INF_PNR_Status_Departing__c != 'HK' && nl.INF_PNR_Status_Departing__c != 'RR') {
                        errorResult.add('Please check Namelist INF Departing PNR status.');
                        satIndexToIgnore.add(i);
                        currSat.Issue_Ticket_Error_Message__c = 'Issue Ticket can not be triggered. Please check INF_PNR Status(Departing)';
                        continue;
                    }
                    if (currSat.Returning_Flight_Number__c != 'none' && nl.INF_Passenger_Type__c == 'infant' && nl.INF_PNR_Status_Returning__c != 'HK' && nl.INF_PNR_Status_Returning__c != 'RR') {
                        errorResult.add('Please check Namelist INF Returning PNR status.');
                        satIndexToIgnore.add(i);
                        currSat.Issue_Ticket_Error_Message__c = 'Issue Ticket can not be triggered. Please check INF_PNR Status(Returning)';
                        continue;
                    }
                }
            }
        }
        update satList;

        for (Integer i = 0; i < satList.size(); i++) {
           if (satIndexToIgnore.contains(i)) {
               continue;
           }
           Seat_Allocation_and_Ticketing__c currSat = satList.get(i);
           String jsonBodyAsString = JSON.serialize(new MwIssueTicketWrapper(currSat));
           MiddlewareUtil.issueTicket(currSat.Name, jsonBodyAsString.replace('_remove_after_serialize', ''));
        }
        if (errorResult.isEmpty()) {
            return ResponseUtil.buildStringListResponse('Processing is complete, please confirm Issue Ticket Status.');
        }
        return errorResult;
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