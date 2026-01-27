/**
 * @description Search criteria for PNR lookup operations
 * @author STARLUX Development Team
 * @date 2024
 */
public class SearchCriteria {
    public String flightNumber { get; set; }
    public Date departureDate { get; set; }
    public String departureLocation { get; set; }
    public List<String> pnrCodes { get; set; }
    
    /**
     * @description Default constructor
     */
    public SearchCriteria() {
        this.pnrCodes = new List<String>();
    }
    
    /**
     * @description Full constructor
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @param departureLocation Origin airport code
     * @param pnrCodes List of PNR codes
     */
    public SearchCriteria(String flightNumber, Date departureDate, String departureLocation, List<String> pnrCodes) {
        this.flightNumber = flightNumber;
        this.departureDate = departureDate;
        this.departureLocation = departureLocation;
        this.pnrCodes = pnrCodes != null ? pnrCodes : new List<String>();
    }
    
    /**
     * @description Validate search criteria
     * @return List of validation errors
     */
    public List<ValidationError> validate() {
        List<ValidationError> errors = new List<ValidationError>();
        
        if (String.isBlank(flightNumber)) {
            errors.add(new ValidationError('flightNumber', 'Flight number is required'));
        }
        
        if (departureDate == null) {
            errors.add(new ValidationError('departureDate', 'Departure date is required'));
        }
        
        if (String.isBlank(departureLocation)) {
            errors.add(new ValidationError('departureLocation', 'Departure location is required'));
        }
        
        if (pnrCodes == null || pnrCodes.isEmpty()) {
            errors.add(new ValidationError('pnrCodes', 'At least one PNR code is required'));
        }
        
        return errors;
    }
    
    /**
     * @description Check if search criteria is valid
     * @return True if valid
     */
    public Boolean isValid() {
        return validate().isEmpty();
    }
}