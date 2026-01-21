@IsTest
private class ExternalTicketFRFTResultController_Test {

    @IsTest
    static void test_fakeMethod() {
        Test.startTest();
        ExternalTicketFRFTResultController.fakeMethod();
        Test.stopTest();

        // fakeMethod 沒有輸出/副作用，至少確認不會噴例外
        System.assert(true, 'fakeMethod should run without exception');
    }
}