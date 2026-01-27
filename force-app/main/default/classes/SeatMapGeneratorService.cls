// FILE: SeatMapGeneratorService.cls
/**
 * @description A self-contained service to build a rich, frontend-friendly JSON structure 
 * for aircraft seat maps. This class encapsulates all static configurations (layouts, row gaps, 
 * disabled seats, etc.) and the logic to generate a detailed map object.
 * IT DOES NOT REQUIRE SeatMapService or AircraftConfiguration classes to function.
 * 
 * USAGE:
 * SeatMapGeneratorService generator = new SeatMapGeneratorService();
 * Set<String> blockedSeats = new Set<String>{'3A', '20C'}; // From live API call
 * SeatMapGeneratorService.FullSeatMap map = generator.generateFullSeatMap('359', blockedSeats);
 * String jsonOutput = JSON.serializePretty(map);
 * 
 * @author STARLUX Development Team (Revised by AI)
 * @date 2024
 */
public with sharing class SeatMapGeneratorService {

    // Internal state for the selected aircraft
    private String aircraftType;
    private Map<String, CabinConfiguration> cabinConfigs;
    private Set<String> apiBlockedSeats;

    // =======================================================================
    // DATA TRANSFER & CONFIGURATION INNER CLASSES
    // =======================================================================

    private class CabinConfiguration {
        public String cabinClass;
        public Integer startRow;
        public Integer endRow;
        public CabinConfiguration(String cls, Integer start, Integer endRowNum) {
            this.cabinClass = cls;
            this.startRow = start;
            this.endRow = endRowNum;
        }
    }

    public class FullSeatMap {
        @AuraEnabled public String aircraftType;
        @AuraEnabled public String aircraftModel;
        @AuraEnabled public List<SeatMapSection> seatMap;
        public FullSeatMap(String type, String model) {
            this.aircraftType = type; this.aircraftModel = model;
            this.seatMap = new List<SeatMapSection>();
        }
    }

    public class SeatMapSection {
        @AuraEnabled public String sectionName;
        @AuraEnabled public String cabinClass;
        @AuraEnabled public List<SeatMapRow> rows;
        public SeatMapSection(String name, String cabin) {
            this.sectionName = name; this.cabinClass = cabin;
            this.rows = new List<SeatMapRow>();
        }
    }

    public class SeatMapRow {
        @AuraEnabled public String rowType;
        @AuraEnabled public Integer rowNumber;
        @AuraEnabled public Boolean isExitRow;
        @AuraEnabled public List<SeatMapElement> elements;
        public SeatMapRow(String type, Integer num, Boolean isExit) {
            this.rowType = type; this.rowNumber = num;
            this.isExitRow = isExit; this.elements = new List<SeatMapElement>();
        }
    }

    public class SeatMapElement {
        @AuraEnabled public String type; // SEAT, AISLE, LAVATORY, GALLEY
        @AuraEnabled public String seatNumber;
        @AuraEnabled public Boolean isAvailable;
        @AuraEnabled public Boolean hasWindow;
        @AuraEnabled public Integer width;
        @AuraEnabled public String align;

        public SeatMapElement(String seatNum, Boolean isAvail, Boolean hasWin) {
            this.type = 'SEAT'; this.seatNumber = seatNum;
            this.isAvailable = isAvail; this.hasWindow = hasWin;
        }
        public SeatMapElement(String simpleType) { this.type = simpleType; }
        public SeatMapElement(String featureType, Integer w, String align) {
            this.type = featureType; this.width = w; this.align = align;
        }
    }

    /**
     * @description Main public method to generate the full seat map structure.
     * @param aircraftType The 3-letter code (e.g., '359', '339', '32Q').
     * @param blockedSeatsFromAPI A set of seat numbers that are occupied/blocked from a live API call.
     * @return A DTO object ready to be serialized into the desired JSON.
     */
    public FullSeatMap generateFullSeatMap(String aircraftType, Set<String> blockedSeatsFromAPI) {
        initialize(aircraftType, blockedSeatsFromAPI);

        switch on this.aircraftType {
            when '359' {
                return generate359Map();
            }
            when '339' {
                return generate339Map();
            }
            when '32Q' {
                return generate32QMap();
            }
            when else {
                return new FullSeatMap(aircraftType, 'Unknown Model');
            }
        }
    }

    /**
     * @description Initializes the generator's internal state for a specific aircraft.
     */
    private void initialize(String aircraftType, Set<String> blockedSeatsFromAPI) {
        this.aircraftType = aircraftType;
        this.apiBlockedSeats = (blockedSeatsFromAPI != null) ? blockedSeatsFromAPI : new Set<String>();
        this.cabinConfigs = new Map<String, CabinConfiguration>();

        switch on this.aircraftType {
            when '32Q' {
                initializeA321Configuration();
            }
            when '339' {
                initializeA330Configuration();
            }
            when '359' {
                initializeA350Configuration();
            }
        }
    }

    // =======================================================================
    // AIRCRAFT-SPECIFIC BUILDERS (COMPLETE)
    // =======================================================================

    private FullSeatMap generate359Map() {
        // FIX: Renamed 'map' to 'seatMapResult' to avoid conflict with the 'Map' type.
        FullSeatMap seatMapResult = new FullSeatMap('359', 'A350-900');

        // --- SECTION 1: First Class (F) ---
        SeatMapSection fSection = new SeatMapSection('First Class', 'F');
        fSection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'LAVATORY', 'width' => 1} }));
        fSection.rows.add(buildSeatingRow(1, 'F', true));
        seatMapResult.seatMap.add(fSection);

        // --- SECTION 2: Business Class (J) ---
        SeatMapSection jSection = new SeatMapSection('Business Class', 'J');
        for (Integer i = 2; i <= 8; i++) jSection.rows.add(buildSeatingRow(i, 'J', false));
        jSection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'LAVATORY', 'width' => 1}, new Map<String, Object>{'type' => 'LAVATORY', 'width' => 1, 'align' => 'right'} }));
        seatMapResult.seatMap.add(jSection);

        // --- SECTION 3: Premium Economy (W) ---
        SeatMapSection wSection = new SeatMapSection('Premium Economy', 'W');
        wSection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'LAVATORY', 'width' => 2, 'align' => 'right'} }));
        for (Integer i = 20; i <= 24; i++) wSection.rows.add(buildSeatingRow(i, 'W', false));
        seatMapResult.seatMap.add(wSection);

        // --- SECTION 4: Economy (Y) ---
        SeatMapSection ySection = new SeatMapSection('Economy', 'Y');
        ySection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'GALLEY', 'width' => 3}, new Map<String, Object>{'type' => 'LAVATORY', 'width' => 3, 'align' => 'center'}, new Map<String, Object>{'type' => 'GALLEY', 'width' => 3, 'align' => 'right'} }));
        for (Integer i = 30; i <= 41; i++) ySection.rows.add(buildSeatingRow(i, 'Y', false));
        ySection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'GALLEY', 'width' => 1}, new Map<String, Object>{'type' => 'LAVATORY', 'width' => 1, 'align' => 'center'}, new Map<String, Object>{'type' => 'LAVATORY', 'width' => 1, 'align' => 'center'}, new Map<String, Object>{'type' => 'GALLEY', 'width' => 1, 'align' => 'right'} }));
        for (Integer i = 50; i <= 69; i++) ySection.rows.add(buildSeatingRow(i, 'Y', (i == 50)));
        ySection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'GALLEY', 'width' => 3}, new Map<String, Object>{'type' => 'GALLEY', 'width' => 3, 'align' => 'center'}, new Map<String, Object>{'type' => 'GALLEY', 'width' => 3, 'align' => 'right'} }));
        seatMapResult.seatMap.add(ySection);
        
        return seatMapResult;
    }

    private FullSeatMap generate339Map() {
        // FIX: Renamed 'map' to 'seatMapResult'
        FullSeatMap seatMapResult = new FullSeatMap('339', 'A330-900');

        SeatMapSection jSection = new SeatMapSection('Business Class', 'J');
        jSection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'LAVATORY', 'width' => 2} }));
        for (Integer i = 2; i <= 8; i++) jSection.rows.add(buildSeatingRow(i, 'J', false));
        jSection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'LAVATORY', 'width' => 2, 'align' => 'right'} }));
        seatMapResult.seatMap.add(jSection);

        SeatMapSection ySection = new SeatMapSection('Economy', 'Y');
        for (Integer i = 30; i <= 69; i++) {
            if (rowExists(i)) ySection.rows.add(buildSeatingRow(i, 'Y', (i == 50)));
        }
        ySection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'LAVATORY', 'width' => 2, 'align' => 'center'} }));
        ySection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'LAVATORY', 'width' => 1}, new Map<String, Object>{'type' => 'LAVATORY', 'width' => 1, 'align' => 'right'} }));
        seatMapResult.seatMap.add(ySection);

        return seatMapResult;
    }

    private FullSeatMap generate32QMap() {
        // FIX: Renamed 'map' to 'seatMapResult'
        FullSeatMap seatMapResult = new FullSeatMap('32Q', 'A321neo');
        
        SeatMapSection jSection = new SeatMapSection('Business Class', 'J');
        jSection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'LAVATORY', 'width' => 2} }));
        for (Integer i = 2; i <= 3; i++) jSection.rows.add(buildSeatingRow(i, 'J', false));
        seatMapResult.seatMap.add(jSection);
        
        SeatMapSection ySection = new SeatMapSection('Economy', 'Y');
        for (Integer i = 4; i <= 33; i++) ySection.rows.add(buildSeatingRow(i, 'Y', (i == 13 || i == 16)));
        ySection.rows.add(buildFeatureRow(true, new List<Map<String, Object>>{ new Map<String, Object>{'type' => 'LAVATORY', 'width' => 2}, new Map<String, Object>{'type' => 'LAVATORY', 'width' => 1, 'align' => 'right'} }));
        seatMapResult.seatMap.add(ySection);

        return seatMapResult;
    }

    // =======================================================================
    // STATIC CONFIGURATION DATA (Now internal to this service)
    // =======================================================================

    private void initializeA321Configuration() {
        cabinConfigs.put('J', new CabinConfiguration('J', 2, 3));
        cabinConfigs.put('Y', new CabinConfiguration('Y', 4, 33));
    }
    private void initializeA330Configuration() {
        cabinConfigs.put('J', new CabinConfiguration('J', 2, 8));
        cabinConfigs.put('Y', new CabinConfiguration('Y', 30, 69));
    }
    private void initializeA350Configuration() {
        cabinConfigs.put('F', new CabinConfiguration('F', 1, 1));
        cabinConfigs.put('J', new CabinConfiguration('J', 2, 8));
        cabinConfigs.put('W', new CabinConfiguration('W', 20, 24));
        cabinConfigs.put('Y', new CabinConfiguration('Y', 30, 69));
    }

    // =======================================================================
    // INTERNAL RULE/LOGIC METHODS (Now self-contained)
    // =======================================================================
    
    private Boolean rowExists(Integer rowNumber) {
        if (rowNumber == null) return false;
        switch on aircraftType {
            when '32Q' {
                return (rowNumber >= 2 && rowNumber <= 33);
            }
            when '339' {
                if ((rowNumber >= 2 && rowNumber <= 8) || (rowNumber >= 30 && rowNumber <= 69)) {
                    return !(rowNumber == 49 || (rowNumber >= 54 && rowNumber <= 56));
                } 
                return false;
            }
            when '359' {
                return (rowNumber == 1) || (rowNumber >= 2 && rowNumber <= 8) || (rowNumber >= 20 && rowNumber <= 24) || (rowNumber >= 30 && rowNumber <= 69);
            }
            when else {
                return false;
            }
        }
    }

    private Boolean isStaticDisabledSeat(String seatCode) {
        if (String.isBlank(seatCode) || seatCode.length() < 2) return false;
        String rowStr = seatCode.substring(0, seatCode.length() - 1);
        String column = seatCode.substring(seatCode.length() - 1);
        Integer rowNum;
        try { rowNum = Integer.valueOf(rowStr); } catch (Exception e) { return false; }

        switch on aircraftType {
            when '32Q' {
                if (rowNum == 4 && (column == 'B' || column == 'J')) return true;
                if (rowNum == 14 || rowNum == 15) return true;
                return false;
            }
            when '339' {
                if (rowNum == 30) return true;
                if (rowNum == 50 && new Set<String>{'D', 'E', 'F', 'G'}.contains(column)) return true;
                if (rowNum == 51 && new Set<String>{'A', 'C', 'H', 'K'}.contains(column)) return true;
                return false;
            }
            when '359' {
                if (rowNum == 30 || rowNum == 50 || rowNum == 51) return true;
                if (rowNum == 31 && new Set<String>{'A', 'B', 'C', 'H', 'J', 'K'}.contains(column)) return true;
                if (rowNum == 52 && new Set<String>{'A', 'B', 'C', 'H', 'J', 'K'}.contains(column)) return true;
                return false;
            }
        }
        return false;
    }

    private Set<String> getNoWindowSeats() {
        Set<String> noWindowSeats = new Set<String>();
        switch on aircraftType {
            when '32Q' {
                noWindowSeats.addAll(new List<String>{'25A', '25B', '25C', '25H', '25J', '25K'});
            }
            when '339' {
                noWindowSeats.addAll(new List<String>{'35A', '35C', '35H', '35K'});
            }
            when '359' {
                noWindowSeats.addAll(new List<String>{'3A', '3K', '7A', '7K'});
            }
        }
        return noWindowSeats;
    }
    
    private List<String> getLayoutPatternForCabin(String cabinClass) {
        switch on aircraftType {
            when '32Q' {
                if (cabinClass == 'J') return new List<String>{ 'A', 'C', 'AISLE', 'H', 'K' };
                if (cabinClass == 'Y') return new List<String>{ 'A', 'B', 'C', 'AISLE', 'H', 'J', 'K' };
            }
            when '339' {
                if (cabinClass == 'J') return new List<String>{ 'C', 'AISLE', 'E', 'G', 'AISLE', 'K' };
                if (cabinClass == 'Y') return new List<String>{ 'A', 'C', 'AISLE', 'D', 'E', 'F', 'G', 'AISLE', 'H', 'K' };
            }
            when '359' {
                if (cabinClass == 'F' || cabinClass == 'J') return new List<String>{ 'A', 'AISLE', 'D', 'G', 'AISLE', 'K' };
                if (cabinClass == 'W') return new List<String>{ 'A', 'C', 'AISLE', 'D', 'E', 'F', 'G', 'AISLE', 'H', 'K' };
                if (cabinClass == 'Y') return new List<String>{ 'A', 'B', 'C', 'AISLE', 'D', 'E', 'G', 'AISLE', 'H', 'J', 'K' };
            }
        }
        return new List<String>();
    }

    private String getCabinClassForRow(Integer rowNumber) {
        if (rowNumber == null) return null;
        for (String cabin : cabinConfigs.keySet()) {
            if (rowNumber >= cabinConfigs.get(cabin).startRow && rowNumber <= cabinConfigs.get(cabin).endRow) {
                return cabin;
            }
        }
        return null;
    }

    // =======================================================================
    // GENERIC ROW BUILDER HELPERS
    // =======================================================================
    
    private SeatMapRow buildSeatingRow(Integer rowNum, String cabinClass, Boolean isExit) {
        SeatMapRow row = new SeatMapRow('SEATING', rowNum, isExit);
        List<String> layoutPattern = getLayoutPatternForCabin(cabinClass);
        Set<String> noWindowSeats = getNoWindowSeats();

        for (String item : layoutPattern) {
            if (item == 'AISLE') {
                row.elements.add(new SeatMapElement('AISLE'));
            } else {
                String seatNum = '' + rowNum + item;
                Boolean isAvail = !apiBlockedSeats.contains(seatNum) && !isStaticDisabledSeat(seatNum);
                Boolean hasWin = !noWindowSeats.contains(seatNum);
                row.elements.add(new SeatMapElement(seatNum, isAvail, hasWin));
            }
        }
        return row;
    }

    private SeatMapRow buildFeatureRow(Boolean isExit, List<Map<String, Object>> features) {
        SeatMapRow row = new SeatMapRow('FEATURES', null, isExit);
        for (Map<String, Object> feature : features) {
            String type = (String)feature.get('type');
            Integer width = (Integer)feature.get('width');
            // Align property can be used by frontend for positioning, e.g., 'left', 'center', 'right'
            String align = (String)feature.get('align'); 
            row.elements.add(new SeatMapElement(type, width, align));
        }
        return row;
    }
}