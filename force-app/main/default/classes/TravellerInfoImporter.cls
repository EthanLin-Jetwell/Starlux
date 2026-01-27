public class TravellerInfoImporter {

    public static void importFromResponseBody(String body, String pnr, String boardpoint) {
        parseTravellerInfoFromXML(body, pnr, boardpoint);
    }
    
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

        parseTravellerInfoFromXML(fullXml, log.PNR__c,boardpoint);
    }

    private static void parseTravellerInfoFromXML(String xmlBody, String fallbackPNR, String boardpoint) {
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

        for (Dom.XmlNode travellerInfoNode : pnrReplyNode.getChildElements()) {
            if (travellerInfoNode.getName() != 'travellerInfo') continue;
            System.debug('📦 Processing <travellerInfo>...');

            Dom.XmlNode empNode = findChildByName(travellerInfoNode, 'elementManagementPassenger');
            if (empNode == null) continue;

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
                    if (typeNode != null) type = typeNode.getText();

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
                        if (dateOfBirth != null) record.DateOfBirth__c = dateOfBirth;

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
            }
        }

        for (TravellerInfo__c t : travellerList) {
            t.ST01__c = st01;
            t.ST02__c = st02;
        }
        
        
        // 解析dataElementsMaster
        //DOCS(O)  
		//DOCO(O)
	 	//DOCA(O)
		//PCTC(O)
		//MEAL(O)
		//RQST(O)
        Dom.XmlNode dataElementsMaster = findChildByName(pnrReplyNode, 'dataElementsMaster');
        if (dataElementsMaster != null) {
            // 🔎 預處理：只保留 DOCS / DOCO / DOCA / PCTC 中每組 (PT-ST) 最大 OT 的 indiv
            Map<String, Dom.XmlNode> bestIndivMap = new Map<String, Dom.XmlNode>();
            Map<String, Integer> bestOTMap = new Map<String, Integer>();
            Set<String> droppedOTNumbers = new Set<String>();
        
            for (Dom.XmlNode indiv : dataElementsMaster.getChildElements()) {
                if (indiv.getName() != 'dataElementsIndiv') continue;
        
                Dom.XmlNode serviceRequest = findChildByName(indiv, 'serviceRequest');
                Dom.XmlNode ssr = findChildByName(serviceRequest, 'ssr');
                if (ssr == null) continue;
                Dom.XmlNode typeNode = findChildByName(ssr, 'type');
                if (typeNode == null) continue;
        
                String ssrType = typeNode.getText();
                if (!new Set<String>{ 'DOCS', 'DOCO', 'DOCA', 'PCTC' }.contains(ssrType)) continue;
        
                Dom.XmlNode refContainer = findChildByName(indiv, 'referenceForDataElement');
                if (refContainer == null) continue;
        
                String pt = null;
                String st = null;
                for (Dom.XmlNode ref : refContainer.getChildElements()) {
                    Dom.XmlNode q = findChildByName(ref, 'qualifier');
                    Dom.XmlNode num = findChildByName(ref, 'number');
                    if (q == null || num == null) continue;
                    if (q.getText() == 'PT') pt = num.getText();
                    if (q.getText() == 'ST') st = num.getText();
                }
                if (pt == null) continue;
        
                String key = pt + '-' + (st == null ? 'NULL' : st);
        
                Dom.XmlNode emd = findChildByPath(indiv, new String[]{ 'elementManagementData', 'reference' });
                Dom.XmlNode otNode = findChildByName(emd, 'number');
                if (otNode == null) continue;
                Integer ot = Integer.valueOf(otNode.getText());
        

                // 在 droppedOTNumbers 處理區塊中同步記錄 OT 值
                if (!bestOTMap.containsKey(key) || ot > bestOTMap.get(key)) {
                    if (bestOTMap.containsKey(key)) {
                        droppedOTNumbers.add(String.valueOf(bestOTMap.get(key)));
                    }
                    bestIndivMap.put(key, indiv);
                    bestOTMap.put(key, ot);
                } else {
                    droppedOTNumbers.add(String.valueOf(ot));
                }
				System.debug('🗑 Dropped OT Numbers: ' + droppedOTNumbers);
                /* 之後補上 WBS 1-8 刪除 droppedOTNumbers 內的 數值 */
            }
        
            // ⚙️ 主處理：逐筆 indiv 處理，四類 SSR 檢查 OT，其他原邏輯照常
            for (Dom.XmlNode indiv : dataElementsMaster.getChildElements()) {
                if (indiv.getName() != 'dataElementsIndiv') continue;
        
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
                String st = null;
        
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
                        st = refNumber;
                        if (st01 != null && refNumber == st01) {
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
        
                if (!allowStore || ptNumber == null || !ptMap.containsKey(ptNumber)) continue;
        
                // 只對四類 SSR 套 OT 過濾邏輯
                Dom.XmlNode serviceRequest = findChildByName(indiv, 'serviceRequest');
                Dom.XmlNode ssr = findChildByName(serviceRequest, 'ssr');
                if (ssr == null) continue;
                Dom.XmlNode typeNode = findChildByName(ssr, 'type');
                if (typeNode == null) continue;
        
                String ssrType = typeNode.getText();
                if (new Set<String>{ 'DOCS', 'DOCO', 'DOCA', 'PCTC' }.contains(ssrType)) {
                    String key = ptNumber + '-' + (st == null ? 'NULL' : st);
                    if (!bestIndivMap.containsKey(key) || bestIndivMap.get(key) != indiv) continue;
                }
                List<TravellerInfo__c> travellers = ptMap.get(ptNumber);
                //添加所有SSR到SSR_RawData__c
                addSSRTypeToTravellers(travellers, ssrType);
                
                if (ssrType == 'DOCS') {
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

                    TravellerInfo__c target;

                    if (isInf && travellers.size() > 1) {
                        target = travellers[1];
                    } else {
                        target = travellers[0];
                    }

                    target.PassportIssuingCountry__c = parts[1];
                    target.PassportNumber__c = parts[2];
                    target.Country__c = parts[3];
                    target.DateOfBirth__c = parts[4];
                    target.Gender__c = freeTextGender;
                    target.PassportExpiryDate__c = parts[6];
                    target.PassportLastName__c = parts[7];
                    target.PassportFirstName__c = parts[8];

                    if (isInf) {
                        System.debug('👶 DOCS (INF) for PT ' + ptNumber + ': ' + target.PassportFirstName__c + ' ' + target.PassportLastName__c);
                    } else {
                        System.debug('🧾 DOCS (ADT/CHD) for PT ' + ptNumber + ': ' + target.PassportFirstName__c + ' ' + target.PassportLastName__c);
                    }
                }
                else if (ssrType == 'DOCO') {
                    List<String> parts = getFreeTextParts(ssr);
                    if (parts.size() < 8) continue;
                    System.debug('📄 Found DOCO SSR for PT ' + ptNumber);

                    String visaNumber = parts.size() > 2 ? parts[2] : null;
                    String issuingCountry = parts.size() > 5 ? parts[5] : null;
                    String visaType = parts.size() > 6 ? parts[6] : null;
                    String visaExpiry = parts.size() > 7 ? parts[7] : null;

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
                        target.VisaNumber__c = visaNumber;
                        target.VisaIssuingCountry__c = issuingCountry;
                        target.VisaExpiryDate__c = visaExpiry;

                        if (target.PassengerType__c == 'INF') {
                            System.debug('👶 DOCO (INF) for PT ' + ptNumber + ': Visa ' + visaNumber + ', Country ' + issuingCountry);
                        } else {
                            System.debug('🧾 DOCO (ADT/CHD) for PT ' + ptNumber + ': Visa ' + visaNumber + ', Country ' + issuingCountry);
                        }
                    }
                }
                else if (ssrType == 'DOCA') {
                    List<String> parts = getFreeTextParts(ssr);
                    if (parts.size() < 5) continue;
                    System.debug('📄 Found DOCA SSR for PT ' + ptNumber);

                    if (travellers == null || travellers.isEmpty()) continue;
                
                    String indicator = parts.size() > 6 ? parts[6] : null;
                    Boolean isInf = (indicator == 'I');
                
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
                        target.USAStreet__c = parts.size() > 2 ? parts[2] : null;
                        target.USACity__c = parts.size() > 3 ? parts[3] : null;
                        target.USAState__c = parts.size() > 4 ? parts[4] : null;
                        target.USAZipCode__c = parts.size() > 5 ? parts[5] : null;
                
                        if (target.PassengerType__c == 'INF') {
                            System.debug('👶 DOCA (INF) for PT ' + ptNumber);
                        } else {
                            System.debug('🧾 DOCA (ADT/CHD) for PT ' + ptNumber);
                        }
                    }
                }
				//RQST/CTCE/CTCM/PCTC/APN/E只需傳給大人(ADT/CHD)
				else if (ssrType == 'PCTC') {
                    List<String> parts = getFreeTextParts(ssr);
                    if (parts.size() < 2) continue;
                    System.debug('📄 Found PCTC SSR for PT ' + ptNumber);

                    if (travellers == null || travellers.isEmpty()) continue;                

                    String contactName = parts[0];
                    String nationalityAndPhone = parts[1];
                
                    String nationality = nationalityAndPhone.length() >= 3 ? nationalityAndPhone.substring(0, 3) : null;
                    String phone = nationalityAndPhone.length() > 3 ? nationalityAndPhone.substring(3) : null;
                
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
                    Dom.XmlNode seatNode = findChildByName(serviceRequest, 'ssrb');
                    if (seatNode == null) continue;
                    Dom.XmlNode seatData = findChildByName(seatNode, 'data');
                    if (seatData == null) continue;
        
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
                            if (hasCH) t.SeatStatus__c = 'CH';
                            System.debug('🪑 SEAT for PT ' + ptNumber + ': ' + seatValue + (hasCH ? ' (CH)' : ''));
                        }
                    }
                }
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
                }
            }
        }
        for (TravellerInfo__c t : travellerList) {
            System.debug('🧳 Final Traveller: ' + t.Name + ' ➔ SSR_RawData__c = ' + (t.SSR_RawData__c != null ? t.SSR_RawData__c : '[None]'));
        }
        if (!travellerList.isEmpty()) {
            System.debug('📤 Upserting ' + travellerList.size() + ' traveller(s)...');
            upsert travellerList Name;
        } else {
            System.debug('⚠️ No traveller to upsert.');
        }
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
    
    private static List<String> getFreeTextParts(Dom.XmlNode ssr) {
        Dom.XmlNode freeTextNode = findChildByName(ssr, 'freeText');
        if (freeTextNode == null) return null;
        return freeTextNode.getText().split('/');
    }
    
    private static Dom.XmlNode findChildByName(Dom.XmlNode parent, String name) {
        if (parent == null) return null;
        for (Dom.XmlNode child : parent.getChildElements()) {
            if (child.getName() == name) return child;
        }
        return null;
    }

    private static Dom.XmlNode findChildByPath(Dom.XmlNode root, String[] path) {
        Dom.XmlNode current = root;
        for (String name : path) {
            current = findChildByName(current, name);
            if (current == null) return null;
        }
        return current;
    }

    private static String extractFirstName(String raw) {
        if (String.isBlank(raw)) return null;
        List<String> parts = raw.split(' ');
        return parts.size() > 1 ? parts[0] : raw;
    }

    private static String extractTitle(String raw) {
        if (String.isBlank(raw)) return null;
        List<String> parts = raw.split(' ');
        return parts.size() > 1 ? parts[1] : null;
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
}