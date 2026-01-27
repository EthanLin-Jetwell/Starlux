/**
 * @description Flight information domain object
 * @author STARLUX Development Team
 * @date 2024
 */
public class FlightInfo {
    public String flightNumber { get; set; }
    public Date departureDate { get; set; }
    public String origin { get; set; }
    public String destination { get; set; }
    public String aircraftType { get; set; }
    public List<String> availableCabins { get; set; }
    public Boolean isValid { get; set; }
    public Time departureTime { get; set; }
    public Time arrivalTime { get; set; }
    public String flightStatus { get; set; }
    
    /**
     * @description Default constructor
     */
    public FlightInfo() {
        this.availableCabins = new List<String>();
        this.isValid = false;
    }
    
    /**
     * @description Constructor with basic flight information
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @param origin Origin airport code
     */
    public FlightInfo(String flightNumber, Date departureDate, String origin) {
        this();
        this.flightNumber = flightNumber;
        this.departureDate = departureDate;
        this.origin = origin;
    }
    
    /**
     * @description Full constructor
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @param origin Origin airport
     * @param destination Destination airport
     * @param aircraftType Aircraft type
     */
    public FlightInfo(String flightNumber, Date departureDate, String origin, String destination, String aircraftType) {
        this();
        this.flightNumber = flightNumber;
        this.departureDate = departureDate;
        this.origin = origin;
        this.destination = destination;
        this.aircraftType = aircraftType;
        this.isValid = true;
    }
    
    /**
     * @description Add available cabin class
     * @param cabinClass Cabin class code
     */
    public void addAvailableCabin(String cabinClass) {
        if (String.isNotBlank(cabinClass) && !availableCabins.contains(cabinClass)) {
            availableCabins.add(cabinClass);
        }
    }
    
    /**
     * @description Check if cabin class is available
     * @param cabinClass Cabin class to check
     * @return True if available
     */
    public Boolean isCabinAvailable(String cabinClass) {
        return availableCabins.contains(cabinClass);
    }
    
    /**
     * @description Get flight route string
     * @return Flight route (e.g., "TPE-LAX")
     */
    public String getFlightRoute() {
        if (String.isNotBlank(origin) && String.isNotBlank(destination)) {
            return origin + '-' + destination;
        }
        return '';
    }
    
    /**
     * @description Validate flight information
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
            errors.add(new ValidationError('origin', 'Origin airport is required'));
        }
        
        if (String.isBlank(destination)) {
            errors.add(new ValidationError('destination', 'Destination airport is required'));
        }
        
        return errors;
    }
    
    /**
     * @description Check if flight info is complete and valid
     * @return True if valid
     */
    public Boolean isComplete() {
        return validate().isEmpty() && String.isNotBlank(aircraftType);
    }
}