/**
 * @description Interface for passenger data management operations
 * @author STARLUX Development Team
 * @date 2024
 */
public interface IPassengerService {
    
    /**
     * @description Get passengers for PNR
     * @param pnrCode PNR code
     * @return List of passenger display info
     */
    List<PassengerDisplayInfo> getPassengersForPNR(String pnrCode);
    
    /**
     * @description Get passenger by external ID
     * @param externalId External passenger ID
     * @return Passenger display info
     */
    PassengerDisplayInfo getPassengerById(String externalId);
    
    /**
     * @description Update passenger information
     * @param passenger Updated passenger info
     * @return Success status
     */
    Boolean updatePassenger(PassengerDisplayInfo passenger);
    
    /**
     * @description Validate passenger data
     * @param passenger Passenger to validate
     * @return Validation result
     */
    ValidationResult validatePassenger(PassengerDisplayInfo passenger);
    
    /**
     * @description Check if passenger has special needs
     * @param passenger Passenger to check
     * @return True if has special needs
     */
    Boolean hasSpecialNeeds(PassengerDisplayInfo passenger);
    
    /**
     * @description Get passenger's cabin class restrictions
     * @param passenger Passenger
     * @return List of allowed cabin classes
     */
    List<String> getAllowedCabinClasses(PassengerDisplayInfo passenger);
    
    /**
     * @description Check if passenger can be assigned to cabin class
     * @param passenger Passenger
     * @param targetCabinClass Target cabin class
     * @return True if allowed
     */
    Boolean canAssignToCabin(PassengerDisplayInfo passenger, String targetCabinClass);
    
    /**
     * @description Get passengers with conflicts for seat assignment
     * @param seatCode Seat code to check
     * @param excludePassengerId Passenger ID to exclude from check
     * @return List of conflicting passengers
     */
    List<PassengerDisplayInfo> getConflictingPassengers(String seatCode, String excludePassengerId);
}