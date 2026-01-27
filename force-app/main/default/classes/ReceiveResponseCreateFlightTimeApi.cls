@RestResource(urlMapping='/receive-response/create-flight-time')
global with sharing class ReceiveResponseCreateFlightTimeApi {

    @HttpPost
    global static void createFlightTime() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // 1) 解析回呼（與 create-pnr 類似：陣列，每筆含 sat_no + legs[]）
            List<Object> items = (List<Object>) JSON.deserializeUntyped(req.requestBody.toString());
            if (items == null || items.isEmpty()) {
                res = ResponseUtil.buildErrorRestResponse(res, 'Empty payload.');
                ApiLogger.log(req, res);
                return;
            }

            // 2) 收集 sat_no
            Set<String> satNos = new Set<String>();
            for (Object o : items) {
                Map<String, Object> row = (Map<String, Object>) o;
                String satNo = (String) row.get('sat_no');
                if (!String.isBlank(satNo)) satNos.add(satNo);
            }
            if (satNos.isEmpty()) {
                res = ResponseUtil.buildErrorRestResponse(res, 'No sat_no provided.');
                ApiLogger.log(req, res);
                return;
            }

            // 3) 取 SAT（要 Case_ID__c）
            Map<String, Seat_Allocation_and_Ticketing__c> satByNo = new Map<String, Seat_Allocation_and_Ticketing__c>(
                [SELECT Id, Name, Case_ID__c
                   FROM Seat_Allocation_and_Ticketing__c
                  WHERE Name IN :satNos]
            );

            // 4) 取 Case（要去回程航班號）
            Set<Id> caseIds = new Set<Id>();
            for (Seat_Allocation_and_Ticketing__c s : satByNo.values()) {
                if (s.Case_ID__c != null) caseIds.add(s.Case_ID__c);
            }
            Map<Id, Case> caseById = caseIds.isEmpty()
                ? new Map<Id, Case>()
                : new Map<Id, Case>(
                    [SELECT Id, Departing_Flight_Number__c, Returning_Flight_Number__c
                       FROM Case
                      WHERE Id IN :caseIds]
                  );

            // 5) 若同一 Case 只需 1 筆紀錄：先抓既有 Flight_Time__c
            Map<Id, Flight_Time__c> existingByCase = caseIds.isEmpty()
                ? new Map<Id, Flight_Time__c>()
                : new Map<Id, Flight_Time__c>(
                    [SELECT Id, Case__c
                       FROM Flight_Time__c
                      WHERE Case__c IN :caseIds]
                  );

            List<Flight_Time__c> toInsert = new List<Flight_Time__c>();
            List<Flight_Time__c> toUpdate = new List<Flight_Time__c>();

            // 6) 逐筆建立/更新 Flight_Time__c（時間皆以原始字串存）
            for (Object o : items) {
                Map<String, Object> row = (Map<String, Object>) o;
                String satNo = (String) row.get('sat_no');
                if (String.isBlank(satNo)) continue;

                Seat_Allocation_and_Ticketing__c sat = satByNo.get(satNo);
                if (sat == null || sat.Case_ID__c == null) continue;

                Case c = caseById.get(sat.Case_ID__c);
                if (c == null) continue;

                List<Object> legs = (List<Object>) row.get('legs');
                if (legs == null || legs.isEmpty()) continue;

                // legs 依 sorting 分組
                Map<Integer, Map<String, Object>> legBySort = new Map<Integer, Map<String, Object>>();
                for (Object lo : legs) {
                    Map<String, Object> leg = (Map<String, Object>) lo;
                    Integer sorting = toInt(leg.get('sorting'));
                    if (sorting != null) legBySort.put(sorting, leg);
                }

                // 字串直接帶入，不轉 Datetime
                String seg1DepStr = getString(legBySort.get(1), 'Departure_Time');
                String seg1ArrStr = getString(legBySort.get(1), 'Arrival_Time');
                String seg2DepStr = getString(legBySort.get(2), 'Departure_Time');
                String seg2ArrStr = getString(legBySort.get(2), 'Arrival_Time');

                Flight_Time__c rec;
                if (existingByCase.containsKey(c.Id)) {
                    // 已有 → 更新
                    rec = existingByCase.get(c.Id);
                    rec.Seg1_Original_Departure_Time__c = seg1DepStr;
                    rec.Seg1_Original_Arrival_Time__c   = seg1ArrStr;
                    rec.Seg2_Original_Departure_Time__c = seg2DepStr;
                    rec.Seg2_Original_Arrival_Time__c   = seg2ArrStr;
                    toUpdate.add(rec);
                } else {
                    // 沒有 → 新增
                    rec = new Flight_Time__c();
                    rec.Case__c                         = c.Id;
                    rec.Seg1_Original_Departure_Time__c = seg1DepStr;
                    rec.Seg1_Original_Arrival_Time__c   = seg1ArrStr;
                    rec.Seg2_Original_Departure_Time__c = seg2DepStr;
                    rec.Seg2_Original_Arrival_Time__c   = seg2ArrStr;
                    toInsert.add(rec);
                }
            }

            if (!toInsert.isEmpty()) insert toInsert;
            if (!toUpdate.isEmpty()) update toUpdate;

            res = ResponseUtil.buildSuccessRestResponse(res);
        } catch (Exception e) {
            res = ResponseUtil.buildErrorRestResponse(res, e.getMessage());
        }
        ApiLogger.log(req, res);
    }

    // 工具：轉 Integer（容錯）
    private static Integer toInt(Object v) {
        if (v == null) return null;
        if (v instanceof Integer) return (Integer)v;
        if (v instanceof Long)    return Integer.valueOf(String.valueOf(v));
        if (v instanceof String)  { try { return Integer.valueOf((String)v); } catch (Exception e) { return null; } }
        try { return Integer.valueOf(String.valueOf(v)); } catch (Exception e) { return null; }
    }

    // 工具：安全取字串
    private static String getString(Map<String, Object> m, String key) {
        if (m == null || key == null) return null;
        Object v = m.get(key);
        return v == null ? null : String.valueOf(v);
    }
}