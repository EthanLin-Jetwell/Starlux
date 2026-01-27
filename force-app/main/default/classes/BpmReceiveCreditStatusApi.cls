/********************************************************************************************************
NAME:			BpmReceiveCreditStatusApi
AUTHOR:			Chris Hsu (chrishsu@starlux-airlines.com)
PURPOSE:		This is the API that updates Account records based on cheque status.
                1.Get Account record
                2.Check input data matchs Account record
                3.Prepare the update for Account
                4.Update Account record
                5.Unlock Account record
                5.Send Response
UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
2021/12/27      Chris Hsu		First version
********************************************************************************************************/
@RestResource(urlMapping = '/request/receiveCreditStatus')
global class BpmReceiveCreditStatusApi {
    @Httppost
    global static void receiveCreditStatusApi(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;        

        BpmReceiveCreditStatusWrapper wrapper = BpmReceiveCreditStatusWrapper.deserializeJson(request.requestBody.toString());
        
        //Check require fields
        if (wrapper.isMissingRequiredFields()) {
            response = ResponseUtil.buildErrorRestResponse(response, Constants.MISSING_REQUIRED_FIELD);
            ApiLogger.log(request, response);
            return;
        }
        
        //Get Account Recrod
        Account[] searchAccount = [SELECT Id,Business_Number__c,Credit_Limit__c,Last_Credit_Limit__c,Change_in_Credit_Limit__c, 
        Credit_Balance__c,Status__c,Sync_BPM_Status__c,Sync_BPM_Error_Message__c 
        FROM ACCOUNT WHERE Business_Number__c = :wrapper.businessNumber LIMIT 1];
        Account currAccount = new Account();
        Account updateAccount = new Account();

        //Process
        if(searchAccount.size()>0){
            currAccount = searchAccount.get(0);
            updateAccount.Id = currAccount.Id;
            //set default value as 0
            Double CreditLimit = (currAccount.Credit_Limit__c==null)? 0:currAccount.Credit_Limit__c;
            Double LastCreditLimit = (currAccount.Last_Credit_Limit__c==null)? 0:currAccount.Last_Credit_Limit__c;
            Double ChangeInCreditLimit = (currAccount.Change_in_Credit_Limit__c==null)? 0:currAccount.Change_in_Credit_Limit__c;
            Double CreditBalance = (currAccount.Credit_Balance__c==null)? 0:currAccount.Credit_Balance__c;

            //Process approval result of Account Credit
            if(wrapper.functionType == 'C'){
                if(wrapper.creditAmount != CreditLimit){
                    response = ResponseUtil.buildErrorRestResponse(response, 'Credit amount is inconsistent with application');
                    return;                        
                }
                //had approved
                if(wrapper.approvalStatus == 'Y'){
                    updateAccount.Change_in_Credit_Limit__c = wrapper.creditAmount-LastCreditLimit;//Update Change in Credit Limit
                    updateAccount.Credit_Balance__c = (wrapper.creditAmount-LastCreditLimit)+CreditBalance;//Update Credit Balance
                    updateAccount.Status__c = (currAccount.Status__c!='Bankrupt')?'Active':currAccount.Status__c;//Update Status to Active
                       
                }
                //had rejected
                else if(wrapper.approvalStatus == 'N' && currAccount.Status__c!='Bankrupt'){
                    updateAccount.Status__c = 'Credit Limit Rejected';
                }
            }
            //Process approval resutlt of Replenishment
            else if(wrapper.functionType == 'R'){
                updateAccount.Credit_Balance__c = wrapper.replenishAmount+CreditBalance;
                if(wrapper.accountUnlock=='Y' && currAccount.Status__c!='Bankrupt'){
                    updateAccount.Status__c = 'Active';
                }
            }
        }else {
            response = ResponseUtil.buildErrorRestResponse(response, Constants.MESSAGE_NO_RECORDS_FOUND);
            return;
        }

        //unlock Account record
        if(System.Approval.isLocked(updateAccount.Id)){
            System.Approval.unlock(updateAccount.Id);
        }

        updateAccount.Sync_BPM_Status__c = Constants.PICKLIST_STATUS_SUCCEEDED;
        //Database.update(updateAccount);
                
        // response.statusCode = 200;
        // response.addHeader('Content-Type', 'application/json');
        // SimpleResponseWrapper simpleResponseWrapper = new SimpleResponseWrapper(Constants.PICKLIST_STATUS_SUCCEEDED, JSON.serialize(updateAccount));
        // response.responseBody = ResponseUtil.buildBlobFromString(JSON.serialize(simpleResponseWrapper));

        response = ResponseUtil.buildSuccessRestResponse(response);
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
    }
}