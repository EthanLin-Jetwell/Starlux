/**
 * @description Seat Assignment Service Implementation
 * @author STARLUX Development Team
 * @date 2024
 */
public class SeatAssignmentService implements ISeatAssignmentService {
    private ITravellerRepository travellerRepository;
    private IPassengerService passengerService;
    private ISeatMapService seatMapService;
    private IAmadeusAPIClient apiClient;
    
    /**
     * @description Constructor with dependencies
     */
    public SeatAssignmentService() {
        // this.travellerRepository = ServiceFactory.getTravellerRepository();
        this.travellerRepository = new TravellerRepository();
        // this.passengerService = ServiceFactory.getPassengerService();
        this.passengerService = new PassengerService();
        // this.seatMapService = ServiceFactory.getSeatMapService();
        this.seatMapService = new SeatMapService();
        // this.apiClient = ServiceFactory.getAmadeusAPIClient();
        this.apiClient = new AmadeusAPIClient();
    }
    
    /**
     * @description Constructor for testing with mocks
     */
    public SeatAssignmentService(ITravellerRepository travellerRepository, 
                                IPassengerService passengerService,
                                ISeatMapService seatMapService,
                                IAmadeusAPIClient apiClient) {
        this.travellerRepository = travellerRepository;
        this.passengerService = passengerService;
        this.seatMapService = seatMapService;
        this.apiClient = apiClient;
    }
    
    /**
     * @description Assign seat to passenger
     * @param passengerId Passenger external ID
     * @param seatCode Seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return Assignment result
     */
    public AssignmentResult assignSeat(String passengerId, String seatCode, String aircraftType, String flightNumber, Date departureDate) {
        try {
            // Validate inputs
            if (String.isBlank(passengerId) || String.isBlank(seatCode)) {
                AssignmentResult result = new AssignmentResult('Passenger ID and seat code are required');
                return result;
            }
            
            // Get passenger information
            PassengerDisplayInfo passenger = passengerService.getPassengerById(passengerId);
            if (passenger == null) {
                AssignmentResult result = new AssignmentResult('Passenger not found: ' + passengerId);
                return result;
            }
            
            // Check for conflicts
            List<ConflictInfo> conflicts = checkSeatAssignmentConflicts(passenger, seatCode, aircraftType, flightNumber, departureDate);
            
            // If there are critical conflicts, return failure
            for (ConflictInfo conflict : conflicts) {
                if (conflict.isCritical()) {
                    AssignmentResult result = new AssignmentResult(conflict.conflictMessage);
                    // Add conflicts to result if needed
                    return result;
                }
            }
            
            // Clear any existing seat assignment for this passenger
            clearPassengerSeatAssignment(passengerId);
            
            // Assign the new seat
            Boolean success = updatePassengerSeatAssignment(passengerId, seatCode);
            
            if (success) {
                // Try to sync with external system
                syncSeatAssignmentWithAPI(passenger, seatCode, flightNumber, departureDate);
                
                AssignmentResult result = new AssignmentResult(true);
                result.addSuccessfulAssignment(passengerId + ':' + seatCode);
                return result;
            } else {
                AssignmentResult result = new AssignmentResult('Failed to update seat assignment in database');
                return result;
            }
            
        } catch (Exception e) {
            System.debug('Error in assignSeat: ' + e.getMessage());
            AssignmentResult result = new AssignmentResult('System error during seat assignment: ' + e.getMessage());
            return result;
        }
    }
    
