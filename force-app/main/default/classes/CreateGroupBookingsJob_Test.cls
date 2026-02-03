/********************************************************************************************************
NAME:			CreateGroupBookingsJob_Test
AUTHOR:			Aik Meng (aikmeng@salesforce.com)
PURPOSE:		This is the test class for CreateGroupBookingsJob class

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
08/08/2019      Aik Meng		First version
********************************************************************************************************/

@isTest(SeeAllData=FALSE)
public class CreateGroupBookingsJob_Test {

    public static testMethod void testBatchJobScheduling() {

        // DEFINE cron expression
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute() + 1);
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        // INVOKE scheduler
        DateTime currentDateTime = Datetime.now();
        Test.StartTest();
        CreateGroupBookingsJob batchJob = new CreateGroupBookingsJob();
        System.schedule('CreateGroupBookingsJob ' + String.valueOf(currentDateTime), nextFireTime, batchJob);
        Test.stopTest();
        
        // making sure job scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, State, NextFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name = : 'CreateGroupBookingsJob ' + String.valueOf(currentDateTime)
        ];
        System.assertNotEquals(null, jobs);
        System.assertEquals(1, jobs.size());

    } // End - testBatchJobScheduling()

    public static testMethod void testBatchJobLogic() {

        // CREATE test record: Account type (Travel Agency)
		Id accountRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Travel_Agency').getRecordTypeId();
/*        Map<String,Object > accountValueMap = new Map<String,Object> ();
        accountValueMap.put('RecordTypeId', accountRecordTypeID);  // SPECIFY the record type for Travel Agency
        accountValueMap.put('Name', 'ABC Travel Agency');
        accountValueMap.put('IATA_MSO_Code__c', 'MSO123456');
        accountValueMap.put('Phone', '11111111');
//        TestUtility.createTravelAgency(accountValueMap);  */
        Account travelAgency = new Account(
            RecordTypeId=accountRecordTypeID,
            Name='ABC Travel Agency',
            IATA_MSO_Code__c='MSO123456',
            Cash_Payment_Only__c = TRUE
        );
        insert travelAgency;
        List<Account> thisAccount = [SELECT Id FROM Account];
        System.assertEquals(1, thisAccount.size());  // VERIFY record created
        
        // CREATE test record: Contact of Travel Agency
        Map<String,Object > contactValueMap = new Map<String,Object> ();
        contactValueMap.put('FirstName', 'Kate');
        contactValueMap.put('LastName', 'Tan');
        contactValueMap.put('AccountID', thisAccount[0].Id);  // Link Contact to Travel Agency
        contactValueMap.put('Email', 'kate.tan@test.com');
        contactValueMap.put('Phone', '12228888');
        TestUtility.createContact(contactValueMap);
        List<Contact> thisContact = [SELECT Id FROM Contact];
        System.assertEquals(1, thisContact.size());  // VERIFY record created
        
        // CREATE Source record: SeatAllocationByAgency (saba) 
        Map<String,Object> sabaFieldValueMap = new Map<String,Object> ();
        Date startDate = date.newinstance(2019,7,1);
        Date endDate = date.newinstance(2019,8,1);
        Boolean isMon=TRUE, isTue=FALSE, isWed=TRUE, isThu=FALSE, isFri=TRUE, isSat=FALSE, isSun=FALSE;
        sabaFieldValueMap.put('Departing_Flight_Number__c', 'TX122');
        sabaFieldValueMap.put('Returning_Flight_Number__c', 'TX123');
        sabaFieldValueMap.put('Start_Date__c', startDate);
        sabaFieldValueMap.put('End_Date__c', endDate);
        sabaFieldValueMap.put('Duration__c', 5);
        sabaFieldValueMap.put('Allocated_Seats__c', 50);
        sabaFieldValueMap.put('Allocation_Type__c', 'SRS');
		sabaFieldValueMap.put('Route__c', 'TPE-KIX-TPE');
        sabaFieldValueMap.put('Processed__c', FALSE);
        sabaFieldValueMap.put('WK_Mon__c', isMon);
        sabaFieldValueMap.put('WK_Tue__c', isTue);
        sabaFieldValueMap.put('WK_Wed__c', isWed);
        sabaFieldValueMap.put('WK_Thu__c', isThu);
        sabaFieldValueMap.put('WK_Fri__c', isFri);
        sabaFieldValueMap.put('WK_Sat__c', isSat);
        sabaFieldValueMap.put('WK_Sun__c', isSun);
        sabaFieldValueMap.put('Travel_Agency_ID__c', thisAccount[0].Id);
        sabaFieldValueMap.put('Travel_Agent_ID__c', thisContact[0].Id);
        //sabaFieldValueMap.put('Run__c', true);
        TestUtility.createSeatAllocationByAgency(sabaFieldValueMap);
        System.assertEquals(1, [SELECT Count() FROM Seat_Allocation_By_Agency__c WHERE Processed__c=FALSE]);  // VERIFY record created
        
        // EXECUTE batch job
        Test.startTest();
        Database.executeBatch(new CreateGroupBookingsJob(), 10);  // Batch size 10
        Test.stopTest();
        
        // VALIDATE outcome //

        List<Date> dateList = CreateGroupBookingsJob.generateDates(startDate, endDate, isMON, isTUE, isWED, isTHU, isFRI, isSAT, isSUN);
        Integer recordCount = dateList.size();  // Number of Dates generated => Target record counts
        System.assertEquals(14, recordCount);  // NOTE: manual count based on start date, end dates & dayOfWeek selection above
        
        // CHECK Source record is flagged as "processed"
        //System.assertEquals(1, [SELECT Count() FROM Seat_Allocation_By_Agency__c WHERE Processed__c=TRUE]);
        // CHECK Target parent & child records are created   
		Id recordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        List<Case> groupBookingCases = [SELECT Id FROM Case WHERE RecordTypeId=:recordTypeID];
        //System.assertEquals(recordCount, groupBookingCases.size());  // Should match the number of Dates generated
        Set<Id> caseIds = new Set<Id>();
        for (Case eachRecord: groupBookingCases) { caseIds.add(eachRecord.Id); }
        
    } // End - testBatchJobLogic()
    
}