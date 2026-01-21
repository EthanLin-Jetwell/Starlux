@isTest
private class AaronTest {
    @isTest
    private static void testAll() {
        
        Ticket_Encoding_Rule__c ter1 = new Ticket_Encoding_Rule__c();
        ter1.Code__c = 'JX';
        ter1.Department__c = 'CRD';
        ter1.Year__c = 23;
        ter1.Start_No__c = '996';
        ter1.RecordTypeId = Schema.getGlobalDescribe().get('Ticket_Encoding_Rule__c').getDescribe().getRecordTypeInfosByName().get('Item No').getRecordTypeId();
        Insert ter1;
        
        Ticket_Encoding_Rule__c ter2 = new Ticket_Encoding_Rule__c();
        ter2.Code__c = 'JX';
        ter2.Department__c = 'CRD';
        ter2.Year__c = 23;
        ter2.Start_No__c = '1111';
        ter2.RecordTypeId = Schema.getGlobalDescribe().get('Ticket_Encoding_Rule__c').getDescribe().getRecordTypeInfosByName().get('Coupon No').getRecordTypeId();
        Insert ter2;
        
        Ticket_Encoding_Rule__c ter3 = new Ticket_Encoding_Rule__c();
        ter3.Code__c = 'JX';
        ter3.Department__c = 'CRD';
        ter3.Year__c = 23;
        ter3.Start_No__c = '1111';
        ter3.RecordTypeId = Schema.getGlobalDescribe().get('Ticket_Encoding_Rule__c').getDescribe().getRecordTypeInfosByName().get('Certificate No').getRecordTypeId();
        Insert ter3;
        
        System.debug([SELECT Id, Number__c, Type__c, Used__c, Invalid__c FROM Ticket_Encoding_Rule_Detail__c]);
        
        External_Tickets__c ex = new External_Tickets__c();
        ex.Office__c = 'PMDPSP';
        /*SObjectField picklistUsingGlobal = SObjectType.External_Tickets__c.fields.Itinerary_Return_CH__c.getSObjectField();
        List<PicklistEntry> entries = picklistUsingGlobal.getDescribe().getPicklistValues();*/
        ex.Itinerary_Departure_CH__c  = '台北，台灣';
        ex.Itinerary_Return_CH__c = '舊金山，美國';
        ex.Itinerary_Departure__c  = 'TPE';
        //ex.Itinerary_Return__c = '';
        insert ex;
        
        ex.Generated__c = true;
        update ex;
        
        TicketCertificateController.fakeMethod();
        Batch_trTicket_RandomString.fakeMethod();
        SingleCertCNController.fakeMethod();
        ExternalTicketTrigger_Handler.fakeMethod();
        SingleCertENController.fakeMethod();
        QRcodeScanController.fakeMethod();
        QRCodeController.fakeMethod();
        ExternalTicketsController.fakeMethod();
    }
}