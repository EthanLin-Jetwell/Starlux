/**
 * @description Result of validation operations
 * @author STARLUX Development Team
 * @date 2024
 */
public class ValidationResult {
    public Boolean isValid { get; set; }
    public List<ValidationError> errors { get; set; }
    public String summary { get; set; }
    
    /**
     * @description Default constructor
     */
    public ValidationResult() {
        this.isValid = true;
        this.errors = new List<ValidationError>();
    }
    
    /**
     * @description Constructor with validation status
     * @param isValid Validation status
     */
    public ValidationResult(Boolean isValid) {
        this();
        this.isValid = isValid;
    }
    
    /**
     * @description Add validation error
     * @param error Validation error to add
     */
    public void addError(ValidationError error) {
        if (error != null) {
            errors.add(error);
            isValid = false;
        }
    }
    
    /**
     * @description Add validation error with field and message
     * @param fieldName Field name
     * @param message Error message
     */
    public void addError(String fieldName, String message) {
        addError(new ValidationError(fieldName, message));
    }
    
    /**
     * @description Check if has errors
     * @return True if has errors
     */
    public Boolean hasErrors() {
        return !errors.isEmpty();
    }
    
    /**
     * @description Get error count
     * @return Number of errors
     */
    public Integer getErrorCount() {
        return errors.size();
    }
    
    /**
     * @description Get all error messages
     * @return List of error messages
     */
    public List<String> getErrorMessages() {
        List<String> messages = new List<String>();
        for (ValidationError error : errors) {
            messages.add(error.getFormattedMessage());
        }
        return messages;
    }
    
    /**
     * @description Get summary of validation result
     * @return Summary string
     */
    public String getSummary() {
        if (String.isNotBlank(summary)) {
            return summary;
        }
        
        if (isValid) {
            return 'Validation successful';
        } else {
            return 'Validation failed with ' + getErrorCount() + ' error(s)';
        }
    }
    
    /**
     * @description Merge another validation result
     * @param other Other validation result to merge
     */
    public void mergeWith(ValidationResult other) {
        if (other != null) {
            if (!other.isValid) {
                this.isValid = false;
            }
            this.errors.addAll(other.errors);
        }
    }
}