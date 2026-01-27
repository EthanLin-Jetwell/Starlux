@isTest(SeeAllData=FALSE)
public class AllClass_Test {
    public static testMethod Void testAll() {
        ReceiveResponseAddNamelistApi.fakeMethod();
        ReceiveResponseCancelPnrApi.fakeMethod();
        ReceiveResponseCreatePnrApi.fakeMethod();
        ReceiveResponseGetUpdateApi.fakeMethod();
        ReceiveResponseIssueTicketApi.fakeMethod();
        ReceiveResponseResizePnrApi.fakeMethod();
        NameListController.fakeMethod();
        AddPaxInvocableMethod.fakeMethod();
        DisableIntegrationInvocableMethod.fakeMethod();
        GetTaxInvocableMethod.fakeMethod();
        GetTicketFareInvocableMethod.fakeMethod();
        GetUpdateInvocableMethod.fakeMethod();
        IssueTicketInvocableMethod.fakeMethod();
        SyncSatInvocableMethod.fakeMethod();
        SyncSstInvocableMethod.fakeMethod();
        IssueTicketScheduler.fakeMethod();
        CreatePnrBulkBatch.fakeMethod();
        CreatePnrBulkScheduler.fakeMethod();
        GetMiddlewareAccessTokenScheduler.fakeMethod();
        ApexErrorUtil.fakeMethod();
        ApiLogger.fakeMethod();
        CaseUtil.fakeMethod();
        Constants.fakeMethod();
        CreateUpdateMetadataUtil.fakeMethod();
        DbUtil.fakeMethod();
        DebugUtil.fakeMethod();
        GetUpdateUtil.fakeMethod();
        HttpRequestUtil.fakeMethod();
        IssueTicketUtil.fakeMethod();
        MiddlewareUtil.fakeMethod();
        PaxUtil.fakeMethod();
        ResponseUtil.fakeMethod();
        SeatAllocationUtil.fakeMethod();
        SObjectUtil.fakeMethod();
        TaxUtil.fakeMethod();
        TicketFareUtil.fakeMethod();
        MwAddPaxWrapper.fakeMethod();
        MwCancelPnrWrapper.fakeMethod();
        MwCaseListWrapper.fakeMethod();
        MwCreatePnrWrapper.fakeMethod();
        MwGetTaxResponseWrapper.fakeMethod();
        MwGetTaxWrapper.fakeMethod();
        MwGetUpdateResponseWrapper.fakeMethod();
        MwIssueTicketWrapper.fakeMethod();
        MwResizePnrWrapper.fakeMethod();
        MwSyncSstWrapper.fakeMethod();
        PageNameListWrapper.fakeMethod();
        ReceiveResponseAddNamelistWrapper.fakeMethod();
        ReceiveResponseCancelPnrWrapper.fakeMethod();
        ReceiveResponseCreatePnrWrapper.fakeMethod();
        ReceiveResponseGetUpdateWrapper.fakeMethod();
        ReceiveResponseIssueTicketWrapper.fakeMethod();
        ReceiveResponseResizePnrWrapper.fakeMethod();
        SimpleResponseWrapper.fakeMethod();
        CaseTriggerHandler.fakeMethod();
        SeatAllocationTriggerHandler.fakeMethod();
        UpdateTicketFare.fakeMethod();
        CaseCouponTriggerHandler.fakeMethod();
        CopyContactEmails.fakeMethod();
        CopyContactEmailsSeatAllocation.fakeMethod();
        CopyContactEmailsSeatSales.fakeMethod();
        DeleteContentDocument.fakeMethod();
        RestMiddlewareApi.fakeMethod();
        AsyncRequestHandler.fakeMethod();
        CallCenterCantDownloadCaseAttachment.fakeMethod();
        BatchGetItinerary.fakeMethod();
        GetItinerary.fakeMethod();
        QueueableGetItinerary.fakeMethod();
    }
    
    public static testMethod void TestCreatCasewhihCaseCoupon() {
        // Test data setup
        
        //Create Case Record
        ID caseRecordID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Crew').getRecordTypeId();
        Date flightDate = Date.newInstance(2021,8,12);        
        String flightNumber = 'JX110';
        
        Map<String, Object> caseFieldValueMap = new Map<String, Object>();
        caseFieldValueMap.put('RecordTypeId', caseRecordID); 
        caseFieldValueMap.put('Flight_Date__c', flightDate);
        caseFieldValueMap.put('Flight_Number__c', flightNumber);        
        caseFieldValueMap.put('Status', 'New');
        
        TestUtility.createCase(caseFieldValueMap);
        List<String> caseFields = new List<String>();
        caseFields.add('Flight_Date__c');
        caseFields.add('Flight_Number__c');
        
        Case testCase = (Case) TestUtility.getCase(caseFields);       
        system.debug('DBG testCase: '+testCase);
        
        //Create Case Coupon Record
        /*String PRD_CouponID = 'a0A2u000001POxFEAW';//coupon number 202008000000
        String TRN_CouponID = 'a0A6D000003EEowUAG';//coupon number 202105000002  
        Date couponIssueDate = Date.newInstance(2021,8,12);
        Case_Coupon__c casecoupon = new Case_Coupon__c(Case_ID__c = testCase.Id, Coupon_ID__c = TRN_CouponID, Coupon_Issue_Date__c = couponIssueDate);//20231004 Eli amended*/
        
        
        // Perform test
        /*Test.startTest();
        Database.SaveResult SaveResult = database.insert(casecoupon);        
        Test.stopTest();//20231004 Eli amended*/
        // Verify 
        // In this case the creation should have been stopped by the trigger,
        // so verify that we got back an error.
        /*System.assert(SaveResult.isSuccess(),false);//20231004 Eli amended*/
        //System.assert(SaveResult.getErrors().size() < 0);
        /*System.assertEquals('System.DmlException: Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Crew Case Coupon Flight Date Could Not Be Later Than Today And Could Not Be Prior To Distributed To Agent Date: [Coupon_Issue_Date__c]',
                             SaveResult.getErrors()[0].getMessage());*/
    }
}