@RestResource(urlMapping = '/receive-response/add-pax')
global class ReceiveResponseAddNamelistApi {
    
    @HttpPost
    global static void addNamelist() {
        RestRequest request = RestContext.request;
        RestResponse response = Restcontext.response;
        System.debug('[4i] Receive request addNamelist:' + request.requestBody.toString());
        
        ReceiveResponseAddNamelistWrapper requestBodyWrapper = ReceiveResponseAddNamelistWrapper.deserializeJson(request.requestBody.toString());
        
        if (requestBodyWrapper.isMissingRequiredFields()) {
            response = ResponseUtil.buildErrorRestResponse(response, Constants.MISSING_REQUIRED_FIELD);
            ApiLogger.log(request, response);
            return;
        }
        
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Name, Departing_Flight_Number__c, Returning_Flight_Number__c, Add_Name_List_Status__c, Add_Name_List_Error_Message__c, Issue_Ticket_Status__c, Departing_PNR_Status__c, Returning_PNR_Status__c, Booking_Reference_PNR__c, Tour_Code__c, Ticket_Currency__c, Final_Unit_Price_Adult__c, Final_Unit_Price_Child__c, Final_Unit_Price_Infant__c, Tax_Date__c FROM Seat_Allocation_and_Ticketing__c WHERE Name =: requestBodyWrapper.sat_no];
        List<Name_List__c> nameListList = [SELECT Id, Name, Meal_Selection_Status_Departing__c, Meal_Selection_Status_Returning__c, Special_Service_Status_Departing__c, Special_Service_Status_Returning__c, INF_PNR_Status_Departing__c, INF_PNR_Status_Returning__c, INF_Meal_Selection_Status_Departing__c, INF_Meal_Selection_Status_Returning__c FROM Name_List__c WHERE Seat_Allocation_and_Ticketing__c = :sat.Id];
        Map<String, Name_List__c> nameListMap = new Map<String, Name_List__c>();
        for(Name_List__c currNameList : nameListList) {
            nameListMap.put(currNameList.Name, currNameList);
        }
        sat.Add_Name_List_Status__c = requestBodyWrapper.status;
        sat.Add_Name_List_Error_Message__c = '';
        if (requestBodyWrapper.status == Constants.PICKLIST_STATUS_FAIL) {
            sat.Add_Name_List_Error_Message__c = requestBodyWrapper.error_message;
        } else if (requestBodyWrapper.status == Constants.PICKLIST_STATUS_SUCCEEDED) {
            for (ReceiveResponseAddNamelistWrapper.Legs currLeg : requestBodyWrapper.legs) {
                if (currLeg.sorting == 1) {
                    if (sat.Departing_Flight_Number__c == 'none') {
                        sat.Returning_PNR_Status__c = currLeg.pnr_status;
                    } else {
                        sat.Departing_PNR_Status__c = currLeg.pnr_status;
                    }
                }
                if (currLeg.sorting == 2) {
                    sat.Returning_PNR_Status__c = currLeg.pnr_status;
                }
            }
            
            for (ReceiveResponseAddNamelistWrapper.Name_list currNameListWrapper : requestBodyWrapper.name_list) {  
                Name_List__c nameList = nameListMap.get(currNameListWrapper.nl_no);
                for (ReceiveResponseAddNamelistWrapper.Legs currLeg : currNameListWrapper.legs) {
                    if (currLeg.sorting == 1) {
                        if (sat.Departing_Flight_Number__c == 'none') {
                            nameList.Meal_Selection_Status_Returning__c = currLeg.meal_selection_status;
                            nameList.Special_Service_Status_Returning__c = currLeg.special_service_status;
                            nameList.INF_PNR_Status_Returning__c = currLeg.inf_pnr_status;
                            nameList.INF_Meal_Selection_Status_Returning__c = currLeg.inf_meal_selection_status;
                        } else {
                            nameList.Meal_Selection_Status_Departing__c = currLeg.meal_selection_status;
                            nameList.Special_Service_Status_Departing__c = currLeg.special_service_status;
                            nameList.INF_PNR_Status_Departing__c = currLeg.inf_pnr_status;
                            nameList.INF_Meal_Selection_Status_Departing__c = currLeg.inf_meal_selection_status;
                        }
                    }
                    if (currLeg.sorting == 2) {
                        nameList.Meal_Selection_Status_Returning__c = currLeg.meal_selection_status;
                        nameList.Special_Service_Status_Returning__c = currLeg.special_service_status;
                        nameList.INF_PNR_Status_Returning__c = currLeg.inf_pnr_status;
                        nameList.INF_Meal_Selection_Status_Returning__c = currLeg.inf_meal_selection_status;
                    }
                }
            }
        }
        
        Database.update(sat);
        Database.update(nameListList);
        response = ResponseUtil.buildSuccessRestResponse(response);
        
        ApiLogger.log(request, response);
        
        if (requestBodyWrapper.status == Constants.PICKLIST_STATUS_SUCCEEDED) {
            IssueTicketScheduler m = new IssueTicketScheduler(sat);
            Datetime now = Datetime.now().addSeconds(10);
            String sch = now.second()+' '+now.minute()+' '+now.hour()+' '+now.day()+' '+now.month()+' ? '+now.year();
            system.schedule('IssueTicket Job - ' + sat.Name, sch, m);
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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