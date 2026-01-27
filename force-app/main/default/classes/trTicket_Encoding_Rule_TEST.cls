@isTest 
public without sharing class trTicket_Encoding_Rule_TEST {
    static testmethod void trTicket_Encoding_Rule_TEST1(){
        Ticket_Encoding_Rule__c TER = new Ticket_Encoding_Rule__c();
        TER.Type__c = 'CPN';
        TER.Country__c = 'TW';
        TER.Year__c = 23;
        TER.Batch__c = 'A';
        TER.Start_No__c = '001';
        TER.End_No__c = '003';
        TER.Start_Check_Code__c = '01';
        TER.End_Check_Code__c = '02';
        TER.RecordTypeId = Schema.getGlobalDescribe().get('Ticket_Encoding_Rule__c').getDescribe().getRecordTypeInfosByName().get('Certificate No').getRecordTypeId();
        Insert TER;
    }
    static testmethod void trTicket_Encoding_Rule_TEST2(){
        Ticket_Encoding_Rule__c TER2 = new Ticket_Encoding_Rule__c();
        TER2.Code__c = 'CPN';
        TER2.Department__c = 'TW';
        TER2.Year__c = 23;
        TER2.Start_No__c = '996';
        TER2.RecordTypeId = Schema.getGlobalDescribe().get('Ticket_Encoding_Rule__c').getDescribe().getRecordTypeInfosByName().get('Item No').getRecordTypeId();
        Insert TER2;
    }
    static testmethod void trTicket_Encoding_Rule_TEST3(){
        Ticket_Encoding_Rule__c TER3 = new Ticket_Encoding_Rule__c();
        TER3.Code__c = 'CPN';
        TER3.Year__c = 23;
        TER3.Start_No__c = '9996';
        TER3.RecordTypeId = Schema.getGlobalDescribe().get('Ticket_Encoding_Rule__c').getDescribe().getRecordTypeInfosByName().get('Coupon No').getRecordTypeId();
        Insert TER3;
    }
}