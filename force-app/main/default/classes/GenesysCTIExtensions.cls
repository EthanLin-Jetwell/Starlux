global with sharing class GenesysCTIExtensions implements purecloud.CTIExtension.ScreenPop {
    public String onScreenPop(String data) {
        //儲存本次data
        API_Log__c Log = new API_Log__c();
        Log.Request_Method__c  = 'Genesys';
        Log.Response_Body__c = data;
        Insert Log;
        
        Map<String, Object> screenPopData = (Map<String, Object>) JSON.deserializeUntyped(data);
        Map<String, Object> dataToReturn = new Map<String, Object>();

        //如果data中沒有"sf_urlpop"就不再往下執行
        IF(
            data.indexOf('"sf_urlpop"') == -1){
            dataToReturn.put('defaultScreenPop', true);
            return JSON.serialize(dataToReturn);           
        }
        
        //data='{"searchValue":"Internal","interaction":{"id":"c1728619-2236-462e-a6df-e250401fb9e0","phone":"sip:664d73008367a11bb294ae5e+starlux-test.orgspan.com@localhost","isConnected":false,"isDisconnected":false,"isDone":false,"state":"ALERTING","attributes":{"sf_urlpop":"lightning/o/Case/new?recordTypeId=0122v000000wMT2&defaultFieldValues=CTI_Location__c=MNL,RecordTypeId=0122v000000wMT2,CTI_Ticket_EMD_Number__c=7777777777777,CTI_Member_ID__c=666666666,SuppliedPhone=tsaiweiting%40gmail."},"isCallback":false,"isDialer":false,"isChat":false,"isEmail":false,"isMessage":false,"isVoicemail":false,"recordingState":"none","securePause":false,"displayAddress":"Internal","queueName":"PAX_PH","ani":"Internal","calledNumber":"651ef721-624e-4a4b-9c1d-8672352f0622","totalIvrDurationSeconds":134,"direction":"Inbound","isInternal":true}}';
        //找到CTI_Location__c、CTI_Ticket_EMD_Number__c、CTI_Member_ID__c
        String location;
        String ticketNumber;
        String memberId;
        String recordTypeName; //20250407 Eli
        String recordTypeId;
        String CTI_Tier;
        String Web_Phone_Call_Back;
        String priority;
        String SuppliedPhone;
        String direction;
        
        //用頭尾關鍵字的方式找到4個參數
        Integer startIndex;
        Integer endIndex;
        startIndex = data.indexOf('CTI_Location__c='); startIndex+=16;
        endIndex = data.indexOf(',', startIndex);
        location = data.substring(startIndex, endIndex);
        startIndex = data.indexOf('CTI_Ticket_EMD_Number__c='); startIndex+=25;
        endIndex = data.indexOf(',', startIndex);
        ticketNumber = data.substring(startIndex, endIndex);
        startIndex = data.indexOf('CTI_Member_ID__c='); startIndex+=17;
        endIndex = data.indexOf(',', startIndex);
        memberId = data.substring(startIndex, endIndex);
        startIndex = data.indexOf('RecordTypeId='); startIndex+=13;
        endIndex = data.indexOf(',', startIndex);
        recordTypeName = data.substring(startIndex, endIndex); //20250407 Eli
        //recordTypeId = data.substring(startIndex, endIndex); //20250407 Eli
        //recordTypeId = '0122v000000wMSxAAM'; //20250407 Eli
        startIndex = data.indexOf('CTI_Tier__c='); startIndex+=12;
        endIndex = data.indexOf('"', startIndex);
        IF(endIndex > data.indexOf(',', startIndex)) endIndex = data.indexOf(',', startIndex);
        CTI_Tier = data.substring(startIndex, endIndex); IF(data.indexOf('CTI_Tier__c=') == -1) CTI_Tier='';
        startIndex = data.indexOf('Web_Phone_Call_Back__c='); startIndex+=23;
        endIndex = data.indexOf('"', startIndex);
        IF(endIndex > data.indexOf(',', startIndex)) endIndex = data.indexOf(',', startIndex);
        Web_Phone_Call_Back = data.substring(startIndex, endIndex); IF(data.indexOf('Web_Phone_Call_Back__c=') == -1) Web_Phone_Call_Back='';
        startIndex = data.indexOf('Priority='); startIndex+=9;
        endIndex = data.indexOf('"', startIndex);
        IF(endIndex > data.indexOf(',', startIndex)) endIndex = data.indexOf(',', startIndex);
        priority = data.substring(startIndex, endIndex); IF(data.indexOf('Priority=') == -1) priority='';
        startIndex = data.indexOf('SuppliedPhone='); startIndex+=14;
        endIndex = data.indexOf('"', startIndex);
        IF(endIndex > data.indexOf(',', startIndex)) endIndex = data.indexOf(',', startIndex);
        SuppliedPhone = data.substring(startIndex, endIndex); IF(data.indexOf('SuppliedPhone=') == -1) SuppliedPhone='';

        
        //4個參數結果
        system.debug(location);
        system.debug(ticketNumber);
        system.debug(memberId);
        system.debug(recordTypeId);
        //system.debug(recordTypeName);//20250407 Eli
        system.debug(CTI_Tier);
        system.debug(Web_Phone_Call_Back);
        system.debug(priority);
        system.debug(SuppliedPhone);
        
        // 以recordTypeName搜尋recordTypeId
        
        IF (recordTypeName != ''){
            RecordType rtName = [SELECT Id, Name, IsActive, SobjectType FROM RecordType WHERE SobjectType = 'Case' AND Name =: recordTypeName AND IsActive = true LIMIT 1]; //20250407 Eli
            recordTypeId = rtName.Id;}
        ElSE
        	{recordTypeId = [SELECT Id, Name, IsActive, SobjectType FROM RecordType WHERE SobjectType = 'Case' AND Name = 'Enquiry and Request' AND IsActive = true LIMIT 1].Id;}//20250407 Eli
        
        // 檢查使用者是否可以使用指定的 Record Type
        Id userProfileId = UserInfo.getProfileId();
        String desiredRecordTypeId = recordTypeId; // 你要檢查的 Record Type ID
        Boolean isRecordTypeAvailable = false;
        
        // 取得Case對應的所有Record Types
        Map<String, Schema.RecordTypeInfo> caseRecordTypes = Schema.SObjectType.Case.getRecordTypeInfosByName();
        
        // 檢查該使用者的Profile是否可以存取指定的Record Type
        for (Schema.RecordTypeInfo recordTypeInfo : caseRecordTypes.values()) {
            if (String.valueOf(recordTypeInfo.getRecordTypeId()).contains(desiredRecordTypeId) && recordTypeInfo.isAvailable()) {
                isRecordTypeAvailable = true;
                break;
            }
        }
            
        //建立Case，並Pop出來
        String phoneNumber = (String) screenPopData.get('searchValue');
        phoneNumber = SuppliedPhone;
        if (String.isNotBlank(phoneNumber)) {
            List<RecordType> RTs = [SELECT Id, Name, DeveloperName, IsActive, SobjectType FROM RecordType where SobjectType = 'Case' and IsActive = true];
            Map<String,Id> MapRT = new Map<String,Id>();
            FOR(RecordType RT:RTs) MapRT.put(RT.DeveloperName, RT.Id);
            Case NewCase = new Case();
            NewCase.SuppliedPhone = phoneNumber;
            IF (priority != '') {NewCase.Priority = priority;} ELSE {NewCase.Priority = 'Medium';} 
            //如果當前使用者不可使用這個RecordType就以 'Enquiry_and_Request' 為主
            IF(isRecordTypeAvailable == False) {
                recordTypeId = MapRT.get('Enquiry_and_Request');
            } ELSE {
                IF(recordTypeId != Null && recordTypeId !='') NewCase.RecordTypeId = recordTypeId;
            }
            NewCase.Status = 'New';
            NewCase.Origin = 'Phone';
            NewCase.CTI_Location__c = location.left(255);
            NewCase.CTI_Ticket_EMD_Number__c = ticketNumber.left(14);
            NewCase.CTI_Member_ID__c = memberId.left(10);
            NewCase.CTI_Tier__c = CTI_Tier.left(10);
            NewCase.Web_Phone_Call_Back__c = Web_Phone_Call_Back;
            NewCase.Case_Sub_type__c = 'Others';
            
            try {
                IF(!Test.isRunningTest()) Insert NewCase;
            }catch (Exception e) {
                // Insert失敗時，記錄錯誤日誌
                API_Log__c InsertLog = new API_Log__c();
                InsertLog.Request_Method__c = 'Genesys';
                InsertLog.Response_Body__c = e.getMessage();  // 取得錯誤訊息
                insert InsertLog;
            }
            
            dataToReturn.put('url', NewCase.Id);
            return JSON.serialize(dataToReturn);
            
        }
        dataToReturn.put('defaultScreenPop', true);
        return JSON.serialize(dataToReturn);
    }
}