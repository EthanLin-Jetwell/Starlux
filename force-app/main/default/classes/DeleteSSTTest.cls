@isTest (SeeAllData=true)
private class DeleteSSTTest {

    @isTest static void testDeleteSST() {
		//Date thisDate = Date.today();
        //Id caseRecord = [SELECT Id,ContactId,Departing_Flight_Date__c FROM Case where Status = 'Ticket Issued' AND Departing_Flight_Date__c < 2024-05-28 Limit 1].Id;
		Id newCaseId = createNewCase();        
        //List<Seat_Sales_Tracking__c> testRecords = new List<Seat_Sales_Tracking__c>();
        //for(Integer i=0; i<2; i++) {
           //testRecords.add(new Seat_Sales_Tracking__c(Case_ID__c = caseRecord));
        //}
        //insert testRecords;

        // Call the batch class
        Test.startTest();
        Database.executeBatch(new DeleteSST(),200);
        Test.stopTest();
        
    }
    
    private static Id createNewCase(){

        Id accountRT = [SELECT Id FROM RecordType WHERE Name = 'Travel Agency' ].Id;
        Id accountId = [SELECT Id FROM Account WHERE RecordTypeId =: accountRT LIMIT 1].Id;
        Id contactId = [SELECT Id FROM Contact WHERE AccountId =: accountId LIMIT 1].Id;
        Id caseRT = [SELECT Id FROM RecordType WHERE Name = 'Group Booking'].Id;
        
        Case testCase = new Case();
        testCase.AccountId = accountId;
        testCase.ContactId = contactId;
        testCase.RecordTypeId = caseRT;
        testCase.Departing_Flight_Number__c = 'JX701';
        testCase.Returning_Flight_Number__c = 'JX702';
        testCase.Departing_Flight_Date__c = Date.today().addDays(-14);
        testCase.Departing_Flight_Arrival_Date__c = Date.today().addDays(-14);
        testCase.Returning_Flight_Date__c = Date.today().addDays(-7);
        testCase.Returning_Flight_Arrival_Date__c = Date.today().addDays(-7);
        testCase.Route__c = 'TPE-DAD-TPE';
        testCase.Status = 'Ticket Issued';
        Insert testCase;
        return testCase.Id;
    }

}