/**
 * @description Detailed PNR information
 * @author STARLUX Development Team
 * @date 2024
 */
public class PNRData {
    public String pnrCode { get; set; }
    public String flightNumber { get; set; }
    public Date departureDate { get; set; }
    public String origin { get; set; }
    public String destination { get; set; }
    public String aircraftType { get; set; }
    public List<String> passengerIds { get; set; }
    public Integer passengerCount { get; set; }
    public Boolean hasUSBoundPassengers { get; set; }
    
    /**
     * @description Default constructor
     */
    public PNRData() {
        this.passengerIds = new List<String>();
        this.passengerCount = 0;
        this.hasUSBoundPassengers = false;
    }
    
    /**
     * @description Constructor with PNR code
     * @param pnrCode PNR code
     */
    public PNRData(String pnrCode) {
        this();
        this.pnrCode = pnrCode;
    }
    
    /**
     * @description Full constructor
     * @param pnrCode PNR code
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @param origin Origin airport
     * @param destination Destination airport
     */
    public PNRData(String pnrCode, String flightNumber, Date departureDate, String origin, String destination) {
        this();
        this.pnrCode = pnrCode;
        this.flightNumber = flightNumber;
        this.departureDate = departureDate;
        this.origin = origin;
        this.destination = destination;
    }
    
    /**
     * @description Add passenger ID
     * @param passengerId Passenger ID to add
     */
    public void addPassengerId(String passengerId) {
        if (String.isNotBlank(passengerId) && !passengerIds.contains(passengerId)) {
            passengerIds.add(passengerId);
            passengerCount = passengerIds.size();
        }
    }
    
    /**
     * @description Check if PNR has passengers
     * @return True if has passengers
     */
    public Boolean hasPassengers() {
        return passengerCount > 0;
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
     * @description Check if PNR data is valid
     * @return True if essential fields are populated
     */
    public Boolean isValid() {
        return String.isNotBlank(pnrCode) && 
               String.isNotBlank(flightNumber) && 
               departureDate != null &&
               hasPassengers();
    }
}