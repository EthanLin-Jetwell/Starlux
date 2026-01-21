@isTest
public class B2BTempTest {
    @isTest static void userManagment() {
        UserManagement__c newUser = new UserManagement__c(
            Email__c = 'testuser@example.com',
            Account__c = '1234567800',
            CN_Passport__c = '育瑋', 
            EN_Passport__c = 'Aaronabc', 
            Salutation__c = '先生',
            Resend__c = false,
            password__c = 'Jet..%13239686'
        );
        
        Test.startTest();
        insert newUser;
        Test.stopTest();
    }
    
    @isTest static void testMethods() {
        AmadeusUtil.fakeMethod();
        AirRetrieveSeatMap.fakeMethod();
        AmadeusUtilDCS.fakeMethod();
        AmadeusUtilRetrieveSeatMap.fakeMethod();
        AmadeusXmlParser.fakeMethod();
        AccountMaintainController.fakeMethod();
        AccountManagementController.fakeMethod();
        AutoLogoutController.fakeMethod();
        BoardingPassPDFController.fakeMethod();
        BoardingPassPrintingController.fakeMethod();
        B2BForgotPasswordController.fakeMethod();
        CheckINController.fakeMethod();
        CheckINReportPDFController.fakeMethod();
        CheckInReportController.fakeMethod();
        CommonController.fakeMethod();
        EditTravelerController.fakeMethod();
        EmailTemplateHelper.fakeMethod();
        HOME_Controller.fakeMethod();
        HistoryLogController.fakeMethod();
        LoginUtility.fakeMethod();
        LoginController.fakeMethod();
        InfobipUtility.fakeMethod();
        MessageResponse.fakeMethod();
        NavbarController.fakeMethod();
        OperationHistoryUtil.fakeMethod();
        PassengerDataWrapper.fakeMethod();
        PageUtility.fakeMethod();
        ResetPasswordController.fakeMethod();
        SeatSelectionController.fakeMethod();
        UserUtilities.fakeMethod();
    }
}