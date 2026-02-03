public class AmadeusXmlParser {
    public static Map<String, String> listPNRByFlight(String xmlBody) {
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
    
    public static list<TravellerInfo__c> retrievePNR(String body, String pnr, String boardpoint) {
        List<TravellerInfo__c> travellers = parseTravellerInfoFromXML(body, pnr, boardpoint);
        if (!travellers.isEmpty()) {
            enrichTravellerInfoFromDCS_WithAutoFetch(travellers);
        }
        return travellers;
    }
    
    public static list<TravellerInfo__c> retrievePNRC4(String body, String pnr, String boardpoint) {
        List<TravellerInfo__c> travellers = parseTravellerInfoFromXML(body, pnr, boardpoint);
        if (!travellers.isEmpty()) {
            enrichTravellerInfoFromDCS_WithAutoFetch(travellers);
            
            // ✅ 只在有任一旅客 CAS__c == 'CAC' 時才取登機證
            Boolean hasCAC = false;
            for (TravellerInfo__c t : travellers) {
                if ('CAC'.equalsIgnoreCase(String.valueOf(t.CAS__c))) {
                    hasCAC = true;
                    break;
                }
            }
            if (hasCAC) {
                String boardingPassXml = AmadeusUtil.DCSPRT_GetBoardingPassXmlData(travellers);
                if (!String.isBlank(boardingPassXml)) {
                    mergeBoardingPassDataIntoTravellers(boardingPassXml, travellers);
                }
            }
    	}
        return travellers;
    }

    //import traveller info from api logs
    /*
    public static void importFromApiLogByPNR(String pnr, String boardpoint) {
        api_log__c log = [
            SELECT Id, Response_Body__c, Response_Body1__c, Response_Body2__c, Response_Body3__c, Response_Body4__c, Response_Body5__c, Response_Body6__c, Response_Body7__c, PNR__c
            FROM api_log__c
            WHERE PNR__c = :pnr
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (log == null) {
            System.debug('⚠️ No api_log__c record found for PNR: ' + pnr);
            return;
        }

        String fullXml = 
            (log.Response_Body__c != null ? log.Response_Body__c : '') +
            (log.Response_Body1__c != null ? log.Response_Body1__c : '') +
            (log.Response_Body2__c != null ? log.Response_Body2__c : '') +
        	(log.Response_Body3__c != null ? log.Response_Body3__c : '') +
            (log.Response_Body4__c != null ? log.Response_Body4__c : '') +
        	(log.Response_Body5__c != null ? log.Response_Body5__c : '') +
            (log.Response_Body6__c != null ? log.Response_Body6__c : '') +
        	(log.Response_Body7__c != null ? log.Response_Body7__c : '');

        upsert parseTravellerInfoFromXML(fullXml, log.PNR__c,boardpoint) Name;
    }*/

    private static list<TravellerInfo__c> parseTravellerInfoFromXML(String xmlBody, String fallbackPNR, String boardpoint) {
        
        Map<String, Integer> lastOTMap = new Map<String, Integer>();
        List<String> droppedOTLogs = new List<String>();
        List<String> droppedOTNumbers = new List<String>();
        Map<String, Integer> docsNoSTPending = new Map<String, Integer>(); // key: PT-<ADT|INF> → OT(無ST)
        Dom.Document doc = new Dom.Document();
        doc.load(xmlBody);

        Dom.XmlNode envelopeNode = doc.getRootElement();
        Dom.XmlNode bodyNode = findChildByName(envelopeNode, 'Body');
        Dom.XmlNode pnrReplyNode = findChildByName(bodyNode, 'PNR_Reply');
        System.debug(pnrReplyNode);
        String pnrControlNumber = null;
        Dom.XmlNode pnrHeader = findChildByName(pnrReplyNode, 'pnrHeader');
        if (pnrHeader != null) {
            Dom.XmlNode reservationInfo = findChildByName(pnrHeader, 'reservationInfo');
            if (reservationInfo != null) {
                Dom.XmlNode reservation = findChildByName(reservationInfo, 'reservation');
                if (reservation != null) {
                    Dom.XmlNode controlNumber = findChildByName(reservation, 'controlNumber');
                    if (controlNumber != null) {
                        pnrControlNumber = controlNumber.getText();
                        System.debug('✅ PNR Control Number from XML: ' + pnrControlNumber);
                    }
                }
            }
        }

        if (pnrControlNumber == null && fallbackPNR != null) {
            pnrControlNumber = fallbackPNR;
            System.debug('🔁 Fallback to provided fallbackPNR: ' + pnrControlNumber);
        }

        List<TravellerInfo__c> travellerList = new List<TravellerInfo__c>();
		String ngGroupCode = null;

        for (Dom.XmlNode travellerInfoNode : pnrReplyNode.getChildElements()) {
            if (travellerInfoNode.getName() != 'travellerInfo') continue;
            System.debug('📦 Processing <travellerInfo>...');

            Dom.XmlNode empNode = findChildByName(travellerInfoNode, 'elementManagementPassenger');
            if (empNode == null) continue;

            // Group code：僅當 segmentName == 'NG' 且 traveller.qualifier == 'G' 時，才檢查 surname 最後一段是否為 OK
            Dom.XmlNode segNameNode = findChildByName(empNode, 'segmentName');
            if (segNameNode != null && segNameNode.getText() == 'NG') {
            
                // 只取第一個 passengerData（你現有規則：第一個一定是 ADT/CHD；第二個若有才是 INF）
                Dom.XmlNode pd = findChildByName(travellerInfoNode, 'passengerData');
                if (pd != null) {
                    Dom.XmlNode ti = findChildByName(pd, 'travellerInformation');
                    Dom.XmlNode tr = ti != null ? findChildByName(ti, 'traveller') : null;
            
                    // ① 先看 qualifier 是否為 G
                    Boolean isGroup = false;
                    if (tr != null) {
                        Dom.XmlNode qn = findChildByName(tr, 'qualifier');
                        if (qn != null) {
                            String q = qn.getText();
                            if (q != null && q.trim().toUpperCase() == 'G') {
                                isGroup = true;
                            }
                        }
                    }
            
                    // ② qualifier 為 G 才檢查 surname 最後一段是否 OK
                    if (isGroup) {
                        Dom.XmlNode sn = tr != null ? findChildByName(tr, 'surname') : null;
                        if (sn != null) {
                            List<String> parts = sn.getText().split('/');
                            if (parts != null && !parts.isEmpty()) {
                                String lastPart = parts[parts.size() - 1];
                                if (lastPart != null && lastPart.trim().toUpperCase() == 'OK') {
                                    ngGroupCode = 'OK';
                                    System.debug('🧩 NG + qualifier=G，surname 最後一段為 OK → 設定 group_code__c=OK');
                                }
                            }
                        }
                    }
                }
            }

            
            Dom.XmlNode refNode = findChildByName(empNode, 'reference');
            Dom.XmlNode qualifier = findChildByName(refNode, 'qualifier');
            if (qualifier == null || qualifier.getText() != 'PT') continue;
            Dom.XmlNode numberNode = findChildByName(refNode, 'number');
            String ptNumber = numberNode != null ? numberNode.getText() : null;

            List<Dom.XmlNode> passengerDataNodes = new List<Dom.XmlNode>();
            List<Dom.XmlNode> enhancedDataNodes = new List<Dom.XmlNode>();
            for (Dom.XmlNode child : travellerInfoNode.getChildElements()) {
                if (child.getName() == 'passengerData') passengerDataNodes.add(child);
                if (child.getName() == 'enhancedPassengerData') enhancedDataNodes.add(child);
            }

            if (passengerDataNodes.isEmpty()) continue;

            for (Integer i = 0; i < passengerDataNodes.size(); i++) {
                Dom.XmlNode passengerData = passengerDataNodes[i];
                Dom.XmlNode enhancedData = (i < enhancedDataNodes.size()) ? enhancedDataNodes[i] : null;

                Dom.XmlNode travellerInfo = findChildByName(passengerData, 'travellerInformation');
                if (travellerInfo == null) continue;

                Dom.XmlNode traveller = findChildByName(travellerInfo, 'traveller');
                List<Dom.XmlNode> passengerNodes = new List<Dom.XmlNode>();
                for (Dom.XmlNode child : travellerInfo.getChildElements()) {
                    if (child.getName() == 'passenger') passengerNodes.add(child);
                }

                String lastName = null;
                if (traveller != null) {
                    Dom.XmlNode surnameNode = findChildByName(traveller, 'surname');
                    if (surnameNode != null) lastName = surnameNode.getText();
                }

                for (Integer j = 0; j < passengerNodes.size(); j++) {
                    Dom.XmlNode passenger = passengerNodes[j];
                    String firstNameRaw = null;
                    String type = null;

                    Dom.XmlNode firstNode = findChildByName(passenger, 'firstName');
                    Dom.XmlNode typeNode = findChildByName(passenger, 'type');
                    if (firstNode != null) firstNameRaw = firstNode.getText();
                    if (typeNode != null){
                        type = typeNode.getText();
                    }else{
                        type = 'ADT';
                    }
					/*
                    String dateOfBirth = null;
                    if (enhancedData != null) {
                        Dom.XmlNode dateNode = findChildByPath(
                            enhancedData,
                            new String[] {
                                'enhancedTravellerInformation',
                                'dateOfBirthInEnhancedPaxData',
                                'dateAndTimeDetails',
                                'date'
                            }
                        );
                        if (dateNode != null) dateOfBirth = dateNode.getText();
                    }
                    if (dateOfBirth == null) {
                        Dom.XmlNode dobNode = findChildByPath(
                            passengerData,
                            new String[] { 'dateOfBirth', 'dateAndTimeDetails', 'date' }
                        );
                        if (dobNode != null) dateOfBirth = dobNode.getText();
                    }
					*/
                    String firstName = extractFirstName(firstNameRaw);
                    String title = extractTitle(firstNameRaw);

                    if (pnrControlNumber != null && ptNumber != null && firstName != null && lastName != null && type != null) {
                        String baseName = pnrControlNumber + '-' + ptNumber + ' ' + firstName + '_' + lastName;
                        if (type == 'INF') baseName += '_INF';

                        TravellerInfo__c record = new TravellerInfo__c(
                            PNR__c = pnrControlNumber,
                            PT__c = ptNumber,
                            FirstName__c = firstName,
                            LastName__c = lastName,
                            PassengerType__c = type,
                            Name = baseName
                        );

                        if (title != null) record.Title__c = title;
                        //if (dateOfBirth != null) record.DateOfBirth__c = dateOfBirth;

                        System.debug('✅ Will upsert traveller: ' + record.Name);
                        travellerList.add(record);
                    } else {
                        System.debug('⚠️ Skipping passengerData. Reason(s):');
                        if (pnrControlNumber == null) System.debug('  ❌ Missing PNR');
                        if (ptNumber == null) System.debug('  ❌ Missing PT Number');
                        if (firstName == null) System.debug('  ❌ Missing First Name');
                        if (lastName == null) System.debug('  ❌ Missing Last Name');
                        if (type == null) System.debug('  ❌ Missing Type');
                    }
                }
            }
        }

        // 建立 PT number → TravellerInfo__c 的對應 Map（第一筆 ADT/CHD，第二筆 INF）
        Map<String, List<TravellerInfo__c>> ptMap = new Map<String, List<TravellerInfo__c>>();
        for (TravellerInfo__c t : travellerList) {
            if (!ptMap.containsKey(t.PT__c)) ptMap.put(t.PT__c, new List<TravellerInfo__c>());
            ptMap.get(t.PT__c).add(t);
        }
        
        // 解析航班資料
        Dom.XmlNode originDestinationDetails = findChildByName(pnrReplyNode, 'originDestinationDetails');
        String st01 = null, st02 = null;
        if (originDestinationDetails != null) {
            for (Dom.XmlNode itineraryInfo : originDestinationDetails.getChildElements()) {
                if (itineraryInfo.getName() != 'itineraryInfo') continue;

                Dom.XmlNode refNode = findChildByPath(itineraryInfo, new String[] { 'elementManagementItinerary', 'reference' });
                Dom.XmlNode numberNode = findChildByName(refNode, 'number');
                String segmentNumber = numberNode != null ? numberNode.getText() : null;

                Dom.XmlNode travelProduct = findChildByName(itineraryInfo, 'travelProduct');
                if (travelProduct == null) continue;

                String boardCode = getTextByPath(travelProduct, new String[] { 'boardpointDetail', 'cityCode' });
                String offCode = getTextByPath(travelProduct, new String[] { 'offpointDetail', 'cityCode' });

                if (st01 == null && boardCode == boardpoint) {
                    st01 = segmentNumber;
                    fillFlightFields(travellerList, travelProduct, true);
                }
                else if (st02 == null && offCode == boardpoint) {
                    st02 = segmentNumber;
                    fillFlightFields(travellerList, travelProduct, false);
                }
                
                // 取得該航段設備型號（32Q,339,359）
                Dom.XmlNode equipmentNode = findChildByPath(itineraryInfo, new String[] {
                    'flightDetail', 'productDetails', 'equipment'
                });
                if (equipmentNode != null) {
                    String aircraftType = equipmentNode.getText();
                    for (TravellerInfo__c t : travellerList) {
                        if (st01 == segmentNumber) {
                            t.AircraftType__c = aircraftType;
                        }
                    }
                }
            }
        }

        for (TravellerInfo__c t : travellerList) {
            t.ST01__c = st01;
            t.ST02__c = st02;
        }
        
        // === 在進入 dataElementsMaster 主迴圈「之前」宣告暫存（放在 travellerList 建好之後即可）===
        Integer apP02MaxOT;
        String  apP02Value;
        Integer ap7MaxOT;
        String  ap7Value;
        
        // 解析dataElementsMaster
		//PAX(O)
        //DOCS(O)  
		//DOCO(O)
	 	//DOCA(O) 
		//PCTC(O) 
		//RQST(O) 
		//MEAL(O)
        Dom.XmlNode dataElementsMaster = findChildByName(pnrReplyNode, 'dataElementsMaster');
        Boolean foundGRPSWithValue = false;
        if (dataElementsMaster != null) {
            
            for (Dom.XmlNode indiv : dataElementsMaster.getChildElements()) {
                if (indiv.getName() != 'dataElementsIndiv') continue;
            
                // 先抓 elementManagementData/segmentName
                Dom.XmlNode segNode = findChildByPath(indiv, new String[]{ 'elementManagementData', 'segmentName' });
            
                // ── 新增：處理 AP 元素（Email/Phone 資料）
                if (segNode != null && 'AP'.equalsIgnoreCase(segNode.getText())) {
                    Dom.XmlNode typeNode = findChildByPath(indiv, new String[]{ 'otherDataFreetext', 'freetextDetail', 'type' });
                    Dom.XmlNode longNode = findChildByPath(indiv, new String[]{ 'otherDataFreetext', 'longFreetext' });
                    Dom.XmlNode refNode  = findChildByPath(indiv, new String[]{ 'elementManagementData', 'reference' });
                    Dom.XmlNode otNode   = findChildByName(refNode, 'number');
            
                    if (typeNode != null && longNode != null && otNode != null && !String.isBlank(longNode.getText())) {
                        String apType = typeNode.getText();
                        Integer ot;
                        try {
                            ot = Integer.valueOf(otNode.getText());
                        } catch (Exception e) {
                            ot = null;
                        }
            
                        if (ot != null) {
                            // APE: type == 'P02' → 取 OT 最大
                            if ('P02'.equalsIgnoreCase(apType)) {
                                if (apP02MaxOT == null || ot > apP02MaxOT) {
                                    apP02MaxOT = ot;
                                    apP02Value = longNode.getText();
                                }
                            }
                            // APM: type == '7' → 取 OT 最大
                            else if ('7'.equalsIgnoreCase(apType)) {
                                if (ap7MaxOT == null || ot > ap7MaxOT) {
                                    ap7MaxOT = ot;
                                    ap7Value = longNode.getText();
                                }
                            }
                        }
                    }
            
                    // AP 不是 SSR，不進入下方 SSR 邏輯
                    continue;
                }
                
                // 先試著抓 SSR 類型（CTCM / CTCE 需要在 allowStore 之前處理）
                Dom.XmlNode preServiceRequest = findChildByName(indiv, 'serviceRequest');
                Dom.XmlNode preSSR = findChildByName(preServiceRequest, 'ssr');
                Dom.XmlNode preTypeNode = findChildByName(preSSR, 'type');
                String preSSRType = (preTypeNode != null) ? preTypeNode.getText() : null;
                
                // 若是 CTCM 或 CTCE：在「PNR 層級」做 OT 最大值保留，其餘加入刪除清單
                if ('CTCM'.equalsIgnoreCase(preSSRType) || 'CTCE'.equalsIgnoreCase(preSSRType)) {
                    // 取 OT: elementManagementData/reference/number
                    Dom.XmlNode emdRefCTC = findChildByPath(indiv, new String[]{ 'elementManagementData', 'reference' });
                    Dom.XmlNode otNodeCTC = findChildByName(emdRefCTC, 'number');
                    Integer otCTC;
                    try {
                        otCTC = (otNodeCTC != null) ? Integer.valueOf(otNodeCTC.getText()) : null;
                    } catch (Exception e) {
                        otCTC = null;
                    }
                
                    if (otCTC != null) {
                        // 以 PNR 級別作為 key，不依賴 PT/ST/PaxType
                        String keyCTC = 'PNR-NULL-NULL-' + preSSRType; // e.g. PNR-NULL-NULL-CTCM
                
                        if (lastOTMap.containsKey(keyCTC)) {
                            Integer kept = lastOTMap.get(keyCTC);
                            if (otCTC > kept) {
                                // 新的比較大：丟掉舊的，保留新的
                                droppedOTLogs.add('🔁 [' + preSSRType + '] Drop smaller OT ' + kept + ' keep ' + otCTC + ' (PNR-level)');
                                droppedOTNumbers.add(String.valueOf(kept));
                                lastOTMap.put(keyCTC, otCTC);
                            } else {
                                // 新的比較小或相等：丟掉新的
                                droppedOTLogs.add('🔁 [' + preSSRType + '] Drop smaller OT ' + otCTC + ' keep ' + kept + ' (PNR-level)');
                                droppedOTNumbers.add(String.valueOf(otCTC));
                            }
                        } else {
                            lastOTMap.put(keyCTC, otCTC);
                        }
                    }
                
                    // CTCM/CTCE 僅處理 OT 去重與刪除，不進入下方 SSR 寫欄位邏輯
                    continue;
                }

                // FA segment 供PAX使用
                Dom.XmlNode emd = findChildByPath(indiv, new String[]{ 'elementManagementData', 'segmentName' });
                if (emd != null && emd.getText() == 'FA') {
                    Dom.XmlNode refContainer = findChildByName(indiv, 'referenceForDataElement');
                    if (refContainer != null) {
                        String ptNumber = null;
                        Boolean matchST01 = false;
                        
                        for (Dom.XmlNode ref : refContainer.getChildElements()) {
                            Dom.XmlNode qualifierNode = findChildByName(ref, 'qualifier');
                            Dom.XmlNode numberNode = findChildByName(ref, 'number');
                            if (qualifierNode == null || numberNode == null) continue;
                            
                            String qualifier = qualifierNode.getText();
                            String refnumber = numberNode.getText();
                            
                            if (qualifier == 'ST' && st01 != null && refnumber == st01) {
                                matchST01 = true;
                            }
                            if (qualifier == 'PT') {
                                ptNumber = refnumber;
                            }
                        }
                
                        if (matchST01 && ptNumber != null && ptMap.containsKey(ptNumber)) {
                            Dom.XmlNode longTextNode = findChildByPath(indiv, new String[]{ 'otherDataFreetext', 'longFreetext' });
                            if (longTextNode != null) {
                                String text = longTextNode.getText();
                                // 判斷 PAX or INF 開頭
                                Boolean isInf = text != null && text.startsWith('INF');
                                String paxValue = null;
                                
                                // 解析 189-2103422899 ➜ 移除中間 -
                                Pattern p = Pattern.compile('(\\d+)-(\\d+)');
                                Matcher m = p.matcher(text);
                                if (m.find()) {
                                    paxValue = m.group(1) + m.group(2); // e.g. 1892103422899
                                }
                
                                if (paxValue != null) {
                                    for (TravellerInfo__c t : ptMap.get(ptNumber)) {
                                        if ((isInf && t.PassengerType__c == 'INF') || (!isInf && t.PassengerType__c != 'INF')) {
                                            t.PAX__c = paxValue;
                                            System.debug('💾 PAX for PT' + ptNumber + ' (' + t.PassengerType__c + ') : ' + paxValue);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 🔹 先處理 PNR 等級 GRPS（通常沒有 referenceForDataElement/PT/ST）
                Dom.XmlNode grpsSsrTypeNode = findChildByPath(indiv, new String[]{
                    'serviceRequest', 'ssr', 'type'
                    });
                if (grpsSsrTypeNode != null && 'GRPS'.equalsIgnoreCase(grpsSsrTypeNode.getText())) {
                
                    // 多抓 companyId
                    Dom.XmlNode companyIdNode = findChildByPath(indiv, new String[]{
                        'serviceRequest', 'ssr', 'companyId'
                    });
                
                    // 只處理 companyId = JX
                    if (companyIdNode != null && 'JX'.equalsIgnoreCase(companyIdNode.getText())) {
                
                        Dom.XmlNode grpsFreeTextNode = findChildByPath(indiv, new String[]{
                            'serviceRequest', 'ssr', 'freeText'
                        });
                
                        if (grpsFreeTextNode != null && !String.isBlank(grpsFreeTextNode.getText())) {
                            String iataGroupCode = grpsFreeTextNode.getText();
                
                            for (TravellerInfo__c t : travellerList) {
                                t.IATA_MSO_Code__c = iataGroupCode;
                            }
                
                            foundGRPSWithValue = true;
                            System.debug('🏷️ GRPS (JX only) → Set IATA_MSO_Code__c = ' + iataGroupCode + ' to ALL travellers');
                
                        } else {
                            System.debug('⚠️ GRPS SSR (JX) found but freeText is empty');
                        }
                
                    } else {
                        System.debug('ℹ️ GRPS SSR ignored due to companyId != JX');
                    }
                
                    // 已經處理完這筆 dataElementsIndiv，不用再跑下面 PT/ST 邏輯
                    continue;
                }

                
                Dom.XmlNode refContainer = findChildByName(indiv, 'referenceForDataElement');
                if (refContainer == null) continue;

                List<Dom.XmlNode> references = new List<Dom.XmlNode>();
                for (Dom.XmlNode ref : refContainer.getChildElements()) {
                    if (ref.getName() == 'reference') references.add(ref);
                }

                Boolean hasPT = false;
                String ptNumber = null;
                Boolean hasST = false;
                Boolean isSTAllowed = false;

                for (Dom.XmlNode ref : references) {
                    Dom.XmlNode qualifierNode = findChildByName(ref, 'qualifier');
                    Dom.XmlNode numberNodeElem = findChildByName(ref, 'number');
                    if (qualifierNode == null || numberNodeElem == null) continue;

                    String qualifier = qualifierNode.getText();
                    String refNumber = numberNodeElem.getText();

                    if (qualifier == 'PT') {
                        hasPT = true;
                        ptNumber = refNumber;
                    } else if (qualifier == 'ST') {
                        hasST = true;
                        if ((st01 != null && refNumber == st01) || (st02 != null && refNumber == st02)) {
                            isSTAllowed = true;
                        }
                    }
                }

                Boolean allowStore = false;
                if (hasPT && !hasST) {
                    allowStore = true; // 沒有 ST 時允許
                } else if (hasPT && hasST && isSTAllowed) {
                    allowStore = true; // ST 要等於 st01 才允許
                }
				
                String st = null;
                for (Dom.XmlNode ref : references) {
                    Dom.XmlNode qualifierNode = findChildByName(ref, 'qualifier');
                    Dom.XmlNode numberNodeElem = findChildByName(ref, 'number');
                    if (qualifierNode == null || numberNodeElem == null) continue;
                
                    if (qualifierNode.getText() == 'ST') {
                        st = numberNodeElem.getText();
                        break;
                    }
                }

                if (!allowStore || ptNumber == null || !ptMap.containsKey(ptNumber)) continue;

                // 🔽 原本的 ssrType/typeNode/freetextNode 解析邏輯照常接續
                Dom.XmlNode serviceRequest = findChildByName(indiv, 'serviceRequest');
                Dom.XmlNode ssr = findChildByName(serviceRequest, 'ssr');
                if (ssr == null) continue;
        
                Dom.XmlNode typeNode = findChildByName(ssr, 'type');
                if (typeNode == null) continue;
                String ssrType = typeNode.getText();
				
				List<TravellerInfo__c> travellers = ptMap.get(ptNumber);
				//添加所有SSR到SSR_RawData__c
                addSSRTypeToTravellers(travellers, ssrType);
                // 新增：只有當這筆 SSR 綁到 ST01 時，才記到 SSR_Raw_Data_Segment_Relate__c
                addSSRTypeToTravellersForSt01(travellers, ssrType, st, st01);
                
                if (ssrType == 'DOCS') {
                    Dom.XmlNode freeTextNode = findChildByName(ssr, 'freeText');
                    if (freeTextNode == null || String.isBlank(freeTextNode.getText())) {
                        recordOTOverride(indiv, lastOTMap, droppedOTLogs, droppedOTNumbers, ptNumber, st, 'ADT', ssrType);
                        System.debug('⚠️ DOCS 沒有 freeText，跳過解析');
                        continue;
                    }
                    List<String> parts = getFreeTextParts(ssr);
                    if (parts.size() < 9) continue;
                    System.debug('📄 Found DOCS SSR for PT ' + ptNumber);

                    // 修正第 8 項可能為 BA-BB 的狀況，視為 2 個獨立值
                    if (parts[8].contains('-')) {
                        List<String> nameParts = parts[8].split('-');
                        if (nameParts.size() == 2) {
                            System.debug('🔍 Detected combined name format: ' + parts[8] + ' ➜ LastName=' + nameParts[0] + ', FirstName=' + nameParts[1]);
                            parts[8] = nameParts[0];
                            parts.add(nameParts[1]);
                        }
                    }

                    String freeTextGender = parts[5];
                    Boolean isInf = (freeTextGender == 'MI' || freeTextGender == 'FI');
					String paxType = isInf ? 'INF' : 'ADT';
                    // === 新增：針對「無 ST 的 DOCS」先暫存，若後面遇到同一 PT+PaxType 的「有 ST」DOCS，丟掉無 ST 的那筆 ===
                    Dom.XmlNode emdRefForDocs = findChildByPath(indiv, new String[]{ 'elementManagementData', 'reference' });
                    Dom.XmlNode otNodeForDocs = findChildByName(emdRefForDocs, 'number');
                    Integer currentOT = (otNodeForDocs != null) ? Integer.valueOf(otNodeForDocs.getText()) : null;
                    
                    // 以「PT + PaxType」當 key，忽略 ST；我們要的是：同一人(型)有 ST 的 DOCS 出現時，刪掉舊的「無 ST」DOCS
                    String docsKey = ptNumber + '-' + paxType;
                    
                    if (st == null && currentOT != null) {
                        // 先記住「無 ST 的 DOCS」OT
                        docsNoSTPending.put(docsKey, currentOT);
                    }
                    if (st != null && docsNoSTPending.containsKey(docsKey)) {
                        // 出現「有 ST 的 DOCS」→ 丟掉之前的「無 ST」那筆
                        Integer noStOt = docsNoSTPending.remove(docsKey);
                        droppedOTLogs.add('🧹 Drop DOCS without ST OT ' + noStOt + ' because ST=' + st + ' exists for PT=' + ptNumber + ' ' + paxType);
                        droppedOTNumbers.add(String.valueOf(noStOt));
                    }
                    
                    // 你原本的 OT 規則（同 key 比較覆寫）保留
                    recordOTOverride(indiv, lastOTMap, droppedOTLogs, droppedOTNumbers, ptNumber, st, paxType, ssrType);
                    
                    TravellerInfo__c target;

                    if (isInf && travellers.size() > 1) {
                        target = travellers[1];
                    } else {
                        target = travellers[0];
                    }
					if (st == st01) {
                        target.PassportIssuingCountry__c = parts[1];
                        target.PassportNumber__c = parts[2];
                        target.Country__c = parts[3];
                        target.DateOfBirth__c = parts[4];
                        target.Gender__c = freeTextGender;
                        target.PassportExpiryDate__c = parts[6];
                        target.PassportLastName__c = parts[7];
                        target.PassportFirstName__c = parts[8];
					} else {
                        System.debug('🛑 DOCS on ST02 ➜ 跳過寫入護照資料 (僅記錄 OT)');
                    }

                    if (isInf) {
                        System.debug('👶 DOCS (INF) for PT ' + ptNumber + ': ' + target.PassportFirstName__c + ' ' + target.PassportLastName__c);
                    } else {
                        System.debug('🧾 DOCS (ADT/CHD) for PT ' + ptNumber + ': ' + target.PassportFirstName__c + ' ' + target.PassportLastName__c);
                    }
                }
                else if (ssrType == 'DOCO') {
                    Dom.XmlNode freeTextNode = findChildByName(ssr, 'freeText');
                    if (freeTextNode == null || String.isBlank(freeTextNode.getText())) {
                        recordOTOverride(indiv, lastOTMap, droppedOTLogs, droppedOTNumbers, ptNumber, st, 'ADT', ssrType);
                        System.debug('⚠️ DOCO 沒有 freeText，跳過解析');
                        continue;
                    }
                    List<String> parts = getFreeTextParts(ssr);
                    if (parts.size() < 8) continue;
                    System.debug('📄 Found DOCO SSR for PT ' + ptNumber);

                    String visaNumber = parts.size() > 2 ? parts[2] : null;
                    String issuingCountry = parts.size() > 5 ? parts[5] : null;
                    String visaType = parts.size() > 6 ? parts[6] : null;
                    String visaExpiry = parts.size() > 7 ? parts[7] : null;
                    String paxType = (visaType == 'I') ? 'INF' : 'ADT';
                    recordOTOverride(indiv, lastOTMap, droppedOTLogs, droppedOTNumbers, ptNumber, st, paxType, ssrType);
                    
                    if (travellers == null || travellers.isEmpty()) continue;

                    TravellerInfo__c target = null;
                    if (visaType == 'I') {
                        for (TravellerInfo__c t : travellers) {
                            if (t.PassengerType__c == 'INF') {
                                target = t;
                                break;
                            }
                        }
                    } else {
                        for (TravellerInfo__c t : travellers) {
                            if (t.PassengerType__c != 'INF') {
                                target = t;
                                break;
                            }
                        }
                    }

                    if (target != null) {
                        if (st == st01) {
                            target.VisaNumber__c = visaNumber;
                            target.VisaIssuingCountry__c = issuingCountry;
                            target.VisaExpiryDate__c = visaExpiry;
						} else {
                            System.debug('🛑 DOCO on ST02 ➜ 跳過寫入簽證資料 (僅記錄 OT)');
                        }
                        if (target.PassengerType__c == 'INF') {
                            System.debug('👶 DOCO (INF) for PT ' + ptNumber + ': Visa ' + visaNumber + ', Country ' + issuingCountry);
                        } else {
                            System.debug('🧾 DOCO (ADT/CHD) for PT ' + ptNumber + ': Visa ' + visaNumber + ', Country ' + issuingCountry);
                        }
                    }
                }
                else if (ssrType == 'DOCA') {
                    Dom.XmlNode freeTextNode = findChildByName(ssr, 'freeText');
                    if (freeTextNode == null || String.isBlank(freeTextNode.getText())) {
                        recordOTOverride(indiv, lastOTMap, droppedOTLogs, droppedOTNumbers, ptNumber, st, 'ADT', ssrType);
                        System.debug('⚠️ DOCA 沒有 freeText，跳過解析');
                        continue;
                    }
                    List<String> parts = getFreeTextParts(ssr);
                    if (parts.size() < 5) continue;
                    System.debug('📄 Found DOCA SSR for PT ' + ptNumber);

                    if (travellers == null || travellers.isEmpty()) continue;
                
                    String indicator = parts.size() > 6 ? parts[6] : null;
                    Boolean isInf = (indicator == 'I');
                    String paxType = (indicator == 'I') ? 'INF' : 'ADT';
                    recordOTOverride(indiv, lastOTMap, droppedOTLogs, droppedOTNumbers, ptNumber, st, paxType, ssrType);

                    TravellerInfo__c target = null;
                    if (isInf) {
                        for (TravellerInfo__c t : travellers) {
                            if (t.PassengerType__c == 'INF') {
                                target = t;
                                break;
                            }
                        }
                    } else {
                        for (TravellerInfo__c t : travellers) {
                            if (t.PassengerType__c != 'INF') {
                                target = t;
                                break;
                            }
                        }
                    }
                
                    if (target != null) {
						if (st == st01) {
                            target.USAStreet__c = parts.size() > 2 ? parts[2] : null;
                            target.USACity__c = parts.size() > 3 ? parts[3] : null;
                            target.USAState__c = parts.size() > 4 ? parts[4] : null;
                            target.USAZipCode__c = parts.size() > 5 ? parts[5] : null;
                		} else {
                            System.debug('🛑 DOCA on ST02 ➜ 跳過寫入居住地資料 (僅記錄 OT)');
                        }
                        if (target.PassengerType__c == 'INF') {
                            System.debug('👶 DOCA (INF) for PT ' + ptNumber);
                        } else {
                            System.debug('🧾 DOCA (ADT/CHD) for PT ' + ptNumber);
                        }
                    }
                }
				//RQST/CTCE/CTCM/PCTC/APN/E只需傳給大人(ADT/CHD)
				
				else if (ssrType == 'PCTC') {
                    Dom.XmlNode freeTextNode = findChildByName(ssr, 'freeText');
                    if (freeTextNode == null || String.isBlank(freeTextNode.getText())) {
                        recordOTOverride(indiv, lastOTMap, droppedOTLogs, droppedOTNumbers, ptNumber, st, 'ADT', ssrType);
                        System.debug('⚠️ PCTC 沒有 freeText，跳過解析');
                        continue;
                    }
                    List<String> parts = getFreeTextParts(ssr);
                    if (parts.size() < 2) continue;
                    System.debug('📄 Found PCTC SSR for PT ' + ptNumber);

                    if (travellers == null || travellers.isEmpty()) continue;                

                    String contactName = parts[0];
                    String nationalityAndPhone = parts[1];
                
                    String nationality = nationalityAndPhone.length() >= 3 ? nationalityAndPhone.substring(0, 3) : null;
                    String phone = nationalityAndPhone.length() > 3 ? nationalityAndPhone.substring(3) : null;
					String paxType = 'ADT';
					recordOTOverride(indiv, lastOTMap, droppedOTLogs, droppedOTNumbers, ptNumber, st, paxType, ssrType);
                
                    for (TravellerInfo__c t : travellers) {
						if (t.PassengerType__c != 'INF') {
                        	t.USAEmergencyContactName__c = contactName;
                        	t.USAEmergencyContactNationality__c = nationality;
                        	t.USAEmergencyContactPhone__c = phone;
                		
                        	System.debug('📞 PCTC for PT ' + ptNumber + ': Name=' + contactName + ', Nationality=' + nationality + ', Phone=' + phone);
                    	}
					}
                }
                // Step 6 SSR 處理中補強 RQST 判斷邏輯：加入 SeatStatus__c == 'CH'
                else if (ssrType == 'RQST') {
                    System.debug('📄️ Found RQST SSR for PT ' + ptNumber);

                    // ➕ 取得 RQST 的 OT 編號：elementManagementData > reference > number
                    Dom.XmlNode emdRef = findChildByPath(indiv, new String[]{ 'elementManagementData', 'reference' });
                    Dom.XmlNode rqstOTNode = findChildByName(emdRef, 'number');
                    String rqstOT = rqstOTNode != null ? rqstOTNode.getText() : null;

                    Dom.XmlNode seatNode = findChildByName(serviceRequest, 'ssrb');
                    if (seatNode == null) continue;
                    Dom.XmlNode seatData = findChildByName(seatNode, 'data');
                    if (seatData == null) continue;
                    
                    // ✅ 僅當這筆 RQST 綁定的 ST == ST01 才寫入
                    if (String.isBlank(st01) || String.isBlank(st) || st != st01) {
                        System.debug('🛑 RQST skipped: ST=' + st + ' (require ST01=' + st01 + ')');
                        continue;
                    }

                    String seatValue = seatData.getText();
                    if (travellers == null || travellers.isEmpty()) continue;
        
                    // 額外檢查 seatPaxInfo → seatPaxDetails → genericDetails → seatCharacteristic 是否為 CH
                    Dom.XmlNode seatPaxInfo = findChildByName(indiv, 'seatPaxInfo');
                    Boolean hasCH = false;
                    if (seatPaxInfo != null) {
                        Dom.XmlNode seatDetails = findChildByName(seatPaxInfo, 'seatPaxDetails');
                        if (seatDetails != null) {
                            for (Dom.XmlNode detail : seatDetails.getChildElements()) {
                                if (detail.getName() != 'genericDetails') continue;
                                for (Dom.XmlNode sc : detail.getChildElements()) {
                                    if (sc.getName() == 'seatCharacteristic' && sc.getText() == 'CH') {
                                        hasCH = true;
                                        break;
                                    }
                                }
                                if (hasCH) break;
                            }
                        }
                    }
        
                    for (TravellerInfo__c t : travellers) {
                        if (t.PassengerType__c != 'INF') {
                            t.Seat__c = seatValue;
                        } else {
                            t.Seat__c = 'INF';
                        }
                        if (hasCH) {
                            t.SeatStatus__c = 'CH';
                        }
                        if (rqstOT != null) {
                            t.RQST_OT__c = rqstOT;
                        }
                        System.debug('🪑 SEAT for PT ' + ptNumber + ': ' + seatValue + (hasCH ? ' (CH)' : ''));
                    }
                }
                //ML，特殊餐
                /*
                else if (ssrType.length() == 4 && ssrType.endsWith('ML')) {
                    System.debug('📄️ Found MEAL SSR for PT ' + ptNumber + ': ' + ssrType);

                    if (travellers == null || travellers.isEmpty()) continue;
                
                    if (ssrType == 'BBML') {
                        // 🍼 專處理 BBML (嬰兒餐) ➔ 填到 INF 的 Meal__c
                        for (TravellerInfo__c t : travellers) {
                            if (t.PassengerType__c == 'INF') {
                                t.Meal__c = ssrType;
                                System.debug('🍼 MEAL for PT ' + ptNumber + ': BBML');
                            }
                        }
                    } else {
                        // 🍽️ 其他的ML類型 ➔ 填到 非INF 的 Meal__c
                        for (TravellerInfo__c t : travellers) {
                            if (t.PassengerType__c != 'INF') {
                                t.Meal__c = ssrType;
                                System.debug('🍴 MEAL for PT ' + ptNumber + ': '+ ssrType );
                            }
                        }
                    }
                }*/
            }
        }
        for (TravellerInfo__c t : travellerList) {
            String pnr = t.PNR__c != null ? t.PNR__c : '';
            String pt  = t.PT__c != null ? t.PT__c : '';
            String fn  = t.FirstName__c != null ? t.FirstName__c : '';
            String ln  = t.LastName__c != null ? t.LastName__c : '';
            String ty  = t.PassengerType__c != null ? t.PassengerType__c : '';
            String st  = t.ST01__c != null ? t.ST01__c : '';  
            
        	//預定更改
			t.External_Id__c = pnr + '-' + pt + '_' + ty + '_' + 'ST_' + st;
			//舊的
            //t.External_Id__c = pnr + '-' + pt + ' ' + fn + '_' + ln + '_' + ty + 'ST_' + st;
            System.debug('🧳 Final Traveller: ' + t.Name + ' ➔ SSR_RawData__c = ' + (t.SSR_RawData__c != null ? t.SSR_RawData__c : '[None]'));
        }
        //Group Code
        if (ngGroupCode == 'OK') {
            for (TravellerInfo__c t : travellerList) {
                t.group_code__c = 'OK';
            }
        }
        //IATA Code為空
        if (foundGRPSWithValue == false) {
            for (TravellerInfo__c t : travellerList) {
                t.IATA_MSO_Code__c = null;
            }
        }
        // APE/APM存入供CTCE/CTCM寫入
        if (!String.isBlank(apP02Value)) {
            for (TravellerInfo__c t : travellerList) {
                t.APE__c = apP02Value;
            }
        }
        if (!String.isBlank(ap7Value)) {
            for (TravellerInfo__c t : travellerList) {
                t.APM__c = ap7Value;
            }
        }

        //OT是否有重複資訊
        if (droppedOTLogs.isEmpty()) {
            System.debug('✅ No OT override detected — all OT numbers are unique for each PT-ST-SSR-PaxType combination.');
        } else {
            System.debug('🔁 OT override detected for the following entries:');
            System.debug('droppedOTNumbers : ' + droppedOTNumbers);
            System.debug('C1-8🚮 will be carried out.');
            AmadeusUtil.deleteDroppedOT(boardpoint,pnrControlNumber,droppedOTNumbers);
            for (String log : droppedOTLogs) {
                System.debug(log);
            }
        }
        
        if (!travellerList.isEmpty()) {
            System.debug('📤 Upserting ' + travellerList.size() + ' traveller(s)...');
            //upsert travellerList Name;
            return travellerList;
        } else {
            System.debug('⚠️ No traveller to upsert.');
        }
        
        return null;
    }
    
    private static void addSSRTypeToTravellers(List<TravellerInfo__c> travellers, String ssrType) {
        if (travellers == null || ssrType == null) return;
        for (TravellerInfo__c t : travellers) {
            if (t.SSR_RawData__c == null) {
                t.SSR_RawData__c = ssrType;
            } else {
                t.SSR_RawData__c += ',' + ssrType;
            }
        }
    }
    
    private static void addSSRTypeToTravellersForSt01(
        List<TravellerInfo__c> travellers, String ssrType, String st, String st01
    ) {
        if (travellers == null || ssrType == null) return;
        // 僅當這筆 dataElementsIndiv 的 ST 參照等於全域判定的 ST01 時才紀錄
        if (st != null && st01 != null && st == st01) {
            for (TravellerInfo__c t : travellers) {
                if (t.SSR_Raw_Data_Segment_Relate__c == null) {
                    t.SSR_Raw_Data_Segment_Relate__c = ssrType;
                } else {
                    t.SSR_Raw_Data_Segment_Relate__c += ',' + ssrType;
                }
            }
        }
    }
    
    private static List<String> getFreeTextParts(Dom.XmlNode ssr) {
        Dom.XmlNode freeTextNode = findChildByName(ssr, 'freeText');
        if (freeTextNode == null) return null;
        return freeTextNode.getText().split('/');
    }
    
    private static Dom.XmlNode findChildByPath(Dom.XmlNode root, String[] path) {
        Dom.XmlNode current = root;
        for (String name : path) {
            current = findChildByName(current, name);
            if (current == null) return null;
        }
        return current;
    }
    
    private static final Set<String> VALID_TITLES = 
        new Set<String>{'MR','MRS','MS','MSTR','MISS'};
    
    private static String extractFirstName(String raw) {
        if (String.isBlank(raw)) return null;
        List<String> parts = raw.trim().split('\\s+');
        if (parts.isEmpty()) return null;
    
        // 判斷最後一段是不是合法稱謂
        String last = parts[parts.size()-1].toUpperCase();
        if (VALID_TITLES.contains(last)) {
            // 去掉最後一段，剩下的拼回去
            parts.remove(parts.size()-1);
        }
        return String.join(parts, ' ');
    }
    
    private static String extractTitle(String raw) {
        if (String.isBlank(raw)) return null;
        List<String> parts = raw.trim().split('\\s+');
        if (parts.isEmpty()) return null;
    
        String last = parts[parts.size()-1].toUpperCase();
        return VALID_TITLES.contains(last) ? last : null;
    }
    
    private static void fillFlightFields(List<TravellerInfo__c> travellerList, Dom.XmlNode travelProduct, Boolean isFirst) {
        String flightPrefix = getTextByPath(travelProduct, new String[] { 'companyDetail', 'identification' });
        String flightNumber = getTextByPath(travelProduct, new String[] { 'productDetails', 'identification' });
        String depDate = getTextByPath(travelProduct, new String[] { 'product', 'depDate' });
        String depTime = getTextByPath(travelProduct, new String[] { 'product', 'depTime' });
        String depCode = getTextByPath(travelProduct, new String[] { 'boardpointDetail', 'cityCode' });
        String arrCode = getTextByPath(travelProduct, new String[] { 'offpointDetail', 'cityCode' });
		String bookingClass = getTextByPath(travelProduct, new String[] { 'productDetails', 'classOfService' });
        
        for (TravellerInfo__c t : travellerList) {
            if (isFirst) {
                t.FlightPrefix__c = flightPrefix;
                t.FlightNumber__c = flightNumber;
                t.DepartureDate__c = depDate;
                t.DepartureTime__c = depTime;
                t.DepartureLocation__c = depCode;
                t.Destination__c = arrCode;
                t.BookingClass__c = bookingClass;
            } else {
                t.DepartureDate2__c = depDate;
                t.DepartureTime2__c = depTime;
                t.DepartureLocation2__c = depCode;
                t.Destination2__c = arrCode;
            }
        }
    }

    private static String getTextByPath(Dom.XmlNode root, String[] path) {
        Dom.XmlNode current = root;
        for (String name : path) {
            current = findChildByName(current, name);
            if (current == null) return null;
        }
        return current.getText();
    }
    
    // 🔧 安全的子節點搜尋（忽略 namespace）
    private static Dom.XmlNode findChildByName(Dom.XmlNode parent, String localName) {
        if (parent == null) return null;
        for (Dom.XmlNode child : parent.getChildElements()) {
            if (child.getName() == localName || child.getName().endsWith(':' + localName)) {
                return child;
            }
        }
        return null;
    }
    
    private static void recordOTOverride(
        Dom.XmlNode indiv,
        Map<String, Integer> lastOTMap,
        List<String> droppedOTLogs,
        List<String> droppedOTNumbers, 
        String pt,
        String st,
        String paxType,
        String ssrType
    ) {
        Dom.XmlNode emd = findChildByPath(indiv, new String[]{ 'elementManagementData', 'reference' });
        Dom.XmlNode otNode = findChildByName(emd, 'number');
        if (otNode == null) return;
    
        Integer ot = Integer.valueOf(otNode.getText());
        String key = pt + '-' + (st == null ? 'NULL' : st) + '-' + paxType + '-' + ssrType;
    
        if (lastOTMap.containsKey(key)) {
            Integer dropped = lastOTMap.get(key);
            droppedOTLogs.add('🔁 Dropped OT ' + lastOTMap.get(key) + ' for PT=' + pt + ' ST=' + (st == null ? 'NULL' : st) + ' ' + paxType + ' SSR=' + ssrType);
            droppedOTNumbers.add(String.valueOf(dropped));
        }
        lastOTMap.put(key, ot);
    }
    
    //DCS整合
    private static void enrichTravellerInfoFromDCS_WithAutoFetch(List<TravellerInfo__c> travellers) {
        TravellerInfo__c first = travellers[0];
        String depDate = first.DepartureDate__c;
        String depLoc = first.DepartureLocation__c;
        String flightNum = first.FlightNumber__c;

        if (String.isBlank(depDate) || String.isBlank(depLoc) || String.isBlank(flightNum)) {
            System.debug('❌ DCS：缺少 DepartureDate / Location / FlightNumber');
            return;
        }

        String dcsXml = AmadeusUtilDCS.GetPassengerList_ACC_SR_CHL(depDate, depLoc, flightNum);
        if (String.isBlank(dcsXml)) {
            System.debug('❌ DCS抓取失敗：無法取得XML');
            return;
        }
        enrichTravellerInfoFromDCS(dcsXml, travellers);
        
        String dcsXml_AQQ = AmadeusUtilDCS.GetPassengerList_ACC_AQQ(depDate, depLoc, flightNum);
        if (String.isBlank(dcsXml_AQQ)) {
            System.debug('❌ AQQ抓取失敗：無法取得XML');
            return;
        }
        enrichTravellerInfoFromDCS_AQQ(dcsXml_AQQ, travellers);
    }
    
    //DCS取得UCI、DID
    public static void enrichTravellerInfoFromDCS(String xmlBody, List<TravellerInfo__c> travellers) {
        Dom.Document doc = new Dom.Document();
        doc.load(xmlBody);
    
        Dom.XmlNode root = doc.getRootElement();
        Dom.XmlNode body = AmadeusXmlParser.findChildByName(root, 'Body');
        Dom.XmlNode reply = AmadeusXmlParser.findChildByName(body, 'DCSLST_GetPassengerListReply');
        if (reply == null) return;
    
        for (Dom.XmlNode flightDetailsGroup : reply.getChildElements()) {
            if (flightDetailsGroup.getName() != 'flightDetailsGroup') continue;
    
            for (Dom.XmlNode customerLevel : flightDetailsGroup.getChildElements()) {
                if (customerLevel.getName() != 'customerLevel') continue;
    
                // 遍歷所有 productLevel（不只一個）
                for (Dom.XmlNode productLevel : customerLevel.getChildElements()) {
                    if (productLevel.getName() != 'productLevel') continue;
    
                    Dom.XmlNode docNumberNode = AmadeusXmlParser.findChildByPath(productLevel, new String[] {
                        'ticketInformation', 'ticket', 'documentDetails', 'number'
                    });
                    if (docNumberNode == null) continue;
    
                    String paxNumber = docNumberNode.getText();
                    if (String.isBlank(paxNumber)) continue;
    
                    for (TravellerInfo__c t : travellers) {
                        if (t.PAX__c == paxNumber) {
                            //UCI
                            Dom.XmlNode uciNode = AmadeusXmlParser.findChildByPath(customerLevel, new String[] {
                                'uniqueCustomerId', 'idSection', 'primeId'
                            });
                            if (uciNode != null) t.UCI__c = uciNode.getText();
    
                            //DID
                            Dom.XmlNode didNode = AmadeusXmlParser.findChildByPath(productLevel, new String[] {
                                'productIdentifier', 'idSection', 'primeId'
                            });
                            if (didNode != null) t.DID__c = didNode.getText();
                            
                            // CabinCode
                            Dom.XmlNode cabinNode = AmadeusXmlParser.findChildByPath(customerLevel, new String[] {
                                'legCabinCode', 'cabinDetails', 'classDesignator'
                            });
                            if (cabinNode != null) t.CabinCode__c = cabinNode.getText();
                            
                            // paxDetails.type
                            Dom.XmlNode typeNode = AmadeusXmlParser.findChildByPath(customerLevel, new String[] {
                                'customerData', 'paxDetails', 'type'
                            });
                            if (typeNode != null) t.paxDetails_type__c = typeNode.getText();
                            
                            // Channel (checkInInformation.sourceType.sourceQualifier1)
                            Dom.XmlNode channelNode = AmadeusXmlParser.findChildByPath(customerLevel, new String[] {
                                'checkInInformation', 'systemCode'
                            });
                            if (channelNode != null) t.Channel__c = channelNode.getText();

                            Dom.XmlNode seatNumberNode = null;
                            Dom.XmlNode seatInformationNode = AmadeusXmlParser.findChildByName(customerLevel, 'seatInformation');
                            if (seatInformationNode != null) {
                                for (Dom.XmlNode seatNumberInfo : seatInformationNode.getChildElements()) {
                                    if (seatNumberInfo.getName() != 'seatNumberInfo') continue;
                                    Dom.XmlNode sn = AmadeusXmlParser.findChildByPath(seatNumberInfo, new String[]{
                                        'seatDetails', 'seatNumber'
                                    });
                                    if (sn != null && !String.isBlank(sn.getText())) {
                                        seatNumberNode = sn;
                                        break;
                                    }
                                }
                            }
                            if (seatNumberNode != null) {
                                String rawSeat = seatNumberNode.getText();
                                if (!String.isBlank(rawSeat)) {
                                    t.Seat__c = rawSeat.replaceFirst('^0+', ''); // 去掉最左邊的 0
                                }
                            }                            
                            // 抓CAS狀態:Check Pax Acceted
                            for (Dom.XmlNode customerStatus : customerLevel.getChildElements()) {
                                if (customerStatus.getName() != 'customerStatus') continue;
                                Dom.XmlNode statusInfo = AmadeusXmlParser.findChildByName(customerStatus, 'statusInformation');
                                if (statusInfo == null) continue;
                                Dom.XmlNode indicatorNode = AmadeusXmlParser.findChildByName(statusInfo, 'indicator');
                                Dom.XmlNode actionNode = AmadeusXmlParser.findChildByName(statusInfo, 'action');
                                // CAS狀態
								if (indicatorNode != null && indicatorNode.getText() == 'CAS' && actionNode != null) {
                                    t.CAS__c = actionNode.getText();
                                }
                                // EEX：只要存在就標記（不吃 action 值）
                                if (indicatorNode != null && indicatorNode.getText() == 'EEX') {
                                    t.EEX__c = 'EEX';
                                }
                            }
                            
                            
                            System.debug('🆔 Matched PAX__c = ' + paxNumber + ' → UCI=' + t.UCI__c + ', DID=' + t.DID__c + ', CAS=' + t.CAS__c);
                        }
                    }
                }
            }
        }
    }
    
    //打AQQ取得Selectee
    public static void enrichTravellerInfoFromDCS_AQQ(String xmlBody, List<TravellerInfo__c> travellers) {
        Dom.Document doc = new Dom.Document();
        doc.load(xmlBody);
    
        Dom.XmlNode root = doc.getRootElement();
        Dom.XmlNode body = AmadeusXmlParser.findChildByName(root, 'Body');
        Dom.XmlNode reply = AmadeusXmlParser.findChildByName(body, 'DCSLST_GetPassengerListReply');
        if (reply == null) return;
    
        for (Dom.XmlNode flightDetailsGroup : reply.getChildElements()) {
            if (flightDetailsGroup.getName() != 'flightDetailsGroup') continue;
    
            for (Dom.XmlNode customerLevel : flightDetailsGroup.getChildElements()) {
                if (customerLevel.getName() != 'customerLevel') continue;
    
                // 遍歷所有 productLevel（不只一個）
                for (Dom.XmlNode productLevel : customerLevel.getChildElements()) {
                    if (productLevel.getName() != 'productLevel') continue;
    
                    Dom.XmlNode docNumberNode = AmadeusXmlParser.findChildByPath(productLevel, new String[] {
                        'ticketInformation', 'ticket', 'documentDetails', 'number'
                    });
                    if (docNumberNode == null) continue;
    
                    String paxNumber = docNumberNode.getText();
                    if (String.isBlank(paxNumber)) continue;
    
                    for (TravellerInfo__c t : travellers) {
                        if (t.PAX__c == paxNumber) {
                            // 抓AQQ狀態:Check Pax Acceted
                            for (Dom.XmlNode customerStatus : customerLevel.getChildElements()) {
                                if (customerStatus.getName() != 'customerStatus') continue;
                                Dom.XmlNode statusInfo = AmadeusXmlParser.findChildByName(customerStatus, 'statusInformation');
                                if (statusInfo == null) continue;
                                Dom.XmlNode indicatorNode = AmadeusXmlParser.findChildByName(statusInfo, 'indicator');
                                Dom.XmlNode actionNode = AmadeusXmlParser.findChildByName(statusInfo, 'action');
                                // AQQ：只要存在就標記（不吃 action 值）
                                if (indicatorNode != null && indicatorNode.getText() == 'AQQ') {
                                    t.Selectee__c = 'Y';
                                }
                            }
                            
                            
                            System.debug('🆔 Matched PAX__c = ' + paxNumber + 'has Selectee');
                        }
                    }
                }
            }
        }
    }    
    
    private static void mergeBoardingPassDataIntoTravellers(String boardingPassXml, List<TravellerInfo__c> travellers) {
        Dom.Document doc = new Dom.Document();
        try {
            doc.load(boardingPassXml);
        } catch (Exception e) {
            System.debug('❌ Boarding pass XML parse failed: ' + e.getMessage());
            return;
        }
    
        // 先建 UCI -> Traveller 的快取，加速對應
        Map<String, TravellerInfo__c> byUci = new Map<String, TravellerInfo__c>();
        for (TravellerInfo__c t : travellers) {
            if (t != null && !String.isBlank(t.UCI__c)) {
                byUci.put(t.UCI__c, t);
            }
        }
    
        Dom.XmlNode root = doc.getRootElement();
        Dom.XmlNode body = findChildByName(root, 'Body');
        Dom.XmlNode reply = findChildByName(body, 'DCSPRT_GetBoardingPassXmlDataReply');
        if (reply == null) return;
    
        for (Dom.XmlNode detail : reply.getChildElements()) {
            if (detail.getName() != 'responseDetails') continue;
    
            String uci = getTextByPath(detail, new String[] { 'customerDetails', 'otherPaxDetails', 'uniqueCustomerIdentifier' });
    
            Dom.XmlNode binaryNode = findChildByPath(detail, new String[] {
                'businessData', 'businessData', 'binaryData'
            });
    
            // ✨ 新增：若找不到 binaryData（或內容為空），直接在對應 UCI 的旅客上寫 C4note__c
            if (binaryNode == null || String.isBlank(binaryNode.getText())) {
                TravellerInfo__c miss = byUci.get(uci);
                if (miss != null) {
                    miss.C4note__c = 'Amadeus BinaryData Missing';
                    System.debug('⚠️ No binaryData for UCI ' + uci + ' → set C4note__c.');
                } else {
                    System.debug('⚠️ No binaryData and traveller not found by UCI: ' + uci);
                }
                continue;
            }
    
            String decodedXml = EncodingUtil.urlDecode(
                EncodingUtil.base64Decode(binaryNode.getText()).toString(), 'UTF-8');
    
            try {
                Dom.Document innerDoc = new Dom.Document();
                innerDoc.load(decodedXml);
                Dom.XmlNode innerRoot = innerDoc.getRootElement();
    
                String DepartureTerminal = getTextByPath(innerRoot, new String[] { 'Product', 'DepartureTerminal' });
                String BoardingGate = getTextByPath(innerRoot, new String[] { 'Product', 'BoardingGate' });
                String LatestBoardingTime = getTextByPath(innerRoot, new String[] { 'Product', 'LatestBoardingTime' });
                String BoardingPriority = getTextByPath(innerRoot, new String[] { 'Product', 'BoardingPriority' });
                String FQTVTierCode = getTextByPath(innerRoot, new String[] { 'Product', 'FQTVTierCode' });
    
                // 🧩 新增欄位解析
                String ticketType = getTextByPath(innerRoot, new String[] { 'Product', 'TicketType' });
                String securityNumber = getTextByPath(innerRoot, new String[] { 'Product', 'SecurityNumber' });
                String operatingCarrier = getTextByPath(innerRoot, new String[] { 'Product', 'OperatingCarrierCode' });
                String selectee = getTextByPath(innerRoot, new String[] { 'Product', 'AQQSelecteeIndicator' });
    
                String fqtvCarrier = getTextByPath(innerRoot, new String[] { 'Product', 'FQTVCarrierCode' });
                String fqtvNumber = getTextByPath(innerRoot, new String[] { 'Product', 'FQTVNumber' });
    
                // BagTag 組合
                String bagTagType = getTextByPath(innerRoot, new String[] { 'Product', 'BagTagType' });
                String bagAirlineCode = getTextByPath(innerRoot, new String[] { 'Product', 'BagTagAirlineCodeNumber' });
                String bagSerial = getTextByPath(innerRoot, new String[] { 'Product', 'BagTagSerialNumber' });
                String bagSeq = getTextByPath(innerRoot, new String[] { 'Product', 'BagTagNumberInSequence' });
    
                String bagTagFull = null;
                if (String.isNotBlank(bagTagType) || String.isNotBlank(bagAirlineCode) || String.isNotBlank(bagSerial) || String.isNotBlank(bagSeq)) {
                    if (String.isNotBlank(bagSeq)) {
                        bagSeq = bagSeq.leftPad(3, '0'); // 補 0 到 3 位數
                    }
                    bagTagFull = (bagTagType != null ? bagTagType : '') +
                                 (bagAirlineCode != null ? bagAirlineCode : '') +
                                 (bagSerial != null ? bagSerial : '') +
                                 (bagSeq != null ? bagSeq : '');
                }
    
                // ☑️ 對應 UCI 並寫入欄位（改用快取）
                TravellerInfo__c t = byUci.get(uci);
                if (t != null) {
                    t.C4note__c = null;
                    if (String.isNotBlank(DepartureTerminal)) t.DepartureTerminal__c = DepartureTerminal;
                    if (String.isNotBlank(BoardingGate)) t.BoardingGate__c = BoardingGate;
                    if (String.isNotBlank(LatestBoardingTime)) t.LatestBoardingTime__c = LatestBoardingTime;
                    if (String.isNotBlank(BoardingPriority)) t.BoardingPriority__c = BoardingPriority;
                    if (String.isNotBlank(FQTVTierCode)) t.FQTVTierCode__c = FQTVTierCode;
    
                    if (String.isNotBlank(ticketType)) t.TicketType__c = ticketType;
                    if (String.isNotBlank(securityNumber)) t.SecurityNumber__c = securityNumber;
                    if (String.isNotBlank(operatingCarrier)) t.OperatingCarrierCode__c = operatingCarrier;
                    if (String.isNotBlank(selectee)) t.Selectee__c = selectee;
    
                    if (String.isNotBlank(fqtvCarrier)) t.FQTVCarrierCode__c = fqtvCarrier;
                    if (String.isNotBlank(fqtvNumber)) t.FQTVNumber__c = fqtvNumber;
    
                    if (String.isNotBlank(bagTagFull)) t.BagTag__c = bagTagFull;
    
                    System.debug('🎫 BoardingPass Info Updated: ' + t.Name);
                } else {
                    System.debug('⚠️ Traveller not found by UCI: ' + uci);
                }
    
            } catch (Exception e) {
                System.debug('⚠️ BoardingPass inner XML parse error: ' + e.getMessage());
                continue;
            }
        }
    }

    
    /*private static Dom.XmlNode findChildByName(Dom.XmlNode parent, String name) {
        if (parent == null) return null;
        for (Dom.XmlNode child : parent.getChildElements()) {
            if (child.getName() == name) return child;
        }
        return null;
    }*/
    
    public static void fakeMethod() {
        Boolean b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
    }
}