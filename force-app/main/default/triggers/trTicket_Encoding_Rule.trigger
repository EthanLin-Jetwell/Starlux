trigger trTicket_Encoding_Rule on Ticket_Encoding_Rule__c (before insert, after insert) {
    IF(Trigger.isBefore){
        
    }
    
    IF(Trigger.isAfter && Trigger.isInsert){
        Boolean isRunBatch = False;
        //產生Detail
        List<Ticket_Encoding_Rule_Detail__c> Insert_TER_Detail = new List<Ticket_Encoding_Rule_Detail__c>();
        FOR(Ticket_Encoding_Rule__c TER : trigger.new){
            //先取得這一筆的記錄類型的名稱
            String RecordTypeName = Schema.getGlobalDescribe().get('Ticket_Encoding_Rule__c').getDescribe().getRecordTypeInfosById().get(TER.RecordTypeId).getName();
            //Certificate No
            IF(RecordTypeName == 'Certificate No'){
                //取得固定的前置碼
                String FixCode = TER.Type__c + TER.Country__c + TER.Year__c + TER.Batch__c;
                //取得預先設定好的參數
                Integer Start1=0, End1=0, Start2=0, End2=0;
                IF(TER.Start_No__c != Null) Start1 = Integer.valueOf(TER.Start_No__c);
                IF(TER.End_No__c != Null) End1 = Integer.valueOf(TER.End_No__c);
                IF(TER.Start_Check_Code__c != Null) Start2 = Integer.valueOf(TER.Start_Check_Code__c);
                IF(TER.End_Check_Code__c != Null) End2 = Integer.valueOf(TER.End_Check_Code__c);
                //以參數開始迴圈
                FOR(Integer i = Start1; i <= End1; i++){
                    FOR(Integer j = Start2; j <= End2; j++){
                        String TempNumber = FixCode;
                        TempNumber += ('00000000'+String.valueOf(i)).Right(TER.End_No__c.length()); //流水號碼數以 End_No__c 碼數為主
                        TempNumber += ('00000000'+String.valueOf(j)).Right(TER.End_Check_Code__c.length()); //檢查碼碼數以 End_Check_Code__c 碼數為主
                        //加入待新增的清單
                        Ticket_Encoding_Rule_Detail__c tmpDetail = new Ticket_Encoding_Rule_Detail__c();
                        tmpDetail.Number__c = TempNumber;
                        tmpDetail.TypeTicket_Encoding_Rule_No__c = TER.Id;
                        Insert_TER_Detail.add(tmpDetail);
                    }
                }
            }
            
            //Item No
            IF(RecordTypeName == 'Item No'){
                //取得固定的前置碼
                String FixCode = TER.Code__c + TER.Year__c + TER.Department__c;
                //取得預先設定好的參數
                Integer Start1 = 0;
                IF(TER.Start_No__c != Null) Start1 = Integer.valueOf(TER.Start_No__c);
                //以參數開始迴圈
                FOR(Integer i = Start1; i <= 999; i++){
                    String TempNumber = FixCode;
                    TempNumber += ('00000000'+String.valueOf(i)).Right(3); //流水號碼數以 3 碼數為主
                    //產生4碼小寫英文
                    TempNumber += generateRandomString(4);
                    //加入待新增的清單
                    Ticket_Encoding_Rule_Detail__c tmpDetail = new Ticket_Encoding_Rule_Detail__c();
                    tmpDetail.Number__c = TempNumber;
                    tmpDetail.TypeTicket_Encoding_Rule_No__c = TER.Id;
                    Insert_TER_Detail.add(tmpDetail);
                }
            }
            
            //Coupon No
            IF(RecordTypeName == 'Coupon No'){
                isRunBatch = True;
                //取得固定的前置碼
                String FixCode = TER.Code__c + TER.Year__c;
                //取得預先設定好的參數
                Integer Start1 = 0;
                IF(TER.Start_No__c != Null) Start1 = Integer.valueOf(TER.Start_No__c);
                //以參數開始迴圈
                FOR(Integer i = Start1; i <= 9999; i++){
                    String TempNumber = FixCode;
                    TempNumber += ('00000000'+String.valueOf(i)).Right(4); //流水號碼數以 4 碼數為主
                    //產生6碼小寫英文
                    TempNumber += 'RandomString(6)'; //RandomString(6) 會被Batch置換為亂碼6位
                    //加入待新增的清單
                    Ticket_Encoding_Rule_Detail__c tmpDetail = new Ticket_Encoding_Rule_Detail__c();
                    tmpDetail.Number__c = TempNumber;
                    tmpDetail.TypeTicket_Encoding_Rule_No__c = TER.Id;
                    Insert_TER_Detail.add(tmpDetail);
                }
            }
        }
        IF(Insert_TER_Detail.size() > 0) {
            Insert Insert_TER_Detail;
            // 觸發異步批次作業
            IF(isRunBatch && !Test.isRunningTest()){
                Batch_trTicket_RandomString batch = new Batch_trTicket_RandomString();
                Database.executeBatch(batch, 200);
            }
        }
    }
    
    String generateRandomString(Integer length) {
        String chars = 'abcdefghijklmnopqrstuvwxyz';
        String randomString = '';
        for (Integer i = 0; i < length; i++) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomString += chars.substring(randomIndex, randomIndex + 1);
        }
        return randomString;
    }
}