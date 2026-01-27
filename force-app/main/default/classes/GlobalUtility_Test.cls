/*******************************************************************
Description: This class is the test class for GlobalUtility Class
*******************************************************************/
@isTest(SeeAllData = false)
public class GlobalUtility_Test {
    
    static testMethod void testLogMessageWithWrapper() {
        // Create Wrapper Class
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        appLogWrapper.logLevel = 'Info';
        appLogWrapper.sourceClass = 'TestBatch';
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ';
        appLogWrapper.logMessage = 'Test Logss';
        appLogWrapper.applicationName = 'GlobalPurgeBatch';
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = DateTime.now();
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level
        appLogWrapper.isDebug = true;
        appLogWrapper.isInfo = true;
        appLogWrapper.isError = true;
        appLogWrapper.isWarning = true;
        Test.startTest();
        GlobalUtility.logMessage(appLogWrapper);
        
        
        List < Application_Log__c > appLogList = [Select Id From Application_Log__c];
        Test.stopTest();
        System.assertequals(1, appLogList.size());
    }
    
    static testMethod void testLogMsgWhenAllThreeFieldExceedsLimits() {
 		Test.startTest();
        // Create Wrapper Class
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        //Create App log
        appLogWrapper.logLevel = 'Info';
        appLogWrapper.sourceClass = 'TestBatch';
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ';
        appLogWrapper.logMessage = 'Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs';
        appLogWrapper.payLoad = 'Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs';
        appLogWrapper.exceptionThrown  = new DMLException('Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs');
        appLogWrapper.applicationName = 'GlobalPurgeBatch';
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = DateTime.now();
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level
        appLogWrapper.isDebug = true;
        appLogWrapper.isInfo = true;
        appLogWrapper.isError = true;
        appLogWrapper.isWarning = true;
        GlobalUtility.LONG_TXT_AREA_MAX_SIZE=20; 
        GlobalUtility.logMessage(appLogWrapper);        
        Test.stopTest(); 
        
        List < Application_Log__c > appLogList = [Select Id From Application_Log__c];
        System.assert(appLogList.size()>3);
    }
    
    static testMethod void testLogMsgWhenOnlyDescExceedsLimits() {
        // Create Wrapper Class
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        appLogWrapper.logLevel = 'Info';
        appLogWrapper.sourceClass = 'TestBatch';
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ';
        appLogWrapper.logMessage = 'Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs';
        appLogWrapper.payLoad = 'Test Logs Split123:';
        appLogWrapper.exceptionThrown  = new DMLException('Test Logs Split123:Test Logs Sp');
        appLogWrapper.applicationName = 'GlobalPurgeBatch';
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = DateTime.now();
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level
        appLogWrapper.isDebug = true;
        appLogWrapper.isInfo = true;
        appLogWrapper.isError = true;
        appLogWrapper.isWarning = true;
        Test.startTest();
        GlobalUtility.LONG_TXT_AREA_MAX_SIZE=20; 
        GlobalUtility.logMessage(appLogWrapper);
        Test.stopTest();
        
        List < Application_Log__c > appLogList = [Select Id From Application_Log__c];
        System.assertequals(math.floor(appLogWrapper.logMessage.length()/20) + 1, appLogList.size());        
    }
    
    
    static testMethod void testLogMsgWhenOnlyPayloadExceedsLimits() {
        // Create Wrapper Class
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        appLogWrapper.logLevel = 'Info';
        appLogWrapper.sourceClass = 'TestBatch';
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ';
        appLogWrapper.logMessage = 'Test Logs Split123';
        appLogWrapper.payLoad = 'Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs';
        appLogWrapper.exceptionThrown  = new DMLException('Test Logs Split123:Test Logs Sp');
        appLogWrapper.applicationName = 'GlobalPurgeBatch';
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = DateTime.now();
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level
        appLogWrapper.isDebug = true;
        appLogWrapper.isInfo = true;
        appLogWrapper.isError = true;
        appLogWrapper.isWarning = true;
        Test.startTest();
        GlobalUtility.LONG_TXT_AREA_MAX_SIZE=20; 
        GlobalUtility.logMessage(appLogWrapper);
        Test.stopTest();
        
        List < Application_Log__c > appLogList = [Select Id From Application_Log__c];
        System.assertequals(math.floor(appLogWrapper.Payload.length()/20) + 1, appLogList.size());
        
    }
    
