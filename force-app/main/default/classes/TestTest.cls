@isTest
public with sharing class TestTest {
    @isTest
    public static void TestTest() {
        DemoHelperClass dm = (DemoHelperClass) Test.createStub(DemoHelperClass.class, new DemoMock());
        DemoHelperClass dm1 = new DemoHelperClass();
        Test.startTest();
        System.debug(DemoClass.demoFunction(dm));
        System.debug(DemoClass.demoFunction(dm1));
        Test.stopTest();
    }
}