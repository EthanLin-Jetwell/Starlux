@isTest
public class LuckyDraw_Test {
    @testSetup 
    static void setup() {
        Lucky_Draw_Setting__c luckyDraw = new Lucky_Draw_Setting__c();
        INSERT luckyDraw;
        Customer_Satisfaction_Surveys__c survey1 = new Customer_Satisfaction_Surveys__c();
        survey1.Drawing_No__c = luckyDraw.Id;
        survey1.Survey_Type__c = 'Ticket buying experience';
        survey1.Booking_class__c = 'Aaron';
        survey1.Survey_Completed__c = true;
        INSERT survey1;
        
        Customer_Satisfaction_Surveys__c survey2 = new Customer_Satisfaction_Surveys__c();
        survey2.Drawing_No__c = luckyDraw.Id;
        survey2.Survey_Type__c = 'Flight experience';
        survey2.Booking_class__c = 'Aaron';
        survey2.Survey_Completed__c = true;
        INSERT survey2;
        
        Prize__c prize1 = new Prize__c();
        prize1.Type__c = 'Ticket buying experience';
        prize1.Prize_Amount__c = 1;
        prize1.Name = 'Aaron';
        prize1.Prize_Name__c = 'Aaron';
        prize1.Unit__c = 'cm';
        prize1.Drawing_No__c = luckyDraw.Id;
        INSERT prize1;
        
        Prize__c prize2 = new Prize__c();
        prize2.Type__c = 'Flight experience';
        prize2.Prize_Amount__c = 1;
        prize2.Name = 'Aaron';
        prize2.Prize_Name__c = 'Aaron';
        prize2.Unit__c = 'cm';
        prize2.Drawing_No__c = luckyDraw.Id;
        INSERT prize2;
    }
    
    public static testMethod void luckyDraw_test() {
        Test.startTest();
		Lucky_Draw_Setting__c luckyDraw = [SELECT Id, Draw_Date__c FROM Lucky_Draw_Setting__c LIMIT 1];
        luckyDraw.Draw_Date__c = Date.today();
        UPDATE luckyDraw;
        Test.stopTest();
    }
    
    public static testMethod void luckyDrawController_test() {
        Lucky_Draw_Setting__c luckyDraw = [SELECT Id, Draw_Date__c FROM Lucky_Draw_Setting__c LIMIT 1];
        luckyDraw.Draw_Date__c = Date.today();
        UPDATE luckyDraw;
        List<Customer_Satisfaction_Surveys__c> participants = [SELECT Id, Lucky_No__c, Lucky_No_Ticket__c, Lucky_No_Flight__c, Draw__c, Survey_Type__c FROM Customer_Satisfaction_Surveys__c WHERE Drawing_No__c =: luckyDraw.Id AND Survey_Completed__c = true];
        Integer luckyNumber = 0;
        Integer luckyNumber_TICKET = 0;
        Integer luckyNumber_FLIGHT = 0;
        for(Customer_Satisfaction_Surveys__c participant : participants) {
            if(participant.Survey_Type__c == 'Ticket buying experience') {
                participant.Lucky_No_Ticket__c = luckyNumber_TICKET;
                luckyNumber_TICKET++;
            } else if(participant.Survey_Type__c == 'Flight experience') {
                participant.Lucky_No_Flight__c = luckyNumber_FLIGHT;
                luckyNumber_FLIGHT++;
            }
            participant.Lucky_No__c = luckyNumber;
            luckyNumber++;
        }
        UPDATE participants;
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(luckyDraw);
        LuckyDrawController  obj = new LuckyDrawController(sc);
		obj.draw();
        obj.save();
        obj.cancel();
        Test.stopTest();
    }
}