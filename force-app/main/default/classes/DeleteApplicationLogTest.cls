@isTest
private class DeleteApplicationLogTest {

    @isTest static void testDeleteApplicationLog() {
        // Create test records
        List<Application_Log__c> testRecords = new List<Application_Log__c>();
        for(Integer i=0; i<100; i++) {
           testRecords.add(new Application_Log__c(
               Application_Name__c = 'ABC',
               Start_Date__c=Date.today(),
               Debug_Level__c= 'Error', 
               Module__c='123', 
               Source_Function__c='123', 
               Type__c='Error Log',
               Custom_Age_Days__c = true));
        }
        insert testRecords;

        // Call the batch class
        Test.startTest();
        Database.executeBatch(new DeleteApplicationLog(),200);
        Test.stopTest();
        
        // Verify that the records were deleted
        Integer recordCount = [SELECT COUNT() FROM Application_Log__c WHERE Custom_Age_Days__c=true];
        System.assertEquals(0, recordCount);
    }
}