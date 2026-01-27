/********************************************************************************************************
NAME:			SapReceiveChequeStatusApi
AUTHOR:			Chris Hsu (chrishsu@starlux-airlines.com)
PURPOSE:		This is the API that updates Payment/Deposit/Fine records based on cheque status.
                1.Get Payment cheque record
                2.Get Account record
                3.Check input data and payment cheque record are match
                4.Prepare the update for Payment cheque
                5.Build the response
                6.Prepare the update for Account
                7.Update Payment cheque & Account record
                8.Send Response
UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
2021/12/27      Chris Hsu		First version
********************************************************************************************************/
@RestResource(urlMapping = '/receive/chequeStatus')
global class SapReceiveChequeStatusApi {
    @Httppost
    global static void receiveChequeStatusApi(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        SapResponseChequeStatusWrapper responsebodyWrapper = new SapResponseChequeStatusWrapper();
        responsebodyWrapper.chequeList = new List<SapResponseChequeStatusWrapper.chequeList>();
        List<Payment_Deposit_Fine_Details__c > updateChequeQueue = new List<Payment_Deposit_Fine_Details__c>();
        List<Account> updateAccountQueue = new List<Account>();

        List<SapReceiveChequeStatusWrapper> requestBodyWrapper = SapReceiveChequeStatusWrapper.deserializeJson(request.requestBody.toString());
        System.debug(requestBodyWrapper);

        //putting all cheques into cheque list
        List<String> chequeList = new List<String>();
        for (SapReceiveChequeStatusWrapper wrapper : requestBodyWrapper) {
            chequeList.add(wrapper.chequeNo);
        }
       
        //Get cheque payment record 找出最新且正數的cheque payment
        Id PaymentRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Payment' and SObjectType = 'Payment_Deposit_Fine_Details__c'].Id;
        AggregateResult[] arPaymentIdList = [SELECT SUM(Payment_Amount__c) paymentAmount, COUNT(Id) counts, Cheque_No__c, RecordTypeId  FROM Payment_Deposit_Fine_Details__c 
                                     WHERE 
                                             //RecordTypeId =:PaymentRecordTypeId AND //2024-03-22 Eli
                                             Cheque_No__c in :chequeList 
                                             //AND Cheque_Cashed_Date__c = NULL AND Cheque_Bounced_Date__c = NULL //2024-01-05 Eli
                                     GROUP BY Cheque_No__c,
                                             RecordTypeId];  //2024-03-29 Eli   

        Map<String, Decimal> paymentSum = new Map<String, Decimal>();
        Map<String, Integer> paymentCounts = new Map<String, Integer>();
        for(AggregateResult ar : arPaymentIdList) {   
 				String chequeNo = String.valueOf(ar.get('Cheque_No__c'));//2024-03-29 Eli 
    			Id recordTypeId = (Id)ar.get('RecordTypeId');//2024-03-29 Eli 
    			if (recordTypeId != PaymentRecordTypeId) {
                            paymentSum.put(String.valueOf(ar.get('Cheque_No__c')), Decimal.valueOf(0));
            				paymentCounts.put(String.valueOf(ar.get('Cheque_No__c')), Integer.valueOf(ar.get('counts')));//2024-03-29 Eli 
            }Else
            {paymentSum.put(String.valueOf(ar.get('Cheque_No__c')), Decimal.valueOf(String.valueOf(ar.get('paymentAmount'))));
            paymentCounts.put(String.valueOf(ar.get('Cheque_No__c')), Integer.valueOf(ar.get('counts')));
            }
            }

        List<Payment_Deposit_Fine_Details__c> searchChequeList = [SELECT Id,Name,Cheque_No__c,Payment_Amount__c,Account_ID__c,Account_ID__r.Business_Number__c,
        Cheque_Cashed_Date__c,Cheque_Bounced_Date__c,Credit_Balance_has_been_Recovered__c, RecordTypeId  
        FROM Payment_Deposit_Fine_Details__c
        WHERE 
                                                                  //RecordTypeId =: PaymentRecordTypeId AND //2024-03-22 Eli
                                                                  Cheque_No__c in : chequeList 
                                                                  //AND Cheque_Cashed_Date__c = NULL AND Cheque_Bounced_Date__c = NULL  //2024-01-05 Eli
                                                                 ];
        
        System.debug(searchChequeList);

        //compare input data with payment cheque record & prepare updateChequeQueue
        Integer chequeInvalidCount = 0;//process result of input cheque 
        for (SapReceiveChequeStatusWrapper wrapper : requestBodyWrapper) {
            SapResponseChequeStatusWrapper.chequeList responseChequeList = new SapResponseChequeStatusWrapper.chequeList();
            Integer count = 0;
            boolean cheqeuFound = false;          
            boolean noMissingValue = false; 
            //check if required field is missing
            if (!wrapper.isMissingRequiredFields()) {
                noMissingValue = true;
                for(Payment_Deposit_Fine_Details__c currCheque : searchChequeList){
                    if(count == paymentCounts.get(wrapper.chequeNo)) {
                        break;
                    }
                    //check if cheque is valid or exists
                    if(wrapper.chequeNo == currCheque.Cheque_No__c && currCheque.RecordTypeId != PaymentRecordTypeId)
                        {cheqeuFound = true;
                        count++;}//2024/03/29 Eli
                    { 
                    if(wrapper.chequeNo == currCheque.Cheque_No__c &&
                       //wrapper.businessNumber == currCheque.Account_ID__r.Business_Number__c && 2023/12/22 Eli
                       (wrapper.chequeStatus =='Cashed' ||  wrapper.chequeStatus =='Bounced')&&
                      wrapper.amount == paymentSum.get(wrapper.chequeNo)){
                          count++;
                           //Found cheque & set Cheque Status
                           cheqeuFound = true;  
                           currCheque.Cheque_Status__c = wrapper.chequeStatus;
                           if(wrapper.chequeStatus == 'Cashed'){
                               currCheque.Cheque_Cashed_Date__c = System.Today();
                               //currCheque.Credit_Balance_has_been_Recovered__c=true; 2023/12/22 Eli
                           }else if(wrapper.chequeStatus == 'Bounced')
                               currCheque.Cheque_Bounced_Date__c = System.Today();                                         
                           //add cheque to updateQueue
                           updateChequeQueue.add(currCheque);
                       }

                }

                }
            }
            if(cheqeuFound && noMissingValue) {
                //add process status to response             
                responseChequeList.businessNumber = wrapper.businessNumber;
                responseChequeList.chequeNo = wrapper.chequeNo;
                responseChequeList.processStatus = Constants.PICKLIST_STATUS_SUCCEEDED;
                responsebodyWrapper.chequeList.add(responseChequeList);   
            }
            if(!cheqeuFound) {
                //add process status to response
                responseChequeList.businessNumber = wrapper.businessNumber;
                responseChequeList.chequeNo = wrapper.chequeNo;
                responseChequeList.processStatus = Constants.PICKLIST_STATUS_FAIL;
                responseChequeList.remark = Constants.MESSAGE_NO_RECORDS_FOUND;
                responsebodyWrapper.chequeList.add(responseChequeList);
                chequeInvalidCount++;
            }
            if(!noMissingValue) {
                //add process status to response
                responseChequeList.businessNumber = wrapper.businessNumber;
                responseChequeList.chequeNo = wrapper.chequeNo;
                responseChequeList.processStatus = Constants.PICKLIST_STATUS_FAIL;
                responseChequeList.remark = Constants.MISSING_REQUIRED_FIELD;
                responsebodyWrapper.chequeList.add(responseChequeList);
                chequeInvalidCount++;
            }
        }

        //Update Payment Cheque
        if(updateChequeQueue.size()>0){
            Database.update(updateChequeQueue);
        }
        
        /*
        //Get cheque payment record 找出最新且正數的cheque payment
        Id PaymentRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Payment' and SObjectType = 'Payment_Deposit_Fine_Details__c'].Id;
        AggregateResult[] arPaymentIdList = [SELECT MAX(id) paymentId FROM Payment_Deposit_Fine_Details__c 
                                             WHERE RecordTypeId =:PaymentRecordTypeId AND Payment_Amount__c>=0 AND Cheque_No__c in :chequeList 
                                             GROUP BY Cheque_No__c];   
        System.debug(chequeList);

        List<String> paymentIdList = new List<String>();
        for(AggregateResult ar : arPaymentIdList) {   
            System.debug(ar);
            paymentIdList.add(String.valueOf(ar.get('paymentId')));
        }

        List<Payment_Deposit_Fine_Details__c> searchChequeList = [SELECT Id,Name,Cheque_No__c,Payment_Amount__c,Account_ID__c,Account_ID__r.Business_Number__c,
        Cheque_Cashed_Date__c,Cheque_Bounced_Date__c,Credit_Balance_has_been_Recovered__c  
        FROM Payment_Deposit_Fine_Details__c
        WHERE id in :paymentIdList];
        //Get Account record
        List<Account> searchAccountList = [SELECT Id,Business_Number__c,Status__c,Credit_Balance__c 
        FROM Account
        WHERE Id in (SELECT Account_ID__c FROM Payment_Deposit_Fine_Details__c WHERE Id in :paymentIdList)];

        //compare input data with payment cheque record & prepare updateChequeQueue
        Integer chequeNotFoundCount = 0;//process result of input cheque 
        for (SapReceiveChequeStatusWrapper wrapper : requestBodyWrapper) {
            SapResponseChequeStatusWrapper.chequeList responseChequeList = new SapResponseChequeStatusWrapper.chequeList();
            boolean cheqeuFound = false;          
            boolean noMissingValue = false; 
            if (!wrapper.isMissingRequiredFields()) {
                noMissingValue = true;
                for(Payment_Deposit_Fine_Details__c currCheque : searchChequeList){
                    if(wrapper.chequeNo == currCheque.Cheque_No__c &&
                       wrapper.businessNumber == currCheque.Account_ID__r.Business_Number__c &&
                       wrapper.amount == currCheque.Payment_Amount__c &&
                       (wrapper.chequeStatus =='Cashed' ||  wrapper.chequeStatus =='Bounced')&&
                       currCheque.Cheque_Cashed_Date__c ==null &&
                       currCheque.Cheque_Bounced_Date__c == null){
                           //Found cheque & set Cheque Status
                           currCheque.Cheque_Status__c = wrapper.chequeStatus;
                           if(wrapper.chequeStatus == 'Cashed'){
                               currCheque.Cheque_Cashed_Date__c = System.now();
                               currCheque.Credit_Balance_has_been_Recovered__c=true;
                           }else if(wrapper.chequeStatus == 'Bounced')
                               currCheque.Cheque_Bounced_Date__c = System.now();                          
                           //add process status to response
                           cheqeuFound = true;                    
                           responseChequeList.businessNumber = currCheque.Account_ID__r.Business_Number__c;
                           responseChequeList.chequeNo = currCheque.Cheque_No__c;
                           responseChequeList.processStatus = Constants.PICKLIST_STATUS_SUCCEEDED;
                           responsebodyWrapper.chequeList.add(responseChequeList);                      
                           //add cheque to updateQueue
                           updateChequeQueue.add(currCheque);
                       }
                }
            }
            if(!cheqeuFound) {
                //add process status to response
                responseChequeList.businessNumber = wrapper.businessNumber;
                responseChequeList.chequeNo = wrapper.chequeNo;
                responseChequeList.processStatus = Constants.PICKLIST_STATUS_FAIL;
                responseChequeList.remark = Constants.MESSAGE_NO_RECORDS_FOUND;
                responsebodyWrapper.chequeList.add(responseChequeList);
                chequeNotFoundCount++;
            }
            if(!noMissingValue) {
                //add process status to response
                responseChequeList.businessNumber = wrapper.businessNumber;
                responseChequeList.chequeNo = wrapper.chequeNo;
                responseChequeList.processStatus = Constants.PICKLIST_STATUS_FAIL;
                responseChequeList.remark = Constants.MISSING_REQUIRED_FIELD;
                responsebodyWrapper.chequeList.add(responseChequeList);
                chequeNotFoundCount++;
            }
        }
        
        //prepare updateAccountQueue
        if(updateChequeQueue.size()>0){
            Map<String, Account> accountListMap = new Map<String, Account>();
            for(Account currAccount : searchAccountList) {
                accountListMap.put(currAccount.Business_Number__c, currAccount);
            }
            //found Account recrod & set content
            for(Payment_Deposit_Fine_Details__c currCheque : updateChequeQueue){
                Account accountformMap = accountListMap.get(currCheque.Account_ID__r.Business_Number__c);                
                if(currCheque.Cheque_Status__c == 'Cashed'){                    
                    //set Credit Balance
                    accountformMap.Credit_Balance__c += currCheque.Payment_Amount__c;
                }else if(currCheque.Cheque_Status__c == 'Bounced' && accountformMap.Status__c !='Bankrupt'){
                    //set Status as Bankrupt
                    accountformMap.Status__c = 'Bankrupt';
                }                
            }
            updateAccountQueue = searchAccountList;            
        }

        //Update Payment Cheque & Account
        if(updateChequeQueue.size()>0 && updateAccountQueue.size()>0){
            // Database.update(updateChequeQueue);
            // Database.update(updateAccountQueue);
            //responsebodyWrapper.message = JSON.serialize(updateChequeQueue);
            //responsebodyWrapper.message += JSON.serialize(updateAccountQueue);
        }*/

        responsebodyWrapper.status = (requestBodyWrapper.size()>chequeInvalidCount)? Constants.PICKLIST_STATUS_SUCCEEDED : Constants.PICKLIST_STATUS_FAIL;
        responsebodyWrapper.message += ' ['+updateChequeQueue.size()+']'+'Succeeded, ['+chequeInvalidCount+']Failed';
        
        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = ResponseUtil.buildBlobFromString(JSON.serialize(responsebodyWrapper));
        //response.responseBody = Blob.valueOf(returnStr);
    }
}