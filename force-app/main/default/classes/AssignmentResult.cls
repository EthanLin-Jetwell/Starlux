/**
 * @description Result of seat assignment operations
 * @author STARLUX Development Team
 * @date 2024
 */
public class AssignmentResult {
    public Boolean success { get; set; }
    public List<String> successfulAssignments { get; set; }
    public List<String> failedAssignments { get; set; }
    public String errorMessage { get; set; }
    public List<ValidationError> validationErrors { get; set; }
    public Integer totalProcessed { get; set; }
    public Integer successCount { get; set; }
    public Integer failureCount { get; set; }
    
    /**
     * @description Default constructor
     */
    public AssignmentResult() {
        this.success = false;
        this.successfulAssignments = new List<String>();
        this.failedAssignments = new List<String>();
        this.validationErrors = new List<ValidationError>();
        this.totalProcessed = 0;
        this.successCount = 0;
        this.failureCount = 0;
    }
    
    /**
     * @description Constructor with success status
     * @param success Success status
     */
    public AssignmentResult(Boolean success) {
        this();
        this.success = success;
    }
    
    /**
     * @description Constructor with error message
     * @param errorMessage Error message
     */
    public AssignmentResult(String errorMessage) {
        this();
        this.success = false;
        this.errorMessage = errorMessage;
    }
    
    /**
     * @description Add successful assignment
     * @param assignment Assignment identifier
     */
    public void addSuccessfulAssignment(String assignment) {
        if (String.isNotBlank(assignment)) {
            successfulAssignments.add(assignment);
            successCount = successfulAssignments.size();
            totalProcessed = successCount + failureCount;
        }
    }
    
    /**
     * @description Add failed assignment
     * @param assignment Assignment identifier
     */
    public void addFailedAssignment(String assignment) {
        if (String.isNotBlank(assignment)) {
            failedAssignments.add(assignment);
            failureCount = failedAssignments.size();
            totalProcessed = successCount + failureCount;
            success = false; // Any failure makes overall result unsuccessful
        }
    }
    
    /**
     * @description Add validation error
     * @param error Validation error
     */
    public void addValidationError(ValidationError error) {
        if (error != null) {
            validationErrors.add(error);
            success = false;
        }
    }
    
    /**
     * @description Check if has partial success
     * @return True if some assignments succeeded but some failed
     */
    public Boolean hasPartialSuccess() {
        return successCount > 0 && failureCount > 0;
    }
    
    /**
     * @description Check if completely successful
     * @return True if all assignments succeeded
     */
    public Boolean isCompleteSuccess() {
        return success && failureCount == 0 && successCount > 0;
    }
    
    /**
     * @description Check if has validation errors
     * @return True if has validation errors
     */
    public Boolean hasValidationErrors() {
        return !validationErrors.isEmpty();
    }
    
    /**
     * @description Get summary message
     * @return Summary of assignment results
     */
    public String getSummaryMessage() {
        if (isCompleteSuccess()) {
            return successCount + ' seat assignments completed successfully';
        } else if (hasPartialSuccess()) {
            return successCount + ' successful, ' + failureCount + ' failed assignments';
        } else if (failureCount > 0) {
            return 'All ' + failureCount + ' seat assignments failed';
        } else if (hasValidationErrors()) {
            return 'Validation errors: ' + validationErrors.size() + ' issues found';
        } else {
            return String.isNotBlank(errorMessage) ? errorMessage : 'Unknown error occurred';
        }
    }
}