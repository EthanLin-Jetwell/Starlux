/**
 * @description API response wrapper for external API calls
 * @author STARLUX Development Team
 * @date 2024
 */
public class APIResponse {
    public Boolean success { get; set; }
    public String responseBody { get; set; }
    public String errorMessage { get; set; }
    public Integer statusCode { get; set; }
    public Map<String, String> headers { get; set; }
    public DateTime responseTime { get; set; }
    public Long responseTimeMs { get; set; }
    
    /**
     * @description Default constructor
     */
    public APIResponse() {
        this.success = false;
        this.headers = new Map<String, String>();
        this.responseTime = DateTime.now();
    }
    
    /**
     * @description Constructor with success status
     * @param success Success status
     */
    public APIResponse(Boolean success) {
        this();
        this.success = success;
    }
    
    /**
     * @description Constructor with success and response body
     * @param success Success status
     * @param responseBody Response body
     */
    public APIResponse(Boolean success, String responseBody) {
        this(success);
        this.responseBody = responseBody;
    }
    
    /**
     * @description Constructor with error
     * @param errorMessage Error message
     * @param statusCode HTTP status code
     */
    public APIResponse(String errorMessage, Integer statusCode) {
        this();
        this.success = false;
        this.errorMessage = errorMessage;
        this.statusCode = statusCode;
    }
    
    /**
     * @description Create successful response
     * @param responseBody Response body
     * @param statusCode HTTP status code
     * @return Successful API response
     */
    public static APIResponse createSuccess(String responseBody, Integer statusCode) {
        APIResponse response = new APIResponse(true, responseBody);
        response.statusCode = statusCode;
        return response;
    }
    
    /**
     * @description Create error response
     * @param errorMessage Error message
     * @param statusCode HTTP status code
     * @return Error API response
     */
    public static APIResponse createError(String errorMessage, Integer statusCode) {
        return new APIResponse(errorMessage, statusCode);
    }
    
    /**
     * @description Create timeout error response
     * @return Timeout error response
     */
    public static APIResponse createTimeoutError() {
        return new APIResponse('Request timeout', 408);
    }
    
    /**
     * @description Add response header
     * @param name Header name
     * @param value Header value
     */
    public void addHeader(String name, String value) {
        if (String.isNotBlank(name)) {
            headers.put(name, value);
        }
    }
    
    /**
     * @description Get response header value
     * @param name Header name
     * @return Header value
     */
    public String getHeader(String name) {
        return headers.get(name);
    }
    
    /**
     * @description Check if response is successful (2xx status codes)
     * @return True if successful
     */
    public Boolean isSuccessful() {
        return success && statusCode != null && statusCode >= 200 && statusCode < 300;
    }
    
    /**
     * @description Check if response is client error (4xx status codes)
     * @return True if client error
     */
    public Boolean isClientError() {
        return statusCode != null && statusCode >= 400 && statusCode < 500;
    }
    
    /**
     * @description Check if response is server error (5xx status codes)
     * @return True if server error
     */
    public Boolean isServerError() {
        return statusCode != null && statusCode >= 500 && statusCode < 600;
    }
    
    /**
     * @description Check if response has content
     * @return True if has response body
     */
    public Boolean hasContent() {
        return String.isNotBlank(responseBody);
    }
    
    /**
     * @description Parse response body as JSON
     * @return Parsed JSON object
     */
    public Object parseJSON() {
        if (!hasContent()) {
            return null;
        }
        
        try {
            return JSON.deserializeUntyped(responseBody);
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * @description Parse response body as specific type
     * @param objectType Target object type
     * @return Parsed object
     */
    public Object parseJSON(Type objectType) {
        if (!hasContent() || objectType == null) {
            return null;
        }
        
        try {
            return JSON.deserialize(responseBody, objectType);
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * @description Set response time in milliseconds
     * @param startTime Start time of request
     */
    public void setResponseTime(DateTime startTime) {
        if (startTime != null) {
            this.responseTimeMs = this.responseTime.getTime() - startTime.getTime();
        }
    }
    
    /**
     * @description Get status description
     * @return Status description
     */
    public String getStatusDescription() {
        if (statusCode == null) {
            return 'Unknown';
        }
        
        switch on statusCode {
            when 200 { return 'OK'; }
            when 201 { return 'Created'; }
            when 400 { return 'Bad Request'; }
            when 401 { return 'Unauthorized'; }
            when 403 { return 'Forbidden'; }
            when 404 { return 'Not Found'; }
            when 408 { return 'Request Timeout'; }
            when 500 { return 'Internal Server Error'; }
            when 502 { return 'Bad Gateway'; }
            when 503 { return 'Service Unavailable'; }
            when else { return 'Status ' + statusCode; }
        }
    }
    
    /**
     * @description Get response summary for logging
     * @return Response summary
     */
    public String getSummary() {
        String summary = 'Status: ' + getStatusDescription();
        
        if (responseTimeMs != null) {
            summary += ' | Time: ' + responseTimeMs + 'ms';
        }
        
        if (hasContent()) {
            summary += ' | Content: ' + responseBody.length() + ' chars';
        }
        
        if (String.isNotBlank(errorMessage)) {
            summary += ' | Error: ' + errorMessage;
        }
        
        return summary;
    }
}