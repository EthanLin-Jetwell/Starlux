@isTest(SeeAllData=false)
public class Chatbot_Test {
    public static testMethod Void testAll() {
        Chatbot_CalloutClass.fakeMethod();
        APT_RestAPI.fakeMethod();
        CaseTriggerHandler.fakeMethod();
        Chatbot_Chat.fakeMethod();
        Schedule_EndCalls.fakeMethod();
        ResponseResultModel.fakeMethod();
        ApexSpecial_Case.fakeMethod();
        Chatbot_Chat_For_S.fakeMethod();
        ApexCase.fakeMethod();
        Chatbot_Home.fakeMethod();
        Chatbot_Individual.fakeMethod();
        Chatbot_KM.fakeMethod();
        Chatbot_Message.fakeMethod();
    }
    
    public static testMethod Void testTrigger() {
        Case c = new Case();
        insert c;
        Work_Hour__c w = new Work_Hour__c();
        w.Start_Time__c = System.now().time();
        w.End_Time__c = System.now().time();
        insert w;
    }
}