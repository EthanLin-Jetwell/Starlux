/**
 * @description Result of seat map service operations
 * @author STARLUX Development Team
 * @date 2024
 */
public class SeatMapResult {
    public String aircraftType { get; set; }
    public List<String> cabinClasses { get; set; }
    public List<String> disabledSeats { get; set; }
    public List<String> noWindowSeats { get; set; }
    public Boolean success { get; set; }
    public String errorMessage { get; set; }
    public AircraftConfiguration aircraftConfig { get; set; }
    public Map<String, List<String>> availableSeats { get; set; }
    
    /**
     * @description Default constructor
     */
    public SeatMapResult() {
        this.cabinClasses = new List<String>();
        this.disabledSeats = new List<String>();
        this.noWindowSeats = new List<String>();
        this.success = false;
        this.availableSeats = new Map<String, List<String>>();
    }
    
    /**
     * @description Constructor with aircraft type
     * @param aircraftType Aircraft type code
     */
    public SeatMapResult(String aircraftType) {
        this();
        this.aircraftType = aircraftType;
        this.success = true;
    }
    
    /**
     * @description Create error result
     * @param errorMessage Error message
     * @return SeatMapResult with error
     */
    public static SeatMapResult createError(String errorMessage) {
        SeatMapResult result = new SeatMapResult();
        result.success = false;
        result.errorMessage = errorMessage;
        return result;
    }
    
    /**
     * @description Add cabin class
     * @param cabinClass Cabin class code
     */
    public void addCabinClass(String cabinClass) {
        if (String.isNotBlank(cabinClass) && !cabinClasses.contains(cabinClass)) {
            cabinClasses.add(cabinClass);
        }
    }
    
    /**
     * @description Add disabled seat
     * @param seatCode Seat code to disable
     */
    public void addDisabledSeat(String seatCode) {
        if (String.isNotBlank(seatCode) && !disabledSeats.contains(seatCode)) {
            disabledSeats.add(seatCode);
        }
    }
    
    /**
     * @description Add no-window seat
     * @param seatCode Seat code with no window
     */
    public void addNoWindowSeat(String seatCode) {
        if (String.isNotBlank(seatCode) && !noWindowSeats.contains(seatCode)) {
            noWindowSeats.add(seatCode);
        }
    }
    
    /**
     * @description Set available seats for cabin class
     * @param cabinClass Cabin class code
     * @param seats List of available seat codes
     */
    public void setAvailableSeats(String cabinClass, List<String> seats) {
        if (String.isNotBlank(cabinClass)) {
            availableSeats.put(cabinClass, seats != null ? seats : new List<String>());
        }
    }
    
    /**
     * @description Get available seats for cabin class
     * @param cabinClass Cabin class code
     * @return List of available seat codes
     */
    public List<String> getAvailableSeats(String cabinClass) {
        List<String> seats = availableSeats.get(cabinClass);
        return seats != null ? seats : new List<String>();
    }
    
    /**
     * @description Check if seat is available
     * @param seatCode Seat code to check
     * @return True if available
     */
    public Boolean isSeatAvailable(String seatCode) {
        if (String.isBlank(seatCode)) {
            return false;
        }
        
        // Check if seat is disabled
        if (disabledSeats.contains(seatCode)) {
            return false;
        }
        
        // Check if seat exists in any cabin's available seats
        for (List<String> seats : availableSeats.values()) {
            if (seats.contains(seatCode)) {
                return true;
            }
        }
        
        return false;
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
     * @description Get total number of available seats
     * @return Total available seats count
     */
    public Integer getTotalAvailableSeats() {
        Integer total = 0;
        for (List<String> seats : availableSeats.values()) {
            total += seats.size();
        }
        return total;
    }
    
    /**
     * @description Get cabin class for seat code
     * @param seatCode Seat code
     * @return Cabin class code
     */
    public String getCabinClassForSeat(String seatCode) {
        if (String.isBlank(seatCode)) {
            return null;
        }
        
        for (String cabinClass : availableSeats.keySet()) {
            if (availableSeats.get(cabinClass).contains(seatCode)) {
                return cabinClass;
            }
        }
        
        return null;
    }
    
    /**
     * @description Convert to SeatMapData for UI
     * @return SeatMapData object
     */
    public SeatMapData toSeatMapData() {
        SeatMapData seatMapData = new SeatMapData(aircraftType);
        
        // Override with actual data from API
        seatMapData.disabledSeats.clear();
        seatMapData.disabledSeats.addAll(disabledSeats);
        
        seatMapData.noWindowSeats.clear();
        seatMapData.noWindowSeats.addAll(noWindowSeats);
        
        seatMapData.cabinClasses.clear();
        seatMapData.cabinClasses.addAll(cabinClasses);
        
        // Refresh JSON for JavaScript
        seatMapData.cabinClassesJSON = JSON.serialize(cabinClasses);
        seatMapData.disabledSeatsJSON = JSON.serialize(disabledSeats);
        seatMapData.noWindowSeatsJSON = JSON.serialize(noWindowSeats);
        
        return seatMapData;
    }
    
    /**
     * @description Check if result is valid and has data
     * @return True if valid
     */
    public Boolean isValid() {
        return success && String.isNotBlank(aircraftType) && !cabinClasses.isEmpty();
    }
}