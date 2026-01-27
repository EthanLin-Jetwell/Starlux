/********************************************************************************************************
NAME:			AccountTriggerHandler_Test
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the test class for AccountTriggerHandler class

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
12/06/2019      Edmond To		First version
********************************************************************************************************/
@isTest
public class AccountTriggerHandler_Test {
    
    public static testMethod void testBeforeDeleteWithWorkingAccount() {
        
        //Create account record
        ID personAccountID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();
        Map<String, Object> accountFieldValueMap = new Map<String, Object>();
        accountFieldValueMap.put('RecordTypeId', personAccountID);
        TestUtility.createAccounts(accountFieldValueMap, 5);
        List<Sobject> testAccountList = TestUtility.getAccounts();
        
        //Create case record
        ID caseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Feedback').getRecordTypeId();
        for (Sobject acct : testAccountList) {
            Map<String, Object> caseFieldValueMap = new Map<String, Object>();
       	 	caseFieldValueMap.put('AccountId', acct.Id);
            caseFieldValueMap.put('RecordTypeID', caseRecordType);
        	TestUtility.createCase(caseFieldValueMap);
        }
        List<Sobject> testCaseList = [SELECT Id, AccountId FROM Case];
        
        /* Contact records can't be created for Person Accounts
        //Create contact record
        for (Sobject acct : testAccountList) {
            Map<String, Object> contactFieldValueMap = new Map<String, Object>();
        	contactFieldValueMap.put('AccountId', acct.Id);
        	TestUtility.createContact(contactFieldValueMap);
        }
        List<Sobject> testContactList = TestUtility.getContacts();
        */
        //Create task record
        for (Sobject acct : testAccountList) {
           	Map<String, Object> taskFieldValueMap = new Map<String, Object>();
        	taskFieldValueMap.put('WhatId', acct.Id);
        	TestUtility.createTask(taskFieldValueMap);
        }
        List<Sobject> testTaskList = TestUtility.getTasks();
        
        //Create email record
        for (Sobject cas : testCaseList) {
            Case c = (Case)cas;
           	Map<String, Object> emailFieldValueMap = new Map<String, Object>();
        	emailFieldValueMap.put('RelatedToId', c.AccountId);
            emailFieldValueMap.put('ParentId', c.Id);
        	TestUtility.createEmail(emailFieldValueMap);
        }
        List<Sobject> testEmailList = TestUtility.getEmails();
        
        //Create live chat transcript record
        for (Sobject acct : testAccountList) {
           	Map<String, Object> transcriptFieldValueMap = new Map<String, Object>();
        	transcriptFieldValueMap.put('AccountId', acct.Id);
        	TestUtility.createTranscript(transcriptFieldValueMap);
        }
        List<Sobject> testTranscriptList = TestUtility.getTranscripts();
        
        //Commence test
        Test.startTest();
        Database.DeleteResult[] deleteResult = database.delete(testAccountList);
        Test.stopTest();
        
        //Assert results
        for (Database.DeleteResult result : deleteResult) {
            system.assertEquals(True, result.isSuccess());
        }
        
        system.assertEquals(10, [SELECT Count() FROM Task WHERE IsDeleted = True ALL ROWS]); //Enhanced Email causes EmailMessage record creation to create a separate Task record
        system.assertEquals(5, [SELECT Count() FROM Case WHERE IsDeleted = True ALL ROWS]);
        system.assertEquals(5, [SELECT Count() FROM Contact WHERE IsDeleted = True ALL ROWS]);
        system.assertEquals(5, [SELECT Count() FROM LiveChatTranscript WHERE IsDeleted = True ALL ROWS]);  
        system.assertEquals(5, [SELECT Count() FROM EmailMessage WHERE IsDeleted = True ALL ROWS]);
    }

    public static testMethod void testBeforeDeleteWithNotWorkingAccount() {
        
        //Create account record
        TestUtility.createAccounts(5);
        List<Sobject> testAccountList = TestUtility.getAccounts();
        
        //Create case record
        for (Sobject acct : testAccountList) {
            Map<String, Object> caseFieldValueMap = new Map<String, Object>();
       	 	//caseFieldValueMap.put('AccountId', acct.Id);
        	TestUtility.createCase(caseFieldValueMap);
        }
        List<Sobject> testCaseList = [SELECT Id, AccountId FROM Case];
        system.debug('DBG TestCaseList: '+testCaseList);
        
        /* Contact records can't be created for Person Accounts
        //Create contact record
        for (Sobject acct : testAccountList) {
            Map<String, Object> contactFieldValueMap = new Map<String, Object>();
        	//contactFieldValueMap.put('AccountId', acct.Id);
        	TestUtility.createContact(contactFieldValueMap);
        }
        List<Sobject> testContactList = TestUtility.getContacts();
        */
        //Create task record
        for (Sobject acct : testAccountList) {
           	Map<String, Object> taskFieldValueMap = new Map<String, Object>();
        	//taskFieldValueMap.put('WhatId', acct.Id);
        	TestUtility.createTask(taskFieldValueMap);
        }
        List<Sobject> testTaskList = TestUtility.getTasks();
        
        //Create email record
        for (Sobject cas : testCaseList) {
            Case c = (Case)cas;
           	Map<String, Object> emailFieldValueMap = new Map<String, Object>();
        	emailFieldValueMap.put('RelatedToId', c.AccountId);
            emailFieldValueMap.put('ParentId', c.Id);
        	TestUtility.createEmail(emailFieldValueMap);
        }
        List<Sobject> testEmailList = TestUtility.getEmails();
        
        //Create live chat transcript record
        for (Sobject acct : testAccountList) {
           	Map<String, Object> transcriptFieldValueMap = new Map<String, Object>();
        	//transcriptFieldValueMap.put('AccountId', acct.Id);
        	TestUtility.createTranscript(transcriptFieldValueMap);
        }
        List<Sobject> testTranscriptList = TestUtility.getTranscripts();
        
        //Commence test
        Test.startTest();
        Database.DeleteResult[] deleteResult = database.delete(testAccountList);
        Test.stopTest();
        
        //Assert results
        for (Database.DeleteResult result : deleteResult) {
            system.assertEquals(True, result.isSuccess());
        }
        
        system.assertEquals(0, [SELECT Count() FROM Task WHERE IsDeleted = True ALL ROWS]);
        system.assertEquals(0, [SELECT Count() FROM Case WHERE IsDeleted = True ALL ROWS]);
        system.assertEquals(5, [SELECT Count() FROM Contact WHERE IsDeleted = True ALL ROWS]); //Person Account Deletion also causes the Contact record to be deleted regardless
        system.assertEquals(0, [SELECT Count() FROM LiveChatTranscript WHERE IsDeleted = True ALL ROWS]);  
        system.assertEquals(0, [SELECT Count() FROM EmailMessage WHERE IsDeleted = True ALL ROWS]);
    }
}