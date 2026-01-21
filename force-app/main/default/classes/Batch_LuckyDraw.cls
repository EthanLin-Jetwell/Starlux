public class Batch_LuckyDraw implements Database.Batchable<sObject>, Database.Stateful{
    public Id recordId {set;get;}
    public final String mode {set;get;}
    public Integer luckyNumber = 0;
    public Integer luckyNumber_TICKET = 0;
    public Integer luckyNumber_FLIGHT = 0;

    public Batch_LuckyDraw(Id recordId, String mode)
    {
        this.recordId = recordId;
        this.mode = mode;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) { 
        Lucky_Draw_Setting__c record = [SELECT Id, Draw_Date__c FROM Lucky_Draw_Setting__c WHERE Id =: recordId LIMIT 1];
        if(record.Draw_Date__c < Date.today()) {
            return NULL;
        }
        return Database.getQueryLocator([SELECT Id, Lucky_No__c, Lucky_No_Ticket__c, Lucky_No_Flight__c, Draw__c, Survey_Type__c FROM Customer_Satisfaction_Surveys__c WHERE Drawing_No__c =: recordId AND Survey_Completed__c = true]);
    }

    public void execute(Database.BatchableContext bc, List<Customer_Satisfaction_Surveys__c> participants) {
        if(mode == 'assign') {
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
        } else if(mode == 'save') {
            for(Customer_Satisfaction_Surveys__c participant : participants) {
                participant.Draw__c = true;
            }
        } else if(mode == 'unsave') {
            for(Customer_Satisfaction_Surveys__c participant : participants) {
                participant.Draw__c = false;
            }
        }
        UPDATE participants;
    }

    public void finish(Database.BatchableContext bc) { 
		System.debug(luckyNumber);
    }
}