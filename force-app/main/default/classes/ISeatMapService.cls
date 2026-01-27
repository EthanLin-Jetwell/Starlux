/**
 * @description Interface for seat map and aircraft configuration operations
 * @author STARLUX Development Team
 * @date 2024
 */
public interface ISeatMapService {
    
    /**
     * @description Get seat map for aircraft and flight
     * @param request Seat map request
     * @return Seat map data
     */
    SeatMapData getSeatMap(SeatMapRequest request);
    
    /**
     * @description Get aircraft configuration
     * @param aircraftType Aircraft type code
     * @return Aircraft configuration
     */
    AircraftConfiguration getAircraftConfiguration(String aircraftType);
    
    /**
     * @description Check if seat is available
     * @param seatCode Seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return True if available
     */
    Boolean isSeatAvailable(String seatCode, String aircraftType, String flightNumber, Date departureDate);
    
    /**
     * @description Get available seats for cabin class
     * @param cabinClass Cabin class code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return List of available seat codes
     */
    List<String> getAvailableSeats(String cabinClass, String aircraftType, String flightNumber, Date departureDate);
}