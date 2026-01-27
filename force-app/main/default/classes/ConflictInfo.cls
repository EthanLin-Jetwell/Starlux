/**
 * @description Information about seat assignment conflicts
 * @author STARLUX Development Team
 * @date 2024
 */
public class ConflictInfo {
    public String seatCode { get; set; }
    public String conflictType { get; set; }
    public String currentPassenger { get; set; }
    public String newPassenger { get; set; }
    public String conflictMessage { get; set; }
    public Boolean canOverride { get; set; }
    public DateTime conflictTime { get; set; }
    
    // Conflict types constants
    public static final String CONFLICT_ALREADY_ASSIGNED = 'ALREADY_ASSIGNED';
    public static final String CONFLICT_SEAT_BLOCKED = 'SEAT_BLOCKED';
    public static final String CONFLICT_CABIN_MISMATCH = 'CABIN_MISMATCH';
    public static final String CONFLICT_SPECIAL_NEEDS = 'SPECIAL_NEEDS';
    public static final String CONFLICT_DUPLICATE_ASSIGNMENT = 'DUPLICATE_ASSIGNMENT';
    
    /**
     * @description Default constructor
     */
    public ConflictInfo() {
        this.canOverride = false;
        this.conflictTime = DateTime.now();
    }
    
    /**
     * @description Constructor with basic conflict info
     * @param seatCode Seat code in conflict
     * @param conflictType Type of conflict
     * @param conflictMessage Conflict description
     */
    public ConflictInfo(String seatCode, String conflictType, String conflictMessage) {
        this();
        this.seatCode = seatCode;
        this.conflictType = conflictType;
        this.conflictMessage = conflictMessage;
    }
    
    /**
     * @description Constructor with passenger information
     * @param seatCode Seat code in conflict
     * @param conflictType Type of conflict
     * @param currentPassenger Current passenger name
     * @param newPassenger New passenger name
     */
    public ConflictInfo(String seatCode, String conflictType, String currentPassenger, String newPassenger) {
        this();
        this.seatCode = seatCode;
        this.conflictType = conflictType;
        this.currentPassenger = currentPassenger;
        this.newPassenger = newPassenger;
        generateConflictMessage();
    }
    
    /**
     * @description Create already assigned conflict
     * @param seatCode Seat code
     * @param currentPassenger Current passenger
     * @param newPassenger New passenger
     * @return Conflict info
     */
    public static ConflictInfo createAlreadyAssigned(String seatCode, String currentPassenger, String newPassenger) {
        ConflictInfo conflict = new ConflictInfo(seatCode, CONFLICT_ALREADY_ASSIGNED, currentPassenger, newPassenger);
        conflict.canOverride = true;
        return conflict;
    }
    
    /**
     * @description Create seat blocked conflict
     * @param seatCode Seat code
     * @param reason Blocking reason
     * @return Conflict info
     */
    public static ConflictInfo createSeatBlocked(String seatCode, String reason) {
        ConflictInfo conflict = new ConflictInfo(seatCode, CONFLICT_SEAT_BLOCKED, 'Seat ' + seatCode + ' is blocked: ' + reason);
        conflict.canOverride = false;
        return conflict;
    }
    
    /**
     * @description Create cabin mismatch conflict
     * @param seatCode Seat code
     * @param passengerCabin Passenger's cabin class
     * @param seatCabin Seat's cabin class
     * @return Conflict info
     */
    public static ConflictInfo createCabinMismatch(String seatCode, String passengerCabin, String seatCabin) {
        String message = 'Cabin mismatch: Passenger is in ' + passengerCabin + ' but seat ' + seatCode + ' is in ' + seatCabin;
        ConflictInfo conflict = new ConflictInfo(seatCode, CONFLICT_CABIN_MISMATCH, message);
        conflict.canOverride = false;
        return conflict;
    }
    
