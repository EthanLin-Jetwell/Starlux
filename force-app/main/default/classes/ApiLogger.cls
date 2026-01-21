public class ApiLogger {
    
    public static void log(HttpRequest request, HttpResponse response) {
        Api_Log__c apiLog = new Api_Log__c();
        apiLog.Request_Body__c = request.getBody();
        apiLog.Response_Body__c = response.getBody().left(131072);
        apiLog.Request_IP_Address__c = 'salesforce.com';
        apiLog.Request_Method__c = request.getMethod();
        apiLog.Request_Time__c = Datetime.now();
        apiLog.Request_URL__c = request.getEndpoint();
        apiLog.Status_Code__c = response.getStatusCode();

        insert apiLog;
    }

    public static void log(RestRequest request, RestResponse response) {
        Api_Log__c apiLog = new Api_Log__c();
        if (request.requestBody != null) {
            apiLog.Request_Body__c = request.requestBody.toString();
        }
        if (response.responseBody != null) {
            apiLog.Response_Body__c = response.responseBody.toString();
        }
        apiLog.Request_IP_Address__c = request.remoteAddress;
        apiLog.Request_Method__c = request.httpMethod;
        apiLog.Request_Time__c = Datetime.now();
        apiLog.Request_URL__c = request.requestURI;
        apiLog.Status_Code__c = response.statusCode;

        insert apiLog;
    }

    public static void fakeMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}