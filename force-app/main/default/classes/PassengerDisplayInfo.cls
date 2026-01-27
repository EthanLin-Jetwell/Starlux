/**
 * @description Passenger display information for UI components
 * @author STARLUX Development Team
 * @date 2024
 */
public class PassengerDisplayInfo {
    @AuraEnabled
    public String id { get; set; }
    @AuraEnabled
    public String externalId { get; set; }
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String currentSeat { get; set; }
    @AuraEnabled
    public String passengerType { get; set; }
    @AuraEnabled
    public Boolean canSelectSeat { get; set; }
    @AuraEnabled
    public String seatRestrictions { get; set; }
    @AuraEnabled
    public Integer sequenceNumber { get; set; }
    @AuraEnabled
    public String pnrCode { get; set; }
    public Boolean hasSpecialRequirements { get; set; }
    
    /**
     * @description Default constructor
     */
    public PassengerDisplayInfo() {
        this.canSelectSeat = true;
        this.hasSpecialRequirements = false;
        this.sequenceNumber = 0;
    }
    
    /**
     * @description Constructor with basic information
     * @param id Passenger ID
     * @param name Passenger name
     * @param passengerType Passenger type (ADT, CHD, etc.)
     */
    public PassengerDisplayInfo(String id, String name, String passengerType) {
        this();
        this.id = id;
        this.name = name;
        this.passengerType = passengerType;
    }
    
    /**
     * @description Check if passenger has seat assigned
     * @return True if seat is assigned
     */
    public Boolean hasSeatAssigned() {
        return String.isNotBlank(currentSeat);
    }
    
    /**
     * @description Get display text for seat
     * @return Seat display text
     */
    public String getSeatDisplayText() {
        if (hasSeatAssigned()) {
            return currentSeat;
        }
        return 'Not assigned';
    }
    
    /**
     * @description Check if passenger can be assigned to seat
     * @param seatCode Seat code to check
     * @return True if assignment is allowed
     */
    public Boolean canAssignToSeat(String seatCode) {
        if (!canSelectSeat) {
            return false;
        }
        
        // Additional validation logic can be added here
        return String.isNotBlank(seatCode);
    }
    
    /**
     * @description Get cabin class from passenger type
     * @return Cabin class code
     */
    public String getCabinClass() {
        // This would typically be determined by booking class or fare type
        // For now, return default based on passenger type
        if (String.isNotBlank(passengerType)) {
            // This logic would need to be customized based on business rules
            return 'Y'; // Default to economy
        }
        return null;
    }
    
    /**
     * @description Create from TravellerInfo__c record
     * @param traveller TravellerInfo__c record
     * @return PassengerDisplayInfo instance
     */
    public static PassengerDisplayInfo fromTravellerInfo(TravellerInfo__c traveller) {
        if (traveller == null) {
            return null;
        }
        
        PassengerDisplayInfo passenger = new PassengerDisplayInfo();
        passenger.id = traveller.Id;
        passenger.externalId = traveller.External_ID__c;
        passenger.name = buildFullName(traveller);
        passenger.currentSeat = traveller.Seat__c;
        passenger.passengerType = traveller.PassengerType__c;
        passenger.pnrCode = traveller.PNR__c;
        passenger.sequenceNumber = Integer.valueOf(traveller.PT__c != null ? traveller.PT__c : '0');
        
        // Set business logic flags
        passenger.canSelectSeat = determineCanSelectSeat(traveller);
        passenger.hasSpecialRequirements = hasSpecialRequirements(traveller);
        passenger.seatRestrictions = buildSeatRestrictions(traveller);
        
        return passenger;
    }
    
    /**
     * @description Build full name from TravellerInfo__c
     * @param traveller TravellerInfo__c record
     * @return Full name
     */
    private static String buildFullName(TravellerInfo__c traveller) {
        List<String> nameParts = new List<String>();
        
        if (String.isNotBlank(traveller.title__c)) {
            nameParts.add(traveller.title__c);
        }
        if (String.isNotBlank(traveller.firstName__c)) {
            nameParts.add(traveller.firstName__c);
        }
        if (String.isNotBlank(traveller.LastName__c)) {
            nameParts.add(traveller.LastName__c);
        }
        
        return String.join(nameParts, ' ');
    }
    
    /**
     * @description Determine if passenger can select seat
     * @param traveller TravellerInfo__c record
     * @return True if can select seat
     */
    private static Boolean determineCanSelectSeat(TravellerInfo__c traveller) {
        // Business logic to determine if passenger can select seat
        // For example, infants might not be able to select certain seats
        if (traveller.PassengerType__c == 'INF') {
            return false;
        }
        
        return true;
    }
    
    /**
     * @description Check if passenger has special requirements
     * @param traveller TravellerInfo__c record
     * @return True if has special requirements
     */
    private static Boolean hasSpecialRequirements(TravellerInfo__c traveller) {
        // Check SSR data or other fields for special requirements
        return String.isNotBlank(traveller.SSR_RawData__c);
    }
    
    /**
     * @description Build seat restrictions text
     * @param traveller TravellerInfo__c record
     * @return Seat restrictions description
     */
    private static String buildSeatRestrictions(TravellerInfo__c traveller) {
        List<String> restrictions = new List<String>();
        
        if (traveller.PassengerType__c == 'INF') {
            restrictions.add('Infant - limited seat selection');
        }
        
        if (String.isNotBlank(traveller.SSR_RawData__c)) {
            restrictions.add('Special service requirements apply');
        }
        
        return restrictions.isEmpty() ? null : String.join(restrictions, '; ');
    }
}