@IsTest class DupeDeleterTest {

    @IsTest static void test1(){
		Date systemToday = System.today()-2;
        Customer_Satisfaction_Surveys__c a = new Customer_Satisfaction_Surveys__c(Departing_Date__c = systemToday,Email_Address__c = 'test@test.com');
        Customer_Satisfaction_Surveys__c b = new Customer_Satisfaction_Surveys__c(Departing_Date__c = systemToday,Email_Address__c = 'test@test.com');
        Customer_Satisfaction_Surveys__c c = new Customer_Satisfaction_Surveys__c(Departing_Date__c = systemToday,Email_Address__c = 'test2@test.com');
        Customer_Satisfaction_Surveys__c d = new Customer_Satisfaction_Surveys__c(Departing_Date__c = systemToday,Email_Address__c = 'test2@test.com');
        Customer_Satisfaction_Surveys__c e = new Customer_Satisfaction_Surveys__c(Departing_Date__c = systemToday,Email_Address__c = 'test3@test.com');        
        insert a;
        insert b;
        insert c;
        insert d;
        insert e;

        Test.startTest();        DupeDeleter.deleteDupes();        Test.stopTest();

    }

}