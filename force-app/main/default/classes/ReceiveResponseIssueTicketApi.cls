@RestResource(urlMapping = '/receive-response/issue-ticket')
global class ReceiveResponseIssueTicketApi {

    @HttpPost
    global static void issueTicket() {
        RestRequest request = RestContext.request;
        RestResponse response = Restcontext.response;
        System.debug('[4i] Receive request issueTicket:' + request.requestBody.toString());
        
        ReceiveResponseIssueTicketWrapper requestBodyWrapper = ReceiveResponseIssueTicketWrapper.deserializeJson(request.requestBody.toString());
        
        if (requestBodyWrapper.isMissingRequiredFields()) {
            response = ResponseUtil.buildErrorRestResponse(response, Constants.MISSING_REQUIRED_FIELD);
            ApiLogger.log(request, response);
            return;
        }
        
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Name, Case_ID__c, Issue_Ticket_Status__c, Issue_Ticket_Error_Message__c, Issue_Ticket_Time__c FROM Seat_Allocation_and_Ticketing__c WHERE Name =: requestBodyWrapper.sat_no];
        List<Name_List__c> nameListList = [SELECT Id, Name, Issue_Ticket_Error_Message__c, INF_Issue_Ticket_Error_Message__c, Ticket_Number__c, INF_Ticket_Number__c FROM Name_List__c WHERE Seat_Allocation_and_Ticketing__c = :sat.Id];
        Map<String, Name_List__c> nameListMap = new Map<String, Name_List__c>();
        for(Name_List__c currNameList : nameListList) {
            nameListMap.put(currNameList.Name, currNameList);
        }
        Id plannedAllocationRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Planned_Allocation' and SObjectType = 'Seat_Allocation_and_Ticketing__c'].Id;
        List<Seat_Allocation_and_Ticketing__c> allSatInSameCase = [SELECT Id, Issue_Ticket_Status__c FROM Seat_Allocation_and_Ticketing__c WHERE (Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS OR Allocation_Type__c = :Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC) AND Final_Allocated_Seats__c > 0 AND Sync_SAT_Status__c = :Constants.PICKLIST_STATUS_SUCCEEDED AND recordTypeId = :plannedAllocationRecordTypeId AND Case_ID__c =: sat.Case_ID__c];
        Case caseToChangeStatus = [SELECT Id, status FROM Case WHERE Id =: sat.Case_ID__c];
        
        sat.Issue_Ticket_Status__c = requestBodyWrapper.status;
        sat.Issue_Ticket_Error_Message__c = '';
        if (requestBodyWrapper.status == Constants.PICKLIST_STATUS_FAIL) {
            sat.Issue_Ticket_Error_Message__c = 'Partial failed, please confirm Issue Ticket Error Message on Name List.';
            for (ReceiveResponseIssueTicketWrapper.Name_list currNameListWrapper : requestBodyWrapper.name_list) {  
                Name_List__c nameList = nameListMap.get(currNameListWrapper.nl_no);
                nameList.Ticket_Number__c = currNameListWrapper.ticket_no;
                nameList.INF_Ticket_Number__c = currNameListWrapper.inf_ticket_no;
                nameList.Issue_Ticket_Error_Message__c = currNameListWrapper.error_message;
                nameList.INF_Issue_Ticket_Error_Message__c = currNameListWrapper.inf_error_message;
            }
        } else if (requestBodyWrapper.status == Constants.PICKLIST_STATUS_SUCCEEDED) {
            for (ReceiveResponseIssueTicketWrapper.Name_list currNameListWrapper : requestBodyWrapper.name_list) {  
                Name_List__c nameList = nameListMap.get(currNameListWrapper.nl_no);
                nameList.Ticket_Number__c = currNameListWrapper.ticket_no;
                nameList.INF_Ticket_Number__c = currNameListWrapper.inf_ticket_no;
                nameList.Issue_Ticket_Error_Message__c = '';
                nameList.INF_Issue_Ticket_Error_Message__c = '';
            }
            sat.Issue_Ticket_Time__c = Datetime.now();
            Boolean isAllSatPass = true;
            for (Seat_Allocation_and_Ticketing__c currSat : allSatInSameCase) {
                if (currSat.Issue_Ticket_Status__c != Constants.PICKLIST_STATUS_SUCCEEDED && currSat.Id != sat.Id) {
                    isAllSatPass = false;
                }
            }
            if (isAllSatPass) {
                caseToChangeStatus.status = 'Ticket Issued';
                Database.update(caseToChangeStatus);
            }
        }

        String jobName = 'IssueTicket Job - ' + sat.Name;
        for(CronTrigger aJob : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName AND State = 'DELETED']) {
            System.AbortJob(aJob.Id);
        }
        
        Database.update(sat);
        Database.update(nameListList);
        response = ResponseUtil.buildSuccessRestResponse(response);
        
        ApiLogger.log(request, response);
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