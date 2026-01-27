@IsTest
public class SapReceiveChequeStatusApi_Test {
    @TestSetup
    public static void SetupData(){
        Account fakeAccount = new Account();
        fakeAccount.Name = 'Aaron';
        fakeAccount.Credit_Balance__c = 3000000;
        fakeAccount.Status__c = 'Active';
        fakeAccount.Business_Number__c = 'AaronTest';
        Insert fakeAccount;
        
        Case fakeCase = new Case();
        fakeCase.Status = 'Waiting for Payment';
        Insert fakeCase;
                
        Replenishment__c  fakeReplenishment = new Replenishment__c();
        fakeReplenishment.AccountId__c = fakeAccount.Id;
        fakeReplenishment.Replenishment_Amount__c = 3000000;
		INSERT fakeReplenishment;
        
        System.debug([SELECT Credit_Balance__c, Credit_Balance2__c FROM Account WHERE Id= : fakeAccount.Id]);
        
        Id PaymentRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Payment' and SObjectType = 'Payment_Deposit_Fine_Details__c'].Id;
        
        Payment_Deposit_Fine_Details__c fakeData = new Payment_Deposit_Fine_Details__c();
        fakeData.RecordTypeId = PaymentRecordTypeId;
        fakeData.Case_ID__c = fakeCase.Id;
        fakeData.Account_ID__c = fakeAccount.Id;
        fakeData.Cheque_No__c = 'Y123456';
        fakeData.Payment_Mode__c = 'Cheque';
        fakeData.Payment_Amount__c = 234220.0;
        fakeData.Cheque_Clearance_Date__c = Date.today();
        fakeData.Cheque_Issuance_Date__c = Date.today();
		INSERT fakeData;
    }
    
	@IsTest
    static void receiveChequeStatusApi_Test() {
        Map<String, String> fakeCheque = new Map<String, String> {'businessNumber' => 'AaronTest', 'chequeNo' => 'Y123456', 'chequeStatus' => 'Cashed', 'amount' => '234220.0'};
        List<Map<String, String>> fakeCheques = new List<Map<String, String>>();
        fakeCheques.add(fakeCheque);
        
        String JsonMsg=JSON.serialize(fakeCheques);
        
        SapResponseChequeStatusWrapper.deserializeJson(JsonMsg);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/receive/chequeStatus';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        SapReceiveChequeStatusApi.receiveChequeStatusApi();
        //ResponseResultModel resultModel = RestLoginApi.login('123456', '1234qwer');
        Test.stopTest();
    }
}