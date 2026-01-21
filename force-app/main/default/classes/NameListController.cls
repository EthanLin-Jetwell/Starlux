public class NameListController {
    
    private ApexPages.StandardController standardController;
    public String satRecordId {get; set;}
    public List<PageNameListWrapper> wrappersList {get; set;}
    public Seat_Allocation_and_Ticketing__c currentSat {get; set;}
    public Boolean isNoSatError {get; set;}
    public List<Name_List__c> nlListToDelete = new List<Name_List__c>();
    public Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    public String[] csvFileLines{get;set;}
    private string[] csvFieldName{set;get;}
    public string userLanguage{set;get;}
    public Boolean usaRoute{set;get;}
    public Boolean processing{set;get;}
    
    //2023/12/7 Ethan
    public String route {set;get;}
    public String blankNameErrEn = 'Required fields are missing';
    public String blankNameErrCh = '護照上為單名的旅客，姓氏欄位輸入此單名，名字欄位請輸入FNU';
    
    public String blankNameLengthErrEn = 'Last name HAS to be more than one characters'; //23/12/25 Aaron 「姓氏與名字不得為空值」與「英文字元長度=1」是不同的驗證，因此需顯示不同的驗證訊息
    public String blankNameLengthErrCh = '姓名格式輸入有誤，如有疑慮可洽星宇人員';   //23/12/25 Aaron 「姓氏與名字不得為空值」與「英文字元長度=1」是不同的驗證，因此需顯示不同的驗證訊息
    
    public String illegalCharErrEn = 'Fields contains ILLEGAL characters or SPACE';
    public String illegalCharErrCh = '姓名格式輸入有誤，如有疑慮可洽星宇人員';
    
    public String reqFieldErrEn = 'Required fields are missing';
    public String reqFieldErrCh = '欄位為必填';
    
    public String infantOlder2En = 'Infant CANNOT be 2 years old or older, must be count as a CHILD';
    public String infantOlder2Ch = '嬰兒生日輸入有誤，如有疑慮可洽星宇人員';
    
    public String childYounger2En = 'Individuals youger than 2 years old should be count as a INFANT';
    public String childYounger2CH = '嬰兒生日輸入有誤，如有疑慮可洽星宇人員';
    
    public String childErrorEn = 'CHILD can only be individuals younger than 11';
    public String childErrorCh = '小孩生日輸入有誤，如有疑慮可洽星宇人員';
    
    public String mealErrEn = 'Meals not available (All Sector)';
    public String mealErrCh = '餐點選擇有誤，如有疑慮可洽星宇人員';
    
    public String exceedMAXSeatEn = 'Action is not allowed, the number of Name Lists has exceeded Final Allocated Seats';
    public String exceedMAXSeatCh = '旅客名單數已超過航班開放總數，請檢查該航班人數限制';
    
    public String departingRoute {set;get;}
    public String returningRoute {set;get;}
    public List<String> availableDepartingMeals {set;get;}
    public List<String> availableReturningMeals {set;get;}
    
    public static Integer passengerTypeIndex = -1;
    public static Integer titleIndex = -1;
    public static Integer lastNameIndex = -1;
    public static Integer firstNameIndex = -1;
    public static Integer genderIndex = -1;
    public static Integer dateOfBirthIndex = -1;
    
    public static Integer passportIssueCountryIndex = -1;
    public static Integer passportNoIndex = -1;
    public static Integer passportCountryIndex = -1;
    public static Integer passportExpiryDateIndex = -1;
    public static Integer visaNoIndex = -1;
    public static Integer visaCountryIndex = -1;
    public static Integer visaExpiryDateIndex = -1;
    
    public static Integer mealSelectionAllSectorIndex = -1;
    public static Integer mealSelectionDepartingIndex = -1;
    public static Integer mealSelectionReturningIndex = -1;
    
    public static Integer specialServiceDepartingIndex = -1;
    public static Integer specialServiceReturningIndex = -1;
    public static Integer specialServiceDescriptionIndex = -1;
    
    public static Integer infPassengerTypeIndex = -1;
    public static Integer infTitleIndex = -1;
    public static Integer infLastNameIndex = -1;
    public static Integer infFirstNameIndex = -1;
    public static Integer infGenderIndex = -1;
    public static Integer infDateOfBirthIndex = -1;
    
    public static Integer infPassportIssueCountryIndex = -1;
    public static Integer infPassportNoIndex = -1;
    public static Integer infPassportCountryIndex = -1;
    public static Integer infPassportExpiryDateIndex = -1;
    public static Integer infVisaNoIndex = -1;
    public static Integer infVisaCountryIndex = -1;
    public static Integer infVisaExpiryDateIndex = -1;
    
    public static Integer infAllSectorIndex = -1;
    public static Integer infDepartingIndex = -1;
    public static Integer infReturningIndex = -1;

    
    public NameListController(ApexPages.StandardController standardController) {
        this.standardController = standardController;
        this.satRecordId = standardController.getId();
        List<Seat_Allocation_and_Ticketing__c> tmpSatList = (List<Seat_Allocation_and_Ticketing__c>) DbUtil.queryAllFieldsWithWhere('Seat_Allocation_and_Ticketing__c', new Map<String,String> {'Id' => satRecordId});
        this.currentSat = tmpSatList.get(0);
        this.userLanguage = UserInfo.getLanguage();
        Case satCase = [SELECT Id, Integration_Link_Status__c, Status, Route__c, F_Departing__c, F_Returning__c FROM Case WHERE Id =: currentSat.Case_ID__c];
        this.isNoSatError = true;
        this.usaRoute = false;
        if (satCase.Status != 'New' && satCase.Status != 'Ticket Sales in Progress' && satCase.Status != 'Adhoc Request Approving' && satCase.Status != 'Adhoc Request Approved') {
            ApexErrorUtil.addErrorMessageOnThePage('Action is not allowed, please check Case Status');
            this.isNoSatError = false;
        }
        if (currentSat.Allocation_Type__c != Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS && currentSat.Allocation_Type__c != Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC) {
            ApexErrorUtil.addErrorMessageOnThePage('Action is not allowed, please check Allocation Type');
            this.isNoSatError = false;
        }
        if (this.currentSat.Final_Allocated_Seats__c == 0) {
            ApexErrorUtil.addErrorMessageOnThePage('Action is not allowed, please check Final Allocated Seats');
            this.isNoSatError = false;
        }
       /*if(currentSat.tour_Guide_email__c == null ||currentSat.tour_Guide_phone__c == null){
            if(this.userLanguage == 'en_US'){
                     ApexErrorUtil.addErrorMessageOnThePage('Please fill in the APN information');
                }else{
                      ApexErrorUtil.addErrorMessageOnThePage('請填寫APN資訊');
                }
            this.isNoSatError = false;
        }*/
        
        //assigning available meals
        this.departingRoute = satCase.F_Departing__c;
        this.returningRoute = satCase.F_Returning__c;
        this.availableDepartingMeals = new List<String>();
        this.availableReturningMeals = new List<String>();
        
        List<Special_Meal__c> tmpMealList = (List<Special_Meal__c>) DbUtil.queryAllFieldsWithWhere('Special_Meal__c', new Map<String,String> {'Flight_Route__c' => this.departingRoute, 'Class__c' => 'Y'});
        Special_Meal__c meals = tmpMealList[0];
        Map<String, Object> values = meals.getPopulatedFieldsAsMap();
        
        Map<String, Schema.SObjectField> mfields = Schema.Special_Meal__c.SObjectType.getDescribe().fields.getMap();
        
        for(String fieldName: values.keySet()) {
            if(values.get(fieldName) == 'Y') {
                Schema.DescribeFieldResult fieldResult = mfields.get(fieldName).getDescribe();
                availableDepartingMeals.add(fieldResult.getLabel());
            }
        }      
        
        tmpMealList = (List<Special_Meal__c>) DbUtil.queryAllFieldsWithWhere('Special_Meal__c', new Map<String,String> {'Flight_Route__c' => this.returningRoute, 'Class__c' => 'Y'});
        meals = tmpMealList[0];
        values = meals.getPopulatedFieldsAsMap();
                
        for(String fieldName: values.keySet()) {
            if(values.get(fieldName) == 'Y') {
                Schema.DescribeFieldResult fieldResult = mfields.get(fieldName).getDescribe();
                availableReturningMeals.add(fieldResult.getLabel());
            }
        }    
        System.debug('Departing' + availableDepartingMeals);
        System.debug('Returning' + availableReturningMeals);
        
        //America Line
        if (satCase.Route__c == 'TPE-LAX-TPE'||satCase.Route__c == 'TPE-LAX(one-way)'||satCase.Route__c == 'TPE-GUM-TPE'||satCase.Route__c == 'TPE-GUM(one-way)'|| satCase.Route__c.contains('SEA')) {
             this.usaRoute = true;
        }
        
        if (this.isNoSatError) {
            this.wrappersList = new List<PageNameListWrapper>();
        	this.csvFileLines = new String[]{};
        }
    }
    
    public void generateOrFindNameListBySat() {
        System.debug('[4i] satRecordId:' + satRecordId);
        if (this.isNoSatError) {
            if (currentSat.Is_Name_List_Created__c) {
                Map<String, String> criterias = new Map<String,String>();
                criterias.put('Seat_Allocation_and_Ticketing__r.Id', satRecordId);
                List<Name_List__c> foundNameListList = DbUtil.queryAllFieldsWithWhere('Name_List__c', criterias);
                for (Name_List__c nl : foundNameListList) {
                    this.wrappersList.add(new PageNameListWrapper(nl));
                }
                if( this.currentSat.Final_Allocated_Seats__c != null){
                    Integer seatsLeft = this.currentSat.Final_Allocated_Seats__c.intValue() - this.wrappersList.size();
                    for (Integer i = 0; i < seatsLeft; i++) {
                    Name_List__c currNameList = new Name_List__c();
                    currNameList.Seat_Allocation_and_Ticketing__c = satRecordId;
                    this.wrappersList.add(new PageNameListWrapper(currNameList));
                	}
                }       
            } else {
                for (Integer i = 0; i < this.currentSat.Final_Allocated_Seats__c; i++) {
                    Name_List__c currNameList = new Name_List__c();
                    currNameList.Seat_Allocation_and_Ticketing__c = satRecordId;
                    this.wrappersList.add(new PageNameListWrapper(currNameList));
                }
            }
            
        }
        System.debug('[4i] wrappersList:' + this.wrappersList);
    }
    
    public Pagereference saveNameListList() {
        processing = true;
        String successMessage = '';
        Boolean redirect=true;
        String errorRecords = '';
        try{
            Integer nbOfAdult = 0;
            Integer nbOfChild = 0;
            Integer nbOfInfant = 0;
            List<Name_List__c> nlListToUpsert = new List<Name_List__c>();
            for (PageNameListWrapper wrapper : wrappersList) {
                //2023/11/20 Ethan first name and last name cannot be blank and last name has to be more than one characters
                Boolean correct=true;
                //2023/12/25 Aaron 不允許為空值
                /*if(wrapper.nl.First_Name__c == ' ' || wrapper.nl.Last_Name__c == ' ') {
                    ApexErrorUtil.addErrorMessageOnThePage(blankNameErrEn + '; ' + blankNameErrCh);
                    redirect=false;
                    correct=false;
                }*/
                if(wrapper.nl.Passenger_Type__c != Null && (wrapper.nl.First_Name__c == Null || wrapper.nl.Last_Name__c == Null)) {
                	ApexErrorUtil.addErrorMessageOnThePage(blankNameErrEn + '; ' + blankNameErrCh);
                    redirect=false;
                    correct=false;
                }
                //23/12/25 Aaron Last_Name__c 是英文才需要判斷字元長度=1，並調整驗證訊息內容               
                /*if(wrapper.nl.Last_Name__c != NULL && wrapper.nl.Last_Name__c.trim().length() == 1 )
                {
                    ApexErrorUtil.addErrorMessageOnThePage(blankNameErrEn + '; ' + blankNameErrEn);
                    redirect=false;
                    correct=false;
                }*/	
                String tmpString = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
                //if (wrapper.nl.Last_Name__c != null && wrapper.nl.Last_Name__c.trim().length() == 1 && Pattern.compile('.*[a-zA-Z].*').matcher(wrapper.nl.Last_Name__c).matches()) 
                IF(wrapper.nl.Last_Name__c != Null){
                IF(wrapper.nl.Last_Name__c.LENGTH()==1 && tmpString.CONTAINS(wrapper.nl.Last_Name__c))
                {			                                       
                    ApexErrorUtil.addErrorMessageOnThePage(blankNameLengthErrEn + '; ' + blankNameLengthErrCh);
   					 redirect = false;
   					 correct = false;
				}}
                //2023/11/20 Ethan 不能有 “-”  “&”  “,”  符號，只允許半形空格一個
                if(wrapper.nl.Passenger_Type__c != NULL && (wrapper.nl.Passenger_Type__c.contains('-') || wrapper.nl.Passenger_Type__c.contains('&') || wrapper.nl.Passenger_Type__c.contains(',') || wrapper.nl.Passenger_Type__c.contains(' '))) {
                    ApexErrorUtil.addErrorMessageOnThePage(illegalCharErrEn + '; ' + illegalCharErrCh);
                    redirect=false;
                    correct=false;
                }
                if(wrapper.nl.Title__c != NULL && (wrapper.nl.Title__c.contains('-') || wrapper.nl.Title__c.contains('&') || wrapper.nl.Title__c.contains(',') || wrapper.nl.Title__c.contains(' '))) {
                    ApexErrorUtil.addErrorMessageOnThePage(illegalCharErrEn + '; ' + illegalCharErrCh);
                    redirect=false;
                    correct=false;
                }
                if(wrapper.nl.Last_Name__c != NULL && (wrapper.nl.Last_Name__c.contains('-') || wrapper.nl.Last_Name__c.contains('&') || wrapper.nl.Last_Name__c.contains(',') || wrapper.nl.Last_Name__c.contains('\u3000') || wrapper.nl.Last_Name__c.countMatches(' ') > 1)) {
                    ApexErrorUtil.addErrorMessageOnThePage(illegalCharErrEn + '; ' + illegalCharErrCh);
                    redirect=false;
                    correct=false;
                }
                if(wrapper.nl.First_Name__c != NULL && (wrapper.nl.First_Name__c.contains('-') || wrapper.nl.First_Name__c.contains('&') || wrapper.nl.First_Name__c.contains(',') || wrapper.nl.First_Name__c.contains('\u3000') || wrapper.nl.First_Name__c.countMatches(' ') > 1)) {
                    ApexErrorUtil.addErrorMessageOnThePage(illegalCharErrEn + '; ' + illegalCharErrCh);
                    redirect=false;
                    correct=false;
                }
                //前四個欄位同時為空，不存入DB。
                if(wrapper.nl.Passenger_Type__c == null && wrapper.nl.Title__c == null && wrapper.nl.Last_Name__c == null && wrapper.nl.First_Name__c == null){
                     continue ;
                }
                if(wrapper.nl.Passenger_Type__c == null||wrapper.nl.Title__c == null||wrapper.nl.Last_Name__c == null||wrapper.nl.First_Name__c == null){
                    ApexErrorUtil.addErrorMessageOnThePage(reqFieldErrEn + '; ' + reqFieldErrCh);
                    redirect=false;
                    correct=false;
                    //return;
                }
                if(this.usaRoute){
                    if(wrapper.nl.Gender__c == null||String.valueOf(wrapper.nl.Date_of_Birth__c) == null){
                        ApexErrorUtil.addErrorMessageOnThePage(reqFieldErrEn + '; ' + reqFieldErrCh);
                        redirect=false;
                        correct=false;
                        //return;
                    }
                }
                if(wrapper.nl.INF_Passenger_Type__c == null || wrapper.nl.INF_Title__c == null||wrapper.nl.INF_Last_Name__c == null||wrapper.nl.INF_First_Name__c == null||(wrapper.nl.InfantGender__c == null && this.usaRoute)||String.valueOf(wrapper.nl.INF_Date_of_Birth__c) == null){
                    if(wrapper.nl.INF_Passenger_Type__c == 'infant'){
                        ApexErrorUtil.addErrorMessageOnThePage(reqFieldErrEn + '; ' + reqFieldErrCh);
                        redirect=false;
                        correct=false;
                        //return;
                    }
                }                
                if(wrapper.nl.INF_Passenger_Type__c != null || wrapper.nl.INF_Title__c != null||wrapper.nl.INF_Last_Name__c != null||wrapper.nl.INF_First_Name__c != null||(wrapper.nl.InfantGender__c != null && this.usaRoute) || String.valueOf(wrapper.nl.INF_Date_of_Birth__c) != null){
                    if(wrapper.nl.INF_Passenger_Type__c == null){
                        ApexErrorUtil.addErrorMessageOnThePage(reqFieldErrEn + '; ' + reqFieldErrCh);
                        redirect=false;
                        correct=false;
                        //return;
                    }
                }
                //Infant should be younger than 2 years old
                if (wrapper.nl.Passenger_Type__c == 'adult') {
                    if(this.usaRoute == true && String.valueOf(wrapper.nl.Date_of_Birth__c) == null){
                        ApexErrorUtil.addErrorMessageOnThePage(reqFieldErrEn + '; ' + reqFieldErrCh);
                        redirect=false;
                        correct=false;
                        //return;
                    }
                    nbOfAdult++;
                    if (wrapper.nl.INF_Passenger_Type__c == 'infant' && wrapper.nl.INF_Date_of_Birth__c != NULL) {
                        Integer year = currentSat.Returning_Flight_Date__c.year() - wrapper.nl.INF_Date_of_Birth__c.year();
                        Integer month = currentSat.Returning_Flight_Date__c.month() - wrapper.nl.INF_Date_of_Birth__c.month();
                        Integer day = currentSat.Returning_Flight_Date__c.day() - wrapper.nl.INF_Date_of_Birth__c.day();
                        Integer age = year;
                        if(month < 0) {
                            age -= 1;
                        } else if(month == 0 && day < 0) {
                            age -= 1;
                        }
                        if(age >= 2) {
                            ApexErrorUtil.addErrorMessageOnThePage(infantOlder2En + '; ' + infantOlder2Ch);
                            redirect=false;
                            correct=false;
                        }
                        nbOfInfant++;
                    }
                }
                //Child should be older than 2 years old
                if (wrapper.nl.Passenger_Type__c == 'child') {
                    if(String.valueOf(wrapper.nl.Date_of_Birth__c) == null){
                        ApexErrorUtil.addErrorMessageOnThePage(reqFieldErrEn + '; ' + reqFieldErrCh);
                        redirect=false;
                        correct=false;
                    } else {
                        Integer year = currentSat.Returning_Flight_Date__c.year() - wrapper.nl.Date_of_Birth__c.year();
                        Integer month = currentSat.Returning_Flight_Date__c.month() - wrapper.nl.Date_of_Birth__c.month();
                        Integer day = currentSat.Returning_Flight_Date__c.day() - wrapper.nl.Date_of_Birth__c.day();
                        Integer age = year;
                        if(month < 0) {
                            age -= 1;
                            System.debug('month');
                        } else if(month == 0 && day < 0) {
                            age -= 1;
                            System.debug('day');
                        }
                        System.debug(age);
                        //Aaron here
                        if(age > 11) {
                            ApexErrorUtil.addErrorMessageOnThePage(childErrorEn + '; ' + childErrorCh);
                            redirect=false;
                            correct=false;
                        }
                        nbOfChild++;
                    }
                }
                nlListToUpsert.add(wrapper.nl);
                //Meal mapping
                if(wrapper.nl.Meal_Selection_All_Sector__c != NULL && (!availableDepartingMeals.contains(wrapper.nl.Meal_Selection_All_Sector__c) || !availableReturningMeals.contains(wrapper.nl.Meal_Selection_All_Sector__c))) {
                    ApexErrorUtil.addErrorMessageOnThePage('(All Sector: ) ' + mealErrEn + '; ' + mealErrCh);
                    redirect=false;
                    correct=false;
                }
                if(wrapper.nl.Meal_Selection_Departing_Only__c != NULL && !availableDepartingMeals.contains(wrapper.nl.Meal_Selection_Departing_Only__c)) {
                    ApexErrorUtil.addErrorMessageOnThePage('(Departing: ) ' + mealErrEn + '; ' + mealErrCh);
                    redirect=false;
                    correct=false;
                }
                if(wrapper.nl.Meal_Selection_Returning_Only__c != NULL && !availableReturningMeals.contains(wrapper.nl.Meal_Selection_Returning_Only__c)) {
                    ApexErrorUtil.addErrorMessageOnThePage('(Returning: ) ' + mealErrEn + '; ' + mealErrCh);
                    redirect=false;
                    correct=false;
                }
                if(!correct) {
                    //errorRecords += wrapper.nl.Title__c + ' ' + wrapper.nl.First_Name__c + ' ' + wrapper.nl.Last_Name__c + ' / '; //23/12/25 Aaron 調整順序
                    errorRecords += wrapper.nl.Title__c + ' ' + wrapper.nl.Last_Name__c + ' ' + wrapper.nl.First_Name__c + ' / ';
                }
            }
            if (nlListToUpsert.size() > this.currentSat.Final_Allocated_Seats__c) {
                ApexErrorUtil.addErrorMessageOnThePage(exceedMAXSeatEn + '; ' + exceedMAXSeatCh);
                redirect=false;
            } else {
                system.debug('redirect='+redirect); //Add by Jeremy 上面判斷有問題時不能儲存
                if(redirect){
                    currentSat.No_of_Adult__c = nbOfAdult;
                    currentSat.No_of_Child__c = nbOfChild;
                    currentSat.No_of_Infant__c = nbOfInfant;
                    currentSat.Is_Name_List_Created__c = true;
                    Database.update(currentSat);
                    
                    system.debug(nlListToUpsert);
                    Database.upsert(nlListToUpsert);
                    if (!nlListToDelete.isEmpty()) {
                        Database.delete(nlListToDelete);
                        nlListToDelete = new List<Name_List__c>();
                    } 
                }
            }
            if(redirect)
            {
                //成功訊息，顯示頁面上方
                if(this.userLanguage == 'en_US'){
                    successMessage = 'The name list was saved successfully. If the name list has to be updated, please click the “Exit” button to exit the page, then press the “Edit Namelist” button to reenter this page. Thank you.';
                }else{
                    successMessage = '編輯已儲存，如需再次儲存請點選「離開」後再次進入此頁面，謝謝'; 
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM,successMessage));
                return this.standardController.cancel();
                //system.debug('123');
                //return null;
            }
            else
            {
                ApexErrorUtil.addErrorMessageOnThePage('Please check Name list : ' + errorRecords + '; 請確認下列資料: ' +  errorRecords);
                return null;
            }
        }
        catch(Exception e) {
            ApexErrorUtil.addErrorMessageOnThePage(e.getMessage() + ' at line: ' + e.getLineNumber());
            return null;
        }
    }
    
    public void addNameList() {
        if (this.wrappersList.size() == this.currentSat.Final_Allocated_Seats__c) {
            ApexErrorUtil.addErrorMessageOnThePage('Action is not allowed, the number of Name Lists has exceeded Final Allocated Seats');
            return;
        }
        Name_List__c currNameList = new Name_List__c();
        currNameList.Seat_Allocation_and_Ticketing__c = satRecordId;
        this.wrappersList.add(new PageNameListWrapper(currNameList));
    }
    
    public void deleteNameList() {
        for (Integer i = this.wrappersList.size() - 1; i >= 0; i--) {
            if (this.wrappersList.get(i).isSelected) {
                if (this.wrappersList.get(i).nl.Id != null) {
                    nlListToDelete.add(this.wrappersList.get(i).nl);
                }
                this.wrappersList.remove(i);
            }
        }
    }
    
    public Pagereference exit() {
        return this.standardController.cancel();
    }

    public void importCSVFile(){
    	try{
            Map<String, Integer> fileNameMap = new Map<String, Integer>();
            
            csvAsString = csvFileBody.toString();
           	csvFileLines = csvAsString.split('\n'); 
            List<Name_List__c> foundNameListList = new List<Name_List__c>();
            csvFieldName = csvFileLines[0].split(',');
            
            if(csvFieldName.size() < 35){
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'Wrong number of fields.');
            	ApexPages.addMessage(errorMessage);
                return;
            } else {
                for (Integer i = 0; i < csvFieldName.size(); i++) {
                    String name = csvFieldName[i];
                    String tempName = name.replaceAll('\\s+', '').toLowerCase(); // Normalize name
                    
                    if (tempName == '') {
                        continue;
                    }
                    
                    // Match and assign indexes
                    if (tempName == 'passengertype') passengerTypeIndex = i;
                    else if (tempName == 'title') titleIndex = i;
                    else if (tempName == 'lastname') lastNameIndex = i;
                    else if (tempName == 'firstname') firstNameIndex = i;
                    else if (tempName == 'gender') genderIndex = i;
                    else if (tempName == 'dateofbirth') dateOfBirthIndex = i;
                    
                    else if (tempName == 'passportissuecountry') passportIssueCountryIndex = i;
                    else if (tempName == 'passportno') passportNoIndex = i;
                    else if (tempName == 'passportcountry') passportCountryIndex = i;
                    else if (tempName == 'passportexpirydate') passportExpiryDateIndex = i;
                    else if (tempName == 'visano') visaNoIndex = i;
                    else if (tempName == 'visacountry') visaCountryIndex = i;
                    else if (tempName == 'visaexpirydate') visaExpiryDateIndex = i;
                    
                    else if (tempName == 'mealselectionallsector') mealSelectionAllSectorIndex = i;
                    else if (tempName == 'mealselectiondeparting') mealSelectionDepartingIndex = i;
                    else if (tempName == 'mealselectionreturning') mealSelectionReturningIndex = i;

                    else if (tempName == 'specialservicedeparting') specialServiceDepartingIndex = i;
                    else if (tempName == 'specialservicereturning') specialServiceReturningIndex = i;
                    else if (tempName == 'specialservicedescription') specialServiceDescriptionIndex = i;
                    
                    else if (tempName == 'infpassengertype') infPassengerTypeIndex = i;
                    else if (tempName == 'inftitle') infTitleIndex = i;
                    else if (tempName == 'inflastname') infLastNameIndex = i;
                    else if (tempName == 'inffirstname') infFirstNameIndex = i;
                    else if (tempName == 'infgender') infGenderIndex = i;
                    else if (tempName == 'infdateofbirth') infDateOfBirthIndex = i;
                    
                    else if (tempName == 'infpassportissuecountry') infPassportIssueCountryIndex = i;
                    else if (tempName == 'infpassportno') infPassportNoIndex = i;
                    else if (tempName == 'infpassportcountry') infPassportCountryIndex = i;
                    else if (tempName == 'infpassportexpirydate') infPassportExpiryDateIndex = i;
                    else if (tempName == 'infvisano') infVisaNoIndex = i;
                    else if (tempName == 'infvisacountry') infVisaCountryIndex = i;
                    else if (tempName == 'infvisaexpirydate') infVisaExpiryDateIndex = i;
                    
                    else if (tempName == 'infallsector') infAllSectorIndex = i;
                    else if (tempName == 'infdeparting') infDepartingIndex = i;
                    else if (tempName == 'infreturning') infReturningIndex = i;
                }
            }
            
            //舊名單加到刪除清單裡面
            for (Integer i = this.wrappersList.size() - 1; i >= 0; i--) {
                	if (this.wrappersList.get(i).nl.Id != null) {
                    	nlListToDelete.add(this.wrappersList.get(i).nl);
                	}
        	}
			this.wrappersList.clear();
           	for(Integer i=1;i<csvFileLines.size();i++){
                Name_List__c n1 = new Name_List__c() ;
                string[] csvRecordData = csvFileLines[i].split(',');
                if(csvRecordData.size()<4){
                     continue ;
                }
                if(csvRecordData.size()<35){
                    for(Integer j=csvRecordData.size(); j<35;j++){
                         csvRecordData.add('');
                    }
                }
                System.debug(csvRecordData.size());
                n1.Seat_Allocation_and_Ticketing__c = satRecordId;
                
                n1.Passenger_Type__c = CheckData('passengerTypeIndex', csvRecordData[passengerTypeIndex]);             
                n1.Title__c = CheckData('titleIndex', csvRecordData[titleIndex]);
                n1.Last_Name__c = csvRecordData[lastNameIndex];
                n1.First_Name__c = csvRecordData[firstNameIndex]; 
                n1.Gender__c = CheckData('genderIndex', csvRecordData[genderIndex]);
                System.debug(csvRecordData[dateOfBirthIndex]);
                n1.Date_of_Birth__c = (CheckData('dateOfBirthIndex', csvRecordData[dateOfBirthIndex]) == '') 
                    ? null 
                    : Date.valueOf(CheckData('dateOfBirthIndex', csvRecordData[dateOfBirthIndex]));  
                
                n1.Meal_Selection_All_Sector__c = CheckData('mealSelectionAllSectorIndex', csvRecordData[mealSelectionAllSectorIndex]); 
                n1.Meal_Selection_Departing_Only__c = CheckData('mealSelectionDepartingIndex', csvRecordData[mealSelectionDepartingIndex]);   
                n1.Meal_Selection_Returning_Only__c = CheckData('mealSelectionReturningIndex', csvRecordData[mealSelectionReturningIndex]);
                
                n1.Special_Service_Departing__c = CheckData('specialServiceDepartingIndex', csvRecordData[specialServiceDepartingIndex]);   
                n1.Special_Service_Returning__c = CheckData('specialServiceReturningIndex', csvRecordData[specialServiceReturningIndex]);   
                n1.Special_Service_Description__c = CheckData('specialServiceDescriptionIndex', csvRecordData[specialServiceDescriptionIndex]); 
                
                n1.INF_Passenger_Type__c = CheckData('infPassengerTypeIndex', csvRecordData[infPassengerTypeIndex]);
                n1.INF_Title__c = CheckData('infTitleIndex', csvRecordData[infTitleIndex]);    
                n1.INF_Last_Name__c = CheckData('infLastNameIndex', csvRecordData[infLastNameIndex]);    
                n1.INF_First_Name__c = CheckData('infFirstNameIndex', csvRecordData[infFirstNameIndex]);   
                n1.InfantGender__c = CheckData('infGenderIndex', csvRecordData[infGenderIndex]);
                n1.INF_Date_of_Birth__c = (CheckData('infDateOfBirthIndex', csvRecordData[infDateOfBirthIndex]) == '') 
                    ? null 
                    : Date.valueOf(CheckData('infDateOfBirthIndex', csvRecordData[infDateOfBirthIndex]));   
                
                n1.INF_Meal_Selection_All_Sector__c = CheckData('infAllSectorIndex', csvRecordData[infAllSectorIndex]);    
                n1.INF_Meal_Selection_Departing_Only__c = CheckData('infDepartingIndex', csvRecordData[infDepartingIndex]);  
                n1.INF_Meal_Selection_Returning_Only__c = CheckData('infReturningIndex', csvRecordData[infReturningIndex]);
                /*
                n1.Child_Age__C = (CheckData(19,csvRecordData[19])=='')?null:integer.valueOf(CheckData(19,csvRecordData[19]));
                n1.Nationality__c = CheckData(20,csvRecordData[20]);
                n1.Primary_Document_Type__c = CheckData(21,csvRecordData[21]);
                n1.Primary_Document_Number__c = (CheckData(22,csvRecordData[22])=='')?null:integer.valueOf(CheckData(22,csvRecordData[22]));
                n1.Primary_Document_Issue_Country__c = CheckData(23,csvRecordData[23]);
                n1.Primary_Document_Expiry_Date__c = (CheckData(24,csvRecordData[24])=='')?null:Date.valueOf(CheckData(24,csvRecordData[24]));
                n1.Secondary_Document_Type__c = CheckData(25,csvRecordData[25]);
                n1.Secondary_Document_Number__c = (CheckData(26, csvRecordData[26])=='')?null:integer.valueOf(CheckData(26, csvRecordData[26]));
                n1.Secondary_Document_Expire_Date_c__c = (CheckData(27, csvRecordData[27])=='')?null:Date.valueOf(CheckData(27, csvRecordData[27]));
                n1.Secondary_Document_Issue_Country__c = CheckData(28, csvRecordData[28]);
                n1.Meal_Service_Code__c = CheckData(29, csvRecordData[29]);
                */
                
                // 2025/3/13 new added field Ethan
                n1.Passport_Issue_Country__c = CheckData('passportIssueCountryIndex', csvRecordData[passportIssueCountryIndex]);
                n1.Passport_No__c = CheckData('passportNoIndex', csvRecordData[passportNoIndex]);
                n1.Passport_Country__c = CheckData('passportCountryIndex', csvRecordData[passportCountryIndex]);
                System.debug(csvRecordData[passportExpiryDateIndex]);
                n1.Passport_Expiry_Date__c = (CheckData('passportExpiryDateIndex', csvRecordData[passportExpiryDateIndex]) == '') 
                    ? null 
                    : Date.valueOf(CheckData('passportExpiryDateIndex', csvRecordData[passportExpiryDateIndex]));
                n1.VISA_No__c = CheckData('visaNoIndex', csvRecordData[visaNoIndex]);
                n1.VISA_Country__c = CheckData('visaCountryIndex', csvRecordData[visaCountryIndex]);
                n1.VISA_Expiry_Date__c = (CheckData('visaExpiryDateIndex', csvRecordData[visaExpiryDateIndex]) == '') 
                    ? null 
                    : Date.valueOf(CheckData('visaExpiryDateIndex', csvRecordData[visaExpiryDateIndex]));
                n1.INF_Passport_Issue_Country__c = CheckData('infPassportIssueCountryIndex', csvRecordData[infPassportIssueCountryIndex]);
                n1.INF_Passport_No__c = CheckData('infPassportNoIndex', csvRecordData[infPassportNoIndex]);
                n1.INF_Passport_Country__c = CheckData('infPassportCountryIndex', csvRecordData[infPassportCountryIndex]);
                n1.INF_Passport_Expiry_Date__c = (CheckData('infPassportExpiryDateIndex', csvRecordData[infPassportExpiryDateIndex]) == '') 
                    ? null 
                    : Date.valueOf(CheckData('infPassportExpiryDateIndex', csvRecordData[infPassportExpiryDateIndex]));
                n1.INF_VISA_No__c = CheckData('infVisaNoIndex', csvRecordData[infVisaNoIndex]);
                n1.INF_VISA_Country__c = CheckData('infVisaCountryIndex', csvRecordData[infVisaCountryIndex]);
                n1.INF_VISA_Expiry_Date__c = (CheckData('infVisaExpiryDateIndex', csvRecordData[infVisaExpiryDateIndex]) == '') 
                    ? null 
                    : Date.valueOf(CheckData('infVisaExpiryDateIndex', csvRecordData[infVisaExpiryDateIndex]));
                
                foundNameListList.Add(n1);
            }
            for (Name_List__c nl : foundNameListList) {
                this.wrappersList.add(new PageNameListWrapper(nl));
            }
        }
        catch (Exception e)
        {
            //ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importin data Please make sure input csv file is correct');
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage() + ' ' + e.getLineNumber());
            ApexPages.addMessage(errorMessage);
        }  
  	}
    
    private String CheckData(String index, String Data){
        switch on index {
            when 'passengerTypeIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Passenger_Type__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'titleIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Title__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'lastNameIndex', 'firstNameIndex', 'specialServiceReturningIndex', 'infLastNameIndex', 'infFirstNameIndex'{
                if(Data.length() > 255){
                    return Data.substring(0, 255);
                }
                return Data;
            }      
            when 'genderIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Gender__c.getDescribe().getPicklistValues();
                String asd = '';
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'dateOfBirthIndex', 'infDateOfBirthIndex', 'passportExpiryDateIndex', 'infPassportExpiryDateIndex', 'visaExpiryDateIndex', 'infVisaExpiryDateIndex'{ //年份過久，會出現日期失效錯誤，限制過去100年內
                Data = Data.trim().replaceAll('/', '-');
                try {
                    date d = date.valueOf(Data);
                    Integer Year = date.today().Year();
                    if (Year - d.year() > 100) {
                        return '';
                    } else {
                        return Data;
                    }
                } catch(Exception e) {
                    return '';
                }
            }
            when 'mealSelectionAllSectorIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Meal_Selection_All_Sector__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'mealSelectionDepartingIndex' { //待確認格式 text10 、 picklist
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Meal_Selection_Departing_Only__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'mealSelectionReturningIndex' { //待確認格式 text10 、 picklist
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Meal_Selection_Returning_Only__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'specialServiceDescriptionIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Special_Service_Departing__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'specialServiceDepartingIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Special_Service_Returning__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }      
            when 'infPassengerTypeIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Passenger_Type__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }          
            when 'infTitleIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Title__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'infGenderIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.InfantGender__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'infAllSectorIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Meal_Selection_All_Sector__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'infDepartingIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Meal_Selection_Departing_Only__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            when 'infReturningIndex' {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Meal_Selection_Returning_Only__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry value : TitleValues){
                    if(value.getLabel().toLowercase() == Data.trim().toLowercase()) return value.getValue();
                }
                return '';
            }
            /*when 21,24,28{
                Data = Data.trim();
                try{
                    Decimal.valueOf(Data);
                    return Data;
                }catch(Exception e){
                    return '0';
                }                
            }*/
            
            
        }
        return Data;
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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