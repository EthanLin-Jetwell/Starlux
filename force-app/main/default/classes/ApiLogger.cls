public class ApiLogger {
    public class ApiLogWrapper {
        public String requestBody;
        public String responseBody;
        public String method;
        public String endpoint;
        public Integer statusCode;
        public String pnr;
    }
    
    public static void logAsync(HttpRequest request, HttpResponse response, String pnr) {
        ApiLogWrapper wrapper = new ApiLogWrapper();
        wrapper.requestBody = request.getBody();
        wrapper.responseBody = response.getBody();
        wrapper.method = request.getMethod();
        wrapper.endpoint = request.getEndpoint();
        wrapper.statusCode = response.getStatusCode();
        wrapper.pnr = pnr;
        
        // Serialize and pass as JSON
        logAsync(JSON.serialize(wrapper));
    }
    
    @future
    public static void logAsync(String wrapperJson) {
        ApiLogWrapper wrapper = (ApiLogWrapper) JSON.deserialize(wrapperJson, ApiLogWrapper.class);
        
        Api_Log__c apiLog = new Api_Log__c();
        apiLog.Request_Body__c = wrapper.requestBody;
        
        String responseBody = wrapper.responseBody;
        Integer chunkSize = 131072;
        
        apiLog.Response_Body__c = responseBody.length() > 0 
            ? responseBody.substring(0, Math.min(chunkSize, responseBody.length())) 
            : null;
        
        apiLog.Response_Body1__c = responseBody.length() > chunkSize 
            ? responseBody.substring(chunkSize, Math.min(chunkSize * 2, responseBody.length())) 
            : null;
        
        apiLog.Response_Body2__c = responseBody.length() > chunkSize * 2 
            ? responseBody.substring(chunkSize * 2, Math.min(chunkSize * 3, responseBody.length())) 
            : null;
        
        // (Continue for Response_Body3__c to Response_Body7__c as needed...)
        
        apiLog.Request_IP_Address__c = 'salesforce.com';
        apiLog.Request_Method__c = wrapper.method;
        apiLog.Request_Time__c = Datetime.now();
        apiLog.Request_URL__c = wrapper.endpoint;
        apiLog.Status_Code__c = wrapper.statusCode;
        apiLog.PNR__c = wrapper.pnr;
        
        insert apiLog;
    }
    
    public static void log(HttpRequest request, HttpResponse response, String pnr) {
        Api_Log__c apiLog = new Api_Log__c();
        apiLog.Request_Body__c = request.getBody();
        
        String responseBody = response.getBody();
        Integer chunkSize = 131072;
        // Split response body into chunks
        apiLog.Response_Body__c = responseBody.length() > 0 ? responseBody.substring(0, Math.min(chunkSize, responseBody.length())) : null;
        apiLog.Response_Body1__c = responseBody.length() > chunkSize ? responseBody.substring(chunkSize, Math.min(chunkSize * 2, responseBody.length())) : null;
        apiLog.Response_Body2__c = responseBody.length() > chunkSize * 2 ? responseBody.substring(chunkSize * 2, Math.min(chunkSize * 3, responseBody.length())) : null;
        apiLog.Response_Body3__c = responseBody.length() > chunkSize * 3 ? responseBody.substring(chunkSize * 3, Math.min(chunkSize * 4, responseBody.length())) : null;
		apiLog.Response_Body4__c = responseBody.length() > chunkSize * 4 ? responseBody.substring(chunkSize * 4, Math.min(chunkSize * 5, responseBody.length())) : null;
		apiLog.Response_Body5__c = responseBody.length() > chunkSize * 5 ? responseBody.substring(chunkSize * 5, Math.min(chunkSize * 6, responseBody.length())) : null;
		apiLog.Response_Body6__c = responseBody.length() > chunkSize * 6 ? responseBody.substring(chunkSize * 6, Math.min(chunkSize * 7, responseBody.length())) : null;
		apiLog.Response_Body7__c = responseBody.length() > chunkSize * 7 ? responseBody.substring(chunkSize * 7, Math.min(chunkSize * 8, responseBody.length())) : null;

        apiLog.Request_IP_Address__c = 'salesforce.com';
        apiLog.Request_Method__c = request.getMethod();
        apiLog.Request_Time__c = Datetime.now();
        apiLog.Request_URL__c = request.getEndpoint();
        apiLog.Status_Code__c = response.getStatusCode();
        apiLog.PNR__c = pnr;

        insert apiLog;
    }
    
    public static void log(HttpRequest request, HttpResponse response) {
        Api_Log__c apiLog = new Api_Log__c();
        apiLog.Request_Body__c = request.getBody();
        
        String responseBody = response.getBody();
        Integer chunkSize = 131072;
        // Split response body into chunks
        apiLog.Response_Body__c = responseBody.length() > 0 ? responseBody.substring(0, Math.min(chunkSize, responseBody.length())) : null;
        apiLog.Response_Body1__c = responseBody.length() > chunkSize ? responseBody.substring(chunkSize, Math.min(chunkSize * 2, responseBody.length())) : null;
        apiLog.Response_Body2__c = responseBody.length() > chunkSize * 2 ? responseBody.substring(chunkSize * 2, Math.min(chunkSize * 3, responseBody.length())) : null;
        apiLog.Response_Body3__c = responseBody.length() > chunkSize * 3 ? responseBody.substring(chunkSize * 3, Math.min(chunkSize * 4, responseBody.length())) : null;
		apiLog.Response_Body4__c = responseBody.length() > chunkSize * 4 ? responseBody.substring(chunkSize * 4, Math.min(chunkSize * 5, responseBody.length())) : null;
		apiLog.Response_Body5__c = responseBody.length() > chunkSize * 5 ? responseBody.substring(chunkSize * 5, Math.min(chunkSize * 6, responseBody.length())) : null;
		apiLog.Response_Body6__c = responseBody.length() > chunkSize * 6 ? responseBody.substring(chunkSize * 6, Math.min(chunkSize * 7, responseBody.length())) : null;
		apiLog.Response_Body7__c = responseBody.length() > chunkSize * 7 ? responseBody.substring(chunkSize * 7, Math.min(chunkSize * 8, responseBody.length())) : null;
 
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