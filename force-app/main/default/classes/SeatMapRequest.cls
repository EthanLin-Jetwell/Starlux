/**
 * @description Seat map request for API calls
 * @author STARLUX Development Team
 * @date 2024
 */
public class SeatMapRequest {
    public String flightNumber { get; set; }
    public Date departureDate { get; set; }
    public String origin { get; set; }
    public String destination { get; set; }
    public String bookingClass { get; set; }
    
    /**
     * @description Default constructor
     */
    public SeatMapRequest() {
    }
    
    /**
     * @description Full constructor
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @param origin Origin airport
     * @param destination Destination airport
     * @param bookingClass Booking class
     */
    public SeatMapRequest(String flightNumber, Date departureDate, String origin, String destination, String bookingClass) {
        this.flightNumber = flightNumber;
        this.departureDate = departureDate;
        this.origin = origin;
        this.destination = destination;
        this.bookingClass = bookingClass;
    }
    
    /**
     * @description Validate request data
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
        
        if (String.isBlank(origin)) {
            errors.add(new ValidationError('origin', 'Origin is required'));
        }
        
        if (String.isBlank(destination)) {
            errors.add(new ValidationError('destination', 'Destination is required'));
        }
        
        return errors;
    }
    
    /**
     * @description Check if request is valid
     * @return True if valid
     */
    public Boolean isValid() {
        return validate().isEmpty();
    }
}