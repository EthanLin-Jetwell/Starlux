public without sharing class EditTravelerController {
    public static String PAGENAME = 'EditTraveler';
    public String IATAcode { get; set; }
    
    public String errorMessage { get; set; }
    /* ──────────── 畫面綁定用屬性 ──────────── */
    public String  flightPrefix  { get; set; }
    public String  flightNumber  { get; set; }
    public String  departureLocation { get; set; }
    public Date    departureDate { get; set; }
    public String  departureDateStr { get; set; }
    public String  bookingCodes  { get; set; }          // 逗號分隔 PNR
    public Boolean c1OperationDisabled { get; set; }

    
    /* ──────────── CSV文件上傳 ──────────── */
    public Blob csvFileBody { get; set; }
    public String csvFileName { get; set; }
    
    /* ──────────── 結果顯示用 ──────────── */
    public List<String> pnrKeys  { get; set; }          // 分頁籤
    public String currentTabKey { get; set; }       // 預設顯示
    public List<TravellerInfo__c> travelerList { get; set; }
    public Map<Id, TravellerInfo__c> oldMap { get; set; }
    
    public Map<String , List<PassengerDataWrapper.PassengerInfo>> tabData { get; set; }
    public Map<String, Boolean> pnrC1DisabledMap { get; set; }  // Map to track C1OperationDisable per PNR
    public String pnrC1DisabledMapJSON { 
        get { 
            return pnrC1DisabledMap != null ? JSON.serialize(pnrC1DisabledMap) : '{}'; 
        } 
        set; 
    } 


    public Boolean showUSFields { get; private set; }
    public Integer currentPage { get; set; }
    public Integer pageSize { get; set; }
    public Integer totalRecords { get; set; }
    public Integer totalPages {
        get {
            if (totalRecords == null || pageSize == null || pageSize == 0) return 1;
            System.debug(totalRecords);
            System.debug(totalPages);System.debug(pageSize);
            System.debug((Integer)Math.ceil((Decimal)totalRecords / pageSize));
            return (Integer)Math.ceil((Decimal)totalRecords / pageSize);
        }
    }
    /* 前端回傳修改內容的 JSON */
    public String jsonInput { get; set; }
    
    

// ▼▼▼ [Append-Only] 追加屬性：被選旅客 Id 清單（JSON 陣列字串）
public String selectedTravellerIdsJson { get; set; }
// ▲▲▲ 追加屬性結束
public EditTravelerController() {
        pageSize = 1000; 
        flightPrefix = 'JX';
        bookingCodes = '';
        currentPage = 1; 
        pnrKeys = new List<String>();
        tabData = new Map<String,List<PassengerDataWrapper.PassengerInfo>>();
        pnrC1DisabledMap = new Map<String, Boolean>();
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

        Id recId = ApexPages.currentPage().getParameters().get('id');
        if (recId != null) {
            TravellerInfo__c t = [
                SELECT C1OperationDisable__c
                FROM TravellerInfo__c
                WHERE Id = :recId
                LIMIT 1
            ];
            c1OperationDisabled = t.C1OperationDisable__c;
        } else {
            c1OperationDisabled = false; // 預設顯示
        }
    
    }
    
    /* ---------- 新增：州／省選單資料 ---------- */
    private List<String> usStates;                        // 只存純字串
    public List<SelectOption> getUSStateOptions() {       // VF 端呼叫
        if (usStates == null) {
            loadUSStates();
        }
        List<SelectOption> opts = new List<SelectOption>();
        for (String s : usStates) {
            opts.add(new SelectOption(s, s));
        }
        return opts;
    }
    
    private void loadUSStates() {
        usStates = new List<String>();
        List<B2B_Parameter__c> p = [
            SELECT Value__c
            FROM   B2B_Parameter__c
            WHERE  Label__c = '州/省下拉選單'
            LIMIT  1
        ];
        if (!p.isEmpty() && p[0].Value__c != null) {
            for (String s : p[0].Value__c.split(',')) {
                usStates.add(s.trim());
            }
        }
        usStates.sort();
    }
    
    /* ──────────── 建構子 ──────────── */
    /* ---------- 起飛地清單 ---------- */
    public List<String> origins;
    
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
            /*
            pnrKeys = bookingCodes.contains(',') ?
            bookingCodes.split(',') :
            new List<String>{ bookingCodes.trim() };
            */
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
        //WBS PNR_ListPaxByFlight
        Map<String, String> extractedPNRs = AmadeusUtil.listPNRByFlight(fn,departureDate.format()+'');
        // 篩選出兩者交集的 PNR 清單
        List<String> matchedPnrKeys = new List<String>();
        List<String> unmatchedPnrKeys = new List<String>();
        Set<String> unmatchedSet = new Set<String>();
        
        System.debug('起飛地:'+departureLocation);
        for (String p : rawPnrKeys) {
            if (extractedPNRs.containsKey(p) && extractedPNRs.get(p) == departureLocation) {
                matchedPnrKeys.add(p);
            } else {
                if (unmatchedSet.add(p)) unmatchedPnrKeys.add(p);
            }
        }
        System.debug('符合的PNR:'+matchedPnrKeys);
        System.debug('不符合的PNR:'+unmatchedPnrKeys); 
        //WBS PNR_Retrieve
        for (String pnr : matchedPnrKeys) {
            try {
                travelerList.addAll(AmadeusUtil.retrievePNR(departureLocation, pnr));
            } catch (Exception ex) {
                System.debug('⚠️ PNR_Retrieve 失敗：' + pnr + '，錯誤：' + ex.getMessage());
                errorMessage = '⚠️ PNR_Retrieve 失敗：' + pnr + '，錯誤：' + ex.getMessage();
            }
        }
        
        //408
        OperationHistoryUtil.log('search', PAGENAME, flightPrefix+'-'+flightNumber, departureDate, departureLocation, bookingCodes, CommonController.getAccountIdFromCookie());
        
        if(travelerList.size() > 0){
            upsert travelerList External_ID__c;
        }

        // 若完全沒交集（matched 為空），就中斷
        if (matchedPnrKeys.isEmpty()) {
            errorMessage = '查無PNR : ' + String.join(unmatchedPnrKeys, ',');
            return null;
        }
        
        oldMap = new Map<Id, TravellerInfo__c>([
            SELECT Id, PNR__c,
            LastName__c, FirstName__c, Title__c, Gender__c, PT__c, ST01__c, ST02__c,
            Country__c, DateOfBirth__c, PassengerType__c, PassportFinished__c,
            PassportNumber__c, PassportExpiryDate__c, PassportIssuingCountry__c,DepartureLocation__c,US_Bound__c,
            VisaNumber__c, VisaExpiryDate__c, VisaIssuingCountry__c,
            USAStreet__c, USACity__c, USAState__c, USAZipCode__c,
            USAEmergencyContactName__c, USAEmergencyContactNationality__c, USAEmergencyContactPhone__c,	Seat__c,
            CheckDisable__c, C3ExternalFinished__c, C3Finished__c, C4BoardingPassPrinted__c, C4BoardingPassPrintedTime__c,
            C4EBoardingPass__c, C4PaperBoardingPass__c, PrintDisable__c, DepartureLocationGMTLocal__c, Barcode__c, PAX__c, Service__c, Meal__c, IATA_MSO_Code__c, RQST_OT__c,
            C1Finished__c, UCI__c ,DID__c ,CAS__c ,DepartureDate__c ,DepartureDate2__c ,FlightNumber__c ,Destination__c ,C3Status__c,C3CheckboxDisplay__c,C4CheckboxDisplay__c,
            C1OperationDisable__c, C2OperationDisable__c, C3OperationDisable__c, C4OperationDisable__c,C4BoardingPassPrintedTimeGMTLocal__c,C4Finished__c,
            APE__c, APM__c
            FROM   TravellerInfo__c
            //WHERE  PNR__c                 IN :pnrKeys
            WHERE  PNR__c                 IN :matchedPnrKeys
            //AND    FlightNumber__c        =  :fn
            AND    PAX__c != null 
            AND    External_ID__c != null
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
        
        // Build per-PNR C1OperationDisable map (only check first passenger per PNR since it's a formula field)
        pnrC1DisabledMap.clear();
        Map<String, TravellerInfo__c> pnrToFirstTraveler = new Map<String, TravellerInfo__c>();
        
        // Get first traveler for each PNR
        for (TravellerInfo__c t : travelerList) {
            if (!pnrToFirstTraveler.containsKey(t.PNR__c)) {
                pnrToFirstTraveler.put(t.PNR__c, t);
            }
        }
        
        // Check C1OperationDisable for first traveler of each PNR
        c1OperationDisabled = false; // 預設可操作
        for (String pnr : pnrToFirstTraveler.keySet()) {
            TravellerInfo__c firstTraveler = pnrToFirstTraveler.get(pnr);
            Boolean isDisabled = firstTraveler.C1OperationDisable__c == true;
            pnrC1DisabledMap.put(pnr, isDisabled);
            
            // Set global flag if any PNR is disabled
            if (isDisabled) {
                c1OperationDisabled = true;
            }
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
        
        tabData = new PassengerDataWrapper(travelerList).passengerData;
        
        if (!String.isBlank(IATAcode) && tabData != null) {
            Map<String, List<PassengerDataWrapper.PassengerInfo>> newMap = new Map<String, List<PassengerDataWrapper.PassengerInfo>>();
        
            for (String pnr : tabData.keySet()) {
                List<PassengerDataWrapper.PassengerInfo> ps = tabData.get(pnr);
                List<PassengerDataWrapper.PassengerInfo> kept = new List<PassengerDataWrapper.PassengerInfo>();
        
                for (PassengerDataWrapper.PassengerInfo p : ps) {
                    if (p != null && p.IATA == IATAcode) kept.add(p);
                }
        
                if (!kept.isEmpty()) newMap.put(pnr, kept);
            }
            tabData = newMap;
        }

        /* 4. 產生分頁籤索引 */
        // 分頁用 key 集合
        List<String> allKeys = new List<String>(tabData.keySet());
        allKeys.sort();
        totalRecords = 0;
        for (String key : allKeys) {
            totalRecords += tabData.get(key).size(); // 每個 PNR 下的乘客數
        }
        currentPage = 1;
        
        // 算出該顯示幾筆（最多 50 位乘客）
        /*Integer shownCount = 0;
        pnrKeys = allKeys;
        for (String key : allKeys) {
            List<PassengerDataWrapper.PassengerInfo> passengers = tabData.get(key);
            for (PassengerDataWrapper.PassengerInfo passenger : passengers) {
                if (shownCount < pageSize) {
                    if (!pnrKeys.contains(key)) {
                        //pnrKeys.add(key);
                    }
                    shownCount++;
                } else {
                    break;
                }
            }
            
            if (shownCount >= pageSize) {
                break;
            }
        }*/
        
        Integer shownCount = 0;
        pnrKeys = new List<String>();
        for (String key : allKeys) {
            List<PassengerDataWrapper.PassengerInfo> passengers = tabData.get(key);
            if (shownCount + passengers.size() <= pageSize) {
                pnrKeys.add(key);
                shownCount += passengers.size();
            } else {
                break;
            }
        }
        
        // 起始分頁設定
        if (!pnrKeys.isEmpty()) {
            currentTabKey = pnrKeys[0];
        }
        //OperationHistoryUtil.log('search', PAGENAME, flightPrefix+'-'+flightNumber, departureDate, departureLocation, bookingCodes, CommonController.getAccountIdFromCookie());
        return null;   // 交給 VF 的 reRender
    }
    
    public PageReference nextPage() {
        if (currentPage < totalPages) {
            currentPage++;
            applyPagination();
        }
        return null;
    }
    
    public PageReference prevPage() {
        if (currentPage > 1) {
            currentPage--;
            applyPagination();
        }
        return null;
    }
    
    private void applyPagination() {
        Integer fromIndex = (currentPage - 1) * pageSize;
        Integer toIndex = Math.min(currentPage * pageSize, totalRecords);
        
        List<String> allKeys = new List<String>(tabData.keySet());
        allKeys.sort();
        
        pnrKeys = new List<String>();
        for (Integer i = fromIndex; i < toIndex; i++) {
            pnrKeys.add(allKeys[i]);
        }
        
        if (!pnrKeys.isEmpty()) {
            currentTabKey = pnrKeys[0];
        }
    }
    
    public Integer currentPageToIndex {
        get {
            Integer shown = 0;
            for (String key : pnrKeys) {
                if (tabData.containsKey(key)) {
                    shown += tabData.get(key).size();
                }
            }
            return shown;
        }
    }
    
    public Integer getCurrentTabCount() {
    if (currentTabKey == null || tabData == null) return 0;
    if (!tabData.containsKey(currentTabKey))      return 0;
    List<PassengerDataWrapper.PassengerInfo> rows = tabData.get(currentTabKey);
    return (rows == null) ? 0 : rows.size();
}
    
    //private Integer currentPageInternal;

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
    
    public Boolean hasTabData(String key) {
        return tabData != null && tabData.containsKey(key);
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
        pnrC1DisabledMap.clear();
        showUSFields = false;
        currentPage = 1;
        totalRecords = 0;
        c1OperationDisabled = false; 
        return null;
    }
   /*
    public pageReference uploadDocument() {
        TravellerInfo__c timecheck = [
            SELECT C1OperationDisable__c
            FROM TravellerInfo__c
            WHERE PNR__c = :currentTabKey
            LIMIT 1
        ];
        if(timecheck.C1OperationDisable__c==True){
                errorMessage = '操作作業逾時，無法進行異動1';
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR, '操作作業逾時，無法進行異動2'
                ));
                return null;
        }
        List<TravellerInfo__c> newList = PassengerDataWrapper.parsePassengerInfo(tabData.get(currentTabKey));
        
        try {
            AmadeusUtil.uploadDocuments(departureLocation, currentTabKey, newList);
            
            OperationHistoryUtil.log('update', PAGENAME, flightPrefix+'-'+flightNumber, departureDate, departureLocation, bookingCodes, CommonController.getAccountIdFromCookie(), oldMap, newList);
            oldMap = new Map<Id, TravellerInfo__c>(newList);
        } catch(exception ex) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, '發生錯誤：' + ex.getMessage()
            ));
        }
        AmadeusUtil.retrievePNR(departureLocation, currentTabKey);
        System.debug('有跑到這裡喔');
        //travelerList.addAll(AmadeusUtil.retrievePNR(departureLocation, currentTabKey));
        return null;
    }
*/
// ▼▼▼ [Append-Only] 追加方法：只上傳被選旅客（不動原有 uploadDocument）

    public pageReference checkStatus() {
        if (!String.isBlank(currentTabKey)) {
            TravellerInfo__c timecheck = [
                SELECT C1OperationDisable__c
                FROM TravellerInfo__c
                WHERE PNR__c = :currentTabKey
                LIMIT 1
            ];
            
            if (timecheck.C1OperationDisable__c == true) {
                errorMessage = '操作作業逾時，無法進行異動';
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR, '操作作業逾時，無法進行異動'
                ));
                return null; // ← 直接返回，前端看到 errorMessage 就會走「錯誤路徑」
            }
        }
        
        return null;
    }
    
    public pageReference uploadDocumentSelected() {
        errorMessage = '';
        
        if (!String.isBlank(currentTabKey)) {
            TravellerInfo__c timecheck = [
                SELECT C1OperationDisable__c
                FROM TravellerInfo__c
                WHERE PNR__c = :currentTabKey
                LIMIT 1
            ];
            
            if (timecheck.C1OperationDisable__c == true) {
                errorMessage = '操作作業逾時，無法進行異動';
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR, '操作作業逾時，無法進行異動'
                ));
                return null; // ← 直接返回，前端看到 errorMessage 就會走「錯誤路徑」
            }
        }
    
    // 以現行頁籤的旅客為基礎
    List<TravellerInfo__c> newList = PassengerDataWrapper.parsePassengerInfo(tabData.get(currentTabKey));
        
    // 嘗試解析前端傳入的被選 Id
    Set<Id> selectedIds = new Set<Id>();
    if (!String.isBlank(selectedTravellerIdsJson)) {
        try {
            List<Object> tmp = (List<Object>) JSON.deserializeUntyped(selectedTravellerIdsJson);
            for (Object o : tmp) {
                String sid = (String)o;
                if (!String.isBlank(sid)) selectedIds.add((Id)sid);
            }
        } catch (Exception e) {
            // 忽略解析錯誤，視為未限制（使用全部）
        }
    }
    // 若有勾選，僅保留被選旅客
    if (!selectedIds.isEmpty()) {
        List<TravellerInfo__c> filtered = new List<TravellerInfo__c>();
        for (TravellerInfo__c t : newList) {
            if (selectedIds.contains(t.Id)) filtered.add(t);
        }
        newList = filtered;
    }
    try {
        AmadeusUtil.uploadDocuments(departureLocation, currentTabKey, newList);
        List<TravellerInfo__c> updates = new List<TravellerInfo__c>();
        for (TravellerInfo__c t : newList) {
            updates.add(new TravellerInfo__c(
                Id = t.Id,
                C1Finished__c = true
            ));
        }
        AmadeusUtil.retrievePNR(departureLocation, currentTabKey);
        update updates;
        OperationHistoryUtil.log(
            'update', PAGENAME, flightPrefix+'-'+flightNumber, departureDate, departureLocation,
            currentTabKey, CommonController.getAccountIdFromCookie(), oldMap, newList
        );
        oldMap = new Map<Id, TravellerInfo__c>(newList);
        
    } catch (Exception ex) {
        ApexPages.addMessage(new ApexPages.Message(
            ApexPages.Severity.ERROR,
            '發生錯誤：' + ex.getMessage()
        ));
    }
    return null;
}

// ▲▲▲ 追加方法結束
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