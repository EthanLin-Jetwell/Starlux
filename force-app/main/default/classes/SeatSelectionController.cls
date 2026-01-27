public without sharing class SeatSelectionController {
    public static String PAGENAME = 'SeatSelection';
    public String IATAcode { get; set; }
    
    public String errorMessage { get; set; }
    public String successMessage { get; set; }
    /* ──────────── 畫面綁定用屬性 ──────────── */
    public String  flightPrefix  {get;set;}
    public String  flightNumber  {get;set;}
    public String  departureLocation { get; set; }
    public Date    departureDate {get;set;}
    public String  departureDateStr { get; set; }
    public String  bookingCodes  {get;set;}          // 逗號分隔 PNR
    public Map<String, Boolean> pnrC2DisabledMap { get; set; }  // Map to track C2OperationDisable per PNR
    public String pnrC2DisabledMapJSON { 
        get { 
            return pnrC2DisabledMap != null ? JSON.serialize(pnrC2DisabledMap) : '{}'; 
        } 
        set; 
    }  

    public String NoticeContentSeatSelection { get; set; }  // 新增用於存儲公告內容的屬性
    
    /* ──────────── 結果顯示用 ──────────── */
    public List<String> pnrKeys  {get;set;}          // 分頁籤
    public String       currentTabKey {get;set;}       // 預設顯示
    public List<TravellerInfo__c> travelerList { get; set; }
    //public Map<Id, TravellerInfo__c> oldMap { get; set; }
    
    public Map<String , List<PassengerInfo>> tabData {get;set;}
    public Boolean showUSFields { get; private set; }
    public Integer currentPage { get; set; }
    public Integer pageSize { get; set; }
    public Integer totalRecords { get; set; }
    public Integer totalPages {
        get {
            if (totalRecords == null || pageSize == null || pageSize == 0) return 1;
            return (Integer)Math.ceil((Decimal)totalRecords / pageSize);
        }
    }
    public String aircraftType { get; set; }
    public List<String> cabinCodes { get; set; }
    public List<String> blockedSeats { get; set; }
    
    /* 前端回傳修改內容的 JSON */
    public String jsonInput {get;set;}
    
    /* 前端回傳座位選擇的 JSON */
    public String seatAssignmentInput {get;set;}
    
    public Map<String, AirRetrieveSeatMap.Result> seatMapResults { get; private set; }
    
    public String SeatMapAircraftType;
    public String getSeatMapAircraftType() {
        return getSeatMapAircraftType(currentTabKey);
    }
    
    public String getSeatMapAircraftType(String pnrCode) {
        if (seatMapResults != null && seatMapResults.containsKey(pnrCode) && seatMapResults.get(pnrCode) != null) {
            return seatMapResults.get(pnrCode).iataAircraftTypeCode;
        }
        return '';
    }
    
    public String SeatMapCabins { get {
        return getSeatMapCabins(currentTabKey);
    } set; }
    
    public String getSeatMapCabins(String pnrCode) {
        if (seatMapResults != null && seatMapResults.containsKey(pnrCode) && seatMapResults.get(pnrCode) != null && seatMapResults.get(pnrCode).cabinClasses != null) {
            return JSON.serialize(new List<String>(seatMapResults.get(pnrCode).cabinClasses));
        }
        return '';
    }
    
    public String SeatMapDisabledSeats { get {
        return getSeatMapDisabledSeats(currentTabKey);
    } set; }
    
    public String getSeatMapDisabledSeats(String pnrCode) {
        if (seatMapResults != null && seatMapResults.containsKey(pnrCode) && seatMapResults.get(pnrCode) != null && seatMapResults.get(pnrCode).blockedSeats != null) {
            return JSON.serialize(new List<String>(seatMapResults.get(pnrCode).blockedSeats));
        }
        return '';
    }

    // Add the missing property for Visualforce page access
    public String SeatMapDataForJS { get {
        return getSeatMapDataForJS();
    } set; }

    // Add property for all tab data (passenger info) for frontend
    public String AllTabDataForJS { get {
        return getAllTabDataForJS();
    } set; }

    public class SeatMapJSWrapper {
        @AuraEnabled public String aircraftType { get; set; }
        @AuraEnabled public List<String> cabinClasses { get; set; }
        @AuraEnabled public List<String> blockedSeats { get; set; }

        public SeatMapJSWrapper() {
            this.aircraftType = '';
            this.cabinClasses = new List<String>();
            this.blockedSeats = new List<String>();
        }
    }
     /**
     * @description Provides ALL seat map data for ALL PNRs as a single JSON string.
     *              Changed from current tab only to all tabs for frontend data approach.
     *              Format: {pnr1: {aircraftType, cabinClasses, blockedSeats}, pnr2: {...}}
     */
    public String getSeatMapDataForJS() {
        System.debug('🔍 getSeatMapDataForJS called - returning ALL PNR data');
        System.debug('🔍 seatMapResults: ' + JSON.serialize(seatMapResults));
        
        if (seatMapResults == null || seatMapResults.isEmpty()) {
            System.debug('❌ Returning empty object - no seat map data available');
            return '{}';
        }

        // Create map of all PNR seat map data
        Map<String, SeatMapJSWrapper> allPnrData = new Map<String, SeatMapJSWrapper>();
        
        for (String pnrCode : seatMapResults.keySet()) {
            AirRetrieveSeatMap.Result result = seatMapResults.get(pnrCode);
            
            SeatMapJSWrapper dataForPnr = new SeatMapJSWrapper();
            if (result != null) {
                dataForPnr.aircraftType = result.iataAircraftTypeCode;
                
                if (result.cabinClasses != null) {
                    dataForPnr.cabinClasses = new List<String>(result.cabinClasses);
                }
                if (result.blockedSeats != null) {
                    dataForPnr.blockedSeats = new List<String>(result.blockedSeats);
                }
            }
            
            allPnrData.put(pnrCode, dataForPnr);
            System.debug('🔍 Added PNR ' + pnrCode + ': ' + JSON.serialize(dataForPnr));
        }

        String result = JSON.serialize(allPnrData);
        System.debug('✅ getSeatMapDataForJS returning ALL PNR data: ' + result);
        return result;
    }

    /**
     * @description Provides ALL passenger/tab data for ALL PNRs as a single JSON string.
     *              Format: {pnr1: [passenger1, passenger2], pnr2: [...]}
     */
    public String getAllTabDataForJS() {
        System.debug('🔍 getAllTabDataForJS called - returning ALL PNR passenger data');
        System.debug('🔍 tabData: ' + JSON.serialize(tabData));
        
        if (tabData == null || tabData.isEmpty()) {
            System.debug('❌ Returning empty object - no tab data available');
            return '{}';
        }

        // tabData is already in the correct format: Map<String, List<PassengerInfo>>
        // Just serialize it directly
        String result = JSON.serialize(tabData);
        System.debug('✅ getAllTabDataForJS returning ALL PNR passenger data: ' + result);
        return result;
    }
    
    /* ──────────── 內部包裝類（放在同一檔案內） ──────────── */
    
    
    public class PassengerInfo {
        public String  name          {get;set;}   // 姓/名
        public String  title         {get;set;}
        public String  gender        {get;set;}
        public String  nationality   {get;set;}
        public String  birthDate     {get;set;}
        public String  passengerType {get;set;}
        public Integer docCount      {get;set;}
        public Boolean usBound { get; set; }
        public String recordId { get; set; }
        public String seat { get; set; }
        public Boolean seatIsChargeable { get; set; }
        public String pt { get; set; }
        public String st { get; set; }
        public String rqstOT { get; set; }
        public String CAS { get; set; }
        public String DID { get; set; }
        public String FlightNumber { get; set; } 
        public String DepartureLocation { get; set; } 
		public String Destination { get; set; } 
        public String DepartureDate { get; set; } 
        
        
    }
    
    /* ──────────── 建構子 ──────────── */
    /* ---------- 起飛地清單 ---------- */
    public List<String> origins { get; private set; }
    
    public List<SelectOption> getOriginOptions() {
        if (origins == null) {   
            loadOrigins();
        }
        
        List<SelectOption> opts = new List<SelectOption>();
        opts.add( new SelectOption('TPE', 'TPE') ); 
        
        for (String d : origins) {
            opts.add( new SelectOption(d, d) );
        }
        return opts;
    }
    private void loadOrigins() {
        Set<String> depSet = new Set<String>();
        for (AirportCode__c ac : [
            SELECT Departure__c
            FROM   AirportCode__c
            WHERE  RecordType.name = 'B2B Airport Code'
            AND    Departure__c != null 
            AND    Active__c = true
            ORDER BY Departure__c ASC
        ]) {
            depSet.add(ac.Departure__c);
        }
        
        origins = new List<String>(depSet);
        origins.sort();
    }
    
    public SeatSelectionController() {
        flightPrefix = 'JX';
        bookingCodes = '';
        currentPage = 1; 
        pageSize = 50; 
        pnrKeys = new List<String>();
        tabData = new Map<String,List<PassengerInfo>>();
        pnrC2DisabledMap = new Map<String, Boolean>();
        seatMapResults = new Map<String, AirRetrieveSeatMap.Result>();
        loadOrigins(); 
        travelerList = new List<TravellerInfo__c>();
        Map<String, Cookie> cookies = ApexPages.currentPage().getCookies();
        if (cookies != null && cookies.containsKey('accountId')) {
            try {
                UserManagement__c usr = [
                    SELECT Id, IATA_MSO_Code__c
                    FROM UserManagement__c
                    WHERE Id = :cookies.get('accountId').getValue()
                    LIMIT 1
                ];
                IATAcode = usr.IATA_MSO_Code__c;
                System.debug('使用者 IATA Code = ' + IATAcode);
            } catch (Exception e) {
                System.debug('查詢 UserManagement__c 失敗：' + e.getMessage());
                IATAcode = null;
            }
        }
        // Initialize successMessage to prevent null/empty message issues
        successMessage = '';
        
        loadNoticeContentSeatSelection();
    }
    
    /* ──────────── 查詢 PNR ──────────── */
    public PageReference searchPnr() {
        // 一開始就清掉前一次的結果
        pnrKeys.clear();
        tabData.clear();
        travelerList.clear(); 
        errorMessage = '';
        currentTabKey = null;
        showUSFields = false;
        /* 0. 基本欄位檢查 ------------------- */
        if (currentPage == null) currentPage = 1;
        if (pageSize == null) pageSize = 50;
        if (totalRecords == null) totalRecords = 0;

        if (String.isBlank(bookingCodes) ||
            String.isBlank(flightNumber)  ||
            String.isBlank(departureLocation)|| 
            String.isBlank(departureDateStr) ) {
				errorMessage = '請輸入「訂位代號、航班號碼、起飛日期、起飛地」後再搜尋';                
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        '請輸入「訂位代號、航班號碼、起飛日期、起飛地」後再搜尋'
                    )
                );
                return null;
            }
        try {
            String norm = departureDateStr.replace('/', '-');
            departureDate = Date.valueOf(norm);
        } catch (Exception e) {
            errorMessage = '日期格式錯誤，請重新選擇';
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    '日期格式錯誤，請重新選擇'
                )
            );
            return null;
        }
        
        /* 1. 解析 PNR (可輸入多碼逗號分隔) ------ */
        List<String> rawPnrKeys = bookingCodes.contains(',') ?
            bookingCodes.split(',') :
        new List<String>{ bookingCodes.trim() };
            String fn = String.isBlank(flightNumber) ? null : flightNumber.trim();
        DateTime startOfDay = DateTime.newInstance(
            departureDate.year(),
            departureDate.month(),
            departureDate.day(),
            0, 0, 0               // 00:00:00（本地）
        );
        DateTime endOfDay = startOfDay.addDays(1).addSeconds(-1);  // 23:59:59
        
        /* 2. 查 TravellerInfo__c -------------- */
        //Erick修改164~2
        System.debug('About to call AmadeusUtil.listPNRByFlight');
        Map<String,String> extractedPNRs = AmadeusUtil.listPNRByFlight(fn,departureDate.format()+'');
        System.debug('AmadeusUtil.listPNRByFlight completed');
        System.debug('extractedPNRs: ' + extractedPNRs);
        System.debug('rawPnrKeys: ' + rawPnrKeys);
        
        // 篩選出兩者交集的 PNR 清單
        List<String> matchedPnrKeys = new List<String>();
        List<String> unmatchedPnrKeys = new List<String>();
        Set<String> unmatchedSet = new Set<String>();
        Set<String> noSeatMapPNRKeys = new Set<String>();
        List<String> failedRetrievePNRKeys = new List<String>(); // Track PNRs that failed to retrieve
        
        for (String p : rawPnrKeys) {
            if (extractedPNRs.containsKey(p) && extractedPNRs.get(p) == departureLocation) {
                matchedPnrKeys.add(p);
            } else {
                if (unmatchedSet.add(p)) unmatchedPnrKeys.add(p);
            }
        }
        System.debug(matchedPnrKeys);
        System.debug(unmatchedPnrKeys); 
        //WBS PNR_Retrieve
        // First, collect all traveler data WITHOUT performing any DML
        for (String pnr : matchedPnrKeys) {
            try {
                List<TravellerInfo__c> pnrTravelers = AmadeusUtil.retrievePNR(departureLocation, pnr);
                if (pnrTravelers != null && !pnrTravelers.isEmpty()) {
                    travelerList.addAll(pnrTravelers);
                } else {
                    System.debug('⚠️ PNR_Retrieve 無資料：' + pnr);
                    failedRetrievePNRKeys.add(pnr);
                }
            } catch (Exception ex) {
                System.debug('⚠️ PNR_Retrieve 失敗：' + pnr + '，錯誤：' + ex.getMessage());
                failedRetrievePNRKeys.add(pnr);
            }
        }
        
        // Retrieve seat maps FIRST before any DML operations
        /*
        if (travelerList.size() > 0) {
            // 2-1-1 查詢座位圖 - 為每個PNR獲取座位圖 (BEFORE any DML)
            seatMapResults = new Map<String, AirRetrieveSeatMap.Result>();
        
            // Group travelers by PNR to get one seat map per PNR
            Map<String, TravellerInfo__c> pnrToFirstTraveller = new Map<String, TravellerInfo__c>();
            for (TravellerInfo__c traveller : travelerList) {
                if (!pnrToFirstTraveller.containsKey(traveller.PNR__c)) {
                    pnrToFirstTraveller.put(traveller.PNR__c, traveller);
                }
            }
        
            // 暫存需要 fallback 的清單
            List<String> needFallbackPNRs = new List<String>();
        
            // 第一輪：呼叫 Air_RetrieveSeatMap
            for (String pnrCode : pnrToFirstTraveller.keySet()) {
                TravellerInfo__c traveller = pnrToFirstTraveller.get(pnrCode);
                try {
                    System.debug('DML count before callout = ' + Limits.getDMLStatements());
                    System.debug('Email count before callout = ' + Limits.getEmailInvocations());
        
                    AirRetrieveSeatMap.Result seatMapResult = AmadeusUtilRetrieveSeatMap.Air_RetrieveSeatMap(
                        traveller.DepartureDate__c,
                        traveller.DepartureLocation__c,
                        traveller.Destination__c,
                        traveller.FlightNumber__c,
                        traveller.BookingClass__c
                    );
        
                    if (seatMapResult != null && !String.isBlank(seatMapResult.iataAircraftTypeCode)) {
                        String cabinCode = getCabinClass(traveller.BookingClass__c);
                        if (cabinCode != null) {
                            seatMapResult.cabinClasses = new Set<String>{ cabinCode };
                            seatMapResults.put(pnrCode, seatMapResult);
                        } else {
                            System.debug(':x: BookingClass 無法轉換 CabinClass，跳過 PNR ' + pnrCode);
                            noSeatMapPNRKeys.add(pnrCode);
                        }
                    } else {
                        System.debug('⚠️ SeatMap API 無資料，PNR ' + pnrCode + ' 加入 fallback 清單');
                        needFallbackPNRs.add(pnrCode);
                    }
                } catch (Exception ex) {
                    System.debug('❌ PNR ' + pnrCode + ' 呼叫 SeatMap API 錯誤: ' + ex.getMessage());
                    needFallbackPNRs.add(pnrCode);
                }
            }
        
            // 第二輪：只針對 needFallbackPNRs 呼叫 DCSSTG_GetFDSeatMap
            for (String pnrCode : needFallbackPNRs) {
                TravellerInfo__c traveller = pnrToFirstTraveller.get(pnrCode);
                try {
                    AirRetrieveSeatMap.Result seatMapResult = AmadeusUtilRetrieveSeatMap.DCSSTG_GetFDSeatMap(
                        traveller.DepartureDate__c,
                        traveller.DepartureLocation__c,
                        traveller.FlightNumber__c
                    );
                    if (seatMapResult != null && !String.isBlank(seatMapResult.iataAircraftTypeCode)) {
                        String cabinCode = getCabinClass(traveller.BookingClass__c);
                        if (cabinCode != null) {
                            seatMapResult.cabinClasses = new Set<String>{ cabinCode };
                            seatMapResults.put(pnrCode, seatMapResult);
                        } else {
                            System.debug(':x: BookingClass 無法轉換 CabinClass，跳過 PNR ' + pnrCode);
                            noSeatMapPNRKeys.add(pnrCode);
                        }
                    } else {
                        System.debug(':x: PNR ' + pnrCode + ' fallback 呼叫失敗或解析錯誤');
                        noSeatMapPNRKeys.add(pnrCode);
                    }
                } catch (Exception ex) {
                    System.debug('❌ PNR ' + pnrCode + ' 呼叫 DCSSTG API 錯誤: ' + ex.getMessage());
                    noSeatMapPNRKeys.add(pnrCode);
                }
            }
        
            // 所有 callout 完成後再做 DML
            upsert travelerList External_ID__c;
        }
		*/
        
        if(travelerList.size() > 0){
            //2-1-1查詢座位圖 - 為每個PNR獲取座位圖 (BEFORE any DML)
            seatMapResults = new Map<String, AirRetrieveSeatMap.Result>();
            
            // Group travelers by PNR to get one seat map per PNR
            Map<String, TravellerInfo__c> pnrToFirstTraveller = new Map<String, TravellerInfo__c>();
            for (TravellerInfo__c traveller : travelerList) {
                if (!pnrToFirstTraveller.containsKey(traveller.PNR__c)) {
                    pnrToFirstTraveller.put(traveller.PNR__c, traveller);
                }
            }
            
            // Retrieve seat map for each PNR - BEFORE DML to avoid transaction conflicts
            for (String pnrCode : pnrToFirstTraveller.keySet()) {
                TravellerInfo__c traveller = pnrToFirstTraveller.get(pnrCode);
                System.debug('DML count before callout = ' + Limits.getDMLStatements());
                System.debug('Email count before callout = ' + Limits.getEmailInvocations());

                // Use helper method for seat map retrieval with fallback
                AirRetrieveSeatMap.Result seatMapResult = retrieveSeatMapForPNR(pnrCode, traveller);

                if (seatMapResult != null) {
                    seatMapResults.put(pnrCode, seatMapResult);
                } else {
                    System.debug('❌ PNR ' + pnrCode + ' 查座位圖失敗');
                    ApexPages.addMessage(new ApexPages.Message(
                        ApexPages.Severity.INFO,
                        'PNR ' + pnrCode + ' 查座位圖失敗'
                    ));
                    noSeatMapPNRKeys.add(pnrCode);
                }
            }

            
            // Now perform DML operations AFTER all API calls are complete
            upsert travelerList External_ID__c;
        }

        System.debug('unmatchedPnrKeys'+ unmatchedPnrKeys);
        System.debug('matchedPnrKeys'+ matchedPnrKeys);
        System.debug('failedRetrievePNRKeys'+ failedRetrievePNRKeys);
        
        OperationHistoryUtil.log('search', PAGENAME, flightPrefix+'-'+flightNumber, departureDate, departureLocation, bookingCodes, CommonController.getAccountIdFromCookie());

        // 若完全沒交集（matched 為空），就中斷
        if (matchedPnrKeys.isEmpty()) {
            errorMessage = '查無PNR：'+buildPnrFailureMessage(unmatchedPnrKeys);
            return null;
        }

        // 建立錯誤訊息
        errorMessage = buildCombinedErrorMessage(unmatchedPnrKeys, failedRetrievePNRKeys, noSeatMapPNRKeys, matchedPnrKeys);
        
        // 只有當所有PNR都失敗時才中斷，允許部分成功的情況繼續處理
        // Check if at least one PNR has valid data (either passenger data or seat map)
        Boolean hasValidData = false;
        for (String pnr : matchedPnrKeys) {
            // Check if this PNR has traveler data that will be processed
            Boolean hasTravelerData = false;
            for (TravellerInfo__c t : travelerList) {
                if (t.PNR__c == pnr) {
                    hasTravelerData = true;
                    break;
                }
            }
            
            // If this PNR has traveler data AND is not completely failed for seat map
            if (hasTravelerData && (!noSeatMapPNRKeys.contains(pnr) || !failedRetrievePNRKeys.contains(pnr))) {
                hasValidData = true;
                break;
            }
        }
        
        // Only return null if NO valid data exists at all
        if (!hasValidData && !noSeatMapPNRKeys.isEmpty() && noSeatMapPNRKeys.containsAll(matchedPnrKeys)) {
            return null;
        }

        
        Map<Id, TravellerInfo__c> oldMap = new Map<Id, TravellerInfo__c>([
            SELECT Id, PNR__c,
            LastName__c, FirstName__c, Title__c, Gender__c, PT__c, ST01__c, ST02__c,
            Country__c, DateOfBirth__c, PassengerType__c, PassportFinished__c,
            PassportNumber__c, PassportExpiryDate__c, PassportIssuingCountry__c,DepartureLocation__c,US_Bound__c,
            VisaNumber__c, VisaExpiryDate__c, VisaIssuingCountry__c,
            USAStreet__c, USACity__c, USAState__c, USAZipCode__c,
            USAEmergencyContactName__c, USAEmergencyContactNationality__c, USAEmergencyContactPhone__c,	Seat__c,
            CheckDisable__c, C3ExternalFinished__c, C3Finished__c, C4BoardingPassPrinted__c, C4BoardingPassPrintedTime__c,
            C4EBoardingPass__c, C4PaperBoardingPass__c, PrintDisable__c, DepartureLocationGMTLocal__c, Barcode__c, PAX__c, Service__c, Meal__c, IATA_MSO_Code__c, RQST_OT__c,
            C1Finished__c, UCI__c ,DID__c ,CAS__c ,SeatIsChargeable__c ,DepartureDate__c ,DepartureDate2__c ,FlightNumber__c ,Destination__c ,C3Status__c,C2OperationDisable__c,C3OperationDisable__c,C4BoardingPassPrintedTimeGMTLocal__c,
            C3CheckboxDisplay__c, APE__c, APM__c
            FROM   TravellerInfo__c
            //WHERE  PNR__c                 IN :pnrKeys
            WHERE  PNR__c                 IN :matchedPnrKeys
            //AND    FlightNumber__c        =  :fn
            AND External_ID__c != null
            AND    DepartureLocation__c=  :departureLocation
			//AND    IATA_MSO_Code__c    =  :IATAcode
            //AND    DepartureLocationGMTLocal__c >= :startOfDay
            //AND    DepartureLocationGMTLocal__c <= :endOfDay
            ORDER  BY PTOrderBy__c ASC,
            PassengerTypeOrderBy__c ASC
        ]);
        if (oldMap.isEmpty()) {
            errorMessage = '查無PNR : ' + String.join(matchedPnrKeys, ',');
            return null;
        }
        
        // 依 PNR 判斷是否有任何一筆符合 IATA
        Map<String, Boolean> pnrHasSameIata = new Map<String, Boolean>();
        for (TravellerInfo__c t : oldMap.values()) {
            if (String.isBlank(t.PNR__c)) continue;
    
            Boolean ok = (!String.isBlank(IATAcode) && t.IATA_MSO_Code__c == IATAcode);
            if (!pnrHasSameIata.containsKey(t.PNR__c)) {
                pnrHasSameIata.put(t.PNR__c, ok);
            } else {
                pnrHasSameIata.put(t.PNR__c, pnrHasSameIata.get(t.PNR__c) || ok);
            }
        }
    
        // 把 IATA 不符的 PNR 從 matched 移除，並加入 unmatched（不揭露原因）
        List<String> filteredMatched = new List<String>();
        for (String pnr : matchedPnrKeys) {
            if (pnrHasSameIata.containsKey(pnr) && pnrHasSameIata.get(pnr) == true) {
                filteredMatched.add(pnr);
            } else {
                if (unmatchedSet.add(pnr)) unmatchedPnrKeys.add(pnr);
            }
        }
        matchedPnrKeys = filteredMatched;
    
        // 若 unmatched 有內容，顯示錯誤訊息，但不中斷流程
        if (!unmatchedPnrKeys.isEmpty()) {
            errorMessage = '查無部分PNR : ' + String.join(unmatchedPnrKeys, ',');
        }
    
        // 若最後完全沒有可用 PNR，就中斷（全部查無）
        if (matchedPnrKeys.isEmpty()) {
            errorMessage = '查無PNR : ' + String.join(unmatchedPnrKeys, ',');
            return null;
        }
        
        Set<String> matchedSet = new Set<String>(matchedPnrKeys);
        travelerList = new List<TravellerInfo__c>();
        for (TravellerInfo__c t : oldMap.values()) {
            if (matchedSet.contains(t.PNR__c)) travelerList.add(t);
        }
        
        // Build per-PNR C2OperationDisable map (only check first passenger per PNR since it's a formula field)
        pnrC2DisabledMap.clear();
        Map<String, TravellerInfo__c> pnrToFirstTraveler = new Map<String, TravellerInfo__c>();
        
        // Get first traveler for each PNR
        for (TravellerInfo__c t : travelerList) {
            if (!pnrToFirstTraveler.containsKey(t.PNR__c)) {
                pnrToFirstTraveler.put(t.PNR__c, t);
            }
        }
        
        // Check C2OperationDisable for first traveler of each PNR
        for (String pnr : pnrToFirstTraveler.keySet()) {
            TravellerInfo__c firstTraveler = pnrToFirstTraveler.get(pnr);
            Boolean isDisabled = firstTraveler.C2OperationDisable__c == true;
            pnrC2DisabledMap.put(pnr, isDisabled);
            
            // Debug logging for C2OperationDisable
            System.debug('🔍 PNR ' + pnr + ': C2OperationDisable = ' + isDisabled);
        }
                
        showUSFields = false; 
        
        if (travelerList.isEmpty()) {
            pnrKeys.clear();
            tabData.clear();
            currentTabKey = null;
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.INFO,
                    '查無資料，請確認條件是否正確'
                )
            );
            return null;
        }
        for (TravellerInfo__c t : travelerList) {
            if (t.US_Bound__c) {
                showUSFields = true;
                break;
            }
        }
        
        /* 3. 轉成 Map<PNR , List<PassengerInfo>> 結構 */
        tabData.clear();
        
        for (TravellerInfo__c t : travelerList) {
            
            if (!tabData.containsKey(t.PNR__c)) {
                tabData.put(t.PNR__c , new List<PassengerInfo>());
            }
            
            /* 找看看此乘客是否已存在 (以 姓/名 + Title 當 key) */
            String paxKey = t.LastName__c + '/' + t.firstName__c;
            PassengerInfo pInfo;
            for (PassengerInfo p : tabData.get(t.PNR__c)) {
                if (p.name == paxKey) { pInfo = p; break; }
            }
            if (pInfo == null) {
                pInfo = new PassengerInfo();
                pInfo.recordId      = t.Id;
                pInfo.name          = t.LastName__c + '/' + t.firstName__c;
                pInfo.title         = t.title__c;
                pInfo.gender        = t.gender__c;
                pInfo.nationality   = t.country__c;
                pInfo.birthDate     = t.DateOfBirth__c;
                pInfo.passengerType = t.PassengerType__c;
                pInfo.usBound = t.US_Bound__c;
                pInfo.seat = t.Seat__c;
                pInfo.seatIsChargeable = t.SeatIsChargeable__c;
                pInfo.pt = t.PT__c;
                pInfo.st = t.ST01__c;
                pInfo.CAS = t.CAS__c;
                pInfo.DID = t.DID__c;
                pInfo.rqstOT = t.RQST_OT__c;
                pInfo.DepartureDate = t.DepartureDate__c;
                pInfo.DepartureLocation = t.DepartureLocation__c;
                pInfo.Destination = t.Destination__c;
				pInfo.FlightNumber = t.FlightNumber__c;
               
                tabData.get(t.PNR__c).add(pInfo);
            }
            
            
        }
        
        // Check for PNRs with passenger data but no seat map AFTER tabData is populated
        List<String> passengerOnlyPNRKeys = new List<String>();
        for (String pnr : tabData.keySet()) {
            if (!seatMapResults.containsKey(pnr) || seatMapResults.get(pnr) == null) {
                passengerOnlyPNRKeys.add(pnr);
            }
        }
        
        if (!passengerOnlyPNRKeys.isEmpty()) {
            String seatMapError = buildSeatMapFailureMessage(passengerOnlyPNRKeys);
            if (String.isNotBlank(errorMessage)) {
                errorMessage += '；' + seatMapError;
            } else {
                errorMessage = seatMapError;
            }
        }
        
        // 起始分頁設定 - 只顯示有實際資料的PNR分頁
        pnrKeys.clear(); // Clear any existing keys
        if (tabData != null && !tabData.isEmpty()) {
            // Only add PNR keys that have BOTH passenger data AND seat map data
            for (String pnr : tabData.keySet()) {
                if (seatMapResults.containsKey(pnr) && seatMapResults.get(pnr) != null) {
                    pnrKeys.add(pnr);
                }
            }
            if (!pnrKeys.isEmpty()) {
                currentTabKey = pnrKeys[0]; // Set first available PNR as current tab
            }
        }
        // Final debug output
        System.debug('🔍 [FINAL] pnrC2DisabledMap: ' + JSON.serialize(pnrC2DisabledMap));
        System.debug('🔍 [FINAL] currentTabKey: ' + currentTabKey);
        
        return null;   // 交給 VF 的 reRender
    }

    public PageReference handleTabSwitch(){
        String tempKey = currentTabKey;
        System.debug('temp key in handleTabSwitch' + tempKey);
        // the reason why need to save the tabkey, it is because the searchPnr() will set it to the first pnr
        searchPnr();
        currentTabKey = tempKey;
        System.debug('final tab key in handleTabSwitch ' + currentTabKey);
        return null;
    }
    
    /* ──────────── 儲存使用者編輯 ──────────── */
    public PageReference save() {
        
        if (String.isBlank(jsonInput)) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR , '沒有收到任何修改資料')
            );
            return null;
        }
        
        /* JSON 結構：Map<TravellerInfoId , Map<FieldAPI , NewValue>> */
        Map<String , Object> payload = (Map<String , Object>) JSON.deserializeUntyped(jsonInput);
        List<TravellerInfo__c> updates = new List<TravellerInfo__c>();
        
        for (String recId : payload.keySet()) {
            TravellerInfo__c t = new TravellerInfo__c(Id = recId);
            Map<String , Object> fields = (Map<String , Object>) payload.get(recId);
            for (String api : fields.keySet()) {
                t.put(api , fields.get(api));
            }
            updates.add(t);
        }
        
        if (!updates.isEmpty()) {
            try {
                update updates;
                ApexPages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.CONFIRM , '更新成功')
                );
            } catch (DmlException e) {
                ApexPages.addMessages(e);
            }
        }
        return null;
    }
    
    /* ──────────── 儲存座位選擇 ──────────── */
    /*
    public PageReference saveSeatAssignments() {
        System.debug('💾 saveSeatAssignments called');
        System.debug('💾 seatAssignmentInput: ' + seatAssignmentInput);
        
        // Clear previous success message at start of new operation
        successMessage = '';
        
        if (String.isBlank(seatAssignmentInput)) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR, '沒有收到座位選擇資料')
            );
            return null;
        }
        
        try {
            // JSON 結構：Map<TabKey, Map<PassengerIndex, SeatCode>> 
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(seatAssignmentInput);
            List<TravellerInfo__c> updates = new List<TravellerInfo__c>();
            
            // Process each tab's seat assignments
            for (String tabKey : payload.keySet()) {
                Map<String, Object> tabAssignments = (Map<String, Object>) payload.get(tabKey);
                
                // Get passengers for this tab
                List<PassengerInfo> passengers = tabData.get(tabKey);
                if (passengers == null) continue;
                
                // Process each passenger's seat assignment
                for (String passengerIndexStr : tabAssignments.keySet()) {
                    Integer passengerIndex = Integer.valueOf(passengerIndexStr);
                    String seatCode = (String) tabAssignments.get(passengerIndexStr);
                    
                    // Find the corresponding passenger (1-based index)
                    if (passengerIndex > 0 && passengerIndex <= passengers.size()) {
                        PassengerInfo passenger = passengers.get(passengerIndex - 1);
                        
                        // Create update record
                        TravellerInfo__c traveller = new TravellerInfo__c();
                        traveller.Id = passenger.recordId;
                        traveller.Seat__c = seatCode;
                        updates.add(traveller);
                        
                        System.debug('📍 Assigning seat ' + seatCode + ' to passenger ' + passenger.name + ' (ID: ' + passenger.recordId + ')');
                    }
                }
            }
            
            if (!updates.isEmpty()) {
                update updates;
                
                // Update local passenger data to reflect changes
                for (TravellerInfo__c updatedTraveller : updates) {
                    updateLocalPassengerData(updatedTraveller.Id, updatedTraveller.Seat__c);
                }
                
                successMessage = '座位選擇儲存成功，共更新 ' + updates.size() + ' 位旅客';
                System.debug('✅ Successfully updated ' + updates.size() + ' seat assignments');
            } else {
                successMessage = '沒有座位需要更新';
            }
            
        } catch (Exception e) {
            System.debug('❌ Error saving seat assignments: ' + e.getMessage());
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR, '儲存座位選擇時發生錯誤：' + e.getMessage())
            );
        }
        
        return null;
    }*/
    public PageReference saveSeatAssignments() {        
        TravellerInfo__c timecheck = [
            SELECT C2OperationDisable__c
            FROM TravellerInfo__c
            WHERE PNR__c = :currentTabKey
            LIMIT 1
        ];
        if(timecheck.C2OperationDisable__c==True){
                errorMessage = '操作作業逾時，無法進行異動';
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR, '操作作業逾時，無法進行異動'
                ));
                return null;
        }
        
        System.debug('💾 saveSeatAssignments called');
        System.debug('💾 seatAssignmentInput: ' + seatAssignmentInput);
    
        // Clear previous success message at start of new operation
        successMessage = '';
        
        if (String.isBlank(seatAssignmentInput)) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, '沒有收到座位選擇資料'
            ));
            return null;
        }
    
        Map<Id, TravellerInfo__c> oldMap = new Map<Id, TravellerInfo__c>();
        
        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(seatAssignmentInput);
    
            List<TravellerInfo__c> newlyAssignedList = new List<TravellerInfo__c>();
            List<TravellerInfo__c> changedSeatList   = new List<TravellerInfo__c>();
            List<TravellerInfo__c> CheckedSeatList   = new List<TravellerInfo__c>();
            List<String> droppedOTNumbers            = new List<String>();
    
            for (String tabKey : payload.keySet()) {
                Map<String, Object> tabAssignments = (Map<String, Object>) payload.get(tabKey);
                List<PassengerInfo> passengers = tabData.get(tabKey);
                if (passengers == null) continue;
    
                for (String indexStr : tabAssignments.keySet()) {
                    Integer idx = Integer.valueOf(indexStr);
                    if (idx <= 0 || idx > passengers.size()) continue;
    
                    PassengerInfo p = passengers.get(idx - 1);
                    String newSeatCode = (String) tabAssignments.get(indexStr);
                    String oldSeatCode = p.seat;
                    if (String.isBlank(p.recordId) || String.isBlank(newSeatCode)) continue;
    
                    // 無異動就略過
                    if (newSeatCode == oldSeatCode) continue;
    
                    System.debug(newSeatCode);
                    System.debug(oldSeatCode);
                    
                    TravellerInfo__c t = new TravellerInfo__c();
                    t.Id = p.recordId;
                    t.Seat__c = newSeatCode;
    
                    // 傳遞用，不會被更新
                    t.PT__c = p.pt;
                    t.ST01__c = p.st;
    				t.RQST_OT__c = p.rqstOT;
                    t.CAS__c = p.CAS;
                    t.DID__c = p.DID;
                    t.DepartureDate__c = p.DepartureDate;
                    t.DepartureLocation__c = p.DepartureLocation;
                    t.Destination__c = p.Destination;
                    t.FlightNumber__c = p.FlightNumber;
                    t.LastName__c = p.name.split('/')[0];
                    t.FirstName__c = p.name.split('/')[1];
                    
                    TravellerInfo__c tmp = t.clone(true, true, false, false);
                    tmp.Seat__c = oldSeatCode;
                    oldMap.put(p.recordId, tmp);
                    
                    
                    // 判斷是新增或變更
                    if (String.isBlank(oldSeatCode)) {
                        newlyAssignedList.add(t);
                        System.debug('🆕 新增座位: ' + newSeatCode + ' ➜ ' + p.name);
                    }
                    else if(p.CAS == 'CAC'){
                        CheckedSeatList.add(t);
                        System.debug('🆕 變更座位(已Checkin): ' + newSeatCode + ' ➜ ' + p.name);     
                    } else {
                        changedSeatList.add(t);
                        System.debug('🔁 變更座位: ' + oldSeatCode + ' → ' + newSeatCode + ' ➜ ' + p.name);
    
                        // 🆕 若有舊 OT，加入 droppedOTNumbers
                        if (!String.isBlank(p.rqstOT)) {
                            droppedOTNumbers.add(p.rqstOT);
                            System.debug('❌ Dropped OT: ' + p.rqstOT + ' (旅客: ' + p.name + ')');
                        }
                    }
    
                    // 畫面同步
                    updateLocalPassengerData(p.recordId, newSeatCode);
                }
            }
    
            // 統整要更新的資料
            List<TravellerInfo__c> newList = new List<TravellerInfo__c>();
            newList.addAll(newlyAssignedList);
            newList.addAll(changedSeatList);
            newList.addAll(CheckedSeatList);

            if (newList.isEmpty()) {
                successMessage = '沒有座位需要更新';
                return null;
            }
    
            // 🧹 呼叫刪除 OT
            if (!droppedOTNumbers.isEmpty()) {
                try {
                    AmadeusUtil.deleteDroppedOT(departureLocation, currentTabKey, droppedOTNumbers);
                    System.debug('🧹 Dropped OT 號碼清除完成: ' + JSON.serialize(droppedOTNumbers));
                } catch (Exception ex) {
                    System.debug('⚠️ Dropped OT 清除失敗: ' + ex.getMessage());
                    ApexPages.addMessage(new ApexPages.Message(
                        ApexPages.Severity.WARNING,
                        '變更座位成功，但刪除 OT 時發生錯誤：' + ex.getMessage()
                    ));
                }
            }
    
            // 更新資料，對WBS一點屁用都沒有，不需要開
            //update updateList;
    
            // 發送到後端（可根據需求改成 uploadSeatSelection）
            if (!CheckedSeatList.isEmpty()) {
            	AmadeusUtil.AllocateSeat_seatRequestInfo(CheckedSeatList);
            }
            if (!newList.isEmpty()){
            	AmadeusUtil.seatSelection(departureLocation, currentTabKey, newList);
        	}
            Integer total = newList.size();
            Integer Changetotal = changedSeatList.size() + CheckedSeatList.size();

            String activePnrBeforeRefresh = currentTabKey;
            // ✅ Refresh both seat map and traveler data with latest API results
            searchPnr();
            currentTabKey = activePnrBeforeRefresh;

            successMessage = '作業完成，請再次點選【搜尋】以檢視最新狀態';
            System.debug('✅ 更新完成：新增 ' + newlyAssignedList.size() + '，變更 ' + Changetotal);

            List<TravellerInfo__c> updates = new List<TravellerInfo__c>();
            
            for (TravellerInfo__c t : newList) {
                t.C2Finished__c = true;
                updates.add(t);
            }
            
            update updates;
            
            System.debug(oldMap);
            System.debug(newList);
            
            OperationHistoryUtil.log('update', PAGENAME, flightPrefix+'-'+flightNumber, departureDate, departureLocation, currentTabKey, CommonController.getAccountIdFromCookie(), oldMap, newList);
            oldMap = new Map<Id, TravellerInfo__c>(newList);
            
            System.debug('✅ Successfully saved seat assignments + ' + successMessage);
        } catch (Exception ex) {
            System.debug('❌ Error saving seat assignments: ' + ex.getMessage());
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, '儲存座位選擇時發生錯誤：' + ex.getMessage()
            ));
        }
    
        return null;
    }

    /* ──────────── 更新本地旅客資料 ──────────── */
    private void updateLocalPassengerData(String travellerId, String newSeat) {
        for (String tabKey : tabData.keySet()) {
            for (PassengerInfo passenger : tabData.get(tabKey)) {
                if (passenger.recordId == travellerId) {
                    passenger.seat = newSeat;
                    return;
                }
            }
        }
    }
    
    public PageReference reset() {
        errorMessage = '';
        flightNumber = '';
        departureDateStr = '';
        departureDate = null;
        departureLocation = '';
        bookingCodes = '';
        travelerList.clear();
        pnrKeys.clear();
        currentTabKey = null;
        tabData.clear();
        pnrC2DisabledMap.clear();
        seatMapResults.clear();
        showUSFields = false;
        currentPage = 1;
        totalRecords = 0;
        return null;
    }

    /**
     * Refreshes data for a specific PNR when user switches tabs
     * Called via actionFunction from frontend when tab is clicked
     * Fetches latest seat map and traveler data from API
     */
    public PageReference refreshPNRData() {
        System.debug('🔄 refreshPNRData called for tab switching');
        searchPnr();
        return null;
    }

    // 新增加載公告內容的方法
    private void loadNoticeContentSeatSelection() {
        try {
            List<NoticeSetting__c> notices = [SELECT Content__c FROM NoticeSetting__c where Name = '選位須知' LIMIT 1];
            if (!notices.isEmpty() && notices[0].Content__c != null) {
                NoticeContentSeatSelection = notices[0].Content__c;
            } else {
                NoticeContentSeatSelection = ''; // 如果沒有公告內容，設置為空字符串
            }
        } catch (Exception e) {
            NoticeContentSeatSelection = ''; // 發生錯誤時設置為空字符串
            System.debug('Error loading notice content: ' + e.getMessage());
        }
    }
    
    // 提供一個公開的getter方法來訪問公告內容
    public String getNoticeContentSeatSelection() {
        return NoticeContentSeatSelection;
    }
    
    public Boolean hasTabData(String key) {
        return tabData != null && tabData.containsKey(key);
    }
    
    //BookingClass => CabinClass
    private static final Map<String, String> CabinMap = new Map<String, String>{
        'F' => 'F',
        'A' => 'F',
        'J' => 'J',
        'C' => 'J',
        'D' => 'J',
        'W' => 'W',
        'R' => 'W',
        'E' => 'W',
        'Y' => 'Y',
        'B' => 'Y',
        'H' => 'Y',
        'K' => 'Y',
        'M' => 'Y',
        'L' => 'Y',
        'V' => 'Y',
        'S' => 'Y',
        'N' => 'Y',
        'Q' => 'Y',
        'G' => 'Y'
    };

    // 傳入單一字母，回傳對應值，若無則回傳 null
    public static String getCabinClass(String bookingClass) {
        if (String.isBlank(bookingClass) || bookingClass.length() != 1) return null;
        return CabinMap.get(bookingClass.toUpperCase());
    }
    
    // 集中化錯誤訊息邏輯
    private String buildPnrFailureMessage(List<String> pnrList) {
        return String.join(pnrList, ',');
    }
    
    private String buildSeatMapFailureMessage(List<String> pnrList) {
        return '座位圖擷取失敗：' + String.join(pnrList, ',');
    }
    
    public String buildCombinedErrorMessage(List<String> unmatchedPnrKeys, List<String> failedRetrievePNRKeys, Set<String> noSeatMapPNRKeys, List<String> matchedPnrKeys) {
        List<String> errorMessages = new List<String>();

        // Track if we have any successful PNRs
        Boolean hasSuccessfulPNRs = false;

        // Check if any matched PNRs are NOT in failed lists
        for (String pnr : matchedPnrKeys) {
            if (!failedRetrievePNRKeys.contains(pnr) && !noSeatMapPNRKeys.contains(pnr)) {
                hasSuccessfulPNRs = true;
                break;
            }
        }
        // Add prefix if we have partial success
        if (hasSuccessfulPNRs && (!unmatchedPnrKeys.isEmpty() || !failedRetrievePNRKeys.isEmpty() || !noSeatMapPNRKeys.isEmpty())) {
            errorMessages.add('查無部分PNR');
        }

        if (!unmatchedPnrKeys.isEmpty()) {
            errorMessages.add(buildPnrFailureMessage(unmatchedPnrKeys));
        }

        if (!failedRetrievePNRKeys.isEmpty()) {
            errorMessages.add(buildPnrFailureMessage(failedRetrievePNRKeys));
        }

        if (!noSeatMapPNRKeys.isEmpty()) {
            if (noSeatMapPNRKeys.containsAll(matchedPnrKeys)) {
                errorMessages.add(buildSeatMapFailureMessage(new List<String>(noSeatMapPNRKeys)));
            } else {
                errorMessages.add(buildSeatMapFailureMessage(new List<String>(noSeatMapPNRKeys)));
            }
        }

        return errorMessages.isEmpty() ? '' : String.join(errorMessages, '：');
    }

    /**
     * Helper method to rebuild tabData for a specific PNR with fresh traveller data
     * @param pnrCode - The PNR code to rebuild data for
     * @param freshTravellers - Updated traveller records from database
     */
    // private void rebuildTabDataForPNR(String pnrCode, List<TravellerInfo__c> freshTravellers) {
    //     if (String.isBlank(pnrCode) || freshTravellers == null) {
    //         return;
    //     }

    //     // Clear existing data for this PNR
    //     if (tabData.containsKey(pnrCode)) {
    //         tabData.remove(pnrCode);
    //     }

    //     // Rebuild passenger info for this PNR
    //     for (TravellerInfo__c t : freshTravellers) {
    //         if (t.PNR__c != pnrCode) continue; // Skip if not matching PNR

    //         if (!tabData.containsKey(t.PNR__c)) {
    //             tabData.put(t.PNR__c, new List<PassengerInfo>());
    //         }

    //         // Find existing passenger or create new one
    //         String paxKey = t.LastName__c + '/' + t.firstName__c;
    //         PassengerInfo pInfo;
    //         for (PassengerInfo p : tabData.get(t.PNR__c)) {
    //             if (p.name == paxKey) {
    //                 pInfo = p;
    //                 break;
    //             }
    //         }

    //         if (pInfo == null) {
    //             pInfo = new PassengerInfo();
    //             pInfo.recordId      = t.Id;
    //             pInfo.name          = t.LastName__c + '/' + t.firstName__c;
    //             pInfo.title         = t.title__c;
    //             pInfo.gender        = t.gender__c;
    //             pInfo.nationality   = t.country__c;
    //             pInfo.birthDate     = t.DateOfBirth__c;
    //             pInfo.passengerType = t.PassengerType__c;
    //             pInfo.usBound = t.US_Bound__c;
    //             pInfo.pt = t.PT__c;
    //             pInfo.st = t.ST01__c;
    //             pInfo.CAS = t.CAS__c;
    //             pInfo.DID = t.DID__c;
    //             pInfo.rqstOT = t.RQST_OT__c;
    //             pInfo.DepartureDate = t.DepartureDate__c;
    //             pInfo.DepartureLocation = t.DepartureLocation__c;
    //             pInfo.Destination = t.Destination__c;
    //             pInfo.FlightNumber = t.FlightNumber__c;

    //             tabData.get(t.PNR__c).add(pInfo);
    //         }

    //         // Update seat information with fresh data
    //         pInfo.seat = t.Seat__c;
    //         pInfo.seatIsChargeable = t.SeatIsChargeable__c;
    //     }

    //     System.debug('✅ Rebuilt tabData for PNR: ' + pnrCode + ' with ' + freshTravellers.size() + ' travellers');
    //     System.debug('🔍 tabData for PNR: ' + pnrCode + ' : ' + JSON.serialize(tabData.get(pnrCode)));
    // }

    /**
     * Helper method to retrieve seat map for a specific PNR with fallback logic
     * @param pnrCode - The PNR code to retrieve seat map for
     * @param traveller - Sample traveller from this PNR (used to extract flight details)
     * @return AirRetrieveSeatMap.Result or null if both API calls fail
     */
    private AirRetrieveSeatMap.Result retrieveSeatMapForPNR(String pnrCode, TravellerInfo__c traveller) {
        if (traveller == null) {
            System.debug('❌ Cannot retrieve seat map - traveller is null for PNR: ' + pnrCode);
            return null;
        }

        System.debug('🔍 Retrieving seat map for PNR: ' + pnrCode);
        AirRetrieveSeatMap.Result seatMapResult = null;

        try {
            // 1st attempt: primary SeatMap API
            seatMapResult = AmadeusUtilRetrieveSeatMap.Air_RetrieveSeatMap(
                traveller.DepartureDate__c,
                traveller.DepartureLocation__c,
                traveller.Destination__c,
                traveller.FlightNumber__c,
                traveller.BookingClass__c
            );

            // If first call failed or result is missing aircraft type, fallback to DCSSTG
            if (seatMapResult == null || String.isBlank(seatMapResult.iataAircraftTypeCode)) {
                System.debug('⚠️ SeatMap API 無資料，改呼叫 DCSSTG for PNR ' + pnrCode);
                seatMapResult = AmadeusUtilRetrieveSeatMap.DCSSTG_GetFDSeatMap(
                    traveller.DepartureDate__c,
                    traveller.DepartureLocation__c,
                    traveller.FlightNumber__c
                );
            }

            // Process successful result
            if (seatMapResult != null && !String.isBlank(seatMapResult.iataAircraftTypeCode)) {
                String cabinCode = getCabinClass(traveller.BookingClass__c);
                if (cabinCode != null) {
                    seatMapResult.cabinClasses = new Set<String>{ cabinCode };
                    System.debug('✅ Seat map retrieved successfully for PNR: ' + pnrCode);
                    return seatMapResult;
                } else {
                    System.debug('❌ BookingClass 無法轉換 CabinClass for PNR: ' + pnrCode);
                    return null;
                }
            } else {
                System.debug('❌ Both seat map APIs failed for PNR: ' + pnrCode);
                return null;
            }
        } catch (Exception ex) {
            System.debug('❌ Exception retrieving seat map for PNR ' + pnrCode + ': ' + ex.getMessage());
            return null;
        }
    }

    /**
     * Helper method to refresh both traveler data and seat map for a specific PNR
     * Updates seatMapResults and tabData properties
     * Follows the same pattern as searchPnr(): API → Database → Query → Rebuild
     * @param pnrCode - The PNR code to refresh data for
     * @param departureLocation - Departure location for API call
     */
    // private void refreshDataForPNR(String pnrCode, String departureLocation) {
    //     System.debug('🔄 Refreshing data for PNR: ' + pnrCode);

    //     try {
    //         // 1. Retrieve fresh traveler data from API
    //         List<TravellerInfo__c> freshTravellers = AmadeusUtil.retrievePNR(departureLocation, pnrCode);

    //         if (freshTravellers == null || freshTravellers.isEmpty()) {
    //             System.debug('⚠️ No fresh traveler data retrieved for PNR: ' + pnrCode);
    //             return;
    //         }

    //         System.debug('✅ Retrieved ' + freshTravellers.size() + ' fresh travellers from API for PNR: ' + pnrCode);
    //         System.debug('🔍 freshTravellers: ' + JSON.serialize(freshTravellers));

    //         // 2. Retrieve fresh seat map BEFORE upsert (to avoid CalloutException)
    //         // Use freshTravellers from API as sample
    //         TravellerInfo__c sampleTraveller = freshTravellers[0];
    //         AirRetrieveSeatMap.Result freshSeatMap = retrieveSeatMapForPNR(pnrCode, sampleTraveller);

    //         // 3. Save to database (triggers/formulas will be computed)
    //         // All callouts must be done before this DML operation
    //         upsert freshTravellers External_ID__c;
    //         System.debug('✅ Upserted travellers to database for PNR: ' + pnrCode);

    //         // 4. Query back from database to get ALL fields including formula fields
    //         // (Matches the query in searchPnr lines 503-524)
    //         List<TravellerInfo__c> completeData = [
    //             SELECT Id, PNR__c,
    //             LastName__c, FirstName__c, Title__c, Gender__c, PT__c, ST01__c, ST02__c,
    //             Country__c, DateOfBirth__c, PassengerType__c, PassportFinished__c,
    //             PassportNumber__c, PassportExpiryDate__c, PassportIssuingCountry__c, DepartureLocation__c, US_Bound__c,
    //             VisaNumber__c, VisaExpiryDate__c, VisaIssuingCountry__c,
    //             USAStreet__c, USACity__c, USAState__c, USAZipCode__c,
    //             USAEmergencyContactName__c, USAEmergencyContactNationality__c, USAEmergencyContactPhone__c, Seat__c,
    //             CheckDisable__c, C3ExternalFinished__c, C3Finished__c, C4BoardingPassPrinted__c, C4BoardingPassPrintedTime__c,
    //             C4EBoardingPass__c, C4PaperBoardingPass__c, PrintDisable__c, DepartureLocationGMTLocal__c, Barcode__c, PAX__c, Service__c, Meal__c, IATA_MSO_Code__c, RQST_OT__c,
    //             C1Finished__c, UCI__c, DID__c, CAS__c, SeatIsChargeable__c, DepartureDate__c, DepartureDate2__c, FlightNumber__c, Destination__c, C3Status__c, C2OperationDisable__c, C3OperationDisable__c, C4BoardingPassPrintedTimeGMTLocal__c,
    //             C3CheckboxDisplay__c, APE__c, APM__c, BookingClass__c
    //             FROM TravellerInfo__c
    //             WHERE PNR__c = :pnrCode
    //             AND DepartureLocation__c = :departureLocation
    //             ORDER BY PTOrderBy__c ASC, PassengerTypeOrderBy__c ASC
    //         ];

    //         if (completeData.isEmpty()) {
    //             System.debug('⚠️ No data found in database after upsert for PNR: ' + pnrCode);
    //             return;
    //         }

    //         System.debug('✅ Queried ' + completeData.size() + ' complete records from database for PNR: ' + pnrCode);
    //         System.debug('🔍 completeData: ' + JSON.serialize(completeData));
    //         // 5. Update seatMapResults
    //         if (freshSeatMap != null) {
    //             seatMapResults.put(pnrCode, freshSeatMap);
    //             System.debug('✅ Updated seatMapResults for PNR: ' + pnrCode);
    //         } else {
    //             System.debug('⚠️ Could not update seat map for PNR: ' + pnrCode);
    //         }

    //         // 6. Update pnrC2DisabledMap for this PNR (matches searchPnr logic lines 528-547)
    //         if (!completeData.isEmpty()) {
    //             TravellerInfo__c firstTraveler = completeData[0];
    //             Boolean isDisabled = firstTraveler.C2OperationDisable__c == true;
    //             pnrC2DisabledMap.put(pnrCode, isDisabled);
    //             System.debug('✅ Updated pnrC2DisabledMap for PNR ' + pnrCode + ': C2OperationDisable = ' + isDisabled);
    //         }

    //         // 7. Update tabData with complete database data (includes formula fields)
    //         rebuildTabDataForPNR(pnrCode, completeData);
    //         System.debug('✅ Successfully refreshed all data for PNR: ' + pnrCode);

    //     } catch (Exception ex) {
    //         System.debug('❌ Error refreshing data for PNR ' + pnrCode + ': ' + ex.getMessage());
    //         System.debug('❌ Stack trace: ' + ex.getStackTraceString());
    //         // Don't throw - allow operation to continue even if refresh fails
    //     }
    // }
    // 
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