    /**
     * @description Clear seat assignment for passenger
     * @param passengerId Passenger external ID
     * @return Success status
     */
    public Boolean clearSeatAssignment(String passengerId) {
        try {
            if (String.isBlank(passengerId)) {
                return false;
            }
            
            return updatePassengerSeatAssignment(passengerId, null);
            
        } catch (Exception e) {
            System.debug('Error in clearSeatAssignment: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Validate seat assignment
     * @param passengerId Passenger external ID
     * @param seatCode Seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return Validation result
     */
    public ValidationResult validateSeatAssignment(String passengerId, String seatCode, String aircraftType, String flightNumber, Date departureDate) {
        ValidationResult result = new ValidationResult();
        
        try {
            // Basic validation
            if (String.isBlank(passengerId)) {
                result.addError(new ValidationError('passengerId', 'Passenger ID is required'));
            }
            
            if (String.isBlank(seatCode)) {
                result.addError(new ValidationError('seatCode', 'Seat code is required'));
            }
            
            if (String.isBlank(aircraftType)) {
                result.addError(new ValidationError('aircraftType', 'Aircraft type is required'));
            }
            
            if (!result.isValid) {
                return result;
            }
            
            // Get passenger information
            PassengerDisplayInfo passenger = passengerService.getPassengerById(passengerId);
            if (passenger == null) {
                result.addError(new ValidationError('passengerId', 'Passenger not found'));
                return result;
            }
            
            // Check for conflicts
            List<ConflictInfo> conflicts = checkSeatAssignmentConflicts(passenger, seatCode, aircraftType, flightNumber, departureDate);
            
            // Add critical conflicts as validation errors
            for (ConflictInfo conflict : conflicts) {
                if (conflict.isCritical()) {
                    result.addError(new ValidationError('seatAssignment', conflict.conflictMessage));
                }
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in validateSeatAssignment: ' + e.getMessage());
            result.addError(new ValidationError('system', 'System error during validation'));
            return result;
        }
    }
    
    /**
     * @description Get seat assignment conflicts
     * @param passengerId Passenger external ID
     * @param seatCode Seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return List of conflicts
     */
    public List<ConflictInfo> getSeatAssignmentConflicts(String passengerId, String seatCode, String aircraftType, String flightNumber, Date departureDate) {
        try {
            if (String.isBlank(passengerId) || String.isBlank(seatCode)) {
                return new List<ConflictInfo>();
            }
            
            PassengerDisplayInfo passenger = passengerService.getPassengerById(passengerId);
            if (passenger == null) {
                return new List<ConflictInfo>();
            }
            
            return checkSeatAssignmentConflicts(passenger, seatCode, aircraftType, flightNumber, departureDate);
            
        } catch (Exception e) {
            System.debug('Error in getSeatAssignmentConflicts: ' + e.getMessage());
            return new List<ConflictInfo>();
        }
    }
    
    /**
     * @description Bulk assign seats to multiple passengers
     * @param assignments Map of passenger ID to seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return List of assignment results
     */
    public List<AssignmentResult> bulkAssignSeats(Map<String, String> assignments, String aircraftType, String flightNumber, Date departureDate) {
        List<AssignmentResult> results = new List<AssignmentResult>();
        
        try {
            if (assignments == null || assignments.isEmpty()) {
                return results;
            }
            
            // Process each assignment
            for (String passengerId : assignments.keySet()) {
                String seatCode = assignments.get(passengerId);
                AssignmentResult result = assignSeat(passengerId, seatCode, aircraftType, flightNumber, departureDate);
                results.add(result);
            }
            
            return results;
            
        } catch (Exception e) {
            System.debug('Error in bulkAssignSeats: ' + e.getMessage());
            AssignmentResult errorResult = new AssignmentResult('System error during bulk assignment: ' + e.getMessage());
            results.add(errorResult);
            return results;
        }
    }
    
    /**
     * @description Check for seat assignment conflicts
     * @param passenger Passenger information
     * @param seatCode Seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return List of conflicts
     */
    private List<ConflictInfo> checkSeatAssignmentConflicts(PassengerDisplayInfo passenger, String seatCode, String aircraftType, String flightNumber, Date departureDate) {
        List<ConflictInfo> conflicts = new List<ConflictInfo>();
        
        // Check if seat exists in aircraft configuration
        AircraftConfiguration aircraftConfig = seatMapService.getAircraftConfiguration(aircraftType);
        if (aircraftConfig == null || !aircraftConfig.seatExists(seatCode)) {
            conflicts.add(ConflictInfo.createSeatBlocked(seatCode, 'Seat does not exist in aircraft configuration'));
            return conflicts;
        }
        
        // Check cabin class compatibility
        String seatCabinClass = aircraftConfig.getCabinClassForRow(getSeatRow(seatCode));
        if (String.isNotBlank(seatCabinClass) && !passengerService.canAssignToCabin(passenger, seatCabinClass)) {
            conflicts.add(ConflictInfo.createCabinMismatch(seatCode, passenger.getCabinClass(), seatCabinClass));
        }
        
        // Check if seat is available
        if (!seatMapService.isSeatAvailable(seatCode, aircraftType, flightNumber, departureDate)) {
            conflicts.add(ConflictInfo.createSeatBlocked(seatCode, 'Seat is not available'));
        }
        
        // Check for existing assignments
        List<PassengerDisplayInfo> conflictingPassengers = passengerService.getConflictingPassengers(seatCode, passenger.externalId);
        for (PassengerDisplayInfo conflictingPassenger : conflictingPassengers) {
            conflicts.add(ConflictInfo.createAlreadyAssigned(seatCode, conflictingPassenger.name, passenger.name));
        }
        
        // Check for duplicate assignment (same passenger assigned to this seat)
        if (String.isNotBlank(passenger.currentSeat) && passenger.currentSeat.equals(seatCode)) {
            conflicts.add(ConflictInfo.createDuplicateAssignment(seatCode, passenger.name));
        }
        
        // Check special needs requirements
        if (passengerService.hasSpecialNeeds(passenger)) {
            // This would be expanded based on specific special needs requirements
            // For now, just check if it's an aisle seat for wheelchair passengers
            if (passenger.hasSpecialRequirements && !isAisleSeat(seatCode)) {
                conflicts.add(ConflictInfo.createSpecialNeeds(seatCode, 'Special needs passenger requires aisle seat'));
            }
        }
        
        return conflicts;
    }
    
    /**
     * @description Clear passenger's current seat assignment
     * @param passengerId Passenger external ID
     * @return Success status
     */
    private Boolean clearPassengerSeatAssignment(String passengerId) {
        try {
            // Find current assignment
            PassengerDisplayInfo passenger = passengerService.getPassengerById(passengerId);
            if (passenger != null && String.isNotBlank(passenger.currentSeat)) {
                // Clear the assignment
                return updatePassengerSeatAssignment(passengerId, null);
            }
            
            return true; // No current assignment to clear
            
        } catch (Exception e) {
            System.debug('Error clearing seat assignment: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Update passenger seat assignment in database
     * @param passengerId Passenger external ID
     * @param seatCode New seat code (null to clear)
     * @return Success status
     */
    private Boolean updatePassengerSeatAssignment(String passengerId, String seatCode) {
        try {
            // Find traveller record
            RepositoryQuery query = new RepositoryQuery();
            query.addExternalId(passengerId);
            query.limitSize = 1;
            
            List<TravellerInfo__c> travellers = travellerRepository.findTravellers(query);
            
            if (travellers.isEmpty()) {
                return false;
            }
            
            TravellerInfo__c traveller = travellers[0];
            traveller.Seat__c = seatCode;
            
            return travellerRepository.updateTravellers(new List<TravellerInfo__c>{traveller});
            
        } catch (Exception e) {
            System.debug('Error updating seat assignment: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Sync seat assignment with external API
     * @param passenger Passenger information
     * @param seatCode Seat code
     * @param flightNumber Flight number
     * @param departureDate Departure date
     */
    private void syncSeatAssignmentWithAPI(PassengerDisplayInfo passenger, String seatCode, String flightNumber, Date departureDate) {
        try {
            if (String.isBlank(flightNumber) || departureDate == null) {
                return; // Cannot sync without flight details
            }
            
            // TODO: Implement seat assignment API sync when available in AmadeusUtil
            // The current AmadeusUtil does not have a seat assignment method
            System.debug('Seat assignment API sync not yet implemented - local assignment only');
            
        } catch (Exception e) {
            System.debug('Error syncing with API: ' + e.getMessage());
            // Continue - local assignment is still valid
        }
    }
    
    /**
     * @description Get row number from seat code
     * @param seatCode Seat code
     * @return Row number
     */
    private Integer getSeatRow(String seatCode) {
        if (String.isBlank(seatCode)) {
            return null;
        }
        
        try {
            String rowStr = seatCode.substring(0, seatCode.length() - 1);
            return Integer.valueOf(rowStr);
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * @description Check if seat is an aisle seat
     * @param seatCode Seat code
     * @return True if aisle seat
     */
    private Boolean isAisleSeat(String seatCode) {
        if (String.isBlank(seatCode)) {
            return false;
        }
        
        String column = seatCode.substring(seatCode.length() - 1);
        
        // Aisle seats are typically C, D, G, H depending on aircraft configuration
        Set<String> aisleSeatColumns = new Set<String>{'C', 'D', 'G', 'H'};
        return aisleSeatColumns.contains(column);
    }
}