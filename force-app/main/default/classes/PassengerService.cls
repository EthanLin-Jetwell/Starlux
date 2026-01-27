/**
 * @description Passenger Service Implementation
 * @author STARLUX Development Team
 * @date 2024
 */
public class PassengerService implements IPassengerService {
    private ITravellerRepository travellerRepository;
    
    /**
     * @description Constructor with dependencies
     */
    public PassengerService() {
        // this.travellerRepository = ServiceFactory.getTravellerRepository(); // TODO: 這邊要改成從外部取得
        this.travellerRepository = new TravellerRepository();
    }
    
    /**
     * @description Constructor for testing with mocks
     * @param travellerRepository Mock repository
     */
    public PassengerService(ITravellerRepository travellerRepository) {
        this.travellerRepository = travellerRepository;
    }
    
    /**
     * @description Get passengers for PNR
     * @param pnrCode PNR code
     * @return List of passenger display info
     */
    public List<PassengerDisplayInfo> getPassengersForPNR(String pnrCode) {
        try {
            List<PassengerDisplayInfo> passengers = new List<PassengerDisplayInfo>();
            
            if (String.isBlank(pnrCode)) {
                return passengers;
            }
            
            // Query repository
            RepositoryQuery query = new RepositoryQuery();
            query.addPNRCode(pnrCode);
            query.orderBy = 'Name';
            
            List<TravellerInfo__c> travellers = travellerRepository.findTravellers(query);
            
            // Convert to passenger display info
            for (TravellerInfo__c traveller : travellers) {
                PassengerDisplayInfo passenger = PassengerDisplayInfo.fromTravellerInfo(traveller);
                passengers.add(passenger);
            }
            
            return passengers;
            
        } catch (Exception e) {
            System.debug('Error in getPassengersForPNR: ' + e.getMessage());
            return new List<PassengerDisplayInfo>();
        }
    }
    
