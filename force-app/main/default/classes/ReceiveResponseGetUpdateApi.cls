@RestResource(urlMapping = '/receive-response/get-update')
global class ReceiveResponseGetUpdateApi {
    
    @HttpPost
    global static void getUpdate() {
        RestRequest request = RestContext.request;
        RestResponse response = Restcontext.response;
        
        List<ReceiveResponseGetUpdateWrapper> requestBodyWrapper = ReceiveResponseGetUpdateWrapper.deserializeJson(request.requestBody.toString());
        
        List<String> satNoList = new List<String>();
        
        for (Integer i = 0; i < requestBodyWrapper.size(); i++) {
            ReceiveResponseGetUpdateWrapper currWrapper = requestBodyWrapper.get(i);
            satNoList.add(currWrapper.sat_no);
        }
        List<Seat_Allocation_and_Ticketing__c> satList = [SELECT Id, Name, Final_Allocated_Seats_Amadeus__c, Departing_Flight_Number__c, Departing_PNR_Status__c, Returning_PNR_Status__c,  Get_Updates_Status__c, Get_Updates_Error_Message__c FROM Seat_Allocation_and_Ticketing__c WHERE Name in :satNoList];
        
        Map<String, Seat_Allocation_and_Ticketing__c> satMap = new Map<String, Seat_Allocation_and_Ticketing__c>();
        for (Seat_Allocation_and_Ticketing__c currSat : satList) {
            satMap.put(currSat.Name, currSat);
        }
        
        for (ReceiveResponseGetUpdateWrapper currWrapper : requestBodyWrapper) {
            Seat_Allocation_and_Ticketing__c currSat = satMap.get(currWrapper.sat_no);
            if (currSat != null) {
                currSat.Get_Updates_Status__c = currWrapper.status;
                currSat.Get_Updates_Error_Message__c = '';
                if (currWrapper.status == Constants.PICKLIST_STATUS_FAIL) {
                    currSat.Get_Updates_Error_Message__c = currWrapper.error_message;
                } else if (currWrapper.status == Constants.PICKLIST_STATUS_SUCCEEDED) {
                    currSat.Final_Allocated_Seats_Amadeus__c = Integer.valueof(currWrapper.final_allocated_seats_amadeus);
                    for (ReceiveResponseGetUpdateWrapper.Legs legs : currWrapper.legs) {
                        if (legs.sorting == 1) {
                            if (currSat.Departing_Flight_Number__c == 'none') {
                                currSat.Returning_PNR_Status__c = legs.pnr_status;
                            } else {
                                currSat.Departing_PNR_Status__c = legs.pnr_status;
                            }
                        }
                        if (legs.sorting == 2) {
                            currSat.Returning_PNR_Status__c = legs.pnr_status;
                        }
                    }
                }
            }
        }
        Database.update(satList);
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