    static testMethod void testLogMsgWhenOnlyStacktraceExceedsLimits() {
        // Create Wrapper Class
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        appLogWrapper.logLevel = 'Info';
        appLogWrapper.sourceClass = 'TestBatch';
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ';
        appLogWrapper.logMessage = 'Test Logs Split';
        appLogWrapper.payLoad = 'Test Logs Split';
        appLogWrapper.exceptionThrown  = new DMLException('Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Test Logs Split123:Te');
        appLogWrapper.applicationName = 'GlobalPurgeBatch';
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = DateTime.now();
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level
        appLogWrapper.isDebug = true;
        appLogWrapper.isInfo = true;
        appLogWrapper.isError = true;
        appLogWrapper.isWarning = true;
        Test.startTest();
        GlobalUtility.LONG_TXT_AREA_MAX_SIZE=20; 
        GlobalUtility.logMessage(appLogWrapper);
        Test.stopTest();
        
        List < Application_Log__c > appLogList = [Select Id From Application_Log__c];
        System.assert(appLogList.size()>1);        
    }
    
    
    static testMethod void testLogMsgWhenAllThreeWithMaxLimits() {
        // Create Wrapper Class
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        appLogWrapper.logLevel = 'Info';
        appLogWrapper.sourceClass = 'TestBatch';
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ';
        appLogWrapper.logMessage = 'Test Logs Split12345';
        appLogWrapper.payLoad = 'Test Logs Split12345';
        appLogWrapper.exceptionThrown  = new DMLException('Test Logs Split12345');
        appLogWrapper.applicationName = 'GlobalPurgeBatch';
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = DateTime.now();
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level
        appLogWrapper.isDebug = true;
        appLogWrapper.isInfo = true;
        appLogWrapper.isError = true;
        appLogWrapper.isWarning = true;
        Test.startTest();
        GlobalUtility.LONG_TXT_AREA_MAX_SIZE=20; 
        GlobalUtility.logMessage(appLogWrapper);
        Test.stopTest();
        List < Application_Log__c > appLogList = [Select Id From Application_Log__c];
        // Stack trace Will be : Class.GlobalUtility_Test.testLogMsgWhenAllThreeWithMaxLimits: line 168, column 1
        System.assert(appLogList.size()>1);
    }
    
    static testMethod void testLogMsgWhenMaxLimits() {
        // Create Wrapper Class
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        appLogWrapper.logLevel = 'Info';
        appLogWrapper.sourceClass = 'TestBatch';
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ';
        appLogWrapper.logMessage = 'Test Logs Split12345';
        appLogWrapper.payLoad = 'Test Logs Split12345';
        appLogWrapper.exceptionThrown  = null;
        appLogWrapper.applicationName = 'GlobalPurgeBatch';
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = DateTime.now();
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level
        appLogWrapper.isDebug = true;
        appLogWrapper.isInfo = true;
        appLogWrapper.isError = true;
        appLogWrapper.isWarning = true;
        Test.startTest();
        GlobalUtility.LONG_TXT_AREA_MAX_SIZE=20; 
        GlobalUtility.logMessage(appLogWrapper);
        Test.stopTest();
        List < Application_Log__c > appLogList = [Select Id From Application_Log__c];
        System.assertequals(1, appLogList.size());
    }
    
    
    static testMethod void testLogMessageWithWrapperList() {
        List < ApplicationLogWrapper > appLogList = new List < ApplicationLogWrapper > ();
        for (Integer i = 0; i < 8; i++) {
            // Create Wrapper Class
            ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
            if (i <= 1) {
                appLogWrapper.logLevel = 'Debug';
            }
            
            if (i >= 1 && i <= 3) {
                appLogWrapper.logLevel = 'Info';
            }
            
            if (i > 3 && i <= 5) {
                appLogWrapper.logLevel = 'Warning';
            }
            
            if (i > 5 && i <= 7) {
                appLogWrapper.logLevel = 'Error';
            }
            
            appLogWrapper.sourceClass = 'TestBatch' + i;
            appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
            appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ' + i;
            appLogWrapper.logMessage = 'Test Logss';
            appLogWrapper.applicationName = 'GlobalPurgeBatch';
            appLogWrapper.exceptionThrown = null;
            appLogWrapper.startDate = DateTime.now();
            appLogWrapper.endDate = DateTime.now();
            appLogWrapper.type = 'Job Log';
            
            // Set Log Level
            appLogWrapper.isDebug = true;
            appLogWrapper.isInfo = true;
            appLogWrapper.isError = true;
            appLogWrapper.isWarning = true;
            
            appLogList.add(appLogWrapper);
        }
        Test.startTest();
        GlobalUtility.logMessage(appLogList);
        Test.stopTest();
        
        List < Application_Log__c > appLogsList = [Select Id From Application_Log__c];
        System.assertequals(8, appLogsList.size());
        
    } //End testLogMessageWithWrapperList
    
