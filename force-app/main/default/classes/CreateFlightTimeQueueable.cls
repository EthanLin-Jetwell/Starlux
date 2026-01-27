public class CreateFlightTimeQueueable implements Queueable, Database.AllowsCallouts {
    private List<String> satNos;
    public CreateFlightTimeQueueable(List<String> satNos) { this.satNos = satNos; }

    public void execute(QueueableContext ctx) {
        if (satNos == null || satNos.isEmpty()) return;
        String currentSatNo = satNos.remove(0);

        // 1️⃣ 取 SAT → Case
        Seat_Allocation_and_Ticketing__c sat = [
            SELECT Id, Name, Case_ID__c
            FROM Seat_Allocation_and_Ticketing__c
            WHERE Name = :currentSatNo
            LIMIT 1
        ];

        if (sat == null || sat.Case_ID__c == null) {
            chainNext(); return;
        }

        // 2️⃣ 撈最近一筆 /receive-response/create-pnr 的 Log（請改成你的實際 Log 物件）
        Api_Log__c logRec = [
            SELECT Request_Body__c, Response_Body__c
            FROM Api_Log__c
            WHERE Request_URL__c = '/receive-response/create-pnr'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (logRec == null) {
            chainNext(); return;
        }

        // 3️⃣ 解析 JSON
        List<Object> items = (List<Object>) JSON.deserializeUntyped(
            logRec.Request_Body__c != null ? logRec.Request_Body__c : logRec.Response_Body__c
        );

        String seg1Dep, seg1Arr, seg2Dep, seg2Arr;

        for (Object o : items) {
            Map<String, Object> row = (Map<String, Object>) o;
            if (currentSatNo != (String)row.get('sat_no')) continue;
            List<Object> legs = (List<Object>) row.get('legs');
            if (legs == null) continue;

            for (Object lo : legs) {
                Map<String, Object> leg = (Map<String, Object>) lo;
                Integer sorting = toInt(leg.get('sorting'));
                if (sorting == 1) {
                    seg1Dep = str(leg.get('Departure_Time'));
                    seg1Arr = str(leg.get('Arrival_Time'));
                } else if (sorting == 2) {
                    seg2Dep = str(leg.get('Departure_Time'));
                    seg2Arr = str(leg.get('Arrival_Time'));
                }
            }
            break;
        }

        // 4️⃣ 建/更 Flight_Time__c（時間全以字串儲存）
        List<Flight_Time__c> existing = [
            SELECT Id FROM Flight_Time__c WHERE Case__c = :sat.Case_ID__c LIMIT 1
        ];

        if (existing.isEmpty()) {
            insert new Flight_Time__c(
                Case__c = sat.Case_ID__c,
                Seg1_Original_Departure_Time__c = seg1Dep,
                Seg1_Original_Arrival_Time__c   = seg1Arr,
                Seg2_Original_Departure_Time__c = seg2Dep,
                Seg2_Original_Arrival_Time__c   = seg2Arr
            );
        } else {
            Flight_Time__c ft = existing[0];
            ft.Seg1_Original_Departure_Time__c = seg1Dep;
            ft.Seg1_Original_Arrival_Time__c   = seg1Arr;
            ft.Seg2_Original_Departure_Time__c = seg2Dep;
            ft.Seg2_Original_Arrival_Time__c   = seg2Arr;
            update ft;
        }

        chainNext();
    }

    // 鏈下一筆 SAT
    private void chainNext() {
        if (!satNos.isEmpty())
            System.enqueueJob(new CreateFlightTimeQueueable(satNos));
    }

    private static Integer toInt(Object v) {
        if (v == null) return null;
        if (v instanceof Integer) return (Integer)v;
        if (v instanceof Long) return Integer.valueOf(String.valueOf(v));
        if (v instanceof String) { try { return Integer.valueOf((String)v); } catch(Exception e){ return null; } }
        return null;
    }
    private static String str(Object v){ return v == null ? null : String.valueOf(v); }
}