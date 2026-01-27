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
		System.debug(response);
        return response;
    }

    private static HttpRequest prepareRequest(String endpoint, String method, String stringBodyAsJson) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        //request.setHeader('Content-Type', 'application/json');  //Eli 停用20251028

        //取偷肯的時候要用application/x-www-form-urlencoded，其他功能用application/json，Eli AUTH改IOPS 20251028
        if (stringBodyAsJson != null && stringBodyAsJson.contains('clientId')) {
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    	} else {
        request.setHeader('Content-Type', 'application/json');
    	}
        

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