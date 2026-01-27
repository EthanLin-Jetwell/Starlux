@isTest 
private class DeleteAPILogTest {

    @isTest static void testDeleteAPILog() {
        
		createAPILog();  
        // Call the batch class
        Test.startTest();
        Database.executeBatch(new DeleteAPILog(),200);
        Test.stopTest();
        
    }
    
    private static void createAPILog(){

        
        API_Log__c testAPILog = new API_Log__c();
        testAPILog.Request_Time__c = DateTime.newInstance(2023,1,1,1,0,0);
        Insert testAPILog;
        
    }

}