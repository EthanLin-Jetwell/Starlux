public without sharing class BPPController {
    public static String PAGENAME = 'BoardingPassPrinting';
    
    public String errorMessage { get; set; }
    public Boolean showActionButtons { get; set; }//c4 show登機證
    public String selectedEmail { get; set; }
    public String noticeContent { get; set; }  // 新增用於存儲公告內容的屬性
    public UserManagement__c currentAccount { get; set; }
    
    /* ──────────── 畫面綁定用屬性 ──────────── */
    public String  flightPrefix  { get; set; }
    public String  flightNumber  { get; set; }
    public String  departureLocation { get; set; }
    public Date    departureDate { get; set; }
    public String  departureDateStr { get; set; }
    public String  bookingCodes  { get; set; }          // 逗號分隔 PNR
    public Boolean c4OperationDisabled { get; set; }
    public Datetime C4BoardingPassPrintedTimeGMTLocal;
    

    
    /* ──────────── CSV文件上傳 ──────────── */
    public Blob csvFileBody { get; set; }
    public String csvFileName { get; set; }
    
    /* ──────────── 結果顯示用 ──────────── */
    public List<String> pnrKeys  { get; set; }          // 分頁籤
    public String currentTabKey { get; set; }       // 預設顯示
    public List<TravellerInfo__c> travelerList { get; set; }
    public Map<Id, TravellerInfo__c> oldMap { get; set; }
    
    public Map<String , List<PassengerDataWrapper.PassengerInfo>> tabData { get; set; }
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
    //for email
    public static Map<String, String>  destinationMap;
    public static Map<String, Integer>  groupCountMap;
    
    /* 前端回傳修改內容的 JSON */
    public String jsonInput { get; set; }
    
    public BPPController() {
        pageSize = 50; 
        flightPrefix = 'JX';
        bookingCodes = '';
        currentPage = 1; 
        pnrKeys = new List<String>();
        tabData = new Map<String,List<PassengerDataWrapper.PassengerInfo>>();
        travelerList = new List<TravellerInfo__c>();
        Id recId = ApexPages.currentPage().getParameters().get('id');
        if (recId != null) {
            TravellerInfo__c t = [
                SELECT C4OperationDisable__c
                FROM TravellerInfo__c
                WHERE Id = :recId
                LIMIT 1
            ];
            c4OperationDisabled = t.C4OperationDisable__c;
        } else {
            c4OperationDisabled = false; // 預設顯示
        }
        
        currentAccount = [SELECT Id, Company__c FROM UserManagement__c WHERE Id = :CommonController.getAccountIdFromCookie()];
        
        loadnoticeContent();
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
        System.debug('起飛地:'+departureLocation);
        for (String p : rawPnrKeys) {
            if (extractedPNRs.containsKey(p) && extractedPNRs.get(p) == departureLocation) {
                matchedPnrKeys.add(p);
            } else {
                unmatchedPnrKeys.add(p);
            }
        }
        System.debug('符合的PNR:'+matchedPnrKeys);
        System.debug('不符合的PNR:'+unmatchedPnrKeys); 
        //WBS PNR_Retrieve
        for (String pnr : matchedPnrKeys) {
            try {
                travelerList.addAll(AmadeusUtil.retrievePNRC4(departureLocation, pnr));
            } catch (Exception ex) {
                System.debug('⚠️ PNR_Retrieve 失敗：' + pnr + '，錯誤：' + ex.getMessage());
                errorMessage = '⚠️ PNR_Retrieve 失敗：' + pnr + '，錯誤：' + ex.getMessage();
            }
        }
        if(travelerList.size() > 0){
            upsert travelerList External_ID__c;
        }
        // 若 unmatched 有內容，顯示錯誤訊息，但不中斷流程
        if (!unmatchedPnrKeys.isEmpty()) {
            //error toast
            /*
String missingMsg = '查無PNR : ' + String.join(unmatchedPnrKeys, ',');

ApexPages.addMessage(
new ApexPages.Message(ApexPages.Severity.ERROR, missingMsg)
);
ApexPages.currentPage().getHeaders().put('pnr-missing', missingMsg);
*/
            errorMessage = '查無部分PNR : ' + String.join(unmatchedPnrKeys, ',');
        }
        // 若完全沒交集（matched 為空），就中斷
        if (matchedPnrKeys.isEmpty()) {
            //error toast
            /*
String missingMsg = '查無PNR : ' + String.join(unmatchedPnrKeys, ',');
ApexPages.addMessage(
new ApexPages.Message(ApexPages.Severity.ERROR, missingMsg)
);
ApexPages.currentPage().getHeaders().put('pnr-missing', missingMsg);
*/
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
            CheckDisable__c, C3ExternalFinished__c, C3Finished__c, C4BoardingPassPrinted__c, C4BoardingPassPrintedTime__c,C4BoardingPassPrintedTimeGMTLocal__c,
            C4EBoardingPass__c, C4PaperBoardingPass__c, PrintDisable__c, DepartureLocationGMTLocal__c, Barcode__c, PAX__c, Service__c, Meal__c, IATA_MSO_Code__c, RQST_OT__c,
            C1Finished__c, UCI__c ,DID__c ,CAS__c ,DepartureDate__c ,DepartureDate2__c ,FlightNumber__c ,Destination__c ,C3Status__c,C4Finished__c,C3CheckboxDisplay__c, C4CheckboxDisplay__c,
            C1OperationDisable__c, C2OperationDisable__c, C3OperationDisable__c, C4OperationDisable__c, APE__c, APM__c, group_code__c
            FROM   TravellerInfo__c
            //WHERE  PNR__c                 IN :pnrKeys
            WHERE  PNR__c                 IN :matchedPnrKeys
            //AND    FlightNumber__c        =  :fn
            AND    DepartureLocation__c=  :departureLocation
            //AND    DepartureLocationGMTLocal__c >= :startOfDay
            //AND    DepartureLocationGMTLocal__c <= :endOfDay
            ORDER  BY PTOrderBy__c ASC,
            PassengerTypeOrderBy__c ASC
        ]);
        showActionButtons = true;
        
        travelerList = oldMap.values();
        
        c4OperationDisabled = false; // 預設可操作
        for (TravellerInfo__c t : travelerList) {
            if (t.C4OperationDisable__c) {
                c4OperationDisabled = true;
                break; // 有一筆是 true 就可以停了
            }
        }
        
        System.debug('目前時間：' + DateTime.now());
            
        for (TravellerInfo__c t : travelerList) {
            System.debug('PNR 出發時間：' + t.DepartureLocationGMTLocal__c);
            
            if (t.DepartureLocationGMTLocal__c != null &&
                t.DepartureLocationGMTLocal__c < DateTime.now()) {
                    System.debug('✋ 這筆已過期，不顯示 checkbox');
                    //showActionButtons = false;  2025/08/18 Aaron 不知道這組是拿來幹嘛用的
                    break;
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
        
        destinationMap = new Map<String, String>();
        groupCountMap = new Map<String, Integer>();
        for (TravellerInfo__c t : travelerList) {
            if(!destinationMap.containsKey(t.pnr__c)) {
                destinationMap.put(t.pnr__c, t.Destination__c);
            }
            if(groupCountMap.containsKey(t.pnr__c)) {
                groupCountMap.put(t.pnr__c, groupCountMap.get(t.pnr__c)+1);
            } else {
                groupCountMap.put(t.pnr__c, 1);
            }
            
            if (t.US_Bound__c) {
                showUSFields = true;
                break;
            }
        }
        
        /* 3. 轉成 Map<PNR , List<PassengerInfo>> 結構 */
        tabData.clear();
        
        tabData = new PassengerDataWrapper(travelerList).passengerData;
        
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
            for (PassengerDataWrapper.PassengerInfo p : passengers) {
                System.debug('🔍 tabData[' + key + '] → Passenger Seat: ' + p.Seat);
            }
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
        
        OperationHistoryUtil.log('search', PAGENAME, flightPrefix+'-'+flightNumber, departureDate, departureLocation, bookingCodes, CommonController.getAccountIdFromCookie());
        return null;   // 交給 VF 的 reRender
    }
    
    
    public PageReference searchXML() {
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
        System.debug('起飛地:'+departureLocation);
        for (String p : rawPnrKeys) {
            if (extractedPNRs.containsKey(p) && extractedPNRs.get(p) == departureLocation) {
                matchedPnrKeys.add(p);
            } else {
                unmatchedPnrKeys.add(p);
            }
        }
        System.debug('符合的PNR:'+matchedPnrKeys);
        System.debug('不符合的PNR:'+unmatchedPnrKeys); 

        // 若 unmatched 有內容，顯示錯誤訊息，但不中斷流程
        if (!unmatchedPnrKeys.isEmpty()) {
            //error toast
            /*
String missingMsg = '查無PNR : ' + String.join(unmatchedPnrKeys, ',');

ApexPages.addMessage(
new ApexPages.Message(ApexPages.Severity.ERROR, missingMsg)
);
ApexPages.currentPage().getHeaders().put('pnr-missing', missingMsg);
*/
            errorMessage = '查無部分PNR : ' + String.join(unmatchedPnrKeys, ',');
        }
        // 若完全沒交集（matched 為空），就中斷
        if (matchedPnrKeys.isEmpty()) {
            //error toast
            /*
String missingMsg = '查無PNR : ' + String.join(unmatchedPnrKeys, ',');
ApexPages.addMessage(
new ApexPages.Message(ApexPages.Severity.ERROR, missingMsg)
);
ApexPages.currentPage().getHeaders().put('pnr-missing', missingMsg);
*/
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
            CheckDisable__c, C3ExternalFinished__c, C3Finished__c, C4BoardingPassPrinted__c, C4BoardingPassPrintedTime__c,C4BoardingPassPrintedTimeGMTLocal__c,
            C4EBoardingPass__c, C4PaperBoardingPass__c, PrintDisable__c, DepartureLocationGMTLocal__c, Barcode__c, PAX__c, Service__c, Meal__c, IATA_MSO_Code__c, RQST_OT__c,
            C1Finished__c, UCI__c ,DID__c ,CAS__c ,DepartureDate__c ,DepartureDate2__c ,FlightNumber__c ,Destination__c ,C3Status__c,C4Finished__c,C3CheckboxDisplay__c, C4CheckboxDisplay__c,
            C1OperationDisable__c, C2OperationDisable__c, C3OperationDisable__c, C4OperationDisable__c, APE__c, APM__c, group_code__c, group_code_check__c, External_ID__c
            FROM   TravellerInfo__c
            //WHERE  PNR__c                 IN :pnrKeys
            WHERE  PNR__c                 IN :matchedPnrKeys
            //AND    FlightNumber__c        =  :fn
            AND    DepartureLocation__c=  :departureLocation
            //AND    DepartureLocationGMTLocal__c >= :startOfDay
            //AND    DepartureLocationGMTLocal__c <= :endOfDay
            ORDER  BY PTOrderBy__c ASC,
            PassengerTypeOrderBy__c ASC
        ]);
        showActionButtons = true;
        
        travelerList = oldMap.values();
        
        c4OperationDisabled = false; // 預設可操作
        for (TravellerInfo__c t : travelerList) {
            if (t.C4OperationDisable__c) {
                c4OperationDisabled = true;
                break; // 有一筆是 true 就可以停了
            }
        }
        
        System.debug('目前時間：' + DateTime.now());
            
        for (TravellerInfo__c t : travelerList) {
            System.debug('PNR 出發時間：' + t.DepartureLocationGMTLocal__c);
            
            if (t.DepartureLocationGMTLocal__c != null &&
                t.DepartureLocationGMTLocal__c < DateTime.now()) {
                    System.debug('✋ 這筆已過期，不顯示 checkbox');
                    //showActionButtons = false;  2025/08/18 Aaron 不知道這組是拿來幹嘛用的
                    break;
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
        
        destinationMap = new Map<String, String>();
        groupCountMap = new Map<String, Integer>();
        for (TravellerInfo__c t : travelerList) {
            if(!destinationMap.containsKey(t.pnr__c)) {
                destinationMap.put(t.pnr__c, t.Destination__c);
            }
            if(groupCountMap.containsKey(t.pnr__c)) {
                groupCountMap.put(t.pnr__c, groupCountMap.get(t.pnr__c)+1);
            } else {
                groupCountMap.put(t.pnr__c, 1);
            }
            
            if (t.US_Bound__c) {
                showUSFields = true;
                break;
            }
        }
        
        /* 3. 轉成 Map<PNR , List<PassengerInfo>> 結構 */
        tabData.clear();
        
        tabData = new PassengerDataWrapper(travelerList).passengerData;
        
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
            for (PassengerDataWrapper.PassengerInfo p : passengers) {
                System.debug('🔍 tabData[' + key + '] → Passenger Seat: ' + p.Seat);
            }
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
            
        // 1) 取回兩邊資料
        List<TravellerInfo__c> fromDb  = oldMap.values();
        List<TravellerInfo__c> fromApi = new List<TravellerInfo__c>();
        for (String pnr : matchedPnrKeys) {
            try { fromApi.addAll(AmadeusUtil.retrievePNRC4(departureLocation, pnr)); }
            catch (Exception ex) { /* errorMessage 處理... */ }
        }
        
        // 2) 以 API 為主，僅把 DB 的 group_code_check__c merge 進來
        Map<String, TravellerInfo__c> byKey = new Map<String, TravellerInfo__c>();
        
        // 2.1 API 當 base
        for (TravellerInfo__c tApi : fromApi) {
            if (tApi == null || String.isBlank(tApi.External_ID__c)) continue;
            byKey.put(tApi.External_ID__c, tApi.clone(false, true, false, false));
        }
        
        // 2.2 蓋回 DB 的欄位（只這一欄 + 帶回 Id）  ⬅️ 重要補強：帶回 Id
        for (TravellerInfo__c tDb : fromDb) {
            if (tDb == null || String.isBlank(tDb.External_ID__c)) continue;
            if (!byKey.containsKey(tDb.External_ID__c)) continue; // API 為主：API 沒有就不納入
            TravellerInfo__c base = byKey.get(tDb.External_ID__c);
            if (tDb.Id != null) base.Id = tDb.Id;                // 帶回 Id，避免誤插入
            base.group_code_check__c = tDb.group_code_check__c;   // DB 有值就維持；多數情況是 null
        }
        
        travelerList = byKey.values();  // 合併後（API 欄位 + DB 的 group_code_check__c）
        
        // 3) 依條件決定是否呼叫 Comment API（僅對目前仍為 null 的）
        List<TravellerInfo__c> CHECK_PPT = new List<TravellerInfo__c>();
        for (TravellerInfo__c t : travelerList) {
            if (t.group_code__c != 'OK' && t.CAS__c == 'CAC' && t.group_code_check__c == null) {
                t.group_code_check__c = 'added High Priority'; // 若是 checkbox/number，改 true/1
                CHECK_PPT.add(t);
            }
        }
        /*
        if (!CHECK_PPT.isEmpty()) {
            AmadeusUtil.DCSCPR_EditCPR_Add_NextComment(CHECK_PPT); // callout
        }*/
        
        // 4) 全部 upsert 回去（API 欄位 + 更新後的 group_code_check__c 一起落庫）
        if (!travelerList.isEmpty()) {
            Database.upsert(travelerList, TravellerInfo__c.External_ID__c, false);
        }


        
        OperationHistoryUtil.log('search', PAGENAME, flightPrefix+'-'+flightNumber, departureDate, departureLocation, bookingCodes, CommonController.getAccountIdFromCookie());
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
        showUSFields = false;
        currentPage = 1;
        totalRecords = 0;
        return null;
    }
    
    public Map<Id, List<String>> emailMap { get; set; }
    
    public List<UserManagement__c> getTourLeaders() {
        List<UserManagement__c> result = [
            SELECT Id, CN_Passport__c, EN_Passport__c, Email__c, Email1__c, Email2__c, Email3__c, Email4__c, Email5__c, Phone1__c
            FROM UserManagement__c
            WHERE Company__c = :currentAccount.Company__c
            AND State__c = '已開通'
            ORDER BY CN_Passport__c
        ];
        
        emailMap = new Map<Id, List<String>>();
        
        System.debug('✅ tourLeaders found: ' + result.size());
        for (UserManagement__c u : result) {
            List<String> emails = new List<String>();
            if(String.isNotBlank(u.Email__c)) emails.add(u.Email__c);
            if(String.isNotBlank(u.Email1__c)) emails.add(u.Email1__c);
            if(String.isNotBlank(u.Email2__c)) emails.add(u.Email2__c);
            if(String.isNotBlank(u.Email3__c)) emails.add(u.Email3__c);
            if(String.isNotBlank(u.Email4__c)) emails.add(u.Email4__c);
            if(String.isNotBlank(u.Email5__c)) emails.add(u.Email5__c);
            
            emailMap.put(u.Id, emails);
        }
        
        return result;
    }
    
    public List<SelectOption> getEmailOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '請選擇')); // 預設空白選項
        
        for (UserManagement__c tl : getTourLeaders()) {
            if (!String.isBlank(tl.Email__c)) {
                String label = tl.CN_Passport__c;
                if (!String.isBlank(tl.EN_Passport__c)) {
                    label += ' / ' + tl.EN_Passport__c;
                }
                label += ' - ' + tl.Email__c;
                
                options.add(new SelectOption(tl.Email__c, label));
            }
        }
        
        return options;
    }
    
    // 新增加載公告內容的方法
    private void loadnoticeContent() {
        try {
            List<NoticeSetting__c> notices = [SELECT Content__c FROM NoticeSetting__c where Name = '登機證告知' LIMIT 1];
            if (!notices.isEmpty() && notices[0].Content__c != null) {
                noticeContent = notices[0].Content__c;
            } else {
                noticeContent = ''; // 如果沒有公告內容，設置為空字符串
            }
        } catch (Exception e) {
            noticeContent = ''; // 發生錯誤時設置為空字符串
            System.debug('Error loading notice content: ' + e.getMessage());
        }
    }
    
    // 提供一個公開的getter方法來訪問公告內容
    public String getnoticeContent() {
        return noticeContent;
    }
    
    @RemoteAction
    public static void handleDownload(String email, String flightNo, String dep, String flightDate, String pnr, List<String> digitalIds, List<String> paperIds, Id userManagementId) {
        OperationHistoryUtil.log('export', PAGENAME, flightNo, Date.valueOf(flightDate), dep, pnr, userManagementId, digitalIds, paperIds);
    }
    
    @RemoteAction
    public static void handleSendEmail(String email, String flightNo, String dep, String flightDate, String pnr, List<String> digitalIds, List<String> paperIds, Id userManagementId) {

        System.debug(email);
        System.debug(digitalIds);
        System.debug(pnr);
        System.debug(flightDate);
        
        Set<String> allUniqueIds = new Set<String>();
        if (digitalIds != null) allUniqueIds.addAll(digitalIds);
        if (paperIds != null) allUniqueIds.addAll(paperIds);
        List<String> allIdsList = new List<String>(allUniqueIds);
        System.debug(groupCountMap);
        
        Integer successCount = allIdsList.size();
        
        //Get destination
        List<TravellerInfo__c> totalGroup = [SELECT Id, Destination__c, C4Finished__c, C4BoardingPassPrintedTime__c FROM TravellerInfo__c WHERE PNR__c = :pnr];
        Integer groupCount = totalGroup.size();
        String des = totalGroup[0]?.Destination__c;
        
        InfobipUtility.BoardingPassStats stats = new InfobipUtility.BoardingPassStats(
            flightNo, dep, des, flightDate, pnr, groupCount, successCount, groupCount - successCount, digitalIds, paperIds
        );
        InfobipUtility.sendBoardingPassEmail(email, userManagementId, stats);
        
        List<TravellerInfo__c> updateList = new List<TravellerInfo__c>();
        for (TravellerInfo__c passenger : totalGroup) {
            if (digitalIds.contains(passenger.Id) || paperIds.contains(passenger.Id)) {
                passenger.C4Finished__c = true;
                passenger.C4BoardingPassPrintedTime__c = System.now();
                updateList.add(passenger);
            }
        }
        
        update updateList;
        
        OperationHistoryUtil.log('send', 'BoardingPassPrinting', flightNo, Date.valueOf(flightDate), dep, pnr, userManagementId, digitalIds, paperIds);
    }
}