/**
 * @description Aircraft configuration for seat layout
 * @author STARLUX Development Team
 * @date 2024
 */
public class AircraftConfiguration {
    public String aircraftType { get; set; }
    public Map<String, CabinConfiguration> cabinConfigs { get; set; }
    public Integer totalSeats { get; set; }
    public List<String> seatColumns { get; set; }
    public Map<String, String> seatTypeMapping { get; set; }
    
    /**
     * @description Default constructor
     */
    public AircraftConfiguration() {
        this.cabinConfigs = new Map<String, CabinConfiguration>();
        this.seatColumns = new List<String>();
        this.seatTypeMapping = new Map<String, String>();
        this.totalSeats = 0;
    }
    
    /**
     * @description Constructor with aircraft type
     * @param aircraftType Aircraft type code
     */
    public AircraftConfiguration(String aircraftType) {
        this();
        this.aircraftType = aircraftType;
        initializeConfiguration();
    }
    
    /**
     * @description Initialize configuration based on aircraft type
     */
    private void initializeConfiguration() {
        switch on aircraftType {
            when '32Q' { // A321 neo
                initializeA321Configuration();
            }
            when '339' { // A330 neo
                initializeA330Configuration();
            }
            when '359' { // A350-900
                initializeA350Configuration();
            }
            when '38M' { // A380-800 (if STARLUX operates)
                initializeA380Configuration();
            }
            when '77W' { // Boeing 777-300ER (if STARLUX operates)
                initializeB777Configuration();
            }
            when else {
                // Default fallback configuration
                initializeDefaultConfiguration();
            }
        }
    }
    
    /**
     * @description Initialize A321 configuration
     */
    private void initializeA321Configuration() {
        // Business Class (J) - Rows 2-3 (corrected based on feedback)
        CabinConfiguration businessConfig = new CabinConfiguration();
        businessConfig.cabinClass = 'J';
        businessConfig.startRow = 2;
        businessConfig.endRow = 3;
        businessConfig.seatsPerRow = 4;
        businessConfig.seatLayout = '2-2';
        cabinConfigs.put('J', businessConfig);
        
        // Economy Class (Y) - Rows 4-33 (overlaps with business, but different sections)
        CabinConfiguration economyConfig = new CabinConfiguration();
        economyConfig.cabinClass = 'Y';
        economyConfig.startRow = 4;
        economyConfig.endRow = 33;
        economyConfig.seatsPerRow = 6;
        economyConfig.seatLayout = '3-3';
        cabinConfigs.put('Y', economyConfig);
        
        // Set seat columns: Business uses A,C,H,K; Economy uses A,B,C,H,J,K
        seatColumns.addAll(new List<String>{'A', 'B', 'C', 'H', 'J', 'K'});
        totalSeats = 188; // Approximate: (2*4) + (30*6)
    }
    
    /**
     * @description Initialize A330 configuration
     */
    private void initializeA330Configuration() {
        // Business Class (J) - Rows 2-8 (corrected based on feedback)
        CabinConfiguration businessConfig = new CabinConfiguration();
        businessConfig.cabinClass = 'J';
        businessConfig.startRow = 2;
        businessConfig.endRow = 8;
        businessConfig.seatsPerRow = 4;
        businessConfig.seatLayout = '1-2-1';
        cabinConfigs.put('J', businessConfig);
        
        // Economy Class (Y) - Starts from row 20 (based on layout diagram)
        CabinConfiguration economyConfig = new CabinConfiguration();
        economyConfig.cabinClass = 'Y';
        economyConfig.startRow = 20;
        economyConfig.endRow = 50; // Approximate end based on typical A330 layout
        economyConfig.seatsPerRow = 8;
        economyConfig.seatLayout = '2-4-2';
        cabinConfigs.put('Y', economyConfig);
        
        // Set seat columns: Business uses C,E,G,K; Economy uses A,C,D,E,F,G,H,K
        seatColumns.addAll(new List<String>{'A', 'C', 'D', 'E', 'F', 'G', 'H', 'K'});
        totalSeats = 280; // Approximate
    }
    