    static testMethod void testisLogMessageWithNArgs() {
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        appLogWrapper.logLevel = 'Info';
        appLogWrapper.sourceClass = 'TestBatch';
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ';
        appLogWrapper.logMessage = 'Test Logss';
        appLogWrapper.applicationName = 'GlobalPurgeBatch';
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = DateTime.now();
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level true
        appLogWrapper.isDebug = true;
        appLogWrapper.isInfo = true;
        appLogWrapper.isError = true;
        appLogWrapper.isWarning = true;
        
        Test.startTest();
        GlobalUtility.logMessage('Info', 'TestBatch', 'finish(Database.BatchableContext bc)',
                                 'RefId', 'Apex Batch: Job Id: ', 'Test Logss', 'GlobalPurgeBatch', 'PayLoad', null,
                                 DateTime.now(), DateTime.now(), 'Job Log', true, true, true, true);
        
        List < Application_Log__c > appLogsList = [Select Id From Application_Log__c];
        System.assertequals(1, appLogsList.size());
        Test.stopTest();
        
    } //End testisLogMessageWithNArgs
    
    static testMethod void testisLoggingEnabledWithWrapper() {
        ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
        appLogWrapper.logLevel = 'Info';
        appLogWrapper.sourceClass = 'TestBatch';
        appLogWrapper.sourceFunction = 'finish(Database.BatchableContext bc)';
        appLogWrapper.referenceInfo = 'Apex Batch: Job Id: ';
        appLogWrapper.logMessage = 'Test Logss';
        appLogWrapper.applicationName = 'GlobalPurgeBatch';
        appLogWrapper.exceptionThrown = null;
        appLogWrapper.startDate = DateTime.now();
        appLogWrapper.endDate = DateTime.now();
        appLogWrapper.type = 'Job Log';
        
        // Set Log Level true
        appLogWrapper.isDebug = true;
        appLogWrapper.isInfo = true;
        appLogWrapper.isError = true;
        appLogWrapper.isWarning = true;
        
        Boolean isEnabled = GlobalUtility.isLoggingEnabled(appLogWrapper);
        System.assertequals(true, isEnabled);
        
        // Set Log Level false
        appLogWrapper.isDebug = false;
        appLogWrapper.isInfo = false;
        appLogWrapper.isError = false;
        appLogWrapper.isWarning = false;
        
        isEnabled = GlobalUtility.isLoggingEnabled(appLogWrapper);
        System.assertequals(false, isEnabled);
    } //End testisLoggingEnabledWithWrapper
    
    static testMethod void testisLoggingEnabledWithNArgs() {
        Boolean isEnabled = GlobalUtility.isLoggingEnabled('Info', true, true, true, true);
        System.assertequals(true, isEnabled);
        
        isEnabled = GlobalUtility.isLoggingEnabled('Info', false, false, false, false);
        System.assertequals(false, isEnabled);
    } //End testisLoggingEnabledWithNArgs
    
} //    END GlobalUtility_Test