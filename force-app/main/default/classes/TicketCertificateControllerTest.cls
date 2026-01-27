@isTest
private class TicketCertificateControllerTest {
	@isTest 
    private static void testMethod1() {
        External_Tickets__c externalTicket = new External_Tickets__c();
        insert externalTicket;
        
        Ticket_Certificate__c ticketCertificate = new Ticket_Certificate__c(Name ='Test', External_Tickets__c = externalTicket.Id);
        insert ticketCertificate;
        
        PageReference pageRef = Page.Ticket_BarterTickets_PDF;
        Test.setCurrentPage(pageRef);
        
        pageRef.getParameters().put('Id', String.valueOf(ticketCertificate.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(ticketCertificate);
        TicketCertificateController testController = new TicketCertificateController(sc);
        ApexPages.StandardController std = NULL;
	}
}