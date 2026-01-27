public class PNRListPaxByFlight {
    public static Set<String> AnalyseFromXmlBody(String xmlBody) {
        Set<String> controlNumberSet = new Set<String>();

        if (String.isBlank(xmlBody)) {
            System.debug('❌ XML empty.');
            return controlNumberSet;
        }

        if (!xmlBody.contains('PNR_ListPassengersByFlightReply')) {
            System.debug('⚠️ Not a valid passenger reply.');
            return controlNumberSet;
        }

        Dom.Document doc = new Dom.Document();
        try {
            doc.load(xmlBody);
        } catch (Exception e) {
            System.debug('❌ XML Load Error: ' + e.getMessage());
            return controlNumberSet;
        }

        Dom.XmlNode root = doc.getRootElement();
        Dom.XmlNode body = findChildByName(root, 'Body');
        if (body == null) {
            System.debug('❌ Missing <Body>');
            return controlNumberSet;
        }

        Dom.XmlNode reply = findChildByName(body, 'PNR_ListPassengersByFlightReply');
        if (reply == null) {
            System.debug('❌ Missing <PNR_ListPassengersByFlightReply>');
            return controlNumberSet;
        }

        Dom.XmlNode aggregatedOutput = findChildByName(reply, 'aggregatedOutput');
        if (aggregatedOutput == null) {
            System.debug('❌ Missing <aggregatedOutput>');
            return controlNumberSet;
        }

        for (Dom.XmlNode pnrViews : aggregatedOutput.getChildElements()) {
            if (pnrViews.getName() != 'pnrViews') continue;

            for (Dom.XmlNode pnrView : pnrViews.getChildElements()) {
                Dom.XmlNode amadeusId = findChildByName(pnrView, 'amadeusId');
                if (amadeusId == null) continue;

                Dom.XmlNode reservation = findChildByName(amadeusId, 'reservation');
                if (reservation == null) continue;

                Dom.XmlNode controlNumber = findChildByName(reservation, 'controlNumber');
                if (controlNumber != null && String.isNotBlank(controlNumber.getText())) {
                    controlNumberSet.add(controlNumber.getText().trim());
                }
            }
        }

        System.debug('🔢 Total PNR Count: ' + controlNumberSet.size());
        //chunkedPrintSet('📦 PNR Set', controlNumberSet, 20); // 每 20 筆印一段
        return controlNumberSet;
    }

    public static Map<String, String> GetPnrDepartureCityMap(String xmlBody) {
        Map<String, String> result = new Map<String, String>();

        if (String.isBlank(xmlBody)) return result;

        Dom.Document doc = new Dom.Document();
        try {
            doc.load(xmlBody);
        } catch (Exception e) {
            System.debug('❌ XML Load Error: ' + e.getMessage());
            return result;
        }

        Dom.XmlNode root = doc.getRootElement();
        Dom.XmlNode body = findChildByName(root, 'Body');
        Dom.XmlNode reply = findChildByName(body, 'PNR_ListPassengersByFlightReply');
        Dom.XmlNode aggregatedOutput = findChildByName(reply, 'aggregatedOutput');

        for (Dom.XmlNode pnrViews : aggregatedOutput.getChildElements()) {
            if (pnrViews.getName() != 'pnrViews') continue;

            Dom.XmlNode pnrView = findChildByName(pnrViews, 'pnrView');
            if (pnrView == null) continue;

            Dom.XmlNode controlNumberNode = findChildByName(findChildByName(findChildByName(pnrView, 'amadeusId'), 'reservation'), 'controlNumber');
            String controlNumber = (controlNumberNode != null) ? controlNumberNode.getText().trim() : null;

            Dom.XmlNode itineraryInfo = findChildByName(findChildByName(pnrView, 'originDestinationDetails'), 'itineraryInfo');
            Dom.XmlNode boardpointDetail = findChildByName(findChildByName(itineraryInfo, 'travelProduct'), 'boardpointDetail');
            Dom.XmlNode cityCodeNode = findChildByName(boardpointDetail, 'cityCode');
            String cityCode = (cityCodeNode != null) ? cityCodeNode.getText().trim() : null;

            if (String.isNotBlank(controlNumber) && String.isNotBlank(cityCode)) {
                result.put(controlNumber, cityCode);
            }
        }

        return result;
    }
    
    // 🔧 安全的子節點搜尋（忽略 namespace）
    private static Dom.XmlNode findChildByName(Dom.XmlNode parent, String localName) {
        for (Dom.XmlNode child : parent.getChildElements()) {
            if (child.getName() == localName || child.getName().endsWith(':' + localName)) {
                return child;
            }
        }
        return null;
    }

    // 🔧 分段印出 Set 內容
	/*
    private static void chunkedPrintSet(String label, Set<String> values, Integer chunkSize) {
        List<String> all = new List<String>(values);
        Integer total = all.size();
        Integer i = 0;
    
        while (i < total) {
            Integer count = Math.min(i + chunkSize, total);
            List<String> chunk = new List<String>();
            for (Integer j = i; j < count; j++) {
                chunk.add(all[j]);
            }
            System.debug(label + ' ' + i + ' ~ ' + (count - 1) + ': ' + String.join(chunk, ','));
            i = count;
        }
    }
	*/
}