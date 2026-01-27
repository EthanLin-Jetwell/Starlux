/**
 * @description Validation error information
 * @author STARLUX Development Team
 * @date 2024
 */
public class ValidationError {
    public String fieldName { get; set; }
    public String message { get; set; }
    public String errorCode { get; set; }
    public Object[] messageParams { get; set; }
    
    /**
     * @description Constructor with field and message
     * @param fieldName Field that has validation error
     * @param message Error message
     */
    public ValidationError(String fieldName, String message) {
        this.fieldName = fieldName;
        this.message = message;
        this.messageParams = new Object[]{};
    }
    
    /**
     * @description Constructor with field, message and error code
     * @param fieldName Field that has validation error
     * @param message Error message
     * @param errorCode Error code for categorization
     */
    public ValidationError(String fieldName, String message, String errorCode) {
        this(fieldName, message);
        this.errorCode = errorCode;
    }
    
    /**
     * @description Constructor with message parameters for formatting
     * @param fieldName Field that has validation error
     * @param message Error message template
     * @param messageParams Parameters for message formatting
     */
    public ValidationError(String fieldName, String message, Object[] messageParams) {
        this.fieldName = fieldName;
        this.message = message;
        this.messageParams = messageParams != null ? messageParams : new Object[]{};
    }
    
    /**
     * @description Get formatted error message
     * @return Formatted error message
     */
    public String getFormattedMessage() {
        if (messageParams != null && !messageParams.isEmpty()) {
            return String.format(message, messageParams);
        }
        return message;
    }
    
    /**
     * @description Override toString for debugging
     * @return String representation
     */
    public override String toString() {
        return fieldName + ': ' + getFormattedMessage();
    }
}