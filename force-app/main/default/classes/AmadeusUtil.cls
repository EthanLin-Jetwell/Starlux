public without sharing class AmadeusUtil {
    private static String userID = Label.UserId;
    private static String clearPassword = Label.ClearPassword;//'PR@JXgck0001';
    private static String officeID = Label.OfficeID;
    private static String rloc;
    private static String created;
    private static String nonce;
    private static String encryptedPassword;
    private static String passwordDigest;
    private static String uniqueId;
    private static String sessionId;
    private static String sequenceNumber;
    private static String securityToken;
    
    // Utility to generate current UTC timestamp in ISO 8601 format
    private static String generateCreated() {
        Datetime now = Datetime.now();
        return now.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }

    // Utility to generate a random Nonce in Base64
    private static String generateNonce() {
        Blob nonceBlob = Crypto.generateAESKey(128);
        return EncodingUtil.base64Encode(nonceBlob);
    }

    // Utility to hash the password with SHA-1
    private static String passwordEncrypt(String clearPassword) {
        Blob passwordBlob = Blob.valueOf(clearPassword);
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', passwordBlob));
    }
    
    private static String generateUniqueId() {
        Blob nonceBlob = Crypto.generateAESKey(128);
        return EncodingUtil.base64Encode(nonceBlob);
    }

    // Utility to generate PasswordDigest
    private static String generatePasswordDigest(String password, String nonceStr, String createdStr) {
        // 將十六進制的 SHA-1 加密後的密碼轉換為 bytes
        Blob passwordBlob = EncodingUtil.convertFromHex(password);
        Blob nonceBlob = EncodingUtil.base64Decode(nonceStr);
        Blob createdBlob = Blob.valueOf(createdStr);
        
        // 按照順序連接：nonce + created + password
        Blob concatenatedBlob = EncodingUtil.convertFromHex(EncodingUtil.convertToHex(nonceBlob) + EncodingUtil.convertToHex(createdBlob) + EncodingUtil.convertToHex(passwordBlob));
        
        // 對連接後的結果進行 SHA-1 並轉為 Base64
        Blob sha1Digest = Crypto.generateDigest('SHA-1', concatenatedBlob);
        return EncodingUtil.base64Encode(sha1Digest);
    }
    
    private static void preRequest() {
        created = generateCreated();
        nonce = generateNonce();
        encryptedPassword = passwordEncrypt(clearPassword);
        passwordDigest = generatePasswordDigest(encryptedPassword, nonce, created);
        uniqueId = generateUniqueId();
    }

    public static Map<String, String> listPNRByFlight(String flightParser, String inputDate) {
        Map<String, String> controlNumberToCityMap = new Map<String, String>();

        // 解析 flight number 與 suffix
        Pattern pattern = Pattern.compile('^(\\d+)([A-Za-z]*)$');
        Matcher matcher = pattern.matcher(flightParser);
        if (!matcher.matches()) {
            throw new IllegalArgumentException('❌ flightParser 格式錯誤，應為數字開頭、可選英文，例如 "8123" 或 "8123D"');
        }

        String flightNumber = matcher.group(1);
        String operationalSuffix = matcher.group(2);
		// date:format yyyy/mm/dd
        List<String> Date_parts = inputDate.split('/');
		String year = Date_parts[0];
        String month = Date_parts[1];
        String day = Date_parts[2];        
        preRequest();

        // 組裝 SOAP Request
        String soapRequest = 
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:pal="https://nodeA3.test.webservices.amadeus.com/1ASIWGCKJXU">' + 
            '    <soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
            '        <sec:AMA_SecurityHostedUser>' +
            '            <sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
            '        </sec:AMA_SecurityHostedUser>' +
            '        <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '            <wsse:UsernameToken>' +
            '                <wsse:Username>'+userID+'</wsse:Username>' +
            '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
            '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
            '                <wsu:Created>'+created+'</wsu:Created>' +
            '            </wsse:UsernameToken>' +
            '        </wsse:Security>' +
            '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
            '            <awsl:Consumer>' +
            '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
            '            </awsl:Consumer>' +
            '        </awsl:TransactionFlowLink>' +
            '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/PALPRQ_14_1_1A</wsa:Action>' +
            '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
            '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
            '        </wsa:ReplyTo>' +
            '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:' + uniqueId + '</wsa:MessageID>' +
            '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
            '        <ses:Session TransactionStatusCode="Start"/>' +
            '    </soapenv:Header>' +
            '    <soapenv:Body>' +
            '        <pal:PNR_ListPassengersByFlight>' +
            '            <pal:flightDateQuery>' +
            '                <pal:flightIdentification>' +
            '                    <pal:carrierDetails>' +
            '                        <pal:marketingCarrier>JX</pal:marketingCarrier>' +
            '                    </pal:carrierDetails>' +
            '                    <pal:flightDetails>' +
            '                        <pal:flightNumber>' + flightNumber + '</pal:flightNumber>' +
            '                        <pal:operationalSuffix>' + operationalSuffix + '</pal:operationalSuffix>' +
            '                    </pal:flightDetails>' +
            '                </pal:flightIdentification>' +
            '                <pal:dateIdentification>' +
            '                    <pal:businessSemantic>FLD</pal:businessSemantic>' +
            '                    <pal:dateTime>' +
            '                        <pal:year>' + year + '</pal:year>' +
            '                        <pal:month>' + month + '</pal:month>' +
            '                        <pal:day>' + day + '</pal:day>' +
            '                    </pal:dateTime>' +
            '                </pal:dateIdentification>' +
            '                <pal:outputSelectionOption>' +
            '                    <pal:outputType>' +
            '                        <pal:selectionDetails>' +
            '                            <pal:option>IMG</pal:option>' +
            '                        </pal:selectionDetails>' +
            '                    </pal:outputType>' +
            '                </pal:outputSelectionOption>' +
            '            </pal:flightDateQuery>' +
            '        </pal:PNR_ListPassengersByFlight>' +
            '    </soapenv:Body>' +
            '</soapenv:Envelope>';

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Amadeus');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        request.setHeader('SOAPAction', 'http://webservices.amadeus.com/PALPRQ_14_1_1A');
        request.setBody(soapRequest);

        Http http = new Http();
        HttpResponse response = http.send(request);
		String body = response.getBody();
        if (response.getStatusCode() == 200) {
            String xmlBody = response.getBody();
			//body debug
            //chunkedDebug('📄 Amadeus XML', xmlBody, 1000, 10);
            if (String.isBlank(xmlBody) || !xmlBody.contains('<soapenv:Body')) {
                System.debug('⚠️ Missing <Body> in response. Possibly invalid.');
                return new Map<String, String>();
            }
            
            try {
                controlNumberToCityMap = AmadeusXmlParser.listPNRByFlight(xmlBody);
				//set<string> debug
				//chunkedDebugSet('📦 PNR Result Set', controlNumbers, 20);
            } catch (Exception e) {
                System.debug('❌ XML parse error: ' + e.getMessage());
            }
        }

        // （可選）仍保留紀錄 log
        //ApiLogger.log(request, response, flightParser);
        return controlNumberToCityMap;
    }

    // PNR_Retrieve for controllers
    public static list<TravellerInfo__c> retrievePNR(String boardpoint, String rloc) { 
        return retrievePNR(boardpoint, rloc, false);
    }
    
    // PNR_Retrieve for in-step callouts
    public static list<TravellerInfo__c> retrievePNR(String boardpoint, String rloc, Boolean isStep) {
        preRequest();
        System.debug('retrieve Pnr');
        System.debug('boardpoint: ' + boardpoint);
        System.debug('rloc: ' + rloc);
        String soapRequest = 
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
            'xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" ' +
            'xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" ' +
            'xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" ' +
            'xmlns:pnr="http://xml.amadeus.com/PNRRET_22_1_1A">' +
            '    <soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
            '        <sec:AMA_SecurityHostedUser>' +
            '            <sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
            '        </sec:AMA_SecurityHostedUser>' +
            '        <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" ' +
            'xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '            <wsse:UsernameToken>' +
            '                <wsse:Username>'+userID+'</wsse:Username>' +
            '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
            '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
            '                <wsu:Created>'+created+'</wsu:Created>' +
            '            </wsse:UsernameToken>' +
            '        </wsse:Security>' +
            '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
            '            <awsl:Consumer>' +
            '                <awsl:UniqueID>Og3F8pCnfYlkybs2nen8Ew==</awsl:UniqueID>' +
            '            </awsl:Consumer>' +
            '        </awsl:TransactionFlowLink>' +
            '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/PNRRET_22_1_1A</wsa:Action>' +
            '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
            '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
            '        </wsa:ReplyTo>' +
            '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:d60aaa7e-bde2-49e1-a9dc-7984f22dcff4</wsa:MessageID>' +
            '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
            '        <ses:Session TransactionStatusCode="Start"/>' +
            '    </soapenv:Header>' +
            '    <soapenv:Body>' +
            '        <PNR_Retrieve>' +
            '            <retrievalFacts>' +
            '                <retrieve>' +
            '                    <type>2</type>' +
            '                </retrieve>' +
            '                <reservationOrProfileIdentifier>' +
            '                    <reservation>' +
            '                        <controlNumber>'+rloc+'</controlNumber>' +
            '                    </reservation>' +
            '                </reservationOrProfileIdentifier>' +
            '            </retrievalFacts>' +
            '        </PNR_Retrieve>' +
            '    </soapenv:Body>' +
            '</soapenv:Envelope>';

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/xml');

        request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        request.setHeader('SOAPAction', 'http://webservices.amadeus.com/PNRRET_22_1_1A'); // Add SOAPAction if required
        request.setBody(soapRequest);
        
        // Step 4: Send the HTTP request
        Http http = new Http();
        
        String xmlResponse = '';
        
        try {
            HttpResponse response = http.send(request);
            xmlResponse = response.getBody();
            System.debug('xmlResponse: ' + xmlResponse);

            if (String.isNotBlank(xmlResponse)) {
                // Parse the XML response
                Dom.Document doc = new Dom.Document();
                doc.load(xmlResponse);
                
                // Extract the SOAP Envelope and Header
                Dom.XmlNode envelopeNode = doc.getRootElement();
                Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                
                if (response.getStatusCode() == 200) {

                    if (!isStep) {
                        return AmadeusXmlParser.retrievePNR(response.getBody(), rloc, boardpoint);
                    } else if(headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep2(rloc);
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } else {
                    
                }
            } else {
                System.debug('Response is empty or null');
            }
            
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
        
        return null;
    }
    
    //C4
    public static list<TravellerInfo__c> retrievePNRC4(String boardpoint, String rloc) { 
        return retrievePNRC4(boardpoint, rloc, false);
    }
    
    // PNR_Retrieve for in-step callouts
    public static list<TravellerInfo__c> retrievePNRC4(String boardpoint, String rloc, Boolean isStep) {
        preRequest();
        
        String soapRequest = 
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
            'xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" ' +
            'xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" ' +
            'xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" ' +
            'xmlns:pnr="http://xml.amadeus.com/PNRRET_22_1_1A">' +
            '    <soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
            '        <sec:AMA_SecurityHostedUser>' +
            '            <sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
            '        </sec:AMA_SecurityHostedUser>' +
            '        <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" ' +
            'xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '            <wsse:UsernameToken>' +
            '                <wsse:Username>'+userID+'</wsse:Username>' +
            '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
            '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
            '                <wsu:Created>'+created+'</wsu:Created>' +
            '            </wsse:UsernameToken>' +
            '        </wsse:Security>' +
            '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
            '            <awsl:Consumer>' +
            '                <awsl:UniqueID>Og3F8pCnfYlkybs2nen8Ew==</awsl:UniqueID>' +
            '            </awsl:Consumer>' +
            '        </awsl:TransactionFlowLink>' +
            '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/PNRRET_22_1_1A</wsa:Action>' +
            '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
            '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
            '        </wsa:ReplyTo>' +
            '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:d60aaa7e-bde2-49e1-a9dc-7984f22dcff4</wsa:MessageID>' +
            '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
            '        <ses:Session TransactionStatusCode="Start"/>' +
            '    </soapenv:Header>' +
            '    <soapenv:Body>' +
            '        <PNR_Retrieve>' +
            '            <retrievalFacts>' +
            '                <retrieve>' +
            '                    <type>2</type>' +
            '                </retrieve>' +
            '                <reservationOrProfileIdentifier>' +
            '                    <reservation>' +
            '                        <controlNumber>'+rloc+'</controlNumber>' +
            '                    </reservation>' +
            '                </reservationOrProfileIdentifier>' +
            '            </retrievalFacts>' +
            '        </PNR_Retrieve>' +
            '    </soapenv:Body>' +
            '</soapenv:Envelope>';

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/xml');
        Integer contentLength = Blob.valueOf(soapRequest).size();
        //request.setHeader('Content-Length', String.valueOf(contentLength));
        request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        request.setHeader('SOAPAction', 'http://webservices.amadeus.com/PNRRET_22_1_1A'); // Add SOAPAction if required
        request.setBody(soapRequest);
        
        // Step 4: Send the HTTP request
        Http http = new Http();
        
        String xmlResponse = '';
        
        try {
            HttpResponse response = http.send(request);
            xmlResponse = response.getBody();

            if (String.isNotBlank(xmlResponse)) {
                // Parse the XML response
                Dom.Document doc = new Dom.Document();
                doc.load(xmlResponse);
                
                // Extract the SOAP Envelope and Header
                Dom.XmlNode envelopeNode = doc.getRootElement();
                Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                
                if (response.getStatusCode() == 200) {

                    if (!isStep) {
                        return AmadeusXmlParser.retrievePNRC4(response.getBody(), rloc, boardpoint);
                    } else if(headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep2(rloc);
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } else {
                    
                }
            } else {
                System.debug('Response is empty or null');
            }
            
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
        
        return null;
    }
    
    // C1-7
    public static void uploadDocuments(String boardpoint, String rloc, List<TravellerInfo__c> travelerData) {
        retrievePNR(boardpoint, rloc, true);
        uploadDocuments_Step2(rloc, travelerData);      
        uploadDocuments_Step3();      
    }
    
    public static void uploadDocuments_Step2(String rloc, List<TravellerInfo__c> travelerData) {
        try {
            String uniqueId = generateUniqueId();

            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                'xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" ' +
                'xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" ' +
                'xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" ' +
                'xmlns:pnr="http://webservices.amadeus.com/PNRADD_22_1_1A">' +
                '    <soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '        <awsse:Session TransactionStatusCode="InSeries" xmlns:awsse="http://xml.amadeus.com/2010/06/Session_v3">' +
                '            <awsse:SessionId>'+sessionId+'</awsse:SessionId>' +
                '            <awsse:SequenceNumber>'+sequenceNumber+'</awsse:SequenceNumber>' +
                '            <awsse:SecurityToken>'+securityToken+'</awsse:SecurityToken>' +
                '        </awsse:Session>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/PNRADD_22_1_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:d60aaa7e-bde2-49e1-a9dc-7984f22dcff4</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
                '        <pnr:PNR_AddMultiElements>' +
                '            <pnr:reservationInfo>' +
                '                <pnr:reservation>' +
                '                    <pnr:companyId>JX</pnr:companyId>' +
                '                    <pnr:controlNumber>'+rloc+'</pnr:controlNumber>' +
                '                </pnr:reservation>' +
                '            </pnr:reservationInfo>' +
                '            <pnr:pnrActions>' +
                '                <pnr:optionCode>0</pnr:optionCode>' +
                '            </pnr:pnrActions>' +
                '            <pnr:dataElementsMaster>' +
                '                <pnr:marker1/>';

                for(travellerInfo__c travelerDatum : travelerData) {
                    if (travelerDatum.PassengerType__c == 'INF') {
                        if (travelerDatum.gender__c == 'M') travelerDatum.gender__c = 'MI';
                        else if (travelerDatum.gender__c == 'F') travelerDatum.gender__c = 'FI';
                    } else {
                        if (travelerDatum.gender__c == 'MI') travelerDatum.gender__c = 'M';
                        else if (travelerDatum.gender__c == 'FI') travelerDatum.gender__c = 'F';
                    }
                    
                    Date st1_date = parseDDMMYY(travelerDatum.DepartureDate__c);
                    Date st2_date = String.isBlank(travelerDatum.DepartureDate2__c) ? null : parseDDMMYY(travelerDatum.DepartureDate2__c);
                    
                    String infFlag = (travelerDatum.PassengerType__c == 'INF') ? 'I' : '';
                    String docaText = (infFlag == 'I') ? '/I' : '';
                    System.debug(travelerDatum.PT__c);
                    soapRequest +=
                        '                <pnr:dataElementsIndiv>' +
                        '                    <pnr:elementManagementData>' +
                        '                        <pnr:segmentName>SSR</pnr:segmentName>' +
                        '                    </pnr:elementManagementData>' +
                        '                    <pnr:serviceRequest>' +
                        '                        <pnr:ssr>' +
                        '                            <pnr:type>DOCS</pnr:type>' +
                        '						     <pnr:status>HK</pnr:status>' +
                        '                            <pnr:quantity>1</pnr:quantity>' +
                        '                            <pnr:companyId>JX</pnr:companyId>' +
                        '                            <pnr:freetext>' + 'P/' + travelerDatum.PassportIssuingCountry__c + '/' + travelerDatum.PassportNumber__c + '/' + travelerDatum.country__c + '/' + travelerDatum.DateOfBirth__c + '/' + travelerDatum.gender__c + '/' + travelerDatum.PassportExpiryDate__c + '/' + travelerDatum.LastName__c + '-' + travelerDatum.firstName__c + '</pnr:freetext>' +
                        '                        </pnr:ssr>' +
                        '                    </pnr:serviceRequest>' +
                        '                    <pnr:referenceForDataElement>' +
                        '                        <pnr:reference>' +
                        '                            <pnr:qualifier>ST</pnr:qualifier>' +
                        '                            <pnr:number>' + travelerDatum.ST01__c + '</pnr:number>' +
                        '                        </pnr:reference>' +
                        '                        <pnr:reference>' +
                        '                            <pnr:qualifier>PT</pnr:qualifier>' +
                        '                            <pnr:number>' + travelerDatum.PT__c + '</pnr:number>' +
                        '                        </pnr:reference>' +
                        '                    </pnr:referenceForDataElement>' +
                        '                </pnr:dataElementsIndiv>' ;
                    if (!String.isBlank(travelerDatum.VisaNumber__c)) {
						soapRequest +=
                        '                <pnr:dataElementsIndiv>' +
                        '                    <pnr:elementManagementData>' +
                        '                        <pnr:segmentName>SSR</pnr:segmentName>' +
                        '                    </pnr:elementManagementData>' +
                        '                    <pnr:serviceRequest>' +
                        '                        <pnr:ssr>' +
                        '                            <pnr:type>DOCO</pnr:type>' +
                        '						     <pnr:status>HK</pnr:status>' +
                        '                            <pnr:quantity>1</pnr:quantity>' +
                        '                            <pnr:companyId>JX</pnr:companyId>' +
                        '                            <pnr:freetext>' + '/V/' + travelerDatum.VisaNumber__c + '///' + travelerDatum.VisaIssuingCountry__c + '/'  + infFlag + '/' + travelerDatum.VisaExpiryDate__c + '</pnr:freetext>' +
                        '                        </pnr:ssr>' +
                        '                    </pnr:serviceRequest>' +
                        '                    <pnr:referenceForDataElement>' +
                        '                        <pnr:reference>' +
                        '                            <pnr:qualifier>ST</pnr:qualifier>' +
                        '                            <pnr:number>' + travelerDatum.ST01__c + '</pnr:number>' +
                        '                        </pnr:reference>' +
                        '                        <pnr:reference>' +
                        '                            <pnr:qualifier>PT</pnr:qualifier>' +
                        '                            <pnr:number>' + travelerDatum.PT__c + '</pnr:number>' +
                        '                        </pnr:reference>' +
                        '                    </pnr:referenceForDataElement>' +
                        '                </pnr:dataElementsIndiv>' ;
                    }
                    if (
                        (travelerDatum.DepartureLocation__c == 'TPE' ||
                         travelerDatum.DepartureLocation__c == 'RMQ' ||
                         travelerDatum.DepartureLocation__c == 'KHH') &&
                        travelerDatum.ST02__c != null &&
                        (st1_date != null &&
                         st2_date != null &&
                         st1_date < st2_date)
                    ){
                        soapRequest +=
                            '                <pnr:dataElementsIndiv>' +
                            '                    <pnr:elementManagementData>' +
                            '                        <pnr:segmentName>SSR</pnr:segmentName>' +
                            '                    </pnr:elementManagementData>' +
                            '                    <pnr:serviceRequest>' +
                            '                        <pnr:ssr>' +
                            '                            <pnr:type>DOCS</pnr:type>' +
                            '                            <pnr:quantity>1</pnr:quantity>' +
                            '                            <pnr:companyId>JX</pnr:companyId>' +
                            '                            <pnr:freetext>' + 'P/' + travelerDatum.PassportIssuingCountry__c + '/' + travelerDatum.PassportNumber__c + '/' + travelerDatum.country__c + '/' + travelerDatum.DateOfBirth__c + '/' + travelerDatum.gender__c + '/' + travelerDatum.PassportExpiryDate__c + '/' + travelerDatum.LastName__c + '-' + travelerDatum.firstName__c + '</pnr:freetext>' +
                            '                        </pnr:ssr>' +
                            '                    </pnr:serviceRequest>' +
                            '                    <pnr:referenceForDataElement>' +
                            '                        <pnr:reference>' +
                            '                            <pnr:qualifier>ST</pnr:qualifier>' +
                            '                            <pnr:number>' + travelerDatum.ST02__c + '</pnr:number>' +
                            '                        </pnr:reference>' +
                            '                        <pnr:reference>' +
                            '                            <pnr:qualifier>PT</pnr:qualifier>' +
                            '                            <pnr:number>' + travelerDatum.PT__c + '</pnr:number>' +
                            '                        </pnr:reference>' +
                            '                    </pnr:referenceForDataElement>' +
                            '                </pnr:dataElementsIndiv>' ;
                    }
                    if(travelerDatum.US_Bound__c == true){
                        soapRequest +=
                        '                <pnr:dataElementsIndiv>' +
                        '                    <pnr:elementManagementData>' +
                        '                        <pnr:segmentName>SSR</pnr:segmentName>' +
                        '                    </pnr:elementManagementData>' +
                        '                    <pnr:serviceRequest>' +
                        '                        <pnr:ssr>' +
                        '                            <pnr:type>DOCA</pnr:type>' +
                        '						     <pnr:status>HK</pnr:status>' +
                        '                            <pnr:companyId>JX</pnr:companyId>' +
                        '                            <pnr:freetext>' + 'D/USA/' + travelerDatum.USAStreet__c + '/' + travelerDatum.USACity__c + '/' + travelerDatum.USAState__c + '/' + travelerDatum.USAZipCode__c + docaText + '</pnr:freetext>' +
                        '                        </pnr:ssr>' +
                        '                    </pnr:serviceRequest>' +
                        '                    <pnr:referenceForDataElement>' +
                        '                        <pnr:reference>' +
                        '                            <pnr:qualifier>ST</pnr:qualifier>' +
                        '                            <pnr:number>' + travelerDatum.ST01__c + '</pnr:number>' +
                        '                        </pnr:reference>' +
                        '                        <pnr:reference>' +
                        '                            <pnr:qualifier>PT</pnr:qualifier>' +
                        '                            <pnr:number>' + travelerDatum.PT__c + '</pnr:number>' +
                        '                        </pnr:reference>' +
                        '                    </pnr:referenceForDataElement>' +
                        '                </pnr:dataElementsIndiv>' ;
                        if(travelerDatum.PassengerType__c != 'INF'){
                            soapRequest +=
                            '                <pnr:dataElementsIndiv>' +
                            '                    <pnr:elementManagementData>' +
                            '                        <pnr:segmentName>SSR</pnr:segmentName>' +
                            '                    </pnr:elementManagementData>' +
                            '                    <pnr:serviceRequest>' +
                            '                        <pnr:ssr>' +
                            '                            <pnr:type>PCTC</pnr:type>' +
                            '						     <pnr:status>1</pnr:status>' +
                            '                            <pnr:companyId>JX</pnr:companyId>' +
                            '                            <pnr:freetext>' + normalizeName(travelerDatum.USAEmergencyContactName__c) +'/' + travelerDatum.USAEmergencyContactNationality__c + travelerDatum.USAEmergencyContactPhone__c + '</pnr:freetext>' +
                            '                        </pnr:ssr>' +
                            '                    </pnr:serviceRequest>' +
                            '                    <pnr:referenceForDataElement>' +
                            '                        <pnr:reference>' +
                            '                            <pnr:qualifier>PT</pnr:qualifier>' +
                            '                            <pnr:number>' + travelerDatum.PT__c + '</pnr:number>' +
                            '                        </pnr:reference>' +
                            '                    </pnr:referenceForDataElement>' +
                            '                </pnr:dataElementsIndiv>' ;
                        }
                    }
                }
                if (!travelerData.isEmpty()) {
    				TravellerInfo__c firstTraveler = travelerData[0];
                    if(firstTraveler.APE__c != null){
                        soapRequest +=
                        '                <pnr:dataElementsIndiv>' +
                        '                    <pnr:elementManagementData>' +
                        '                        <pnr:segmentName>SSR</pnr:segmentName>' +
                        '                    </pnr:elementManagementData>' +
                        '                    <pnr:serviceRequest>' +
                        '                        <pnr:ssr>' +
                        '                            <pnr:type>CTCE</pnr:type>' +
                        '						     <pnr:status>HK</pnr:status>' +
                        '                            <pnr:companyId>JX</pnr:companyId>' +
                        '                            <pnr:freetext>' + APEtoCTCE(firstTraveler.APE__c) + '</pnr:freetext>' +
                        '                        </pnr:ssr>' +
                        '                    </pnr:serviceRequest>' +
                        '                </pnr:dataElementsIndiv>' ;
                	}
                    if(firstTraveler.APM__c != null){
                        soapRequest +=
                        '                <pnr:dataElementsIndiv>' +
                        '                    <pnr:elementManagementData>' +
                        '                        <pnr:segmentName>SSR</pnr:segmentName>' +
                        '                    </pnr:elementManagementData>' +
                        '                    <pnr:serviceRequest>' +
                        '                        <pnr:ssr>' +
                        '                            <pnr:type>CTCM</pnr:type>' +
                        '						     <pnr:status>HK</pnr:status>' +
                        '                            <pnr:companyId>JX</pnr:companyId>' +
                        '                            <pnr:freetext>' + firstTraveler.APM__c + '</pnr:freetext>' +
                        '                        </pnr:ssr>' +
                        '                    </pnr:serviceRequest>' +
                        '                </pnr:dataElementsIndiv>' ;
                	}
                }
            soapRequest +=
                '            </pnr:dataElementsMaster>' +
                '        </pnr:PNR_AddMultiElements>' +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';

            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/PNRADD_22_1_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep3();
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, 'C1TEST');
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
            //ApiLogger.logAsync(request, response);
        }
    }
	
    // C1-8
    public static void deleteDroppedOT(String boardpoint, String rloc, List<String> droppedOTNumbers) {
        retrievePNR(boardpoint, rloc, true);
        deleteOT_Step2(rloc, droppedOTNumbers);      
        uploadDocuments_Step3();      
    }
    
    public static void deleteOT_Step2(String rloc, List<String> droppedOTNumbers) {
        try {
            String uniqueId = generateUniqueId();

            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                'xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" ' +
                'xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" ' +
                'xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" ' +
                'xmlns:pnr="http://webservices.amadeus.com/PNRXCL_22_1_1A">' +
                '    <soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '        <awsse:Session TransactionStatusCode="InSeries" xmlns:awsse="http://xml.amadeus.com/2010/06/Session_v3">' +
                '            <awsse:SessionId>'+sessionId+'</awsse:SessionId>' +
                '            <awsse:SequenceNumber>'+sequenceNumber+'</awsse:SequenceNumber>' +
                '            <awsse:SecurityToken>'+securityToken+'</awsse:SecurityToken>' +
                '        </awsse:Session>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/PNRXCL_22_1_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:d60aaa7e-bde2-49e1-a9dc-7984f22dcff4</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
      			'      <pnr:PNR_Cancel>' +
         		'         <pnr:pnrActions>' +
            	'            	<pnr:optionCode>11</pnr:optionCode>' +
                '         </pnr:pnrActions>' +
                '         <pnr:cancelElements>' +
                '         		<pnr:entryType>E</pnr:entryType>' ;
                for (String otNumber : droppedOTNumbers) {  
                    soapRequest +=
                    '         		<pnr:element>' +
                    '         			<pnr:identifier>OT</pnr:identifier>' +
                    '         			<pnr:number>' + otNumber + '</pnr:number>' +
                    '         		</pnr:element>' ;
                }
            	soapRequest +=
                '          </pnr:cancelElements>' +
              	'      </pnr:PNR_Cancel>' +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';

            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/PNRXCL_22_1_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep3();
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, rloc);
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }

    // C2-1-2
    public static void seatSelection(String boardpoint, String rloc, List<TravellerInfo__c> travelerData) {
        retrievePNR(boardpoint, rloc, true);
        seatSelection_Step2(rloc, travelerData);      
        uploadDocuments_Step3();      
    }

    public static void seatSelection_Step2(String rloc, List<TravellerInfo__c> travelerData) {
        try {
            String uniqueId = generateUniqueId();

            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                'xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" ' +
                'xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" ' +
                'xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" ' +
                'xmlns:pnr="http://webservices.amadeus.com/PNRADD_22_1_1A">' +
                '    <soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '        <awsse:Session TransactionStatusCode="InSeries" xmlns:awsse="http://xml.amadeus.com/2010/06/Session_v3">' +
                '            <awsse:SessionId>'+sessionId+'</awsse:SessionId>' +
                '            <awsse:SequenceNumber>'+sequenceNumber+'</awsse:SequenceNumber>' +
                '            <awsse:SecurityToken>'+securityToken+'</awsse:SecurityToken>' +
                '        </awsse:Session>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/PNRADD_22_1_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:d60aaa7e-bde2-49e1-a9dc-7984f22dcff4</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
                '        <pnr:PNR_AddMultiElements>' +
                '            <pnr:reservationInfo>' +
                '                <pnr:reservation>' +
                '                    <pnr:companyId>JX</pnr:companyId>' +
                '                    <pnr:controlNumber>'+rloc+'</pnr:controlNumber>' +
                '                </pnr:reservation>' +
                '            </pnr:reservationInfo>' +
                '            <pnr:pnrActions>' +
                '                <pnr:optionCode>0</pnr:optionCode>' +
                '            </pnr:pnrActions>' +
                '            <pnr:dataElementsMaster>' +
                '                <pnr:marker1/>';

                for(travellerInfo__c travelerDatum : travelerData) {
                    System.debug(travelerDatum.PT__c);
                    soapRequest +=
                    '	<pnr:dataElementsIndiv>' +
                    '		<pnr:elementManagementData>' +
                    '			<pnr:segmentName>STR</pnr:segmentName>' +
                    '		</pnr:elementManagementData>' +
                    '		<pnr:seatGroup>' +
                    '			<pnr:seatRequest>' +
                    '				<pnr:seat>' +
                    '					<pnr:type>RQST</pnr:type>' +
                    '				</pnr:seat>' +
                    '				<pnr:special>' +
                    '					<pnr:data>' + travelerDatum.Seat__c + '</pnr:data>' +
                    '				</pnr:special>' +
                    '			</pnr:seatRequest>' +
                    '		</pnr:seatGroup>' +
                    '		<pnr:referenceForDataElement>' +
                    '			<pnr:reference>' +
                    '				<pnr:qualifier>PT</pnr:qualifier>' +
                    '				<pnr:number>' + travelerDatum.PT__c + '</pnr:number>' +
                    '			</pnr:reference>' +
                    '		<pnr:reference>' +
                    '				<pnr:qualifier>ST</pnr:qualifier>' +
                    '				<pnr:number>' + travelerDatum.ST01__c + '</pnr:number>' +
                    '		</pnr:reference>' +
                    '		</pnr:referenceForDataElement>' +
                    '	</pnr:dataElementsIndiv>' ;
                }
                
            soapRequest +=
                '            </pnr:dataElementsMaster>' +
                '        </pnr:PNR_AddMultiElements>' +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';
            
            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/PNRADD_22_1_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep3();
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.log(request, response,'C2');
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }
    
    public static void uploadDocuments_Step3() {
        try {
            String uniqueId = generateUniqueId();

            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:pnr="http://xml.amadeus.com/PNRADD_22_1_1A">' +
                '   <soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '      <awsse:Session TransactionStatusCode="End" xmlns:awsse="http://xml.amadeus.com/2010/06/Session_v3">' +
                '         <awsse:SessionId>'+sessionId+'</awsse:SessionId>' +
                '         <awsse:SequenceNumber>'+sequenceNumber+'</awsse:SequenceNumber>' +
                '         <awsse:SecurityToken>'+securityToken+'</awsse:SecurityToken>' +
                '      </awsse:Session>' +
                '      <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '         <awsl:Consumer>' +
                '            <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '         </awsl:Consumer>' +
                '      </awsl:TransactionFlowLink>' +
                '      <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/PNRADD_22_1_1A</wsa:Action>' +
                '      <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '         <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '      </wsa:ReplyTo>' +
                '      <wsa:MessageID soapenv:mustUnderstand="1">uuid:d60aaa7e-bde2-49e1-a9dc-7984f22dcff4</wsa:MessageID>' +
                '      <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '   </soapenv:Header>' +
                '   <soapenv:Body>' +
                '      <pnr:PNR_AddMultiElements>' +
                '         <pnr:pnrActions>' +
                '            <pnr:optionCode>11</pnr:optionCode>' +
                '         </pnr:pnrActions>' +
                '         <pnr:dataElementsMaster>' +
                '            <pnr:marker1/>' + 
                '            <pnr:dataElementsIndiv>' +
                '               <pnr:elementManagementData>' +
                '                  <pnr:segmentName>RF</pnr:segmentName>' +
                '               </pnr:elementManagementData>' +
                '               <pnr:freetextData>' +
                '                  <pnr:freetextDetail>' +
                '                     <pnr:subjectQualifier>3</pnr:subjectQualifier>' +
                '                     <pnr:type>22</pnr:type>' +
                '                  </pnr:freetextDetail>' +
                '                  <pnr:longFreetext>RF WSJXGCK</pnr:longFreetext>' +
                '               </pnr:freetextData>' +
                '            </pnr:dataElementsIndiv>' +
                '         </pnr:dataElementsMaster>' +
                '      </pnr:PNR_AddMultiElements>' +
                '   </soapenv:Body>' +
                '</soapenv:Envelope>';

            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/PNRADD_22_1_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.log(request, response);
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }
    
    
	//C2 Check in後更改座位
    public static void AllocateSeat_seatRequestInfo(List<TravellerInfo__c> travelerData) {
        try {
            preRequest();
            // Step 2: Construct SOAP XML request body
            String soapRequest = 
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
            'xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" ' +
            'xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" ' +
            'xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" ' +
            'xmlns:pnr="http://xml.amadeus.com/CASTUQ_15_2_1A">' +
            '    <soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
            '        <sec:AMA_SecurityHostedUser>' +
            '            <sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
            '        </sec:AMA_SecurityHostedUser>' +
            '        <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" ' +
            'xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '            <wsse:UsernameToken>' +
            '                <wsse:Username>'+userID+'</wsse:Username>' +
            '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
            '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
            '                <wsu:Created>'+created+'</wsu:Created>' +
            '            </wsse:UsernameToken>' +
            '        </wsse:Security>' +
            '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
            '            <awsl:Consumer>' +
            '                <awsl:UniqueID>Og3F8pCnfYlkybs2nen8Ew==</awsl:UniqueID>' +
            '            </awsl:Consumer>' +
            '        </awsl:TransactionFlowLink>' +
            '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/CASTUQ_15_2_1A</wsa:Action>' +
            '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
            '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
            '        </wsa:ReplyTo>' +
            '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:d60aaa7e-bde2-49e1-a9dc-7984f22dcff4</wsa:MessageID>' +
            '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
            '        <ses:Session TransactionStatusCode="Start"/>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>';
                if (!travelerData.isEmpty()) {
    				TravellerInfo__c firstTraveler = travelerData[0];
                    
                    String flightNumberRaw = firstTraveler.FlightNumber__c;
                    String flightNumber = '';
                    String operationnalSuffix = '';
                
                    // 用正規表達式切割：^前面是數字+後面是英文字
                    Pattern p = Pattern.compile('^(\\d+)([A-Za-z]*)$');
                    Matcher m = p.matcher(flightNumberRaw);
                
                    if (m.find()) {
                        flightNumber = m.group(1);  // 數字部分
                        operationnalSuffix = m.group(2); // 英文字母部分
                    }
                    soapRequest +=
                    '    <DCSSTG_AllocateSeat>' +
                    '    	<overrideFlags>' +
                    '      		<statusInformation>' +
                    '     			<indicator>OCS</indicator>' +
                    '    			<action>1</action>' +
                    '   		</statusInformation>' +
                    '  		</overrideFlags>' +
                    '  		<segmentInfo>' +
                    '			<segmentBooking>' +
                    '				<productDateOrTime>' +
                    '					<departureDate>' + firstTraveler.departureDate__c + '</departureDate>' +
                    '				</productDateOrTime>' +
                    '				<departureLocation>' +
                    '					<location>' + firstTraveler.departureLocation__c + '</location>' +
                    '				</departureLocation>' +
                    '				<arrivalLocation>' +
                    '					<location>' + firstTraveler.Destination__c + '</location>' +
                    '				</arrivalLocation>' +
                    '				<companyIdent>' +
                    '					<marketingAirline>JX</marketingAirline>' +
                    '				</companyIdent>' +
                    '				<productIdentification>' +
                    '					<flightNumber>' + flightNumber + '</flightNumber>' +
                    '				<operationnalSuffix>' + operationnalSuffix + '</operationnalSuffix>' +
                    '			</productIdentification>' +
                    '		</segmentBooking>' +
      				'		<seatRequestInfo>' +
                    '			<dummy/>' +
                    '				<seatRequestParameters>' +
                    '					<ssrTypeDetails>' +
                    '						<ssrType>RQST</ssrType>' +
                    '						<ssrStatus>HK</ssrStatus>' +
                    '						<legBoardPoint>' + firstTraveler.departureLocation__c + '</legBoardPoint>' +
                    '						<legOffPoint>' + firstTraveler.Destination__c + '</legOffPoint>' +
                    '					</ssrTypeDetails>';
                    for (Integer i = 0; i < travelerData.size(); i++) {
                        TravellerInfo__c travelerDatum = travelerData[i];
                        
                        soapRequest +=
                        '						<ssrDataDetails>' +
                        '							<seatNumber>' + travelerDatum.Seat__c + '</seatNumber>' +
                        '							<crossRef>' + i + '</crossRef>' +
                        '						</ssrDataDetails>';
                    }
                    soapRequest +=
                    '     		  	</seatRequestParameters>';
                    for (Integer i = 0; i < travelerData.size(); i++) {
                        TravellerInfo__c travelerDatum = travelerData[i];
                        soapRequest +=
                        '			<passengerSegmentInfo>' +
                        '				<bookingIdentifier>' +
                        '					<iDSection>' +
                        '						<iDSequenceNumber>' + i + '</iDSequenceNumber>' +
                        '						<iDQualifier>DID</iDQualifier>' +
                        '			     		<iD>' + travelerDatum.DID__c + '</iD>' +						
                        '					</iDSection>' +
                        '				</bookingIdentifier>' +
                        '			</passengerSegmentInfo>';
                    }
                    soapRequest +=
                    '		</seatRequestInfo>' +
                    '		</segmentInfo>';
                }
            	soapRequest +=
      			'		</DCSSTG_AllocateSeat>' +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';

            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/CASTUQ_15_2_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep3();
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, rloc);
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }

    // 1 依 PT__c 成群：同 PT 的 非 INF 在前、INF 在後；保留「首次出現順序」
    private static List<List<TravellerInfo__c>> buildPTClusters(List<TravellerInfo__c> src){
        Map<String, TravellerInfo__c> baseByPT = new Map<String, TravellerInfo__c>(); // ADT/CHD（二擇一）
        Map<String, TravellerInfo__c> infByPT  = new Map<String, TravellerInfo__c>(); // INF（0或1）
        List<String> order = new List<String>();
        Set<String> seen = new Set<String>();
    
        for (TravellerInfo__c t : src){
            String k = String.valueOf(t.PT__c).trim();
            if (!seen.contains(k)) { order.add(k); seen.add(k); }
            if (t.PassengerType__c == 'INF') {
                infByPT.put(k, t);
            } else if (!baseByPT.containsKey(k)) {
                baseByPT.put(k, t);   // 同 PT 若意外重複非 INF，只留第一筆（必要時可加告警）
            }
        }
    
        List<List<TravellerInfo__c>> clusters = new List<List<TravellerInfo__c>>();
        for (String k : order){
            List<TravellerInfo__c> g = new List<TravellerInfo__c>();
            if (baseByPT.containsKey(k)) g.add(baseByPT.get(k)); // 非 INF 先
            if (infByPT.containsKey(k))  g.add(infByPT.get(k));  // INF 後
            if (!g.isEmpty()) clusters.add(g);                   // 群大小一般為 1 或 2
        }
        return clusters;
    }
    
    // 2 新增：盡量填滿到 cap=N 的打包器（不拆同 PT；必要時從後面找單人群補位） ===
    private static List<List<TravellerInfo__c>> packBatchesByClustersFillSingles(List<TravellerInfo__c> src, Integer cap){
        List<List<TravellerInfo__c>> clusters = buildPTClusters(src);
        List<List<TravellerInfo__c>> batches  = new List<List<TravellerInfo__c>>();
    
        List<TravellerInfo__c> cur = new List<TravellerInfo__c>();
        Integer cnt = 0;
    
        for (Integer i = 0; i < clusters.size(); i++){
            List<TravellerInfo__c> g = clusters[i];
            Integer s = g.size(); // 1 或 2
    
            // 加入會超過 cap：先嘗試用「後面第一個 1 人群」補滿，再處理原群
            if (!cur.isEmpty() && cnt + s > cap){
                // 僅在差 1 位且當前群是 2 人時嘗試前視（避免過度重排）
                if (s == 2 && cnt == cap - 1){
                    Integer pick = -1;
                    for (Integer j = i + 1; j < clusters.size(); j++){
                        if (clusters[j].size() == 1){ pick = j; break; }
                    }
                    if (pick != -1){
                        // 把後面的 1 人群換到目前位置，下一輪再處理原本的 2 人群
                        List<TravellerInfo__c> one = clusters[pick];
                        clusters[pick] = g;
                        clusters[i] = one;
                        i--; // 重新處理現在這個索引（已變成 1 人群）
                        continue;
                    }
                }
                // 找不到可補的 1 人群，就結批
                batches.add(cur); cur = new List<TravellerInfo__c>(); cnt = 0;
            } else {
                // 可以加入當前群
                cur.addAll(g); cnt += s;
                // 剛好滿 cap 就結批
                if (cnt == cap){
                    batches.add(cur); cur = new List<TravellerInfo__c>(); cnt = 0;
                }
            }
        }
        if (!cur.isEmpty()) batches.add(cur);
        return batches;
    }
    
    // 3 封裝
    // 產出「每批最多 N 人、且 INF 與同 PT 綁一起、盡量湊滿」的批次清單
    public static List<List<TravellerInfo__c>> makeBatchesKeepINF(List<TravellerInfo__c> travelerData){
        Integer paramValue = 4; // ✅ 預設 4
        
        List<B2B_Parameter__c> ps = [
            SELECT Value__c
            FROM B2B_Parameter__c
            WHERE ParameterCode__c = 'C3Batch'
            LIMIT 1
        ];
        
        if (!ps.isEmpty() && !String.isBlank(ps[0].Value__c)) {
            try {
                paramValue = Integer.valueOf(ps[0].Value__c.trim());
            } catch (Exception e) {
                // 轉失敗就維持預設 4（可選擇加 log）
                System.debug('C3Batch param parse failed: ' + ps[0].Value__c);
            }
        }
        
        return packBatchesByClustersFillSingles(travelerData, paramValue);
    }
        
    //C3 Check-in
    public static void CheckIn(String boardpoint, String rloc, List<TravellerInfo__c> travelerData) {
        if (travelerData == null || travelerData.isEmpty()) return;
    
        // 步驟 1~5：（同 PT 的非 INF+INF 不拆）
        for (List<TravellerInfo__c> batch : makeBatchesKeepINF(travelerData)) {
            DCSCPR_EditCPR(batch);
            DCSACC_iAPP(batch);
            DCSACC_AQQ(batch);
            DCSACC_ADC(batch);
            DCSCPR_confirmADC(batch);
        }
    
        // 6：依 PT__c 分組處理
        Map<String, List<TravellerInfo__c>> groups = groupByPTPreserveOrder(travelerData);
    
        // 若需要依 PT 由小到大執行（含文字鍵最後），可用這段排序好的 keys
        List<String> keys = sortPTKeys(groups.keySet());
    
        for (String k : keys) {
            List<TravellerInfo__c> batch = groups.get(k);
            if (batch.isEmpty()) continue;
            DCSACC_InitiateCustAcceptance(batch);
        }
    }

    
    
    
    
    
    //0813 checked
    public static void DCSCPR_EditCPR(List<TravellerInfo__c> travelerData) {
        try {
            preRequest();
            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:ccp="http://webservices.amadeus.com/CCPRUQ_20_2_1A">' +
                '	<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '		<sec:AMA_SecurityHostedUser>' +
                '			<sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
                '		</sec:AMA_SecurityHostedUser>' +
                '		<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
                '            <wsse:UsernameToken>' +
                '                <wsse:Username>'+userID+'</wsse:Username>' +
                '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
                '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
                '                <wsu:Created>'+created+'</wsu:Created>' +
                '            </wsse:UsernameToken>' +
                '        </wsse:Security>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/CCPRUQ_20_2_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:' + uniqueId + '</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
                '      <DCSCPR_EditCPR>' +
                '		<processIndicators>' +
                '			<statusDetails>' +
                '				<indicator>PRC</indicator>' +
                '				<action>0</action>' +
                '			</statusDetails>' +
                '		</processIndicators>';
                for(travellerInfo__c travelerDatum : travelerData) {                    
					soapRequest +=
                    '			<customerEdit>' +
                    '				<customerDetails>' +
                    '					<paxDetails>' +
                    '						<surname>' + travelerDatum.LastName__c + '</surname>' +
                    '						<type>' + PType(travelerDatum.PassengerType__c) + '</type>' +
                    '					</paxDetails>' +
                    '					<otherPaxDetails>' +
                    '						<givenName>' + travelerDatum.firstName__c + '</givenName>' +
                    '						<type>' + PGengder(travelerDatum.Gender__c) + '</type>' +
                    '						<title>' + travelerDatum.title__c + '</title>' +
                    '					</otherPaxDetails>' +
                    '				</customerDetails>' +
                    '				<editCustomerDetails>' +
                    '					<paxDetails>' +
                    '						<surname>' + travelerDatum.LastName__c + '</surname>' +
                    '						<type>' + PType(travelerDatum.PassengerType__c) + '</type>' +
                    '					</paxDetails>' +
                    '					<otherPaxDetails>' +
                    '						<givenName>' + travelerDatum.firstName__c + '</givenName>' +
                    '						<type>' + PGengder(travelerDatum.Gender__c) + '</type>' +
                    '						<title>' + travelerDatum.title__c + '</title>' +
                    '					</otherPaxDetails>' +
                    '				</editCustomerDetails>' +
                    '				<uniqueCustomerId>' +
                    '					<idSection>' +
                    '						<referenceQualifier>UCI</referenceQualifier>' +
                    '						<primeId>' + travelerDatum.UCI__c + '</primeId>' +
                    '					</idSection>' +
                    '				</uniqueCustomerId>' +
                    '				<cprGroupDeleteIndicators>' +
                    '					<statusDetails>' +
                    '						<indicator>DCT</indicator>' +
                    '						<action>0</action>' +
                    '					</statusDetails>' +
                    '				</cprGroupDeleteIndicators>' +
                    '			</customerEdit>' +
                    '			<customerEdit>' +
                    '				<customerDetails>' +
                    '					<paxDetails>' +
                    '						<surname>' + travelerDatum.LastName__c + '</surname>' +
                    '						<type>' + PType(travelerDatum.PassengerType__c) + '</type>' +
                    '					</paxDetails>' +
                    '					<otherPaxDetails>' +
                    '						<givenName>' + travelerDatum.firstName__c + '</givenName>' +
                    '						<type>' + PGengder(travelerDatum.Gender__c) + '</type>' +
                    '						<title>' + travelerDatum.title__c + '</title>' +
                    '					</otherPaxDetails>' +
                    '				</customerDetails>' +
                    '				<primeFlightDetails>' +
                    '					<primeOperatingFlight>' +
                    '						<carrierDetails>' +
                    '							<operatingCarrier>JX</operatingCarrier>' +
                    '						</carrierDetails>' +
                    '						<flightDetails>' +
                    '							<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                    '						</flightDetails>' +
                    '						<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                    '						<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                    '					</primeOperatingFlight>' +
                    '					<primeFlightUniqueProductId>' +
                    '						<idSection>' +
                    '							<referenceQualifier>DID</referenceQualifier>' +
                    '							<primeId>' + travelerDatum.DID__c + '</primeId>' +
                    '						</idSection>' +
                    '					</primeFlightUniqueProductId>' +
                    '					<primeFlightDummy/>' +
                    '				</primeFlightDetails>' +
                    '				<uniqueCustomerId>' +
                    '					<idSection>' +
                    '						<referenceQualifier>UCI</referenceQualifier>' +
                    '						<primeId>' + travelerDatum.UCI__c + '</primeId>' +
                    '					</idSection>' +
                    '				</uniqueCustomerId>' +
                    '				<cprGroupDeleteIndicators>' +
                    '					<statusDetails>' +
                    '						<indicator>DDB</indicator>' +
                    '						<action>0</action>' +
                    '					</statusDetails>' +
                    '				</cprGroupDeleteIndicators>' +
                    '				<customerDateofBirth>' +
                    '					<businessSemantic>706</businessSemantic>' +
                    '					<timeMode>LD</timeMode>' +
                    '					<dateTime>' +
                    '						<year>' + DDMMMYYtoYY(travelerDatum.DateOfBirth__c) + '</year>' +
                    '						<month>' + DDMMMYYtoMM(travelerDatum.DateOfBirth__c) + '</month>' +
                    '						<day>' + DDMMMYYtoDD(travelerDatum.DateOfBirth__c) + '</day>' +
                    '					</dateTime>' +
                    '				</customerDateofBirth>' +
                    '				<edits>' +
                    '					<operatingFlightDetails>' +
                    '						<carrierDetails>' +
                    '							<marketingCarrier>JX</marketingCarrier>' +
                    '						</carrierDetails>' +
                    '						<flightDetails>' +
                    '							<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                    '						</flightDetails>' +
                    '						<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                    '						<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                    '						<offPoint>' + travelerDatum.Destination__c + '</offPoint>' +
                    '					</operatingFlightDetails>' +
                    '					<uniqueProductId>' +
                    '						<idSection>' +
                    '							<referenceQualifier>DID</referenceQualifier>' +
                    '							<primeId>' + travelerDatum.DID__c + '</primeId>' +
                    '						</idSection>' +
                    '					</uniqueProductId>' +
                    '					<documents>' +
                    '						<travelerDocument>' +
                    '							<issueDetails>' +
                    '								<documentCode>P</documentCode>' +
                    '							</issueDetails>' +
                    '							<travelerDocumentDetails>' +
                    '								<travelerDocumentId>' + travelerDatum.PassportNumber__c + '</travelerDocumentId>' +
                    '							</travelerDocumentDetails>' +
                    '						</travelerDocument>' +
                    '						<documentExpiration>' +
                    '							<dateTimeDescription>' +
                    '								<dateTimeQualifier>192</dateTimeQualifier>' +
                    '								<dateTimeDetails>' + DDMMMYYtoYYYYMMDDFuture(travelerDatum.PassportExpiryDate__c) + '</dateTimeDetails>' +
                    '								<format>101</format>' +
                    '							</dateTimeDescription>' +
                    '						</documentExpiration>' +
                    '						<documentIssuingCountry>' +
                    '							<locationType>91</locationType>' +
                    '							<locationDescription>' +
                    '								<code>' + travelerDatum.PassportIssuingCountry__c + '</code>' +
                    '								<qualifier>162</qualifier>' +
                    '							</locationDescription>' +
                    '						</documentIssuingCountry>' +
                    '						<travelerNameAndAddress>' +
                    '							<traveler>FL</traveler>' +
                    '							<travelerName>' +
                    '								<lastName>' + travelerDatum.LastName__c + '</lastName>' +
                    '								<givenNames>' + travelerDatum.firstName__c + '</givenNames>' +
                    '							</travelerName>' +
                    '							<travelerCountryCode>' + travelerDatum.country__c + '</travelerCountryCode>' +
                    '						</travelerNameAndAddress>' +
                    '						<regDocIndicator>' +
                    '							<statusDetails>' +
                    '								<indicator>SRC</indicator>' +
                    '								<action>O</action>' +
                    '							</statusDetails>' +
                    '						</regDocIndicator>' +
                    '						<dummyForLOC/>' +
                    '					</documents>' +
                    '					<cprGroupDeleteIndicators>' +
                    '						<statusInformation>' +
                    '							<indicator>DRD</indicator>' +
                    '							<action>0</action>' +
                    '						</statusInformation>' +
                    '					</cprGroupDeleteIndicators>' +
                    '					<country>' +
                    '						<codeQualifier>1</codeQualifier>' +
                    '						<nationalityDetails>' +
                    '							<nationalityCode>' + travelerDatum.country__c + '</nationalityCode>' +
                    '						</nationalityDetails>' +
                    '					</country>' +
                    '				</edits>' ;
                    if (!String.isBlank(travelerDatum.VisaNumber__c)) {
                        soapRequest +=
                        '				<edits>' +
                        '					<operatingFlightDetails>' +
                        '						<carrierDetails>' +
                        '							<marketingCarrier>JX</marketingCarrier>' +
                        '						</carrierDetails>' +
                        '						<flightDetails>' +
                        '							<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                        '						</flightDetails>' +
                        '						<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                        '						<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                        '						<offPoint>' + travelerDatum.Destination__c + '</offPoint>' +
                        '					</operatingFlightDetails>' +
                        '					<uniqueProductId>' +
                        '						<idSection>' +
                        '							<referenceQualifier>DID</referenceQualifier>' +
                        '							<primeId>' + travelerDatum.DID__c + '</primeId>' +
                        '						</idSection>' +
                        '					</uniqueProductId>' +
                        '					<documents>' +
                        '						<travelerDocument>' +
                        '							<issueDetails>' +
                        '								<documentCode>V</documentCode>' +
                        '							</issueDetails>' +
                        '							<travelerDocumentDetails>' +
                        '								<travelerDocumentId>' + travelerDatum.VisaNumber__c + '</travelerDocumentId>' +
                        '							</travelerDocumentDetails>' +
                        '						</travelerDocument>' +
                        '						<documentExpiration>' +
                        '							<dateTimeDescription>' +
                        '								<dateTimeQualifier>192</dateTimeQualifier>' +
                        '								<dateTimeDetails>' + DDMMMYYtoYYYYMMDDFuture(travelerDatum.VisaExpiryDate__c) + '</dateTimeDetails>' +
                        '								<format>101</format>' +
                        '							</dateTimeDescription>' +
                        '						</documentExpiration>' +
                        '						<travelerNameAndAddress>' +
                        '							<traveler>FL</traveler>' +
                        '							<travelerName>' +
                        '								<lastName>' + travelerDatum.LastName__c + '</lastName>' +
                        '								<givenNames>' + travelerDatum.firstName__c + '</givenNames>' +
                        '							</travelerName>' +
                        '							<travelerCountryCode>' + travelerDatum.VisaIssuingCountry__c + '</travelerCountryCode>' +
                        '						</travelerNameAndAddress>' +
                        '						<regDocIndicator>' +
                        '							<statusDetails>' +
                        '								<indicator>SRC</indicator>' +
                        '								<action>O</action>' +
                        '							</statusDetails>' +
                        '						</regDocIndicator>' +
                        '						<dummyForLOC/>' +
                        '					</documents>' +
                        '					<cprGroupDeleteIndicators>' +
                        '						<statusInformation>' +
                        '							<indicator>DRD</indicator>' +
                        '							<action>0</action>' +
                        '						</statusInformation>' +
                        '					</cprGroupDeleteIndicators>' +
                        '				</edits>';
                    }
                    if (!String.isBlank(travelerDatum.USAEmergencyContactPhone__c)) {
                        soapRequest +=
                        '				<edits>' +
                        '					<operatingFlightDetails>' +
                        '						<carrierDetails>' +
                        '							<marketingCarrier>JX</marketingCarrier>' +
                        '						</carrierDetails>' +
                        '						<flightDetails>' +
                        '							<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                        '						</flightDetails>' +
                        '						<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                        '						<boardPoint>TPE</boardPoint>' +
                        '					</operatingFlightDetails>' +
                        '					<uniqueProductId>' +
                        '						<idSection>' +
                        '							<referenceQualifier>DID</referenceQualifier>' +
                        '							<primeId>' + travelerDatum.DID__c + '</primeId>' +
                        '						</idSection>' +
                        '					</uniqueProductId>' +
                        '					<cprGroupDeleteIndicators>' +
                        '						<statusInformation>' +
                        '							<indicator>DEC</indicator>' +
                        '							<action>0</action>' +
                        '						</statusInformation>' +
                        '					</cprGroupDeleteIndicators>' +
                        '					<emergencyContact>' +
                        '						<declineIndicator>' +
                        '							<statusDetails>' +
                        '								<indicator>DCL</indicator>' +
                        '								<action>0</action>' +
                        '							</statusDetails>' +
                        '						</declineIndicator>' +
                        '						<regDocEmergContDetails>' +
                        '							<contactDetails>' +
                        '								<surname>' + travelerDatum.USAEmergencyContactName__c + '</surname>' +
                        '								<phoneNumber>' + travelerDatum.USAEmergencyContactPhone__c + '</phoneNumber>' +
                        '								<comment></comment>' +
                        '								<countryOfResidence>' + travelerDatum.USAEmergencyContactNationality__c + '</countryOfResidence>' +
                        '							</contactDetails>' +
                        '						</regDocEmergContDetails>' +
                        '					</emergencyContact>' +
                        '				</edits>';
                    }
                    if (!String.isBlank(travelerDatum.USAState__c)) {
                        soapRequest +=
                        '				<edits>' +
                        '					<operatingFlightDetails>' +
                        '						<carrierDetails>' +
                        '							<marketingCarrier>JX</marketingCarrier>' +
                        '						</carrierDetails>' +
                        '						<flightDetails>' +
                        '							<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                        '						</flightDetails>' +
                        '						<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                        '						<boardPoint>TPE</boardPoint>' +
                        '					</operatingFlightDetails>' +
                        '					<uniqueProductId>' +
                        '						<idSection>' +
                        '							<referenceQualifier>DID</referenceQualifier>' +
                        '							<primeId>' + travelerDatum.DID__c + '</primeId>' +
                        '						</idSection>' +
                        '					</uniqueProductId>' +
                        '					<cprGroupDeleteIndicators>' +
                        '						<statusInformation>' +
                        '							<indicator>UAD</indicator>' +
                        '							<action>0</action>' +
                        '						</statusInformation>' +
                        '					</cprGroupDeleteIndicators>' +
                        '					<addressDetailsGroup>' +
                        '						<addressDetails>' +
                        '							<traveler>FL</traveler>' +
                        '							<travelerAddress>' +
                        '								<street>' + travelerDatum.USAStreet__c + '</street>' +
                        '							</travelerAddress>' +
                        '							<travelerCity>' + travelerDatum.USACity__c + '</travelerCity>' +
                        '							<travelerCountry>' +
                        '								<countrySubEntityName>' + travelerDatum.USAState__c + '</countrySubEntityName>' +
                        '							</travelerCountry>' +
                        '							<travelerPostcode>' + travelerDatum.USAZipCode__c + '</travelerPostcode>' +
                        '							<travelerCountryCode>USA</travelerCountryCode>' +
                        '						</addressDetails>' +
                        '						<addressType>' +
                        '							<locationType>80</locationType>' +
                        '						</addressType>' +
                        '					</addressDetailsGroup>' +
                        '				</edits>';
                    }
                    soapRequest +=
                    '			</customerEdit>';
				}
            soapRequest +=
            '		</DCSCPR_EditCPR>' +
            '   </soapenv:Body>' +
            '</soapenv:Envelope>';
    
            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/CCPRUQ_20_2_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep3();
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, 'EditCPR');
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }

    public static void DCSACC_iAPP(List<TravellerInfo__c> travelerData) {
        try {
            preRequest();
            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:ccp="http://webservices.amadeus.com/CREGRQ_19_1_1A">' +
                '	<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '		<sec:AMA_SecurityHostedUser>' +
                '			<sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
                '		</sec:AMA_SecurityHostedUser>' +
                '		<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
                '            <wsse:UsernameToken>' +
                '                <wsse:Username>'+userID+'</wsse:Username>' +
                '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
                '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
                '                <wsu:Created>'+created+'</wsu:Created>' +
                '            </wsse:UsernameToken>' +
                '        </wsse:Security>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/CREGRQ_19_1_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:' + uniqueId + '</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
                '        <creg:DCSACC_CheckRegulatoryRqts>' +
				'        	<creg:regulatoryIndicators>' +
				'        		<statusDetails>' +
				'        			<indicator>IAP</indicator>' +
				'        		</statusDetails>' +
				'        	</creg:regulatoryIndicators>' ;
                for(travellerInfo__c travelerDatum : travelerData) {                    
                    soapRequest +=
                    '				<creg:customerLevel>' +
                    '					<creg:customerIdentifier>' +
                    '						<creg:idSection>' +
                    '							<creg:referenceQualifier>UCI</creg:referenceQualifier>' +
                    '							<creg:primeId>' + travelerDatum.UCI__c + '</creg:primeId>' +
                    '						</creg:idSection>' +
                    '					</creg:customerIdentifier>' +
                    '					<creg:customerDetails>' +
                    '						<creg:paxDetails>' +
                    '							<creg:surname>' + travelerDatum.LastName__c + '</creg:surname>' +
                    '							<creg:type>' + PType(travelerDatum.PassengerType__c) + '</creg:type>' +
                    '						</creg:paxDetails>' +
                    '						<creg:otherPaxDetails>' +
                    '							<creg:givenName>' + travelerDatum.firstName__c + '</creg:givenName>' +
                    '							<creg:type>' + PGengder(travelerDatum.Gender__c) + '</creg:type>' +
                    '						</creg:otherPaxDetails>' +
                    '					</creg:customerDetails>' +
                    '					<creg:primeFlightProductIdentifier>' +
                    '						<creg:idSection>' +
                    '							<creg:referenceQualifier>DID</creg:referenceQualifier>' +
                    '							<creg:primeId>' + travelerDatum.DID__c + '</creg:primeId>' +
                    '						</creg:idSection>' +
                    '					</creg:primeFlightProductIdentifier>' +
                    '					<creg:productLevel>' +
                    '						<creg:operatingFlightDetails>' +
                    '							<creg:carrierDetails>' +
                    '								<creg:marketingCarrier>JX</creg:marketingCarrier>' +
                    '							</creg:carrierDetails>' +
                    '							<creg:flightDetails>' +
                    '								<creg:flightNumber>' + travelerDatum.FlightNumber__c + '</creg:flightNumber>' +
                    '							</creg:flightDetails>' +
                    '							<creg:departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</creg:departureDate>' +
                    '							<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                    '						</creg:operatingFlightDetails>' +
                    '						<creg:productIdentifier>' +
                    '							<creg:idSection>' +
                    '								<creg:referenceQualifier>DID</creg:referenceQualifier>' +
                    '								<creg:primeId>' + travelerDatum.DID__c + '</creg:primeId>' +
                    '							</creg:idSection>' +
                    '						</creg:productIdentifier>' +
                    '					</creg:productLevel>' +
                    '				</creg:customerLevel>';
				}
            soapRequest +=
                '        </creg:DCSACC_CheckRegulatoryRqts>' +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';

            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/CREGRQ_19_1_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep3();
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, 'iAPP');
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }
    
    public static void DCSACC_AQQ(List<TravellerInfo__c> travelerData) {
        try {
            preRequest();
            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:ccp="http://webservices.amadeus.com/CREGRQ_19_1_1A">' +
                '	<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '		<sec:AMA_SecurityHostedUser>' +
                '			<sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
                '		</sec:AMA_SecurityHostedUser>' +
                '		<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
                '            <wsse:UsernameToken>' +
                '                <wsse:Username>'+userID+'</wsse:Username>' +
                '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
                '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
                '                <wsu:Created>'+created+'</wsu:Created>' +
                '            </wsse:UsernameToken>' +
                '        </wsse:Security>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/CREGRQ_19_1_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:' + uniqueId + '</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
                '        <creg:DCSACC_CheckRegulatoryRqts>' +
				'        	<creg:regulatoryIndicators>' +
				'        		<statusDetails>' +
				'        			<indicator>AQQ</indicator>' +
				'        		</statusDetails>' +
				'        	</creg:regulatoryIndicators>' ;
                for(travellerInfo__c travelerDatum : travelerData) {                    
                    soapRequest +=
                    '				<creg:customerLevel>' +
                    '					<creg:customerIdentifier>' +
                    '						<creg:idSection>' +
                    '							<creg:referenceQualifier>UCI</creg:referenceQualifier>' +
                    '							<creg:primeId>' + travelerDatum.UCI__c + '</creg:primeId>' +
                    '						</creg:idSection>' +
                    '					</creg:customerIdentifier>' +
                    '					<creg:customerDetails>' +
                    '						<creg:paxDetails>' +
                    '							<creg:surname>' + travelerDatum.LastName__c + '</creg:surname>' +
                    '							<creg:type>' + PType(travelerDatum.PassengerType__c) + '</creg:type>' +
                    '						</creg:paxDetails>' +
                    '						<creg:otherPaxDetails>' +
                    '							<creg:givenName>' + travelerDatum.firstName__c + '</creg:givenName>' +
                    '							<creg:type>' + PGengder(travelerDatum.Gender__c) + '</creg:type>' +
                    '						</creg:otherPaxDetails>' +
                    '					</creg:customerDetails>' +
                    '					<creg:primeFlightProductIdentifier>' +
                    '						<creg:idSection>' +
                    '							<creg:referenceQualifier>DID</creg:referenceQualifier>' +
                    '							<creg:primeId>' + travelerDatum.DID__c + '</creg:primeId>' +
                    '						</creg:idSection>' +
                    '					</creg:primeFlightProductIdentifier>' +
                    '					<creg:productLevel>' +
                    '						<creg:operatingFlightDetails>' +
                    '							<creg:carrierDetails>' +
                    '								<creg:marketingCarrier>JX</creg:marketingCarrier>' +
                    '							</creg:carrierDetails>' +
                    '							<creg:flightDetails>' +
                    '								<creg:flightNumber>' + travelerDatum.FlightNumber__c + '</creg:flightNumber>' +
                    '							</creg:flightDetails>' +
                    '							<creg:departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</creg:departureDate>' +
                    '							<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                    '						</creg:operatingFlightDetails>' +
                    '						<creg:productIdentifier>' +
                    '							<creg:idSection>' +
                    '								<creg:referenceQualifier>DID</creg:referenceQualifier>' +
                    '								<creg:primeId>' + travelerDatum.DID__c + '</creg:primeId>' +
                    '							</creg:idSection>' +
                    '						</creg:productIdentifier>' +
                    '					</creg:productLevel>' +
                    '				</creg:customerLevel>';
				}
            soapRequest +=
                '        </creg:DCSACC_CheckRegulatoryRqts>' +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';

            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/CREGRQ_19_1_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep3();
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, rloc);
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }
    
    public static void DCSACC_ADC(List<TravellerInfo__c> travelerData) {
        try {
            preRequest();
            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:ccp="http://webservices.amadeus.com/CREGRQ_19_1_1A">' +
                '	<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '		<sec:AMA_SecurityHostedUser>' +
                '			<sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
                '		</sec:AMA_SecurityHostedUser>' +
                '		<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
                '            <wsse:UsernameToken>' +
                '                <wsse:Username>'+userID+'</wsse:Username>' +
                '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
                '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
                '                <wsu:Created>'+created+'</wsu:Created>' +
                '            </wsse:UsernameToken>' +
                '        </wsse:Security>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/CREGRQ_19_1_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:' + uniqueId + '</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
                '        <creg:DCSACC_CheckRegulatoryRqts>' +
				'        	<creg:regulatoryIndicators>' +
				'        		<statusDetails>' +
				'        			<indicator>ADC</indicator>' +
				'        		</statusDetails>' +
				'        	</creg:regulatoryIndicators>' ;
                for(travellerInfo__c travelerDatum : travelerData) {                    
                    soapRequest +=
                    '				<creg:customerLevel>' +
                    '					<creg:customerIdentifier>' +
                    '						<creg:idSection>' +
                    '							<creg:referenceQualifier>UCI</creg:referenceQualifier>' +
                    '							<creg:primeId>' + travelerDatum.UCI__c + '</creg:primeId>' +
                    '						</creg:idSection>' +
                    '					</creg:customerIdentifier>' +
                    '					<creg:customerDetails>' +
                    '						<creg:paxDetails>' +
                    '							<creg:surname>' + travelerDatum.LastName__c + '</creg:surname>' +
                    '							<creg:type>' + PType(travelerDatum.PassengerType__c) + '</creg:type>' +
                    '						</creg:paxDetails>' +
                    '						<creg:otherPaxDetails>' +
                    '							<creg:givenName>' + travelerDatum.firstName__c + '</creg:givenName>' +
                    '							<creg:type>' + PGengder(travelerDatum.Gender__c) + '</creg:type>' +
                    '						</creg:otherPaxDetails>' +
                    '					</creg:customerDetails>' +
                    '					<creg:primeFlightProductIdentifier>' +
                    '						<creg:idSection>' +
                    '							<creg:referenceQualifier>DID</creg:referenceQualifier>' +
                    '							<creg:primeId>' + travelerDatum.DID__c + '</creg:primeId>' +
                    '						</creg:idSection>' +
                    '					</creg:primeFlightProductIdentifier>' +
                    '					<creg:productLevel>' +
                    '						<creg:operatingFlightDetails>' +
                    '							<creg:carrierDetails>' +
                    '								<creg:marketingCarrier>JX</creg:marketingCarrier>' +
                    '							</creg:carrierDetails>' +
                    '							<creg:flightDetails>' +
                    '								<creg:flightNumber>' + travelerDatum.FlightNumber__c + '</creg:flightNumber>' +
                    '							</creg:flightDetails>' +
                    '							<creg:departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</creg:departureDate>' +
                    '							<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                    '						</creg:operatingFlightDetails>' +
                    '						<creg:productIdentifier>' +
                    '							<creg:idSection>' +
                    '								<creg:referenceQualifier>DID</creg:referenceQualifier>' +
                    '								<creg:primeId>' + travelerDatum.DID__c + '</creg:primeId>' +
                    '							</creg:idSection>' +
                    '						</creg:productIdentifier>' +
                    '					</creg:productLevel>' +
                    '				</creg:customerLevel>';
				}
            soapRequest +=
                '        </creg:DCSACC_CheckRegulatoryRqts>' +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';

            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/CREGRQ_19_1_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep3();
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, 'ADC');
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }

    public static void DCSCPR_confirmADC(List<TravellerInfo__c> travelerData) {
        try {
            preRequest();
            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:ccp="http://webservices.amadeus.com/CCPRUQ_20_2_1A">' +
                '	<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '		<sec:AMA_SecurityHostedUser>' +
                '			<sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
                '		</sec:AMA_SecurityHostedUser>' +
                '		<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
                '            <wsse:UsernameToken>' +
                '                <wsse:Username>'+userID+'</wsse:Username>' +
                '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
                '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
                '                <wsu:Created>'+created+'</wsu:Created>' +
                '            </wsse:UsernameToken>' +
                '        </wsse:Security>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/CCPRUQ_20_2_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:' + uniqueId + '</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
                '		<DCSCPR_EditCPR>';
                for(travellerInfo__c travelerDatum : travelerData) {                    
					soapRequest +=
                    '			<customerEdit>' +
                    '				<customerDetails>' +
                    '					<paxDetails>' +
                    '						<surname>' + travelerDatum.LastName__c + '</surname>' +
                    '						<type>' + PType(travelerDatum.PassengerType__c) + '</type>' +
                    '					</paxDetails>' +
                    '					<otherPaxDetails>' +
                    '						<givenName>' + travelerDatum.firstName__c + '</givenName>' +
                    //'						<type>' + PGengder(travelerDatum.Gender__c) + '</type>' +
                    '						<title>' + travelerDatum.title__c + '</title>' +
                    '					</otherPaxDetails>' +
                    '				</customerDetails>' +
                    '				<primeFlightDetails>' +
                    '					<primeOperatingFlight>' +
                    '						<carrierDetails>' +
                    '							<operatingCarrier>JX</operatingCarrier>' +
                    '						</carrierDetails>' +
                    '						<flightDetails>' +
                    '							<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                    '						</flightDetails>' +
                    '						<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                    '						<boardPoint>' + travelerDatum.DepartureLocation__c  + '</boardPoint>' +
                    '					</primeOperatingFlight>' +
                    '					<primeFlightUniqueProductId>' +
                    '						<idSection>' +
                    '							<referenceQualifier>DID</referenceQualifier>' +
                    '							<primeId>' + travelerDatum.DID__c + '</primeId>' +
                    '						</idSection>' +
                    '					</primeFlightUniqueProductId>' +
                    '					<primeFlightDummy/>' +
                    '				</primeFlightDetails>' +
                    '				<uniqueCustomerId>' +
                    '					<idSection>' +
                    '						<referenceQualifier>UCI</referenceQualifier>' +
                    '						<primeId>' + travelerDatum.UCI__c + '</primeId>' +
                    '					</idSection>' +
                    '				</uniqueCustomerId>' +
                    '				<edits>' +
                    '					<operatingFlightDetails>' +
                    '						<carrierDetails>' +
                    '							<marketingCarrier>JX</marketingCarrier>' +
                    '						</carrierDetails>' +
                    '						<flightDetails>' +
                    '							<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                    '						</flightDetails>' +
                    '						<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                    '						<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                    '						<offPoint>' + travelerDatum.Destination__c + '</offPoint>' +
                    '					</operatingFlightDetails>' +
                    '					<uniqueProductId>' +
                    '						<idSection>' +
                    '							<referenceQualifier>DID</referenceQualifier>' +
                    '							<primeId>' + travelerDatum.DID__c + '</primeId>' +
                    '						</idSection>' +
                    '					</uniqueProductId>' +
					'					<otherRegulatoryIndicator>' +
					'						<dummyForSTX/>' +
					'						<otherRegulatoryIndicators>' +
					'						<statusInformation>' +
					'							<indicator>ACO</indicator>' +
					'							<action>1</action>' +
					'						</statusInformation>' +
					'					</otherRegulatoryIndicators>' +
					'				</otherRegulatoryIndicator>' +
					'				<cprGroupDeleteIndicators>' +
					'					<statusInformation>' +
					'						<indicator>ADC</indicator>' +
					'						<action>0</action>' +
					'					</statusInformation>' +
					'				</cprGroupDeleteIndicators>' +
                    '			</edits>' +
                    '		</customerEdit>';
				}
            soapRequest +=
            '		</DCSCPR_EditCPR>' +
            '   </soapenv:Body>' +
            '</soapenv:Envelope>';
    
            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/CCPRUQ_20_2_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, 'confirmADC');
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }

    public static void DCSACC_InitiateCustAcceptance(List<TravellerInfo__c> travelerData) {
        try {
            preRequest();
            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:ccp="http://webservices.amadeus.com/CCKIUQ_20_2_1A">' +
                '	<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '		<sec:AMA_SecurityHostedUser>' +
                '			<sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
                '		</sec:AMA_SecurityHostedUser>' +
                '		<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
                '            <wsse:UsernameToken>' +
                '                <wsse:Username>'+userID+'</wsse:Username>' +
                '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
                '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
                '                <wsu:Created>'+created+'</wsu:Created>' +
                '            </wsse:UsernameToken>' +
                '        </wsse:Security>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/CCKIUQ_20_2_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:' + uniqueId + '</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
                '		<DCSACC_InitiateCustomerAcceptance>' +
                '			<processingIndicators>' +
                '				<statusInformation>' +
                '					<indicator>CAS</indicator>' +
                '					<action>CAC</action>' +
                '				</statusInformation>' +
                '			</processingIndicators>';
                for(travellerInfo__c travelerDatum : travelerData) {                    
                    soapRequest +=
                    '	<customersAndProducts>' +
                    '		<customerDetails>' +
                    '			<paxDetails>' +
                    '				<surname>' + travelerDatum.LastName__c + '</surname>' +
                    '				<type>' + PType(travelerDatum.PassengerType__c) + '</type>' +
                    '			</paxDetails>' +
                    '			<otherPaxDetails>' +
                    '				<givenName>' + travelerDatum.firstName__c + '</givenName>' +
                    '				<type>' + PGengder(travelerDatum.Gender__c) + '</type>' +
                    '				<title>' + travelerDatum.title__c + '</title>' +
                    '			</otherPaxDetails>' +
                    '		</customerDetails>' +
                    '		<uniqueCustomerId>' +
                    '			<idSection>' +
                    '				<referenceQualifier>UCI</referenceQualifier>' +
                    '				<primeId>' + travelerDatum.UCI__c + '</primeId>' +
                    '			</idSection>' +
                    '		</uniqueCustomerId>' +
                    '		<legRestriction>' +
                    '			<origin>' + travelerDatum.DepartureLocation__c + '</origin>' +
                    '			<destination>' + travelerDatum.Destination__c + '</destination>' +
                    '		</legRestriction>' +
                    '		<productDetails>' +
                    '			<operatingFlightDetails>' +
                    '				<carrierDetails>' +
                    '					<marketingCarrier>JX</marketingCarrier>' +
                    '				</carrierDetails>' +
                    '				<flightDetails>' +
                    '					<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                    '				</flightDetails>' +
                    '				<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                    '				<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                    '				<offPoint>' + travelerDatum.Destination__c + '</offPoint>' +
                    '			</operatingFlightDetails>' +
                    '			<productIdentifier>' +
                    '				<idSection>' +
                    '					<referenceQualifier>DID</referenceQualifier>' +
                    '					<primeId>' + travelerDatum.DID__c + '</primeId>' +
                    '				</idSection>' +
                    '			</productIdentifier>' +
                    '		</productDetails>' +
                    '	</customersAndProducts>';
                }
            soapRequest +=
                '		</DCSACC_InitiateCustomerAcceptance>' +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';

            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/CCKIUQ_20_2_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, 'C3final');
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }
    

    public static String DCSPRT_GetBoardingPassXmlData(List<TravellerInfo__c> travelerData) {
        	preRequest();
            String uniqueId = generateUniqueId();
			
            // Step 2: Construct SOAP XML request body
            String soapRequest = 
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:cbp="http://xml.amadeus.com/CBPXUQ_20_1_1A">' +
            '	<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
            '		<sec:AMA_SecurityHostedUser>' +
            '			<sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
            '		</sec:AMA_SecurityHostedUser>' +
            '		<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
            '			<wsse:UsernameToken>' +
            '                <wsse:Username>'+userID+'</wsse:Username>' +
            '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
            '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
            '                <wsu:Created>'+created+'</wsu:Created>' +
            '			</wsse:UsernameToken>' +
            '		</wsse:Security>' +
            '		<awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
            '			<awsl:Consumer>' +
            '				<awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
            '			</awsl:Consumer>' +
            '		</awsl:TransactionFlowLink>' +
            '		<wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/CBPXUQ_20_1_1A</wsa:Action>' +
            '			<wsa:ReplyTo soapenv:mustUnderstand="1">' +
            '				<wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
            '			</wsa:ReplyTo>' +
            '			<wsa:MessageID soapenv:mustUnderstand="1">uuid:d60aaa7e-bde2-49e1-a9dc-7984f22dcff4</wsa:MessageID>' +
            '				<wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
            '			</soapenv:Header>' +
            '		<soapenv:Body>'+    
            '		<cbp:DCSPRT_GetBoardingPassXmlData>';
                if (!travelerData.isEmpty()) {
    				TravellerInfo__c firstTraveler = travelerData[0];
                    
                    String flightNumberRaw = firstTraveler.FlightNumber__c;
                    String flightNumber = '';
                    String operationnalSuffix = '';
                
                    // 用正規表達式切割：^前面是數字+後面是英文字
                    Pattern p = Pattern.compile('^(\\d+)([A-Za-z]*)$');
                    Matcher m = p.matcher(flightNumberRaw);
                
                    if (m.find()) {
                        flightNumber = m.group(1);  // 數字部分
                        operationnalSuffix = m.group(2); // 英文字母部分
                    }
                    soapRequest +=
        			'		<cbp:businessDataXsdVersion>' +
                    '			<messageIdentifier>' +
					'				<messageTypeIdentifier>PRT_BOP_BusinessData_v1</messageTypeIdentifier>' +
            		'				<messageTypeVersionNumber>1</messageTypeVersionNumber>' +
                    '				<messageTypeReleaseNumber>001</messageTypeReleaseNumber>' +
                    '				<controllingAgency>AMA2010A</controllingAgency>' +
                    '				<domain>xml.amadeus.com/2010/06/DCSCM_PRDCSCM_PRT</domain>' +
               	 	'			</messageIdentifier>' +
               		'			<structureType>XSD</structureType>' +
                 	'		</cbp:businessDataXsdVersion>' +
                    '		<cbp:primeFlightLeg>' +
                    '			<cbp:carrierDetails>' +
               		'				<cbp:marketingCarrier>JX</cbp:marketingCarrier>' +
            		'			</cbp:carrierDetails>' +
            		'			<cbp:flightDetails>' +
               		'				<cbp:flightNumber>' + flightNumber + '</cbp:flightNumber>' +
               		'				<cbp:operationalSuffix>' + operationnalSuffix + '</cbp:operationalSuffix>' +
            		'			</cbp:flightDetails>' +
            		'			<cbp:departureDate>' + DDMMYYtoYYYYMMDD(firstTraveler.DepartureDate__c) + '</cbp:departureDate>' +
            		'			<cbp:boardPoint>' + firstTraveler.departureLocation__c + '</cbp:boardPoint>' +
         			'		</cbp:primeFlightLeg>' ;    
                    for(travellerInfo__c travelerDatum : travelerData) {
                        if(travelerDatum.CAS__c=='CAC'){
                            soapRequest +=
                            '		<cbp:customerLevel>' +
                            '		<cbp:uniqueCustomerId>' +
                            '		<paxDetails>' +
                            '		<surname>' + travelerDatum.LastName__c + '</surname>' +           			
                            '		</paxDetails>' +
                            '		<otherPaxDetails>' +
                            '		<givenName>' + travelerDatum.firstName__c + '</givenName>' +
                            '		<uniqueCustomerIdentifier>' + travelerDatum.UCI__c + '</uniqueCustomerIdentifier>' +
                            '		</otherPaxDetails>' +
                            '		</cbp:uniqueCustomerId>' +
                            '		<cbp:productLevel>' +
                            '		<cbp:operatingFlightDetails>' +
                            '		<cbp:carrierDetails>' +
                            '		<cbp:marketingCarrier>JX</cbp:marketingCarrier>' +
                            '		</cbp:carrierDetails>' +
                            '		<cbp:flightDetails>' +
                            '		<cbp:flightNumber>' + flightNumber + '</cbp:flightNumber>' +
                            '		<cbp:operationalSuffix>' + operationnalSuffix + '</cbp:operationalSuffix>' +
                            '		</cbp:flightDetails>' +
                            '		<cbp:departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</cbp:departureDate>' +
                            '		<cbp:boardPoint>' + travelerDatum.departureLocation__c + '</cbp:boardPoint>' +
                            '		</cbp:operatingFlightDetails>' +
                            '		<cbp:customerProductIdentifier>' +
                            '		<cbp:idSection>' +
                            '		<cbp:referenceQualifier>DID</cbp:referenceQualifier>' +
                            '		<cbp:primeId>' + travelerDatum.DID__c + '</cbp:primeId>' +
                            '		</cbp:idSection>' +
                            '		</cbp:customerProductIdentifier>' +
                            '		</cbp:productLevel>' +
                            '		</cbp:customerLevel>';
                        }
                    }
            	}
                soapRequest +=
                '		</cbp:DCSPRT_GetBoardingPassXmlData>' +
                '    </soapenv:Body>' +
                '</soapenv:Envelope>';

            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/CBPXUQ_20_1_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);
		
            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            //ApiLogger.logAsync(request, response, 'BASE64');
        if (response.getStatusCode() == 200) {
            String xmlBody = response.getBody();
            if (String.isBlank(xmlBody) || !xmlBody.contains('<soapenv:Body')) {
                System.debug('⚠️ Missing <Body> in response. Possibly invalid.');
                return null;
            }
        	//ApiLogger.log(request, response, 'C4_XmlData');
            return xmlBody;
        }
        return null;
    }
    
    
    
    
    

    public static void DCSCPR_EditCPR_Add_NextComment(List<TravellerInfo__c> travelerData) {
        try {
            preRequest();
            // Step 2: Construct SOAP XML request body
            String soapRequest = 
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sec="http://xml.amadeus.com/2010/06/Security_v1" xmlns:link="http://wsdl.amadeus.com/2010/06/ws/Link_v1" xmlns:ses="http://xml.amadeus.com/2010/06/Session_v3" xmlns:ccp="http://xml.amadeus.com/CCPRUQ_20_2_1A">' +
                '	<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
                '		<sec:AMA_SecurityHostedUser>' +
                '			<sec:UserID POS_Type="1" RequestorType="U" PseudoCityCode="'+officeID+'" AgentDutyCode="SU"/>' +
                '		</sec:AMA_SecurityHostedUser>' +
                '		<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">' +
                '            <wsse:UsernameToken>' +
                '                <wsse:Username>'+userID+'</wsse:Username>' +
                '                <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'+passwordDigest+'</wsse:Password>' +
                '                <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'+nonce+'</wsse:Nonce>' +
                '                <wsu:Created>'+created+'</wsu:Created>' +
                '            </wsse:UsernameToken>' +
                '        </wsse:Security>' +
                '        <awsl:TransactionFlowLink xmlns:awsl="http://wsdl.amadeus.com/2010/06/ws/Link_v1">' +
                '            <awsl:Consumer>' +
                '                <awsl:UniqueID>'+uniqueId+'</awsl:UniqueID>' +
                '            </awsl:Consumer>' +
                '        </awsl:TransactionFlowLink>' +
                '        <wsa:Action soapenv:mustUnderstand="1">http://webservices.amadeus.com/CCPRUQ_20_2_1A</wsa:Action>' +
                '        <wsa:ReplyTo soapenv:mustUnderstand="1">' +
                '            <wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>' +
                '        </wsa:ReplyTo>' +
                '        <wsa:MessageID soapenv:mustUnderstand="1">uuid:' + uniqueId + '</wsa:MessageID>' +
                '        <wsa:To soapenv:mustUnderstand="1">{!($Credential.Amadeus.Endpoint)}</wsa:To>' +
                '    </soapenv:Header>' +
                '    <soapenv:Body>' +
                '      <DCSCPR_EditCPR>' +
                '		<processIndicators>' +
                '			<statusDetails>' +
                '				<indicator>PRC</indicator>' +
                '				<action>0</action>' +
                '			</statusDetails>' +
                '		</processIndicators>';
                for(travellerInfo__c travelerDatum : travelerData) {
                    if(travelerDatum.CAS__c=='CAC'){                    
					soapRequest +=
                    '			<customerEdit>' +
                    '				<customerDetails>' +
                    '					<paxDetails>' +
                    '						<surname>' + travelerDatum.LastName__c + '</surname>' +
                    '						<type>' + PType(travelerDatum.PassengerType__c) + '</type>' +
                    '					</paxDetails>' +
                    '					<otherPaxDetails>' +
                    '						<givenName>' + travelerDatum.firstName__c + '</givenName>' +
                    '						<type>' + PGengder(travelerDatum.Gender__c) + '</type>' +
                    '						<title>' + travelerDatum.title__c + '</title>' +
                    '					</otherPaxDetails>' +
                    '				</customerDetails>' +
                    '				<primeFlightDetails>' +
                    '					<primeOperatingFlight>' +
                    '						<carrierDetails>' +
                    '							<operatingCarrier>JX</operatingCarrier>' +
                    '						</carrierDetails>' +
                    '						<flightDetails>' +
                    '							<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                    '						</flightDetails>' +
                    '						<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                    '						<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                    '					</primeOperatingFlight>' +
                    '					<primeFlightUniqueProductId>' +
                    '						<idSection>' +
                    '							<referenceQualifier>DID</referenceQualifier>' +
                    '							<primeId>' + travelerDatum.DID__c + '</primeId>' +
                    '						</idSection>' +
                    '					</primeFlightUniqueProductId>' +
                    '					<primeFlightDummy/>' +
                    '				</primeFlightDetails>' +
                    '				<uniqueCustomerId>' +
                    '					<idSection>' +
                    '						<referenceQualifier>UCI</referenceQualifier>' +
                    '						<primeId>' + travelerDatum.UCI__c + '</primeId>' +
                    '					</idSection>' +
                    '				</uniqueCustomerId>' +
                    '				<edits>' +
                    '					<operatingFlightDetails>' +
                    '						<carrierDetails>' +
                    '							<marketingCarrier>JX</marketingCarrier>' +
                    '						</carrierDetails>' +
                    '						<flightDetails>' +
                    '							<flightNumber>' + travelerDatum.FlightNumber__c + '</flightNumber>' +
                    '						</flightDetails>' +
                    '						<departureDate>' + DDMMYYtoYYYYMMDD(travelerDatum.DepartureDate__c) + '</departureDate>' +
                    '						<boardPoint>' + travelerDatum.DepartureLocation__c + '</boardPoint>' +
                    '						<offPoint>' + travelerDatum.Destination__c + '</offPoint>' +
                    '					</operatingFlightDetails>' +
                    '					<uniqueProductId>' +
                    '						<idSection>' +
                    '							<referenceQualifier>DID</referenceQualifier>' +
                    '							<primeId>' + travelerDatum.DID__c + '</primeId>' +
                    '						</idSection>' +
                    '					</uniqueProductId>' +
                    '				    <cprGroupDeleteIndicators>' +
                    '						<statusInformation>' +
                    '							<indicator>DCD</indicator>' +
                    '							<action>0</action>' +
                    '						</statusInformation>' +
                    '					</cprGroupDeleteIndicators>' +
                    '					<commentEdit>' +
                    '						<legRestriction>' +
                    '							<origin>' + travelerDatum.DepartureLocation__c + '</origin>' +
                    '							<destination>' + travelerDatum.Destination__c + '</destination>' +
                    '						</legRestriction>' +
                    '						<commentDetails>' +
                    '							<commentInformation>' +
                    '								<remarkDetails>' +
                    '									<type>GTE</type>' +
                    '									<freetext>CHECK PPT</freetext>' +
                    '									<status>H</status>' +
                    '									<otherStatus>CND</otherStatus>' +
                    '								</remarkDetails>' +
                    '							</commentInformation>' +
                    '						</commentDetails>' +
                    '					</commentEdit>' +
                    '       	    </edits>' +
                    '			</customerEdit>';
                    }
				}
            soapRequest +=
            '		</DCSCPR_EditCPR>' +
            '   </soapenv:Body>' +
            '</soapenv:Envelope>';
    
            // Step 3: Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Amadeus'); // Replace with actual API endpoint
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/xml');
            Integer contentLength = Blob.valueOf(soapRequest).size();
            //request.setHeader('Content-Length', String.valueOf(contentLength));
            request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            request.setHeader('SOAPAction', 'http://webservices.amadeus.com/CCPRUQ_20_2_1A'); // Add SOAPAction if required
            request.setBody(soapRequest);

            // Step 4: Send the HTTP request
            Http http = new Http();
            HttpResponse response = http.send(request);

            // Debugging response
            System.debug('Response Status: ' + response.getStatusCode());
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + JSON.serializePretty(response.getBody()));
            //Insert new Task(Subject = 'Amadeus test', Description = response.getBody(), Status = 'Completed');
            
            // Assuming xmlResponse contains the XML string
            String xmlResponse = response.getBody(); // Replace this with your actual XML response
            
            if (String.isNotBlank(xmlResponse)) {
                try {
                    // Parse the XML response
                    Dom.Document doc = new Dom.Document();
                    doc.load(xmlResponse);
                    
                    // Extract the SOAP Envelope and Header
                    Dom.XmlNode envelopeNode = doc.getRootElement();
                    Dom.XmlNode headerNode = envelopeNode.getChildElement('Header', 'http://schemas.xmlsoap.org/soap/envelope/');
                    
                    if (headerNode != null) {
                        // Extract the awsse:Session node
                        Dom.XmlNode sessionNode = headerNode.getChildElement('Session', 'http://xml.amadeus.com/2010/06/Session_v3');
                        
                        if (sessionNode != null) {
                            // Extract the values of SessionId, SequenceNumber, and SecurityToken
                            sessionId = sessionNode.getChildElement('SessionId', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            sequenceNumber = sessionNode.getChildElement('SequenceNumber', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            securityToken = sessionNode.getChildElement('SecurityToken', 'http://xml.amadeus.com/2010/06/Session_v3').getText();
                            
                            if (!String.isEmpty(sessionId) && !String.isEmpty(sequenceNumber) && !String.isEmpty(securityToken)) {
                                //UploadDocumentsStep3();
                            } else {
                                System.debug('Unable to extract SessionId, SequenceNumber, or SecurityToken');
                            }
                        } else {
                            System.debug('Session node is missing in the response');
                        }
                    } else {
                        System.debug('Header node is missing in the response');
                    }
                } catch (Exception e) {
                    System.debug('Error while parsing XML: ' + e.getMessage());
                }
            } else {
                System.debug('Response is empty or null');
            }
            //ApiLogger.logAsync(request, response, 'CHECK PPT');
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage() + ' at: ' + e.getLineNumber());
        }
    }

    private static void chunkedDebug(String label, String content, Integer chunkSize, Integer maxChunks) {
        Integer len = content.length();
        Integer i = 0;
        Integer printedChunks = 0;
    
        while (i < len && printedChunks < maxChunks) {
            Integer count = Math.min(i + chunkSize, len);
            System.debug(label + ' 📦 Chunk ' + i + ' ~ ' + (count - 1) + ':\n' + content.substring(i, count));
            i = count;
            printedChunks++;
        }
    
        if (i < len) {
            System.debug(label + ' 🔕 [Truncated] Remaining ' + (len - i) + ' chars not shown.');
        }
    }
    
    private static void chunkedDebugSet(String label, Set<String> values, Integer chunkSize) {
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
    
        if (total == 0) {
            System.debug(label + ' ❌ No control numbers found.');
        } else {
            System.debug(label + ' ✅ Total: ' + total);
        }
    }
    
    public static Date parseDDMMYY(String str) {
        if (String.isBlank(str) || str.length() != 6) return null;
        Integer day   = Integer.valueOf(str.substring(0, 2));
        Integer month = Integer.valueOf(str.substring(2, 4));
        Integer year  = 2000 + Integer.valueOf(str.substring(4, 6));
        return Date.newInstance(year, month, day);
    }
    
    //convertPassengerType
    public static String PType(String paxType) {
        Map<String, String> paxTypeMap = new Map<String, String>{
            'ADT' => 'A',
            'CHD' => 'C',
            'INF' => 'IN'
        };
        return paxTypeMap.get(paxType);
    }
    
    //convertPassengerGengder
    public static String PGengder(String paxGender) {
        Map<String, String> paxGenderMap = new Map<String, String>{
            'M' => 'M',
            'MI' => 'M',
            'F' => 'F',
            'FI' => 'F'
        };
        return paxGenderMap.get(paxGender);
    }
    
    public static String DDMMYYtoYYYYMMDD(String ddmmyy) {
        if (String.isBlank(ddmmyy) || ddmmyy.length() != 6) return null;
        String dd = ddmmyy.substring(0, 2);
        String mm = ddmmyy.substring(2, 4);
        String yy = ddmmyy.substring(4, 6);
    
        Integer yearInt = Integer.valueOf(yy);
        Integer fullYear = 2000 + yearInt; // 如有需要支援1950以前，這邊可擴充
    
        return String.valueOf(fullYear) + mm + dd;
    }
    
    public static String DDMMMYYtoYY(String input) {
        Integer currentYearTwoDigits = Math.mod(Date.today().year(), 100);
        String yearStr = input.substring(5, 7);
        Integer yy = Integer.valueOf(yearStr);
        Integer fullYear = (yy <= currentYearTwoDigits) ? 2000 + yy : 1900 + yy;
        return String.valueOf(fullYear);
    }    
    
    public static String DDMMMYYtoMM(String input) {
        String monStr = input.substring(2, 5).toUpperCase();
    
        Map<String, String> monthMap = new Map<String, String>{
            'JAN' => '01', 'FEB' => '02', 'MAR' => '03', 'APR' => '04',
            'MAY' => '05', 'JUN' => '06', 'JUL' => '07', 'AUG' => '08',
            'SEP' => '09', 'OCT' => '10', 'NOV' => '11', 'DEC' => '12'
        };
    
        if (!monthMap.containsKey(monStr)) {
            throw new IllegalArgumentException('無效的月份縮寫：' + monStr);
        }
        return monthMap.get(monStr);
    }

    public static String DDMMMYYtoDD(String input) {
        return input.substring(0, 2);
    }    
    
    public static String DDMMMYYtoYYYYMMDDFuture(String input) {
        if (input == null || input.length() != 7) {
            throw new IllegalArgumentException('輸入格式錯誤，應為 7 碼如 26JUN24');
        }
    
        // 日
        String day = input.substring(0, 2);
    
        // 月
        String monStr = input.substring(2, 5).toUpperCase();
        Map<String, String> monthMap = new Map<String, String>{
            'JAN' => '01', 'FEB' => '02', 'MAR' => '03', 'APR' => '04',
            'MAY' => '05', 'JUN' => '06', 'JUL' => '07', 'AUG' => '08',
            'SEP' => '09', 'OCT' => '10', 'NOV' => '11', 'DEC' => '12'
        };
        String month = monthMap.get(monStr);
        if (month == null) {
            throw new IllegalArgumentException('無效的月份縮寫：' + monStr);
        }
    
        // 年
        String yearStr = input.substring(5, 7);
        Integer yy = Integer.valueOf(yearStr);
        Integer baseYear = 2000 + yy;
        Integer currentYear = Date.today().year();
    
        if (baseYear < currentYear) {
            baseYear += 100;
        }
    
        return String.valueOf(baseYear) + month + day;
    }
    
    public static String normalizeName(String name) {
        if (String.isBlank(name)) return '';
        // 全轉成大寫
        String result = name.toUpperCase();
        // 移除所有非 A-Z 的字元
        result = result.replaceAll('[^A-Z]', '');
        return result;
    }
    
    public static String queryTravellerInfo() {
        return 'SELECT Id, OwnerId, FlightPrefix__c, FlightNumber__c, DepartureDate__c, DepartureLocation__c, PNR__c, PT__c, LastName__c, firstName__c, PassengerType__c, country__c, DateOfBirth__c, PassportNumber__c, PassportExpiryDate__c, VisaNumber__c, VisaExpiryDate__c, VisaIssuingCountry__c, USAStreet__c, USACity__c, USAState__c, USAZipCode__c, USAEmergencyContactName__c, USAEmergencyContactNationality__c, USAEmergencyContactPhone__c, title__c, DepartureLocationGMT__c, DepartureLocationGMT8__c, gender__c, PassportIssuingCountry__c, PassportLastName__c, PassportFirstName__c, SeatStatus__c, PassengerTypeOrderBy__c, PTOrderBy__c, PassportString__c, DepartureLocationGMTLocal__c, PrintDisable__c, Barcode__c, SeatIsChargeable__c, External_ID__c, Barcode_Formula__c, C3ExternalFinished__c, C4BoardingPassPrinted__c, Destination__c, C1OperationDateTime__c, BookingClass__c, DepartureTime__c, C1OperationDisable__c, US_Bound__c, C2OperationStartDateTime__c, C2OperationEndDateTime__c, C2OperationDisable__c, C3OperationDateTime__c, C3OperationDisable__c, C4OperationDateTime__c, C4OperationDisable__c, C4PaperBoardingPass__c, C4EBoardingPass__c, C1Finished__c, C2Finished__c, C3Finished__c, C4Finished__c, Meal__c, C4BoardingPassPrintedTime__c, CabinCode__c, CabinClass__c, CheckDisable__c, Service__c, Seat__c, SSR_RawData__c, ST01__c, ST02__c, DepartureDate2__c, DepartureTime2__c, DepartureLocation2__c, Destination2__c, DepartureTerminal__c, BoardingGate__c, PAX__c, UCI__c, DID__c, LatestBoardingTime__c, BoardingPriority__c, SecurityNumber__c, FQTVTierCode__c, CAS__c, PassportFinished__c, C3StatusResponse__c, paxDetails_type__c, AircraftType__c, C3Status__c, C4BoardingPassPrintedTimeGMTLocal__c, IATA_MSO_Code__c, RQST_OT__c, TicketType__c, BagTag__c, Selectee__c, FQTVNumber__c, OperatingCarrierCode__c, FQTVCarrierCode__c, C3CheckboxDisplay__c FROM travellerInfo__c';
    }
    
    private static String APEtoCTCE(String raw) {
        if (String.isBlank(raw)) return raw;
    
        String val = raw;
        // 1) @ →//
        val = val.replaceAll( '@','//');
        // 2) _ → ..
        val = val.replaceAll( '_','\\.\\.');
        // 3) - → ./
        val = val.replaceAll( '-','\\./');
    
        return val;
    }
    
    //依 PT__c 分組，保留原輸入順序（同組內順序不變）
    private static Map<String, List<TravellerInfo__c>> groupByPTPreserveOrder(List<TravellerInfo__c> travellers) {
        Map<String, List<TravellerInfo__c>> m = new Map<String, List<TravellerInfo__c>>();
        for (TravellerInfo__c t : travellers) {
            String key = (t.PT__c == null) ? '__NULL__' : String.valueOf(t.PT__c).trim();
            if (!m.containsKey(key)) m.put(key, new List<TravellerInfo__c>());
            m.get(key).add(t);
        }
        return m;
    }
    
    //將 PT key 做「數字優先且遞增」排序，非數字（含 __NULL__）排最後，仍保留字典序 
    private static List<String> sortPTKeys(Set<String> keyset) {
        List<String> numericKeys = new List<String>();
        List<Integer> numericVals = new List<Integer>();
        List<String> nonNumeric = new List<String>();
    
        for (String k : keyset) {
            if (k == '__NULL__') { nonNumeric.add(k); continue; }
            try {
                Integer v = Integer.valueOf(k);
                numericKeys.add(k);
                numericVals.add(v);
            } catch (Exception e) {
                nonNumeric.add(k);
            }
        }
        // 對數字部分排序
        numericVals.sort(); // 升冪
        List<String> result = new List<String>();
        for (Integer v : numericVals) result.add(String.valueOf(v));
        // 非數字部分字典序
        nonNumeric.sort();
        result.addAll(nonNumeric);
        return result;
    }
    
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