    /**
     * @description Initialize A350 configuration
     */
    private void initializeA350Configuration() {
        // First Class (F) - Row 1 only
        CabinConfiguration firstConfig = new CabinConfiguration();
        firstConfig.cabinClass = 'F';
        firstConfig.startRow = 1;
        firstConfig.endRow = 1;
        firstConfig.seatsPerRow = 4;
        firstConfig.seatLayout = '1-2-1';
        cabinConfigs.put('F', firstConfig);
        
        // Business Class (J) - Rows 2-8
        CabinConfiguration businessConfig = new CabinConfiguration();
        businessConfig.cabinClass = 'J';
        businessConfig.startRow = 2;
        businessConfig.endRow = 8;
        businessConfig.seatsPerRow = 4;
        businessConfig.seatLayout = '1-2-1';
        cabinConfigs.put('J', businessConfig);
        
        // Premium Economy (W) - Rows 20-24
        CabinConfiguration premiumConfig = new CabinConfiguration();
        premiumConfig.cabinClass = 'W';
        premiumConfig.startRow = 20;
        premiumConfig.endRow = 24;
        premiumConfig.seatsPerRow = 8;
        premiumConfig.seatLayout = '2-4-2';
        cabinConfigs.put('W', premiumConfig);
        
        // Economy Class (Y) - Rows 30-69 (with gaps)
        CabinConfiguration economyConfig = new CabinConfiguration();
        economyConfig.cabinClass = 'Y';
        economyConfig.startRow = 30;
        economyConfig.endRow = 69;
        economyConfig.seatsPerRow = 9;
        economyConfig.seatLayout = '3-3-3';
        cabinConfigs.put('Y', economyConfig);
        
        // Set seat columns: All cabins combined use A,B,C,D,E,G,H,J,K (no F)
        seatColumns.addAll(new List<String>{'A', 'B', 'C', 'D', 'E', 'G', 'H', 'J', 'K'});
        totalSeats = 306; // Approximate
    }
    
