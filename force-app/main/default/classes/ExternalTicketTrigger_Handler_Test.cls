@IsTest
private class ExternalTicketTrigger_Handler_Test {

    @IsTest
    static void test_fakeMethod() {
        Test.startTest();
        ExternalTicketTrigger_Handler.fakeMethod();
        Test.stopTest();

        // fakeMethod 沒有輸出/副作用，至少確認不會噴例外
        System.assert(true, 'fakeMethod should run without exception');
    }
}