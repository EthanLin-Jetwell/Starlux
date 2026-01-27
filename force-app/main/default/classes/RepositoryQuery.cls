/**
 * @description Database query parameters for repository operations
 * @author STARLUX Development Team
 * @date 2024
 */
public class RepositoryQuery {
    public List<String> pnrCodes { get; set; }
    public String flightNumber { get; set; }
    public Date departureDate { get; set; }
    public String departureLocation { get; set; }
    public List<String> externalIds { get; set; }
    public Integer limitSize { get; set; }
    public String orderBy { get; set; }
    public Boolean includeInactive { get; set; }
    
    /**
     * @description Default constructor
     */
    public RepositoryQuery() {
        this.pnrCodes = new List<String>();
        this.externalIds = new List<String>();
        this.limitSize = 1000; // Default limit
        this.includeInactive = false;
    }
    
    /**
     * @description Constructor for PNR and flight search
     * @param pnrCodes List of PNR codes
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @param departureLocation Origin airport
     */
    public RepositoryQuery(List<String> pnrCodes, String flightNumber, Date departureDate, String departureLocation) {
        this();
        this.pnrCodes = pnrCodes != null ? pnrCodes : new List<String>();
        this.flightNumber = flightNumber;
        this.departureDate = departureDate;
        this.departureLocation = departureLocation;
    }
    
    /**
     * @description Constructor for external ID search
     * @param externalIds List of external IDs
     */
    public RepositoryQuery(List<String> externalIds) {
        this();
        this.externalIds = externalIds != null ? externalIds : new List<String>();
    }
    
    /**
     * @description Add PNR code to query
     * @param pnrCode PNR code to add
     */
    public void addPNRCode(String pnrCode) {
        if (String.isNotBlank(pnrCode) && !pnrCodes.contains(pnrCode)) {
            pnrCodes.add(pnrCode);
        }
    }
    
    /**
     * @description Add external ID to query
     * @param externalId External ID to add
     */
    public void addExternalId(String externalId) {
        if (String.isNotBlank(externalId) && !externalIds.contains(externalId)) {
            externalIds.add(externalId);
        }
    }
    
    /**
     * @description Check if query has PNR criteria
     * @return True if has PNR codes
     */
    public Boolean hasPNRCriteria() {
        return !pnrCodes.isEmpty();
    }
    
    /**
     * @description Check if query has external ID criteria
     * @return True if has external IDs
     */
    public Boolean hasExternalIdCriteria() {
        return !externalIds.isEmpty();
    }
    
    /**
     * @description Check if query has flight criteria
     * @return True if has flight information
     */
    public Boolean hasFlightCriteria() {
        return String.isNotBlank(flightNumber) && departureDate != null;
    }
    
    /**
     * @description Validate query parameters
     * @return List of validation errors
     */
    public List<ValidationError> validate() {
        List<ValidationError> errors = new List<ValidationError>();
        
        if (!hasPNRCriteria() && !hasExternalIdCriteria() && !hasFlightCriteria()) {
            errors.add(new ValidationError('criteria', 'At least one search criteria is required'));
        }
        
        if (limitSize != null && limitSize <= 0) {
            errors.add(new ValidationError('limitSize', 'Limit size must be greater than 0'));
        }
        
        if (limitSize != null && limitSize > 10000) {
            errors.add(new ValidationError('limitSize', 'Limit size cannot exceed 10,000 records'));
        }
        
        return errors;
    }
    
    /**
     * @description Check if query is valid
     * @return True if valid
     */
    public Boolean isValid() {
        return validate().isEmpty();
    }
    
    /**
     * @description Get query description for logging
     * @return Query description
     */
    public String getDescription() {
        List<String> parts = new List<String>();
        
        if (hasPNRCriteria()) {
            parts.add('PNRs: ' + String.join(pnrCodes, ', '));
        }
        
        if (hasFlightCriteria()) {
            parts.add('Flight: ' + flightNumber + ' on ' + departureDate.format());
        }
        
        if (hasExternalIdCriteria()) {
            parts.add('External IDs: ' + externalIds.size() + ' items');
        }
        
        return String.join(parts, ' | ');
    }
}