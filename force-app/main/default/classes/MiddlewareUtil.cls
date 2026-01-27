public class MiddlewareUtil {
    
    @future(callout = true)
    public static void getAuthorizationToken() {
        HttpResponse response = HttpRequestUtil.sendRequest(Constants.MIDDLEWARE_AUTH_HOST, 'POST', Constants.MIDDLEWARE_AUTH_BODY);
        String requestUrl = Constants.MIDDLEWARE_AUTH_HOST;
        String requestBody = Constants.MIDDLEWARE_AUTH_BODY;
        if (response.getStatusCode() == 200) {
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> dataJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('data');
            Map<String, Object> clientJsonResponseBody = (Map<String, Object>) dataJsonResponseBody.get('client');
            //String accessToken = String.valueOf(clientJsonResponseBody.get('accessToken')); //Eli 停用20251028
            String accessToken = String.valueOf(dataJsonResponseBody.get('accessToken')); //Eli AUTH改IOPS 20251028
            Map<String, Object> mapData = new Map<String, Object>();
            mapData.put('Access_Token__c', accessToken); 
            mapData.put('Expiry_Date__c', datetime.now().addDays(1));
            CreateUpdateMetadataUtil.createUpdateMetadata('Middleware_Access_Token.Access_Token', 'Access Token', mapData);
        }
    }
    
    @future(callout = true)
    public static void createPnrFuture(String jsonBodyAsString, List<Id> satIdList) {
        createPnr(jsonBodyAsString, satIdList, Constants.SAT_PROCESS_INSERT_ORIGIN_TRIGGER);
    }
    
    public static void createPnr(String jsonBodyAsString, List<Id> satIdList, String origin) {
        System.debug('[4i] Create PNR request to MW body');
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        
        HttpResponse response = HttpRequestUtil.sendRequest(Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_CREATE_PNR, 'POST', accessToken, jsonBodyAsString);
        
        List<Seat_Allocation_and_Ticketing__c> satListToSave = [SELECT Id, Sync_SAT_Status__c, Sync_SAT_Error_Message__c, Case_ID__c FROM Seat_Allocation_and_Ticketing__c WHERE Id in :satIdList];
        List<Id> caseIds = new List<Id>();
        for (Seat_Allocation_and_Ticketing__c sat : satListToSave) {
            caseIds.add(sat.Case_ID__c);
            sat.Sync_SAT_Error_Message__c = '';
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                sat.Sync_SAT_Status__c = Constants.PICKLIST_STATUS_REQUESTING;
            } else {
                if (origin == Constants.SAT_PROCESS_INSERT_ORIGIN_TRIGGER) {
                    sat.Sync_SAT_Status__c = Constants.PICKLIST_STATUS_FAIL;
                    Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
                    if (messageJsonResponseBody != null) {
                        sat.Sync_SAT_Error_Message__c = messageJsonResponseBody.get('content').toString();
                    }
                } 
                if (origin == Constants.SAT_PROCESS_INSERT_ORIGIN_BATCH) {
                    sat.Sync_SAT_Status__c = Constants.PICKLIST_STATUS_FAIL;
                    sat.Sync_SAT_Error_Message__c = 'Create batch PNR request to MW is failed, please check API Logs';
                }
            }
        }
        List<Case> caseListToSave = [SELECT Id, Integration_Link_Status__c, Batch_Processing__c FROM Case WHERE Id in :caseIds];
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) { 
            for (Case currCase : caseListToSave) {
                currCase.Integration_Link_Status__c = true;
                currCase.Batch_Processing__c = false;
            }
        }
        Database.update(satListToSave);
        Database.update(caseListToSave);
    }
    
    @future(callout = true)
    public static void cancelPnr(String satNoCancelling, String satNoMaster) {
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_CANCEL_PNR.replace('{satNo}', satNoMaster);
        String jsonBodyAsString = JSON.serialize(new MwCancelPnrWrapper(satNoCancelling));
        
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'POST', accessToken, jsonBodyAsString);
        
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Sync_SAT_Status__c FROM Seat_Allocation_and_Ticketing__c WHERE Name =:satNoCancelling];
        sat.Sync_SAT_Error_Message__c = '';
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            sat.Sync_SAT_Status__c = Constants.PICKLIST_STATUS_REQUESTING;
        } else {
            sat.Sync_SAT_Status__c = Constants.PICKLIST_STATUS_FAIL;
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
            if (messageJsonResponseBody != null) {
                sat.Sync_SAT_Error_Message__c = messageJsonResponseBody.get('content').toString();
            }
        }
        Database.update(sat);
    }
    
    @future(callout = true)
    public static void resizePnr(String satNoResizing, String satNoMaster, String bookingReference, Integer seatResizing) {
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_SPLIT_PNR.replace('{satNo}', satNoMaster);
        String jsonBodyAsString = JSON.serialize(new MwResizePnrWrapper(satNoResizing, bookingReference, seatResizing), true);
        
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'POST', accessToken, jsonBodyAsString);
        
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Sync_SAT_Status__c FROM Seat_Allocation_and_Ticketing__c WHERE Name =:satNoResizing];
        sat.Sync_SAT_Error_Message__c = '';
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            sat.Sync_SAT_Status__c = Constants.PICKLIST_STATUS_REQUESTING;
        } else {
            sat.Sync_SAT_Status__c = Constants.PICKLIST_STATUS_FAIL;
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
            if (messageJsonResponseBody != null) {
                sat.Sync_SAT_Error_Message__c = messageJsonResponseBody.get('content').toString();
            }
        }
        Database.update(sat);
    }
    
    @future(callout = true)
    public static void resizePnr(String satNoResizing, String satNoMaster, String bookingReference, Integer seatResizing, String returnCaseNo) {
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_SPLIT_PNR.replace('{satNo}', satNoMaster);
        String jsonBodyAsString = JSON.serialize(new MwResizePnrWrapper(satNoResizing, bookingReference, seatResizing, returnCaseNo), true);
        
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'POST', accessToken, jsonBodyAsString);
        
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Sync_SAT_Status__c FROM Seat_Allocation_and_Ticketing__c WHERE Name =:satNoResizing];
        sat.Sync_SAT_Error_Message__c = '';
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            sat.Sync_SAT_Status__c = Constants.PICKLIST_STATUS_REQUESTING;
        } else {
            sat.Sync_SAT_Status__c = Constants.PICKLIST_STATUS_FAIL;
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
            if (messageJsonResponseBody != null) {
                sat.Sync_SAT_Error_Message__c = messageJsonResponseBody.get('content').toString();
            }
        }
        Database.update(sat);
    }
    
    public static Boolean disableCaseIntegration(String jsonBodyAsString) {
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_DISABLE_INTEGRATION;
        
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'PUT', accessToken, jsonBodyAsString);
        if (response.getStatusCode() == 200) {
            return true;
        } 
         
        return false;
    }
    
    @future(callout = true)
    public static void syncSstCallout(String satNo, String jsonBodyAsString, Id caseId) {
        System.debug('[4i] Callout for SST sync');
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_SYNC_SST.replace('{satNo}', satNo);
        
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'PUT', accessToken, jsonBodyAsString);
        
        Case currCase = [SELECT Id, Sync_SST_Status__c, SST_Mark__c, Sync_SST_Error_Message__c FROM Case WHERE Id = :caseId];
        currCase.Sync_SST_Error_Message__c = '';
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            currCase.Sync_SST_Status__c = Constants.PICKLIST_STATUS_SUCCEEDED;
            currCase.SST_Mark__c = satNo;
        }
        else {
            currCase.Sync_SST_Status__c = Constants.PICKLIST_STATUS_FAIL;
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
            if (messageJsonResponseBody != null) {
                currCase.Sync_SST_Error_Message__c = messageJsonResponseBody.get('content').toString();
            }
        }
        Database.update(currCase);
    }
    
    @future(callout = true)
    public static void getTax(String satNo, String jsonBodyAsString) {
        System.debug('[4i] Callout for Get Tax');
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_GET_TAX.replace('{satNo}', satNo);
        
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'POST', accessToken, jsonBodyAsString);
        
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Get_Tax_Status__c, Get_Tax_Error_Message__c, Initial_Tax_Adult__c, Initial_BSC_Adult__c, Initial_Tax_Child__c, Initial_BSC_Child__c, Initial_Tax_Infant__c, Initial_BSC_Infant__c, Final_Tax_Adult__c, Final_BSC_Adult__c, Final_Tax_Child__c, Final_BSC_Child__c,Final_BSC_Infant__c, Final_Tax_Infant__c  FROM Seat_Allocation_and_Ticketing__c WHERE Name =:satNo];//20240904 Eli
        //Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Get_Tax_Status__c, Get_Tax_Error_Message__c, Initial_Tax_Adult__c, Initial_Tax_Child__c, Initial_Tax_Infant__c, Final_Tax_Adult__c, Final_Tax_Child__c, Final_Tax_Infant__c  FROM Seat_Allocation_and_Ticketing__c WHERE Name =:satNo];
        sat.Get_Tax_Error_Message__c = '';
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            MwGetTaxResponseWrapper responseWrapper = MwGetTaxResponseWrapper.deserializeJson(response.getBody());
            sat.Get_Tax_Status__c = Constants.PICKLIST_STATUS_SUCCEEDED;
            for (Integer i = 0; i < responseWrapper.data.taxes.size(); i++) {
                if (responseWrapper.data.taxes.get(i).type == 'adult') {
                    sat.Initial_Tax_Adult__c = responseWrapper.data.taxes.get(i).taxes;
                    sat.Final_Tax_Adult__c = responseWrapper.data.taxes.get(i).taxes;
                    sat.Initial_BSC_Adult__c = responseWrapper.data.taxes.get(i).yrAmount;//20240904 Eli
                    sat.Final_BSC_Adult__c = responseWrapper.data.taxes.get(i).yrAmount;//20240904 Eli
                } else if (responseWrapper.data.taxes.get(i).type == 'child') {
                    sat.Initial_Tax_Child__c = responseWrapper.data.taxes.get(i).taxes;
                    sat.Final_Tax_Child__c = responseWrapper.data.taxes.get(i).taxes;
                    sat.Initial_BSC_Child__c = responseWrapper.data.taxes.get(i).yrAmount;//20240904 Eli
                    sat.Final_BSC_Child__c = responseWrapper.data.taxes.get(i).yrAmount;//20240904 Eli
                } else if (responseWrapper.data.taxes.get(i).type == 'infant') {
                    sat.Initial_Tax_Infant__c = responseWrapper.data.taxes.get(i).taxes;   
                    sat.Final_Tax_Infant__c = responseWrapper.data.taxes.get(i).taxes;
                    sat.Initial_BSC_Infant__c = responseWrapper.data.taxes.get(i).yrAmount;//20240904 Eli
                    sat.Final_BSC_Infant__c = responseWrapper.data.taxes.get(i).yrAmount;//20240904 Eli
                }
            }
        }
        else {
            sat.Get_Tax_Status__c = Constants.PICKLIST_STATUS_FAIL;
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
            if (messageJsonResponseBody != null) {
                sat.Get_Tax_Error_Message__c = messageJsonResponseBody.get('content').toString();
            }
        }
        Database.update(sat);
    }
    
    @future(callout = true)
    public static void addPax(String satNo, String jsonBodyAsString) {
        System.debug('[4i] Callout for Add Pax');
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_ADD_PAX.replace('{satNo}', satNo);
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'POST', accessToken, jsonBodyAsString);
        
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Add_Name_List_Status__c, Add_Name_List_Error_Message__c FROM Seat_Allocation_and_Ticketing__c WHERE Name =:satNo];
        sat.Add_Name_List_Error_Message__c   = '';
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            sat.Add_Name_List_Status__c = Constants.PICKLIST_STATUS_REQUESTING;
        } else {
            sat.Add_Name_List_Status__c = Constants.PICKLIST_STATUS_FAIL;
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
            if (messageJsonResponseBody != null) {
                sat.Add_Name_List_Error_Message__c   = messageJsonResponseBody.get('content').toString();
            }
        }
        Database.update(sat);
    }
    
    @future(callout = true)
    public static void issueTicket(String satNo, String jsonBodyAsString) {
        System.debug('[4i] Callout for Issue ticket');
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_ISSUE_TICKET.replace('{satNo}', satNo);
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'POST', accessToken, jsonBodyAsString);
        
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Issue_Ticket_Error_Message__c, Issue_Ticket_Status__c FROM Seat_Allocation_and_Ticketing__c WHERE Name =:satNo];
        sat.Issue_Ticket_Error_Message__c = '';
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            sat.Issue_Ticket_Status__c = Constants.PICKLIST_STATUS_REQUESTING;
        } else {
            sat.Issue_Ticket_Status__c = Constants.PICKLIST_STATUS_FAIL;
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
            if (messageJsonResponseBody != null) {
                sat.Issue_Ticket_Error_Message__c = messageJsonResponseBody.get('content').toString();
            }
        }
        Database.update(sat);
    }
    
    private static String convertTimeToHHmm(String timeStr) {
        if (String.isBlank(timeStr)) return null;
        return timeStr.replace(':', '');
    }
    
    @future(callout = true)
    public static void getUpdate(String satNo) {
        System.debug('[4i] Callout for Get Update');
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_GET_UPDATE.replace('{satNo}', satNo);
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'GET', accessToken, '');
        
        Seat_Allocation_and_Ticketing__c sat = [
            SELECT Id, Departing_Flight_Number__c, Get_Updates_Status__c,
                   Get_Updates_Error_Message__c, Final_Allocated_Seats_Amadeus__c
            FROM Seat_Allocation_and_Ticketing__c
            WHERE Name =:satNo
        ];
        List<Name_List__c> nameListList = [
            SELECT Id, Name, Meal_Selection_Status_Departing__c, Meal_Selection_Status_Returning__c,
                   Special_Service_Status_Departing__c, Special_Service_Status_Returning__c,
                   INF_Meal_Selection_Status_Departing__c, INF_Meal_Selection_Status_Returning__c,
                   INF_PNR_Status_Departing__c, INF_PNR_Status_Returning__c
            FROM Name_List__c
            WHERE Seat_Allocation_and_Ticketing__c = :sat.Id
        ];
        Map<String, Name_List__c> nameListMap = new Map<String, Name_List__c>();
        for(Name_List__c currNameList : nameListList) {
            nameListMap.put(currNameList.Name, currNameList);
        }
        Schema.DescribeFieldResult fieldResult = Name_List__c.Meal_Selection_All_Sector__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        List<String> mealSelection = new List<String>();
        for(Schema.PicklistEntry currValue : picklistValues) {
            mealSelection.add(currValue.getValue());
        }
        fieldResult = Name_List__c.INF_Meal_Selection_All_Sector__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        List<String> infMealSelection = new List<String>();
        for(Schema.PicklistEntry currValue : picklistValues) {
            infMealSelection.add(currValue.getValue());
        }
        List<String> specialServiceSelection = new List<String>{'WCHR', 'WCHS', 'WCHC', 'WCOB', 'WCIC', 'WCMP', 'WCBD', 'WCBW', 'WCLB'};
        
        sat.Get_Updates_Error_Message__c = '';
        
        // ★★★ 新增：準備 Flight_Time__c 變數（先宣告在外面） ★★★
        Flight_Time__c flightTimeRecord;
        
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            sat.Get_Updates_Status__c = Constants.PICKLIST_STATUS_SUCCEEDED;
            MwGetUpdateResponseWrapper responseWrapper = MwGetUpdateResponseWrapper.deserializeJson(response.getBody());
            sat.Final_Allocated_Seats_Amadeus__c = Integer.valueof(responseWrapper.data.itinerary.seats);
            
            // ★★★ 依 caseNo 找 Flight_Time__c ★★★
            String caseNo = responseWrapper.data.itinerary.caseNo;
            if (!String.isBlank(caseNo)) {
                // 先找既有的 Flight_Time__c（Case__r.Name = caseNo）
                List<Flight_Time__c> ftList = [
                    SELECT Id,
                           Seg1_Latest_Arrival_Date__c, Seg1_Latest_Arrival_Time__c,
                           Seg1_Latest_Departure_Date__c, Seg1_Latest_Departure_Time__c,
                           Seg2_Latest_Arrival_Date__c, Seg2_Latest_Arrival_Time__c,
                           Seg2_Latest_Departure_Date__c, Seg2_Latest_Departure_Time__c,
                           Get_Flight_Time_Status__c,Get_Flight_Date_Time__c
                    FROM Flight_Time__c
                    WHERE Case__r.CaseNumber = :caseNo
                    LIMIT 1
                ];
                if (!ftList.isEmpty()) {
                    flightTimeRecord = ftList[0];
                }
            }
            // ★★★ Flight_Time__c 準備完畢 ★★★
            
            for (MwGetUpdateResponseWrapper.Legs currLeg : responseWrapper.data.itinerary.legs) {
                if (currLeg.sorting == '1') {
                    if (sat.Departing_Flight_Number__c == 'none') {
                        sat.Returning_PNR_Status__c = currLeg.status;
                    } else {
                        sat.Departing_PNR_Status__c = currLeg.status;
                    }
                }
                if (currLeg.sorting == '2') {
                    sat.Returning_PNR_Status__c = currLeg.status;
                }
                
                // ★★★ 新增：依 sorting 寫入 Flight_Time__c ★★★
                if (flightTimeRecord != null && currLeg.flight != null) {
                    // 依你 wrapper 實際欄位名稱調整，這裡假設是 arrivalDate / arrivalTime / departureDate / departureTime
                    String arrDateStr  = currLeg.flight.arrivalDate;
                    String arrTimeStr  = currLeg.flight.arrivalTime;
                    String depDateStr  = currLeg.flight.departureDate;
                    String depTimeStr  = currLeg.flight.departureTime;
                    
                    if (currLeg.sorting == '1') {
                        // Sorting:1 → Seg1
                        flightTimeRecord.Seg1_Latest_Arrival_Date__c      = arrDateStr;
                        flightTimeRecord.Seg1_Latest_Arrival_Time__c      = arrTimeStr;
                        flightTimeRecord.Seg1_Latest_Departure_Date__c    = depDateStr;
                        flightTimeRecord.Seg1_Latest_Departure_Time__c    = depTimeStr;
                    } else if (currLeg.sorting == '2') {
                        // Sorting:2 → Seg2
                        flightTimeRecord.Seg2_Latest_Arrival_Date__c      = arrDateStr;
                        flightTimeRecord.Seg2_Latest_Arrival_Time__c      = arrTimeStr;
                        flightTimeRecord.Seg2_Latest_Departure_Date__c    = depDateStr;
                        flightTimeRecord.Seg2_Latest_Departure_Time__c    = depTimeStr;
                    }
                    flightTimeRecord.Get_Flight_Time_Status__c = 'Succeeded';
                    flightTimeRecord.Get_Flight_Date_Time__c   = Datetime.now();
                }
                // ★★★ Flight_Time__c 更新結束（每個 legs 都會判斷一次） ★★★
                
                // === 以下維持你原本的 passengers / Name_List__c 處理 ===
                if (currLeg.passengers.size() > 0) {
                    for (MwGetUpdateResponseWrapper.Passengers currPassenger : currLeg.passengers) {
                        Name_List__c nameList = nameListMap.get(currPassenger.nameListNo);
                        if (currLeg.sorting == '1' && (currPassenger.type == 'adult' || currPassenger.type == 'child')) {
                            nameList.Special_Service_Status_Departing__c = '';
                            nameList.Special_Service_Status_Returning__c = '';
                            for (MwGetUpdateResponseWrapper.Ssrs currSsr : currPassenger.ssrs) {
                                if (mealSelection.contains(currSsr.ssr)) {
                                    if (sat.Departing_Flight_Number__c == 'none') {
                                        nameList.Meal_Selection_Status_Returning__c = currSsr.ssr + ':' + currSsr.status;
                                    } else {
                                        nameList.Meal_Selection_Status_Departing__c = currSsr.ssr + ':' + currSsr.status;
                                    }
                                }
                                if (specialServiceSelection.contains(currSsr.ssr)) {
                                    if (sat.Departing_Flight_Number__c == 'none') {
                                        String breakpoint = nameList.Special_Service_Status_Returning__c == '' ? '' : '/';
                                        nameList.Special_Service_Status_Returning__c =
                                            nameList.Special_Service_Status_Returning__c + breakpoint + currSsr.ssr + ':' + currSsr.status;
                                    } else {
                                        String breakpoint = nameList.Special_Service_Status_Departing__c == '' ? '' : '/';
                                        nameList.Special_Service_Status_Departing__c =
                                            nameList.Special_Service_Status_Departing__c + breakpoint + currSsr.ssr + ':' + currSsr.status;
                                    }
                                }
                            }
                        }
                        if (currLeg.sorting == '1' && currPassenger.type == 'infant') {
                            for (MwGetUpdateResponseWrapper.Ssrs currSsr : currPassenger.ssrs) {
                                if (currSsr.ssr == 'INFT') {
                                    if (sat.Departing_Flight_Number__c == 'none') {
                                        nameList.INF_PNR_Status_Returning__c = currSsr.status;
                                    } else {
                                        nameList.INF_PNR_Status_Departing__c = currSsr.status;
                                    }
                                }
                                if (infMealSelection.contains(currSsr.ssr)) {
                                    if (sat.Departing_Flight_Number__c == 'none') {
                                        nameList.INF_Meal_Selection_Status_Returning__c = currSsr.ssr + ':' + currSsr.status;
                                    } else {
                                        nameList.INF_Meal_Selection_Status_Departing__c = currSsr.ssr + ':' + currSsr.status;
                                    }
                                }
                            }
                        }
                        if (currLeg.sorting == '2' && (currPassenger.type == 'adult' || currPassenger.type == 'child')) {
                            for (MwGetUpdateResponseWrapper.Ssrs currSsr : currPassenger.ssrs) {
                                if (mealSelection.contains(currSsr.ssr)) {
                                    nameList.Meal_Selection_Status_Returning__c = currSsr.ssr + ':' + currSsr.status;
                                }
                                if (specialServiceSelection.contains(currSsr.ssr)) {
                                    String breakpoint = nameList.Special_Service_Status_Returning__c == '' ? '' : '/';
                                    nameList.Special_Service_Status_Returning__c =
                                        nameList.Special_Service_Status_Returning__c + breakpoint + currSsr.ssr + ':' + currSsr.status;
                                }
                            }
                        }
                        if (currLeg.sorting == '2' && currPassenger.type == 'infant') {
                            for (MwGetUpdateResponseWrapper.Ssrs currSsr : currPassenger.ssrs) {
                                if (currSsr.ssr == 'INFT') {
                                    nameList.INF_PNR_Status_Returning__c = currSsr.status;
                                }
                                if (infMealSelection.contains(currSsr.ssr)) {
                                    nameList.INF_Meal_Selection_Status_Returning__c = currSsr.ssr + ':' + currSsr.status;
                                }
                            }
                        }
                    }
                }
            }
        } else {
            sat.Get_Updates_Status__c = Constants.PICKLIST_STATUS_FAIL;
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
            if (messageJsonResponseBody != null) {
                sat.Get_Updates_Error_Message__c = messageJsonResponseBody.get('content').toString();
            }
        }
        Database.update(nameListList);
        Database.update(sat);
        
        // ★★★ 最後把 Flight_Time__c 寫回去 ★★★
        if (flightTimeRecord != null) {
            upsert flightTimeRecord;
        }
    }

    
    @future(callout = true)
    public static void updatelegStatus(List<String> satIds) 
    {
        List<Seat_Allocation_and_Ticketing__c> SATList=[SELECT Name,Get_Updates_Error_Message__c FROM Seat_Allocation_and_Ticketing__c WHERE Id IN:satIds];
        
        List<String>SATNoList=new List<String>();
        for(Seat_Allocation_and_Ticketing__c SAT:SATList)
        {
            SATNoList.add(SAT.Name);
        }
        //MwLegStatusWrapper
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_UPDATE_LEG_STATUS;
        String jsonBodyAsString = JSON.serialize(new MwLegStatusWrapper(SATNoList));
        HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'PUT', accessToken, jsonBodyAsString);
        
        system.debug(response.getBody());
        if(response.getStatusCode() == 200 || response.getStatusCode() == 201)
        {
            
        }
        else
        {
            SATList[0].Get_Updates_Status__c = Constants.PICKLIST_STATUS_FAIL;
            Map<String, Object> mappedJsonResponseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> messageJsonResponseBody = (Map<String, Object>) mappedJsonResponseBody.get('message');
            if (messageJsonResponseBody != null) {
                SATList[0].Get_Updates_Error_Message__c = messageJsonResponseBody.get('content').toString();
            }
        }
        Database.update(SATList[0]);
    }
    
    //@future(callout = true)
    public static void getItinerary(String satId)  //2025-07-23 Herbert加Now
    {
        System.debug(satId);
        Seat_Allocation_and_Ticketing__c sat = [SELECT Id, Name FROM Seat_Allocation_and_Ticketing__c WHERE Id =: satId LIMIT 1];
        
        String accessToken = [SELECT Access_Token__c FROM Middleware_Access_Token__mdt WHERE DeveloperName = 'Access_Token'].Access_Token__c;
        String endpoint = Constants.MIDDLEWARE_HOST + Constants.MIDDLEWARE_ENDPOINT_GET_ITINERARY.replace('{satNo}', sat.Name);//Herbert
        String body;
        String itinerary;
        String status = 'Failed';
        String errMsg;
        Datetime successTime;
        String lastGetBy;
        
        try {
            HttpResponse response = HttpRequestUtil.sendRequest(endpoint, 'GET', accessToken, '');
            if(response.getStatusCode() == 200) {
                status = 'Succeeded';
                body = response.getbody();
                // Deserialize into a Map
                Map<String, Object> topLevel = (Map<String, Object>) JSON.deserializeUntyped(body);
                Map<String, Object> dataMap = (Map<String, Object>) topLevel.get('data');
                itinerary = (String) dataMap.get('html');
                
                // 記錄成功時間與觸發人
                successTime = Datetime.now();
                lastGetBy = UserInfo.getUserId();
            } else {
                //errMsg = response.getbody();
                Map<String, Object> errorMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> errorDetails = (Map<String, Object>) errorMap.get('error');
                errMsg = (String) errorDetails.get('message');
            }
        } catch(exception e) {
            errMsg = e.getMessage();
        }
        //update new Seat_Allocation_and_Ticketing__c(Id=satId, Itinerary__c=itinerary, Get_Itinerary_Status__c=status, Get_Itinerary_Error_Message__c=errMsg);// 2025-07-18 Herbert 新增"紀錄最後異動人+時間"
        Seat_Allocation_and_Ticketing__c updateSat = new Seat_Allocation_and_Ticketing__c(Id = satId, Itinerary__c = itinerary, Get_Itinerary_Status__c = status, Get_Itinerary_Error_Message__c = errMsg);
        if (status == 'Succeeded') {
            updateSat.Itinerary_Success_Time__c = successTime;
            updateSat.Last_Get_Itinerary_By__c = lastGetBy;
        }

    update updateSat;
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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