public class GetPurchaseInvocableMethod {
    @InvocableMethod(label='Get Purchase') 
    public static void getPurchase(List<Id> recordIds) {
        List<Case> cases = [SELECT Id, Account.Name, Account.Business_Number__c, (SELECT Id, Booking_Reference_PNR__c FROM Group_Bookings__r WHERE Allocation_Type__c IN ('SRS', 'ADC') AND Final_Allocated_Seats__c > 0) FROM Case WHERE Id IN :recordIds];
        Set<String> pnrs = new Set<String>();
        for (Seat_Allocation_and_Ticketing__c sat : cases[0].Group_Bookings__r) {
            pnrs.add(sat.Booking_Reference_PNR__c);
        }

        String jsonString = JSON.serialize(new Map<String, Object>{
            'caseId' => cases[0].Id,
                'pnr' => pnrs,
                    'accountName' => cases[0].Account.Name,
                    'businessNumber' => cases[0].Account.Business_Number__c
                    });
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://ecapi-uat.starlux-airlines.com/ctfs/v2/group-certification');
        req.setMethod('POST');
        req.setHeader('Authorization', 'App 177ae8fa48fc5a23674f376161a649e1-2abe7a43-91e9-436a-b69a-7d651c034d9b');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(120000);
        req.setBody(jsonString);
        
        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Status: ' + res.getStatus());
        System.debug('Status Code: ' + res.getStatusCode());
        System.debug('Response Body: ' + res.getBody());
        
        GetPurchaseResponseWrapper parsed = (GetPurchaseResponseWrapper) JSON.deserialize(res.getBody(), GetPurchaseResponseWrapper.class);
        
        Case c = new Case(Id=cases[0].Id);
        if (parsed.message.code == '00000') {
            c.Get_Purchase_Status__c = 'Succeeded';
        } else {
            c.Get_Purchase_Status__c = 'Failed';
        }
        c.Get_Purchase_Error_Message__c = parsed.message.content;
        
        update c;
        
        ApiLogger.log(req, res);
    }
}