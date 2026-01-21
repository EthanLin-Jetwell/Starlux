public class ContinuationDemoController {
	// Unique label corresponding to the continuation
    public String requestLabel;
    // Result of callout
    public String result {get;set;}
    // Callout endpoint as a named credential URL 
    // or, as shown here, as the long-running service URL
    private static final String LONG_RUNNING_SERVICE_URL = 
        'https://opentdb.com/api.php?amount=4&category=9&difficulty=easy&type=multiple';
   
   // Action method
    public Object startRequest() {
      // Create continuation with a timeout
      Continuation con = new Continuation(40);
      // Set callback method
      con.continuationMethod='processResponse';
      
      // Create callout request
      HttpRequest req = new HttpRequest();
      req.setMethod('GET');
      req.setEndpoint(LONG_RUNNING_SERVICE_URL);
      
      // Add callout request to continuation
      this.requestLabel = con.addHttpRequest(req);
      System.debug(this.requestLabel);
      // Return the continuation
      return con;  
    }
    
    // Callback method 
    public Object processResponse() {   
      // Get the response by using the unique label
      HttpResponse response = Continuation.getResponse(this.requestLabel);
      // Set the result variable that is displayed on the Visualforce page
      this.result = response.getBody();
      System.debug(result);
      // Return null to re-render the original Visualforce page
      return null;
    }
}