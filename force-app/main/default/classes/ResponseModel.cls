global class ResponseModel {
    public class Data {
        public String status {get; set;}
        public String recordId {get; set;}
        public String SF_Return_BG_No {get; set;}
        
        public Data(String status, String recordId, String SF_Return_BG_No) {
            this.status = status;
            this.recordId = recordId;
            this.SF_Return_BG_No = SF_Return_BG_No;
        }
    }
    
    public class Message {
        public Integer code {get; set;}
        public String content {get; set;}
        public String details {get; set;}
        
        public Message(Integer code, String content, String details) {
            this.code = code;
            this.content = content;
            this.details = details;
        }
    }
    
    public Data data {get; set;}
    public String traceID {get; set;}
    public Boolean success {get; set;}
    public Message message {get; set;}
    
    public ResponseModel(Integer resultCode, String traceID, String objectID, String SF_Return_BG_No, String resultMessage) {
        this.traceID = traceID;
        this.success = success(resultCode);
        this.data = new Data(success? 'success' : 'fail', objectID, SF_Return_BG_No);
        this.message = new Message(resultCode, getHttpMessage(resultCode, resultMessage), NULL);
    }
    
    public String getHttpMessage(Integer resultCode, String resultMessage) {
        switch on resultCode {
            when 200 {
                return 'OK';
            }
            when 201 {
                return 'Created';
            }
            when 204 {
                return 'No Content,' + ' ' + resultMessage;
            }
            when 400 {
                return 'Bad Request,' + ' ' + resultMessage;
            }
            when 401 {
                 return 'Unauthorized,' + ' ' + resultMessage;
            }
            when 403 {
                return 'Forbidden,' + ' ' + resultMessage;
            }
            when 404 {
                return 'Not Found,' + ' ' + resultMessage;
            }
            when 500 {
                return 'Internal Server Error,' + ' ' + resultMessage;
            }
        }
        
        return 'Invalid HTTP status code';
    }
    
    public Boolean success(Integer resultCode) {
        switch on resultCode {
            when 200, 201 {
                return true;
            }
            when else {	
                return false;
            }
        }
    }
}