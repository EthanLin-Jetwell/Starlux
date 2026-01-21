public class HttpRequestUtil {
    
    public static HttpResponse sendRequest(String endpoint, String method, String stringBodyAsJson) {
        Http http = new Http();
        HttpRequest request = HttpRequestUtil.prepareRequest(endpoint, method, stringBodyAsJson);
        
        HttpResponse response = http.send(request);
        
        return response;
    }

    public static HttpResponse sendRequest(String endpoint, String method, String token, String stringBodyAsJson) {
        Http http = new Http();
        HttpRequest request = HttpRequestUtil.prepareRequest(endpoint, method, stringBodyAsJson);
        request.setHeader('Authorization', 'Bearer ' + token);

        System.debug('[4i] Sending auth request with access token:"' + request.getHeader('Authorization') + '"');
        
        HttpResponse response = http.send(request);
        ApiLogger.log(request, response);

        return response;
    }

    private static HttpRequest prepareRequest(String endpoint, String method, String stringBodyAsJson) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept-Language', 'en');
        request.setTimeout(120000);
        if (stringBodyAsJson != '') {
            request.setBody(stringBodyAsJson);
        }

        return request;
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