    /**
     * @description Create special needs conflict
     * @param seatCode Seat code
     * @param specialNeeds Special needs requirement
     * @return Conflict info
     */
    public static ConflictInfo createSpecialNeeds(String seatCode, String specialNeeds) {
        String message = 'Seat ' + seatCode + ' does not meet special needs requirement: ' + specialNeeds;
        ConflictInfo conflict = new ConflictInfo(seatCode, CONFLICT_SPECIAL_NEEDS, message);
        conflict.canOverride = false;
        return conflict;
    }
    
    /**
     * @description Create duplicate assignment conflict
     * @param seatCode Seat code
     * @param passengerName Passenger name
     * @return Conflict info
     */
    public static ConflictInfo createDuplicateAssignment(String seatCode, String passengerName) {
        String message = 'Passenger ' + passengerName + ' is already assigned to seat ' + seatCode;
        ConflictInfo conflict = new ConflictInfo(seatCode, CONFLICT_DUPLICATE_ASSIGNMENT, message);
        conflict.canOverride = true;
        return conflict;
    }
    
    /**
     * @description Generate conflict message based on type and passengers
     */
    private void generateConflictMessage() {
        switch on conflictType {
            when 'ALREADY_ASSIGNED' {
                conflictMessage = 'Seat ' + seatCode + ' is already assigned to ' + currentPassenger + 
                                 '. Attempting to assign to ' + newPassenger + '.';
            }
            when 'DUPLICATE_ASSIGNMENT' {
                conflictMessage = 'Passenger ' + newPassenger + ' is already assigned to seat ' + seatCode + '.';
            }
            when else {
                conflictMessage = 'Conflict with seat ' + seatCode + ': ' + conflictType;
            }
        }
    }
    
    /**
     * @description Check if conflict is critical (cannot be overridden)
     * @return True if critical
     */
    public Boolean isCritical() {
        return !canOverride;
    }
    
    /**
     * @description Check if conflict is related to passenger assignment
     * @return True if passenger-related
     */
    public Boolean isPassengerConflict() {
        return conflictType == CONFLICT_ALREADY_ASSIGNED || 
               conflictType == CONFLICT_DUPLICATE_ASSIGNMENT;
    }
    
    /**
     * @description Check if conflict is related to seat availability
     * @return True if seat-related
     */
    public Boolean isSeatConflict() {
        return conflictType == CONFLICT_SEAT_BLOCKED || 
               conflictType == CONFLICT_CABIN_MISMATCH || 
               conflictType == CONFLICT_SPECIAL_NEEDS;
    }
    
    /**
     * @description Get conflict severity level
     * @return Severity (HIGH, MEDIUM, LOW)
     */
    public String getSeverity() {
        switch on conflictType {
            when 'SEAT_BLOCKED', 'CABIN_MISMATCH', 'SPECIAL_NEEDS' {
                return 'HIGH';
            }
            when 'ALREADY_ASSIGNED' {
                return 'MEDIUM';
            }
            when 'DUPLICATE_ASSIGNMENT' {
                return 'LOW';
            }
            when else {
                return 'MEDIUM';
            }
        }
    }
    
    /**
     * @description Get formatted conflict description for UI
     * @return Formatted description
     */
    public String getFormattedDescription() {
        String description = conflictMessage;
        
        if (canOverride) {
            description += ' (Can be overridden)';
        } else {
            description += ' (Cannot be overridden)';
        }
        
        return description;
    }
    
    /**
     * @description Convert to JSON for JavaScript processing
     * @return JSON string
     */
    public String toJSON() {
        Map<String, Object> data = new Map<String, Object>{
            'seatCode' => seatCode,
            'conflictType' => conflictType,
            'conflictMessage' => conflictMessage,
            'canOverride' => canOverride,
            'severity' => getSeverity(),
            'currentPassenger' => currentPassenger,
            'newPassenger' => newPassenger
        };
        
        return JSON.serialize(data);
    }
}