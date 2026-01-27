/**
 * @description Seat map data for UI rendering
 * @author STARLUX Development Team
 * @date 2024
 */
public class SeatMapData {
    @AuraEnabled
    public String aircraftType { get; set; }
    public List<String> cabinClasses { get; set; }
    @AuraEnabled
    public List<String> disabledSeats { get; set; }
    @AuraEnabled
    public List<String> noWindowSeats { get; set; }
    @AuraEnabled
    public Map<String, Integer> cabinRowRanges { get; set; }
    @AuraEnabled
    public String cabinClassesJSON { get; set; }
    @AuraEnabled
    public String disabledSeatsJSON { get; set; }
    @AuraEnabled
    public String noWindowSeatsJSON { get; set; }
    
    /**
     * @description Default constructor
     */
    public SeatMapData() {
        this.cabinClasses = new List<String>();
        this.disabledSeats = new List<String>();
        this.noWindowSeats = new List<String>();
        this.cabinRowRanges = new Map<String, Integer>();
    }
    
    /**
     * @description Constructor with aircraft type
     * @param aircraftType Aircraft type code
     */
    public SeatMapData(String aircraftType) {
        this();
        this.aircraftType = aircraftType;
        initializeForAircraftType();
    }
    
    /**
     * @description Initialize seat map based on aircraft type
     */
    private void initializeForAircraftType() {
        switch on aircraftType {
            when '32Q' { // A321 neo
                cabinClasses.addAll(new List<String>{'J', 'Y'});
                cabinRowRanges.put('J', 6);   // Rows 1-6
                cabinRowRanges.put('Y', 50);  // Rows 7-56
            }
            when '339' { // A330 neo
                cabinClasses.addAll(new List<String>{'J', 'Y'});
                cabinRowRanges.put('J', 7);   // Rows 1-7
                cabinRowRanges.put('Y', 50);  // Rows 8-57
            }
            when '359' { // A350-900
                cabinClasses.addAll(new List<String>{'F', 'J', 'W', 'Y'});
                cabinRowRanges.put('F', 2);   // Rows 1-2
                cabinRowRanges.put('J', 7);   // Rows 6-12
                cabinRowRanges.put('W', 4);   // Rows 18-21
                cabinRowRanges.put('Y', 42);  // Rows 22-63
            }
        }
        
        // Convert to JSON for JavaScript usage
        refreshJSON();
    }
    
    /**
     * @description Add disabled seat
     * @param seatCode Seat code to disable
     */
    public void addDisabledSeat(String seatCode) {
        if (String.isNotBlank(seatCode) && !disabledSeats.contains(seatCode)) {
            disabledSeats.add(seatCode);
            refreshJSON();
        }
    }
    
    /**
     * @description Add no-window seat
     * @param seatCode Seat code with no window
     */
    public void addNoWindowSeat(String seatCode) {
        if (String.isNotBlank(seatCode) && !noWindowSeats.contains(seatCode)) {
            noWindowSeats.add(seatCode);
            refreshJSON();
        }
    }
    
    /**
     * @description Check if seat is disabled
     * @param seatCode Seat code to check
     * @return True if disabled
     */
    public Boolean isSeatDisabled(String seatCode) {
        return disabledSeats.contains(seatCode);
    }
    
    /**
     * @description Check if seat has no window
     * @param seatCode Seat code to check
     * @return True if no window
     */
    public Boolean isNoWindowSeat(String seatCode) {
        return noWindowSeats.contains(seatCode);
    }
    
    /**
     * @description Get cabin class for row number
     * @param rowNumber Row number
     * @return Cabin class code
     */
    public String getCabinClassForRow(Integer rowNumber) {
        if (rowNumber == null) {
            return null;
        }
        
        switch on aircraftType {
            when '32Q' { // A321 neo
                return rowNumber <= 6 ? 'J' : 'Y';
            }
            when '339' { // A330 neo
                return rowNumber <= 7 ? 'J' : 'Y';
            }
            when '359' { // A350-900
                if (rowNumber <= 2) return 'F';
                if (rowNumber >= 6 && rowNumber <= 12) return 'J';
                if (rowNumber >= 18 && rowNumber <= 21) return 'W';
                if (rowNumber >= 22) return 'Y';
                return null; // Gap rows
            }
            when else {
                return null;
            }
        }
    }
    
    /**
     * @description Refresh JSON strings for JavaScript usage
     */
    private void refreshJSON() {
        this.cabinClassesJSON = JSON.serialize(cabinClasses);
        this.disabledSeatsJSON = JSON.serialize(disabledSeats);
        this.noWindowSeatsJSON = JSON.serialize(noWindowSeats);
    }
    
    /**
     * @description Check if seat map is valid
     * @return True if valid
     */
    public Boolean isValid() {
        return String.isNotBlank(aircraftType) && !cabinClasses.isEmpty();
    }
}