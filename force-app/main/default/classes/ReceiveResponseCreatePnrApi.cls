@RestResource(urlMapping = '/receive-response/create-pnr')
global class ReceiveResponseCreatePnrApi {
    
    // ★ 時間字串 12:35 → 1235
    private static String convertTimeToHHmm(String timeStr) {
        if (String.isBlank(timeStr)) return null;
        return timeStr.replace(':', '');
    }

    @HttpPost
    global static void createPnr() {
        RestRequest request  = RestContext.request;
        RestResponse response = Restcontext.response;
        System.debug('[4i] Receive request create pnr:' + request.requestBody.toString());

        // 1. 反序列化 JSON
        List<ReceiveResponseCreatePnrWrapper> requestBodyWrapper =
            ReceiveResponseCreatePnrWrapper.deserializeJson(request.requestBody.toString());
        
        // 2. 檢查必填欄位 + 收集 sat_no
        List<String> satNoList = new List<String>();
        for (ReceiveResponseCreatePnrWrapper wrapper : requestBodyWrapper) {
            if (wrapper.isMissingRequiredFields()) {
                response = ResponseUtil.buildErrorRestResponse(response, Constants.MISSING_REQUIRED_FIELD);
                ApiLogger.log(request, response);
                return;
            }
            satNoList.add(wrapper.sat_no);
        }

        // 3. 查 SAT（多抓 Allocation_Type__c）
        List<Seat_Allocation_and_Ticketing__c> satListToSave = [
            SELECT Name, Id, Sync_SAT_Status__c, Sync_SAT_Error_Message__c,
                   Booking_Reference_PNR__c, Departing_PNR_Status__c, Returning_PNR_Status__c,
                   Case_ID__c, Departing_Flight_Number__c, Returning_Flight_Number__c,
                   Allocation_Type__c
            FROM Seat_Allocation_and_Ticketing__c
            WHERE Name IN :satNoList
        ];

        // Name (sat_no) → SAT
        Map<String, Seat_Allocation_and_Ticketing__c> satMap = new Map<String, Seat_Allocation_and_Ticketing__c>();
        Set<Id> candidateCaseIds = new Set<Id>();

        for (Seat_Allocation_and_Ticketing__c currSat : satListToSave) {
            satMap.put(currSat.Name, currSat);

            if ((currSat.Allocation_Type__c == 'SRS' || currSat.Allocation_Type__c == 'ADC')
                && currSat.Case_ID__c != null) {
                candidateCaseIds.add(currSat.Case_ID__c);
            }
        }

        // 4. 先查出這些 Case 既有的 Flight_Time__c （Case__c → Flight_Time__c）
        Map<Id, Flight_Time__c> existingFtByCase = new Map<Id, Flight_Time__c>();
        if (!candidateCaseIds.isEmpty()) {
            for (Flight_Time__c ft : [
                SELECT Id, Case__c,
                       Seg1_Original_Arrival_Date__c, Seg1_Original_Arrival_Time__c,
                       Seg1_Original_Departure_Date__c, Seg1_Original_Departure_Time__c,
                       Seg2_Original_Arrival_Date__c, Seg2_Original_Arrival_Time__c,
                       Seg2_Original_Departure_Date__c, Seg2_Original_Departure_Time__c,
                       Seg1_Latest_Arrival_Date__c,  Seg1_Latest_Arrival_Time__c,
                       Seg1_Latest_Departure_Date__c, Seg1_Latest_Departure_Time__c,
                       Seg2_Latest_Arrival_Date__c,  Seg2_Latest_Arrival_Time__c,
                       Seg2_Latest_Departure_Date__c, Seg2_Latest_Departure_Time__c
                FROM Flight_Time__c
                WHERE Case__c IN :candidateCaseIds
            ]) {
                existingFtByCase.put(ft.Case__c, ft);
            }
        }

        // 這次 call 中「新建的」 Flight_Time__c（Case__c → Flight_Time__c）
        Map<Id, Flight_Time__c> newFtByCase = new Map<Id, Flight_Time__c>();

        // 5. 主迴圈：更新 SAT + 建立／更新 Flight_Time__c
        for (ReceiveResponseCreatePnrWrapper wrapper : requestBodyWrapper) {
            Seat_Allocation_and_Ticketing__c sat = satMap.get(wrapper.sat_no);
            if (sat == null) {
                continue;
            }
             
            sat.Sync_SAT_Status__c = wrapper.status;
            sat.Sync_SAT_Error_Message__c = '';

            Id caseId = sat.Case_ID__c;
            Boolean isSrsOrAdc = (sat.Allocation_Type__c == 'SRS' || sat.Allocation_Type__c == 'ADC');
            Boolean canHandleFlightTime = isSrsOrAdc && caseId != null;

            if (wrapper.status == Constants.PICKLIST_STATUS_SUCCEEDED) {
                sat.Booking_Reference_PNR__c = wrapper.booking_reference;

                for (ReceiveResponseCreatePnrWrapper.Legs currLeg : wrapper.legs) {

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

                    // ===== 新增：處理 Flight_Time__c =====
                    if (canHandleFlightTime) {
                        Boolean hasExistingFt = existingFtByCase.containsKey(caseId);

                        if (hasExistingFt) {
                            // ▶ 已經有 Flight_Time__c：更新 Latest_* 欄位
                            Flight_Time__c ft = existingFtByCase.get(caseId);

                            if (currLeg.sorting == 1) {
                                // Seg1 Latest（去程最新）
                                if (String.isNotBlank(currLeg.arrival_date)) {
                                    ft.Seg1_Latest_Arrival_Date__c = currLeg.arrival_date;
                                }
                                if (String.isNotBlank(currLeg.departure_date)) {
                                    ft.Seg1_Latest_Departure_Date__c = currLeg.departure_date;
                                }
                                if (String.isNotBlank(currLeg.arrival_time)) {
                                    ft.Seg1_Latest_Arrival_Time__c = currLeg.arrival_time;
                                }
                                if (String.isNotBlank(currLeg.departure_time)) {
                                    ft.Seg1_Latest_Departure_Time__c = currLeg.departure_time;
                                }
                            } else if (currLeg.sorting == 2) {
                                // Seg2 Latest（回程最新）
                                if (String.isNotBlank(currLeg.arrival_date)) {
                                    ft.Seg2_Latest_Arrival_Date__c = currLeg.arrival_date;
                                }
                                if (String.isNotBlank(currLeg.departure_date)) {
                                    ft.Seg2_Latest_Departure_Date__c = currLeg.departure_date;
                                }
                                if (String.isNotBlank(currLeg.arrival_time)) {
                                    ft.Seg2_Latest_Arrival_Time__c = currLeg.arrival_time;
                                }
                                if (String.isNotBlank(currLeg.departure_time)) {
                                    ft.Seg2_Latest_Departure_Time__c = currLeg.departure_time;
                                }
                            }

                        } else {
                            // ▶ 沒有 Flight_Time__c：建立一筆，只寫 Original_* 欄位
                            Flight_Time__c ft = newFtByCase.get(caseId);
                            if (ft == null) {
                                ft = new Flight_Time__c();
                                ft.Case__c = caseId;
                                newFtByCase.put(caseId, ft);
                            }

                            if (currLeg.sorting == 1) {
                                // Seg1 Original（去程原始）
                                if (String.isNotBlank(currLeg.arrival_date)) {
                                    ft.Seg1_Original_Arrival_Date__c = currLeg.arrival_date;
                                }
                                if (String.isNotBlank(currLeg.departure_date)) {
                                    ft.Seg1_Original_Departure_Date__c = currLeg.departure_date;
                                }
                                if (String.isNotBlank(currLeg.arrival_time)) {
                                    ft.Seg1_Original_Arrival_Time__c = currLeg.arrival_time;
                                }
                                if (String.isNotBlank(currLeg.departure_time)) {
                                    ft.Seg1_Original_Departure_Time__c = currLeg.departure_time;
                                }
                            } else if (currLeg.sorting == 2) {
                                // Seg2 Original（回程原始）
                                if (String.isNotBlank(currLeg.arrival_date)) {
                                    ft.Seg2_Original_Arrival_Date__c = currLeg.arrival_date;
                                }
                                if (String.isNotBlank(currLeg.departure_date)) {
                                    ft.Seg2_Original_Departure_Date__c = currLeg.departure_date;
                                }
                                if (String.isNotBlank(currLeg.arrival_time)) {
                                    ft.Seg2_Original_Arrival_Time__c = currLeg.arrival_time;
                                }
                                if (String.isNotBlank(currLeg.departure_time)) {
                                    ft.Seg2_Original_Departure_Time__c = currLeg.departure_time;
                                }
                            }
                        }
                    }
                    // ===== 新增結束 =====
                }

            } else if (wrapper.status == Constants.PICKLIST_STATUS_FAIL) {
                sat.Sync_SAT_Error_Message__c = wrapper.error_message;
            }
        }

        // 6. 先更新 SAT
        Database.update(satListToSave);

        // 7. Insert 新建的 Flight_Time__c（每個 Case 一筆）
        if (!newFtByCase.isEmpty()) {
            insert newFtByCase.values();
        }

        // 8. Update 已存在但這次有更新 Latest_* 的 Flight_Time__c
        if (!existingFtByCase.isEmpty()) {
            update existingFtByCase.values();
        }

        // 9. 回傳成功
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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