    /**
     * @description Initialize A380 configuration (if applicable)
     */
    private void initializeA380Configuration() {
        // First Class (F) - Upper deck rows 1-3
        CabinConfiguration firstConfig = new CabinConfiguration();
        firstConfig.cabinClass = 'F';
        firstConfig.startRow = 1;
        firstConfig.endRow = 3;
        firstConfig.seatsPerRow = 4;
        firstConfig.seatLayout = '1-2-1';
        cabinConfigs.put('F', firstConfig);
        
        // Business Class (J) - Upper deck rows 6-26
        CabinConfiguration businessConfig = new CabinConfiguration();
        businessConfig.cabinClass = 'J';
        businessConfig.startRow = 6;
        businessConfig.endRow = 26;
        businessConfig.seatsPerRow = 6;
        businessConfig.seatLayout = '1-2-1';
        cabinConfigs.put('J', businessConfig);
        
        // Premium Economy (W) - Main deck rows 38-45
        CabinConfiguration premiumConfig = new CabinConfiguration();
        premiumConfig.cabinClass = 'W';
        premiumConfig.startRow = 38;
        premiumConfig.endRow = 45;
        premiumConfig.seatsPerRow = 8;
        premiumConfig.seatLayout = '2-4-2';
        cabinConfigs.put('W', premiumConfig);
        
        // Economy Class (Y) - Main deck rows 46-88
        CabinConfiguration economyConfig = new CabinConfiguration();
        economyConfig.cabinClass = 'Y';
        economyConfig.startRow = 46;
        economyConfig.endRow = 88;
        economyConfig.seatsPerRow = 10;
        economyConfig.seatLayout = '3-4-3';
        cabinConfigs.put('Y', economyConfig);
        
        seatColumns.addAll(new List<String>{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K'});
        totalSeats = 525; // Approximate
    }
    
    /**
     * @description Initialize B777 configuration (if applicable)
     */
    private void initializeB777Configuration() {
        // Business Class (J) - Rows 1-8
        CabinConfiguration businessConfig = new CabinConfiguration();
        businessConfig.cabinClass = 'J';
        businessConfig.startRow = 1;
        businessConfig.endRow = 8;
        businessConfig.seatsPerRow = 6;
        businessConfig.seatLayout = '1-2-1';
        cabinConfigs.put('J', businessConfig);
        
        // Premium Economy (W) - Rows 15-19
        CabinConfiguration premiumConfig = new CabinConfiguration();
        premiumConfig.cabinClass = 'W';
        premiumConfig.startRow = 15;
        premiumConfig.endRow = 19;
        premiumConfig.seatsPerRow = 7;
        premiumConfig.seatLayout = '2-3-2';
        cabinConfigs.put('W', premiumConfig);
        
        // Economy Class (Y) - Rows 20-60
        CabinConfiguration economyConfig = new CabinConfiguration();
        economyConfig.cabinClass = 'Y';
        economyConfig.startRow = 20;
        economyConfig.endRow = 60;
        economyConfig.seatsPerRow = 9;
        economyConfig.seatLayout = '3-3-3';
        cabinConfigs.put('Y', economyConfig);
        
        seatColumns.addAll(new List<String>{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'K'});
        totalSeats = 350; // Approximate
    }
    
    /**
     * @description Initialize default configuration for unknown aircraft types
     */
    private void initializeDefaultConfiguration() {
        // Basic economy configuration
        CabinConfiguration economyConfig = new CabinConfiguration();
        economyConfig.cabinClass = 'Y';
        economyConfig.startRow = 1;
        economyConfig.endRow = 40;
        economyConfig.seatsPerRow = 6;
        economyConfig.seatLayout = '3-3';
        cabinConfigs.put('Y', economyConfig);
        
        seatColumns.addAll(new List<String>{'A', 'B', 'C', 'D', 'E', 'F'});
        totalSeats = 240; // Basic estimate
    }
    
    /**
     * @description Get cabin configuration for specific cabin class
     * @param cabinClass Cabin class code
     * @return Cabin configuration
     */
    public CabinConfiguration getCabinConfig(String cabinClass) {
        return cabinConfigs.get(cabinClass);
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
            when '32Q' { // A321neo - handle overlapping rows
                // Business class rows 2-3
                if (rowNumber >= 2 && rowNumber <= 3) {
                    return 'J'; // Business
                } else if (rowNumber >= 4 && rowNumber <= 33) {
                    return 'Y'; // Economy
                }
                return null;
            }
            when '339' { // A330neo - no overlapping rows
                if (rowNumber >= 2 && rowNumber <= 8) {
                    return 'J'; // Business
                } else if (rowNumber >= 20 && rowNumber <= 50) {
                    return 'Y'; // Economy
                }
                return null;
            }
            when '359' { // A350-900 - no overlapping rows
                if (rowNumber == 1) {
                    return 'F'; // First
                } else if (rowNumber >= 2 && rowNumber <= 8) {
                    return 'J'; // Business
                } else if (rowNumber >= 20 && rowNumber <= 24) {
                    return 'W'; // Premium Economy
                } else if (rowNumber >= 30 && rowNumber <= 69) {
                    return 'Y'; // Economy
                }
                return null;
            }
            when else {
                // Default logic for other aircraft types
                for (CabinConfiguration config : cabinConfigs.values()) {
                    if (rowNumber >= config.startRow && rowNumber <= config.endRow) {
                        return config.cabinClass;
                    }
                }
                return null;
            }
        }
    }
    
    /**
     * @description Check if seat exists in aircraft
     * @param seatCode Seat code (e.g., "2A")
     * @return True if seat exists
     */
    public Boolean seatExists(String seatCode) {
        if (String.isBlank(seatCode) || seatCode.length() < 2) {
            return false;
        }
        
        String rowStr = seatCode.substring(0, seatCode.length() - 1);
        String column = seatCode.substring(seatCode.length() - 1);
        
        try {
            Integer rowNumber = Integer.valueOf(rowStr);
            
            // Check if row exists in this aircraft (accounting for gaps)
            if (!rowExists(rowNumber)) {
                return false;
            }
            
            String cabinClass = getCabinClassForRow(rowNumber);
            
            if (cabinClass == null) {
                return false;
            }
            
            CabinConfiguration config = getCabinConfig(cabinClass);
            return config != null && seatColumns.contains(column);
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * @description Check if row exists in aircraft (handles gaps like A350's 53→58 jump)
     * @param rowNumber Row number to check
     * @return True if row exists
     */
    public Boolean rowExists(Integer rowNumber) {
        if (rowNumber == null) {
            return false;
        }
        
        switch on aircraftType {
            when '32Q' { // A321neo - business and economy separate rows
                // Business: rows 2-3, Economy: rows 4-33
                return (rowNumber >= 2 && rowNumber <= 33);
            }
            when '339' { // A330neo
                // Business: rows 2-8, Economy: starts from 20
                return (rowNumber >= 2 && rowNumber <= 8) || (rowNumber >= 20 && rowNumber <= 50);
            }
            when '359' { // A350-900 has row gaps
                // First: 1, Business: 2-8, Premium: 20-24, Economy: 30-69
                // Row gap: 53→58 (rows 54-57 don't exist based on original spec)
                if (rowNumber >= 54 && rowNumber <= 57) {
                    return false;
                }
                return (rowNumber == 1) || 
                       (rowNumber >= 2 && rowNumber <= 8) || 
                       (rowNumber >= 20 && rowNumber <= 24) || 
                       (rowNumber >= 30 && rowNumber <= 69);
            }
            when else {
                // For other aircraft, check if row is within any cabin range
                for (CabinConfiguration config : cabinConfigs.values()) {
                    if (rowNumber >= config.startRow && rowNumber <= config.endRow) {
                        return true;
                    }
                }
                return false;
            }
        }
    }
    
    /**
     * @description Inner class for cabin configuration
     */
    public class CabinConfiguration {
        public String cabinClass { get; set; }
        public Integer startRow { get; set; }
        public Integer endRow { get; set; }
        public Integer seatsPerRow { get; set; }
        public String seatLayout { get; set; }
        
        public CabinConfiguration() {
        }
    }
}