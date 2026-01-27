public class GetPurchaseResponseWrapper {
    public Boolean success;
    public String traceId;
    public Message message;
    public Data data;
    public Object links;
    public Object meta;

    public class Data {
        public String status;
        public String recordId;
    }
    
    public class Message {
        public String code;
        public String content;
        public List<String> details;
    }
    
    public GetPurchaseResponseWrapper() {
        
    }
}