    /**
     * @description Get passenger by external ID
     * @param externalId External passenger ID
     * @return Passenger display info
     */
    public PassengerDisplayInfo getPassengerById(String externalId) {
        try {
            if (String.isBlank(externalId)) {
                return null;
            }
            
            // Query repository
            RepositoryQuery query = new RepositoryQuery();
            query.addExternalId(externalId);
            query.limitSize = 1;
            
            List<TravellerInfo__c> travellers = travellerRepository.findTravellers(query);
            
            if (travellers.isEmpty()) {
                return null;
            }
            
            return PassengerDisplayInfo.fromTravellerInfo(travellers[0]);
            
        } catch (Exception e) {
            System.debug('Error in getPassengerById: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Update passenger information
     * @param passenger Updated passenger info
     * @return Success status
     */
    public Boolean updatePassenger(PassengerDisplayInfo passenger) {
        try {
            if (passenger == null || String.isBlank(passenger.externalId)) {
                return false;
            }
            
            // Find existing traveller record
            RepositoryQuery query = new RepositoryQuery();
            query.addExternalId(passenger.externalId);
            query.limitSize = 1;
            
            List<TravellerInfo__c> travellers = travellerRepository.findTravellers(query);
            
            if (travellers.isEmpty()) {
                return false;
            }
            
            TravellerInfo__c traveller = travellers[0];
            
            // Update fields that can be modified
            traveller.Seat__c = passenger.currentSeat;
            traveller.SSR_RawData__c = passenger.hasSpecialRequirements ? 'SPECIAL_REQUIREMENTS' : null;
            
            // Save changes
            return travellerRepository.updateTravellers(new List<TravellerInfo__c>{traveller});
            
        } catch (Exception e) {
            System.debug('Error in updatePassenger: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Validate passenger data
     * @param passenger Passenger to validate
     * @return Validation result
     */
    public ValidationResult validatePassenger(PassengerDisplayInfo passenger) {
        ValidationResult result = new ValidationResult();
        
        try {
            if (passenger == null) {
                result.addError(new ValidationError('passenger', 'Passenger data is required'));
                return result;
            }
            
            // Basic validation
            if (String.isBlank(passenger.name)) {
                result.addError(new ValidationError('name', 'Passenger name is required'));
            }
            
            String cabinClass = passenger.getCabinClass();
            if (String.isBlank(cabinClass)) {
                result.addError(new ValidationError('cabinClass', 'Cabin class is required'));
            }
            
            // Validate seat assignment format if provided
            if (String.isNotBlank(passenger.currentSeat)) {
                if (!isValidSeatFormat(passenger.currentSeat)) {
                    result.addError(new ValidationError('seatAssignment', 'Invalid seat format: ' + passenger.currentSeat));
                }
            }
            
            // Validate special needs if provided
            if (passenger.hasSpecialRequirements) {
                // Additional validation for special requirements can be added here
                System.debug('Passenger has special requirements');
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in validatePassenger: ' + e.getMessage());
            result.addError(new ValidationError('system', 'System error during passenger validation'));
            return result;
        }
    }
    
    /**
     * @description Check if passenger has special needs
     * @param passenger Passenger to check
     * @return True if has special needs
     */
    public Boolean hasSpecialNeeds(PassengerDisplayInfo passenger) {
        if (passenger == null) {
            return false;
        }
        
        return passenger.hasSpecialRequirements;
    }
    
    /**
     * @description Get passenger's cabin class restrictions
     * @param passenger Passenger
     * @return List of allowed cabin classes
     */
    public List<String> getAllowedCabinClasses(PassengerDisplayInfo passenger) {
        List<String> allowedCabins = new List<String>();
        
        if (passenger == null) {
            return allowedCabins;
        }
        
        String cabinClass = passenger.getCabinClass();
        if (String.isBlank(cabinClass)) {
            return allowedCabins;
        }
        
        // Passengers can select seats in their booked cabin class or higher
        switch on cabinClass {
            when 'F' { // First Class
                allowedCabins.add('F');
            }
            when 'J' { // Business Class
                allowedCabins.addAll(new List<String>{'F', 'J'});
            }
            when 'W' { // Premium Economy
                allowedCabins.addAll(new List<String>{'F', 'J', 'W'});
            }
            when 'Y' { // Economy
                allowedCabins.addAll(new List<String>{'F', 'J', 'W', 'Y'});
            }
            when else {
                // Default to their booked cabin
                allowedCabins.add(cabinClass);
            }
        }
        
        return allowedCabins;
    }
    
    /**
     * @description Check if passenger can be assigned to cabin class
     * @param passenger Passenger
     * @param targetCabinClass Target cabin class
     * @return True if allowed
     */
    public Boolean canAssignToCabin(PassengerDisplayInfo passenger, String targetCabinClass) {
        if (passenger == null || String.isBlank(targetCabinClass)) {
            return false;
        }
        
        List<String> allowedCabins = getAllowedCabinClasses(passenger);
        return allowedCabins.contains(targetCabinClass);
    }
    
    /**
     * @description Get passengers with conflicts for seat assignment
     * @param seatCode Seat code to check
     * @param excludePassengerId Passenger ID to exclude from check
     * @return List of conflicting passengers
     */
    public List<PassengerDisplayInfo> getConflictingPassengers(String seatCode, String excludePassengerId) {
        try {
            List<PassengerDisplayInfo> conflictingPassengers = new List<PassengerDisplayInfo>();
            
            if (String.isBlank(seatCode)) {
                return conflictingPassengers;
            }
            
            // Find travellers assigned to this seat
            List<TravellerInfo__c> travellers = travellerRepository.findTravellersBySeat(seatCode);
            
            for (TravellerInfo__c traveller : travellers) {
                // Exclude the specified passenger
                if (String.isNotBlank(excludePassengerId) && 
                    traveller.External_ID__c == excludePassengerId) {
                    continue;
                }
                
                PassengerDisplayInfo passenger = PassengerDisplayInfo.fromTravellerInfo(traveller);
                conflictingPassengers.add(passenger);
            }
            
            return conflictingPassengers;
            
        } catch (Exception e) {
            System.debug('Error in getConflictingPassengers: ' + e.getMessage());
            return new List<PassengerDisplayInfo>();
        }
    }
    
    /**
     * @description Validate seat format
     * @param seatCode Seat code to validate
     * @return True if valid format
     */
    private Boolean isValidSeatFormat(String seatCode) {
        if (String.isBlank(seatCode)) {
            return false;
        }
        
        // Basic format validation: number followed by letter(s)
        Pattern seatPattern = Pattern.compile('^\\d{1,2}[A-K]$');
        return seatPattern.matcher(seatCode).matches();
    }
}