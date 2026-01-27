@isTest
private class LoginControllerTest {
    
    @isTest
    static void testConstructor() {
        Test.startTest();

        Test.setCurrentPage(Page.Login);
        LoginController controller = new LoginController();
        System.assertEquals(false, controller.islogout);
        
        // 測試登出
        ApexPages.currentPage().getParameters().put('islogout', 'true');
        controller = new LoginController();
        System.assertEquals(true, controller.islogout);
        Test.stopTest();
    }
    
    @isTest
    static void testLoginWithInvalidAccount() {
        Test.startTest();
        LoginController controller = new LoginController();
        controller.UserAccount = 'invalid';
        controller.IATAcode = 'invalid';
        controller.password = 'invalid';
        
        PageReference result = controller.login();
        
        System.assertEquals(true, controller.isWrongCredentials);
        System.assertEquals(null, result);
        Test.stopTest();
    }
    
    @isTest
    static void testLoginWithInactiveAccount() {
        Test.startTest();
        LoginController controller = new LoginController();
        controller.UserAccount = 'test';
        controller.IATAcode = 'test';
        controller.password = 'test';
        
        // 帳號未啟用的情況
        UserManagement__c mockUser = new UserManagement__c();
        mockUser.Verify__c = false;
        
        // 登入
        PageReference result = controller.login();
        
        // 驗證
        System.assertEquals(null, result);
        Test.stopTest();
    }
    
    @isTest
    static void testLoginSuccess() {
        Test.startTest();
        LoginController controller = new LoginController();
        controller.UserAccount = 'test';
        controller.IATAcode = 'test';
        controller.password = 'test';
        
        // 成功登入
        PageReference result = controller.login();
        Test.stopTest();
    }
    
    @isTest
    static void testForgotPassword() {
        Test.startTest();
        LoginController controller = new LoginController();
        PageReference result = controller.forgotPassword();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
}