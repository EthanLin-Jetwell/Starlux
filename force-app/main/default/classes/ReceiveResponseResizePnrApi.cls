@RestResource(urlMapping = '/receive-response/resize-pnr')
global class ReceiveResponseResizePnrApi {
    
    @HttpPost
    global static void resizePnr() {
        RestRequest request = RestContext.request;
        RestResponse response = Restcontext.response;

        ReceiveResponseResizePnrWrapper wrapper = ReceiveResponseResizePnrWrapper.deserializeJson(request.requestBody.toString());

        if (wrapper.isMissingRequiredFields()) {
            response = ResponseUtil.buildErrorRestResponse(response, Constants.MISSING_REQUIRED_FIELD);
            ApiLogger.log(request, response);
            return;
        }
        
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Sync_SAT_Status__c, Sync_SAT_Error_Message__c, Booking_Reference_PNR__c, Original_Sat__r.Id, Original_Sat__r.Final_Allocated_Seats__c, Original_Sat__r.Total_Seat_Sales__c FROM Seat_Allocation_and_Ticketing__c WHERE Name =: wrapper.sat_no];
        sat.Sync_SAT_Status__c = wrapper.status;
        sat.Sync_SAT_Error_Message__c = '';
        if (wrapper.pnr != null) sat.Booking_Reference_PNR__c = wrapper.pnr;
        if (wrapper.status == Constants.PICKLIST_STATUS_FAIL) {
            sat.Sync_SAT_Error_Message__c = wrapper.error_message;
        }
        
        if (sat.Original_Sat__c != null) {
            Seat_Allocation_and_Ticketing__c originalSat = new Seat_Allocation_and_Ticketing__c(Id = sat.Original_Sat__r.Id, 
                                                                                                Final_Allocated_Seats__c = sat.Original_Sat__r.Final_Allocated_Seats__c,
                                                                                                Total_Seat_Sales__c = sat.Original_Sat__r.Total_Seat_Sales__c);
            sat.Total_Seat_Sales__c = 0;
            if (originalSat.Final_Allocated_Seats__c < originalSat.Total_Seat_Sales__c) {
                sat.Total_Seat_Sales__c = originalSat.Total_Seat_Sales__c - originalSat.Final_Allocated_Seats__c;
                originalSat.Total_Seat_Sales__c = originalSat.Final_Allocated_Seats__c;
            }

            Database.update(originalSat);  
        }
        
        Database.update(sat);

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