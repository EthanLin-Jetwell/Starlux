/*******************************************************************
Description: This is the test class for Utility class
*******************************************************************/
@isTest
private class Utilities_Test {
    @isTest
    private static void testGetAppSettings(){
        system.assertNotEquals(0, Utilities.getAppSettings().size());
    }
    
    @isTest
    private static void testGetLogLevel(){
        system.assertNotEquals(null, Utilities.getLogLevel('Application Log Purge Batch'));
    }

    @isTest
    private static void testMdtByKey(){
        system.assertNotEquals(null, Utilities.getAppSettingsMdtValueByKey('APPLICATION_NAME'));
    }
    
    /*
    @isTest
    private static void testqueueIdByName(){
        Utilities.getQueueIdByName('Error Handling Queue');
    }
	*/
    
    @isTest
    private static void testCreateApp(){
        Utilities.createApplicationLog('Error', 'Routing', 'testMethod', '500failedrecord-id', 'Routing', 'Test P Log', 'sample payload', 'Error Log', DateTime.now(), Utilities.getLogLevel('Application Log Purge Batch'), null);
    }
    
    @isTest
    private static void testGetLogSettings(){
        system.assertNotEquals(0, Utilities.getLogSettings('Application Log Purge Batch').size());
    }
}