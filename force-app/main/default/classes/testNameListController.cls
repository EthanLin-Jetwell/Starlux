public class testNameListController {
    
	public Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    public String[] csvFileLines{get;set;}
    public List<PageNameListWrapper> wrappersList{get;set;}
    private string[] csvFieldName{set;get;}
    public Seat_Allocation_and_Ticketing__c currentSat {get; set;}
    public List<Name_List__c> nlListToDelete = new List<Name_List__c>();
    public testNameListController(){
        csvFileLines = new String[]{};
        wrappersList = New List<PageNameListWrapper>(); 
    }
    
    public void saveNameListList() {
        Integer nbOfAdult = 0;
        Integer nbOfChild = 0;
        Integer nbOfInfant = 0;
        List<Name_List__c> nlListToUpsert = new List<Name_List__c>();
        for (PageNameListWrapper wrapper : wrappersList) {
            if (wrapper.nl.Passenger_Type__c == 'adult') {
                nbOfAdult++;
                if (wrapper.nl.INF_Passenger_Type__c == 'infant') {
                    nbOfInfant++;
                }
            }
            if (wrapper.nl.Passenger_Type__c == 'child') {
                nbOfChild++;
            }
            nlListToUpsert.add(wrapper.nl);
        }
        if (nlListToUpsert.size() > this.currentSat.Final_Allocated_Seats__c) {
            ApexErrorUtil.addErrorMessageOnThePage('Action is not allowed, the number of Name Lists has exceeded Final Allocated Seats');
        } else {
            try {
                Database.upsert(nlListToUpsert);
                if (!nlListToDelete.isEmpty()) {
                    Database.delete(nlListToDelete);
                    nlListToDelete = new List<Name_List__c>();
                } 
                currentSat.No_of_Adult__c = nbOfAdult;
                currentSat.No_of_Child__c = nbOfChild;
                currentSat.No_of_Infant__c = nbOfInfant;
                currentSat.Is_Name_List_Created__c = true;
                Database.update(currentSat);
            }
            catch(Exception e) {
                ApexErrorUtil.addErrorMessageOnThePage(e.getMessage());
            }
        }
    }
    public void importCSVFile(){
    	try{
           	csvAsString = csvFileBody.toString();
           	csvFileLines = csvAsString.split('\n'); 
            List<Name_List__c> foundNameListList = new List<Name_List__c>();
            csvFieldName = csvFileLines[0].split(',');
            /*
            if(csvFieldName.size() < 30){
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'Wrong number of fields.');
            	ApexPages.addMessage(errorMessage);
                return;
            }
			*/
           	for(Integer i=1;i<csvFileLines.size();i++){
                Name_List__c n1 = new Name_List__c() ;
                string[] csvRecordData = csvFileLines[i].split(',');
                n1.Passenger_Type__c = CheckData(0,csvRecordData[0]);             
                n1.Title__c = CheckData(1,csvRecordData[1]);
                n1.Last_Name__c = csvRecordData[2];
                n1.First_Name__c = csvRecordData[3];   
                n1.Date_of_Birth__c = Date.valueOf(CheckData(4,csvRecordData[4]));  
                n1.Meal_Selection_All_Sector__c = CheckData(5,csvRecordData[5]); 
                n1.Meal_Selection_Departing_Only__c = CheckData(6,csvRecordData[6]);   
                n1.Meal_Selection_Returning_Only__c = CheckData(7,csvRecordData[7]);   
                n1.Special_Service_Departing__c = CheckData(8,csvRecordData[8]);   
                n1.Special_Service_Returning__c = CheckData(9,csvRecordData[9]);   
                n1.Special_Service_Description__c = CheckData(10,csvRecordData[10]);
                n1.INF_Passenger_Type__c = CheckData(11,csvRecordData[11]);
                n1.INF_Title__c = CheckData(12,csvRecordData[12]);    
                n1.INF_Last_Name__c = CheckData(13,csvRecordData[13]);    
                n1.INF_First_Name__c = CheckData(14,csvRecordData[14]);    
                n1.INF_Date_of_Birth__c = Date.valueOf(CheckData(15,csvRecordData[15]));   
                n1.INF_Meal_Selection_All_Sector__c =  CheckData(16,csvRecordData[16]);    
                n1.INF_Meal_Selection_Departing_Only__c =  CheckData(17,csvRecordData[17]);  
                n1.INF_Meal_Selection_Returning_Only__c =  CheckData(18,csvRecordData[18]); 
                n1.Child_Age__C = decimal.valueOf(CheckData(19,csvRecordData[19]));
                n1.Nationality__c = CheckData(20,csvRecordData[20]);
                n1.Primary_Document_Type__c = CheckData(21,csvRecordData[21]);
                n1.Primary_Document_Number__c = decimal.valueOf(CheckData(22,csvRecordData[22]));
                n1.Primary_Document_Issue_Country__c = CheckData(23,csvRecordData[23]);
                n1.Primary_Document_Expiry_Date__c = Date.valueOf(CheckData(24,csvRecordData[24]));
                n1.Secondary_Document_Type__c = CheckData(25,csvRecordData[25]);
                n1.Secondary_Document_Number__c = decimal.valueOf(CheckData(26, csvRecordData[26]));
                n1.Secondary_Document_Expire_Date_c__c = Date.valueOf(CheckData(27, csvRecordData[27]));
                n1.Secondary_Document_Issue_Country__c = CheckData(28, csvRecordData[28]);
                n1.Meal_Service_Code__c = CheckData(29, csvRecordData[29]);	
                foundNameListList.Add(n1);
            }
            for (Name_List__c nl : foundNameListList) {
                this.wrappersList.add(new PageNameListWrapper(nl));
            }
        }
        catch (Exception e)
        {
            //ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importin data Please make sure input csv file is correct');
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage());
            ApexPages.addMessage(errorMessage);
        }  
  	}
    
    private String CheckData(Integer index, String Data){
        switch on index{
            when 0 {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Passenger_Type__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 1 {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Title__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 4,15,24,27{ //年份過久，會出現日期失效錯誤
                Data = Data.replaceAll('/', '-');
                
                if(Data.length()>0 && (Data.contains('/') || Data.contains('-'))){
                    if(Data.contains('/')){
                        
                    }else if(Data.contains('-')){
                        
                    }
                    return Data.replaceAll('/', '-');
                }
                return '';
            }
            when 5 {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Meal_Selection_All_Sector__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 6{ //待確認格式 text10 、 picklist
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Meal_Selection_Departing_Only__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 7{ //待確認格式 text10 、 picklist
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Meal_Selection_Returning_Only__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 8{
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Special_Service_Departing__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            
            when 9{
                List<Schema.PicklistEntry> TitleValues = Name_List__c.Special_Service_Returning__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 10 {
                if(Data.length() > 255){
                    return Data.substring(0, 255);
                }
                return Data;
            }            
            when 11 {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Passenger_Type__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }          
            when 12 {
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Title__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 16{
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Meal_Selection_All_Sector__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 17{
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Meal_Selection_Departing_Only__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 18{
                List<Schema.PicklistEntry> TitleValues = Name_List__c.INF_Meal_Selection_Returning_Only__c.getDescribe().getPicklistValues();
            	for(Schema.PicklistEntry value : TitleValues){
                    if(value.getValue().toLowercase() == Data.toLowercase()) return value.getValue();
                }
                return '';
            }
            when 19,22,26{
                try{
                    Integer.valueOf(Data);
                    return Data;
                }catch(Exception e){
                    return '0';
                }                
            }
            
            
        }
        return Data;
    }
	
}