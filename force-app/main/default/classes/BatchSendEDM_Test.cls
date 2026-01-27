@isTest
public class BatchSendEDM_Test {
    @testSetup
    static void initTestData() 
    {
        Date today = Date.today();

        Customer_Satisfaction_Surveys__c C1 = new Customer_Satisfaction_Surveys__c();
        C1.Survey_Type__c = 'Ticket buying experience';
        C1.Date_of_Birth__c = Date.newInstance(2000, 10, 18);
        C1.Booking_class__c = 'J';
        C1.Ticket_buying_date__c = today.addDays(-5);
        C1.Departing_Date__c = today.addDays(-5);
        C1.Departing_Flight_Number__c = 'aa';
        C1.Email_Address__c = 'ethan1688.lin@gmail.com';
        insert C1;

        Customer_Satisfaction_Surveys__c C2 = new Customer_Satisfaction_Surveys__c();
        C2.Survey_Type__c = 'Ticket buying experience';
        C2.Date_of_Birth__c = Date.newInstance(2000, 10, 18);
        C2.Booking_class__c = 'Y';
        C2.Ticket_buying_date__c = today.addDays(-5);
        C2.Departing_Date__c = today.addDays(-5);
        C2.Departing_Flight_Number__c = 'aa';
        C2.Email_Address__c = 'ethan1688.lin@gmail.com';
        insert C2;

        Customer_Satisfaction_Surveys__c C3 = new Customer_Satisfaction_Surveys__c();
        C3.Survey_Type__c = 'Flight experience';
        C3.Date_of_Birth__c = Date.newInstance(2000, 10, 18);
        C3.Booking_class__c = 'J';
        C3.Ticket_buying_date__c = today.addDays(-5);
        C3.Departing_Date__c = today.addDays(-5);
        C3.Departing_Flight_Number__c = 'aa';
        C3.Email_Address__c = 'ethan1688.lin@gmail.com';
        insert C3;

        Customer_Satisfaction_Surveys__c C4 = new Customer_Satisfaction_Surveys__c();
        C4.Survey_Type__c = 'Flight experience';
        C4.Date_of_Birth__c = Date.newInstance(2000, 10, 18);
        C4.Booking_class__c = 'Y';
        C4.Ticket_buying_date__c = today.addDays(-5);
        C4.Departing_Date__c = today.addDays(-5);
        C4.Departing_Flight_Number__c = 'aa';
        C4.Email_Address__c = 'ethan1688.lin@gmail.com';
        insert C4;

        Survey_URL__c S1 = new Survey_URL__c();
        S1.Name = 'Hello';
        S1.Used__c = false;
        S1.Survey_Type__c = 'Ticket buying experience';
        S1.Link__c = 'Hello';
        S1.Unique_Expired_Date__c = today.addDays(100);
        insert S1;

        Survey_URL__c S2 = new Survey_URL__c();
        S2.Name = 'Hello2';
        S2.Used__c = false;
        S2.Survey_Type__c = 'Flight experience';
        S2.Link__c = 'Hello2';
        S2.Unique_Expired_Date__c = today.addDays(100);
        insert S2;

        Survey_URL__c S3 = new Survey_URL__c();
        S3.Name = 'Hello3';
        S3.Used__c = false;
        S3.Survey_Type__c = 'Flight experience';
        S3.Link__c = 'Hello3';
        S3.Unique_Expired_Date__c = today.addDays(100);
        insert S3;

        Survey_URL__c S4 = new Survey_URL__c();
        S4.Name = 'Hello4';
        S4.Used__c = false;
        S4.Survey_Type__c = 'Ticket buying experience';
        S4.Link__c = 'Hello4';
        S4.Unique_Expired_Date__c = today.addDays(100);
        insert S4;

        Survey_URL__c S5 = new Survey_URL__c();
        S5.Name = 'Hello5';
        S5.Used__c = false;
        S5.Survey_Type__c = 'Ticket buying experience';
        S5.Link__c = 'Hello5';
        S5.Unique_Expired_Date__c = today.addDays(100);
        insert S5;

        Survey_URL__c S6 = new Survey_URL__c();
        S6.Name = 'Hello6';
        S6.Used__c = false;
        S6.Survey_Type__c = 'Ticket buying experience';
        S6.Link__c = 'Hello6';
        S6.Unique_Expired_Date__c = today.addDays(100);
        insert S6;

        Survey_URL__c S7 = new Survey_URL__c();
        S7.Name = 'Hello7';
        S7.Used__c = false;
        S7.Survey_Type__c = 'Ticket buying experience';
        S7.Link__c = 'Hello7';
        S7.Unique_Expired_Date__c = today.addDays(100);
        insert S7;

        Lucky_Draw_Setting__c L = new Lucky_Draw_Setting__c();
        L.Drawing_Start_Date__c = today.addDays(-10);
        L.Drawing_End_Date__c = today.addDays(10);
        L.First_Class_Delivery_Rate__c = 100;
        L.Other_Delivery_Rate__c = 100;
        insert L;

        Flight_Survey_Setting__c F = new Flight_Survey_Setting__c();
        F.LuckyDrawSettingID__c = L.Id;
        F.Name = 'aa';
        F.Departing_Filght_Number_Rate__c = 100;
        insert F;
    }
    
    static testMethod void test1() 
    {
        Test.StartTest();
        
        SchedulableContext sc = null;
        ScheduleSendSurveyEDM sss = new ScheduleSendSurveyEDM();
        sss.execute(sc);
        
        BatchSendEDM batch = new BatchSendEDM();
        Database.executeBatch(batch);
        
        Test.StopTest();
    }
}