public class ERCApiCallout {
    public static String getToken() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Label.ERC + '/api/Salesforce/GetToken');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        //request.setHeader('Authorization', 'Basic ' + myBase64String);
        
        // Wrap inside another Map
        Map<String, Object> jsonMap = new Map<String, Object>();
        jsonMap.put('username', Label.ERCUserName);
        jsonMap.put('password', Label.ERCPassword);
        String jsonBody = JSON.serialize(jsonMap);
        
        request.setBody(jsonBody);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if(response.getStatusCode() == 200)
        {
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeuntyped(response.getBody());
            System.debug(responseBody);
            return (String) responseBody.get('data');
        }
        
        return null;
    }
    
    @future(callout=true)
    public static void syncCaseData(Id mainCaseId) {
        Case mainCase = [SELECT Id, CaseNumber, Status, Accompany_Family_Case__c, Accompany_Family_Case__r.CaseNumber, NOK_Request_1__c, 
                         NOK_Request_2__c, NOK_Request_3__c, NOK_Request_4__c, NOK_Request_5__c, NOK_Request_6__c, Description, 
                         Primary_Contact_NOK_Title__c, Primary_Contact_NOK_Name__c,
                         Primary_Contact_Relationship__c, Primary_Contact_Preferred_Language__c, 
                         Primary_Contact_Phone__c, Primary_Contact_Web_Phone__c, Primary_Contact_Email__c,
                         Primary_Contact_Others__c, Secondary_Contact_NOK_Title__c, Secondary_Contact_NOK_Name__c,
                         Secondary_Contact_Relationship__c, Secondary_Contact_Preferred_Language__c, 
                         Secondary_Contact_Phone__c, Secondary_Contact_Web_Phone__c, Secondary_Contact_Email__c,
                         Secondary_Contact_Others__c
                         FROM Case WHERE Id = :mainCaseId LIMIT 1][0];
        String token = getToken();
        if(token != null) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Label.ERC + '/api/Salesforce/SyncSFData');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + token);
            System.debug(token);
            
            // Prepare RequestBody
            RequestBody req = new RequestBody();
            req.sfCaseID = mainCase.Id;
            req.caseNumber = mainCase.CaseNumber;
            //req.accompanyFamilyCase = mainCase.Accompany_Family_Case__c;
            req.accompanyFamilyCase = mainCase.Accompany_Family_Case__r.CaseNumber;
            req.caseStatus = mainCase.Status;
            
            req.nokData = new List<NokInfo>();
            
            NokInfo nok1 = new NokInfo();
            nok1.nokTitle = mainCase.Primary_Contact_NOK_Title__c;
            nok1.nokName = mainCase.Primary_Contact_NOK_Name__c;
            nok1.relationship = mainCase.Primary_Contact_Relationship__c;
            nok1.preferredLanguage = mainCase.Primary_Contact_Preferred_Language__c;
            nok1.phone = mainCase.Primary_Contact_Phone__c;
            nok1.webPhone = mainCase.Primary_Contact_Web_Phone__c;
            nok1.emailAddress = mainCase.Primary_Contact_Email__c;
            nok1.others = mainCase.Primary_Contact_Others__c;
            
            NokInfo nok2 = new NokInfo();
            nok2.nokTitle = mainCase.Secondary_Contact_NOK_Title__c;
            nok2.nokName = mainCase.Secondary_Contact_NOK_Name__c;
            nok2.relationship = mainCase.Secondary_Contact_Relationship__c;
            nok2.preferredLanguage = mainCase.Secondary_Contact_Preferred_Language__c;
            nok2.phone = mainCase.Secondary_Contact_Phone__c;
            nok2.webPhone = mainCase.Secondary_Contact_Web_Phone__c;
            nok2.emailAddress = mainCase.Secondary_Contact_Email__c;
            nok2.others = mainCase.Secondary_Contact_Others__c;
            
            req.nokData.add(nok1);
            req.nokData.add(nok2);
            
            req.paxCurrentCondition = mainCase.NOK_Request_1__c;
            req.confirmTheLocation = mainCase.NOK_Request_2__c;
            req.contactOtherFamily = mainCase.NOK_Request_3__c;
            req.requestTicketOrAccomm = mainCase.NOK_Request_4__c;
            req.toFACAccommHospOnSelf = mainCase.NOK_Request_5__c;
            req.otherSpecialRequest = mainCase.NOK_Request_6__c;
            req.description = mainCase.Description;
            
            // Serialize to JSON
            String jsonBody = JSON.serialize(req);
            
            
            request.setBody(jsonBody);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200)
            {
                System.debug('yeah');
                /*Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeuntyped(response.getBody());
System.debug(responseBody);
return (String) responseBody.get('Data');*/
            }
            System.debug(response.getStatusCode());
            System.debug(response.getBody());
            ApiLogger.log(request, response);  
            System.debug(jsonBody);
        }
    }
    
    public class NokInfo {
        public String nokTitle;
        public String nokName;
        public String relationship;
        public String preferredLanguage;
        public String phone;
        public String webPhone;
        public String emailAddress;
        public String others;
    }
    
    public class RequestBody {
        public String sfCaseID;
        public String caseNumber;
        public String accompanyFamilyCase;
        public String caseStatus;
        public List<NokInfo> nokData;
        public String paxCurrentCondition;
        public String confirmTheLocation;
        public String contactOtherFamily;
        public String requestTicketOrAccomm;
        public String toFACAccommHospOnSelf;
        public String otherSpecialRequest;
        public String description;
    }
}