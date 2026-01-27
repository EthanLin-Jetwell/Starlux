/**
 * @description Interface for seat assignment operations
 * @author STARLUX Development Team
 * @date 2024
 */
public interface ISeatAssignmentService {
    
    /**
     * @description Assign seat to passenger
     * @param passengerId Passenger external ID
     * @param seatCode Seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return Assignment result
     */
    AssignmentResult assignSeat(String passengerId, String seatCode, String aircraftType, String flightNumber, Date departureDate);
    
    /**
     * @description Clear seat assignment for passenger
     * @param passengerId Passenger external ID
     * @return Success status
     */
    Boolean clearSeatAssignment(String passengerId);
    
    /**
     * @description Validate seat assignment
     * @param passengerId Passenger external ID
     * @param seatCode Seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return Validation result
     */
    ValidationResult validateSeatAssignment(String passengerId, String seatCode, String aircraftType, String flightNumber, Date departureDate);
    
    /**
     * @description Get seat assignment conflicts
     * @param passengerId Passenger external ID
     * @param seatCode Seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return List of conflicts
     */
    List<ConflictInfo> getSeatAssignmentConflicts(String passengerId, String seatCode, String aircraftType, String flightNumber, Date departureDate);
    
    /**
     * @description Bulk assign seats to multiple passengers
     * @param assignments Map of passenger ID to seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return List of assignment results
     */
    List<AssignmentResult> bulkAssignSeats(Map<String, String> assignments, String aircraftType, String flightNumber, Date departureDate);
}