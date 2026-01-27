/**
 * @description Seat Map Service Implementation
 * @author STARLUX Development Team
 * @date 2024
 */
public class SeatMapService implements ISeatMapService {
    private IAmadeusAPIClient apiClient;
    
    /**
     * @description Constructor with dependencies
     */
    public SeatMapService() {
        // this.apiClient = ServiceFactory.getAmadeusAPIClient();
        this.apiClient = new AmadeusAPIClient();
    }
    
    /**
     * @description Constructor for testing with mocks
     * @param apiClient Mock API client
     */
    public SeatMapService(IAmadeusAPIClient apiClient) {
        this.apiClient = apiClient;
    }
    
    /**
     * @description Get seat map for aircraft and flight
     * @param request Seat map request
     * @return Seat map data
     */
    public SeatMapData getSeatMap(SeatMapRequest request) {
        try {
            // Validate request
            List<ValidationError> validationErrors = request.validate();
            if (!validationErrors.isEmpty()) {
                ValidationResult validation = new ValidationResult(false);
                for (ValidationError error : validationErrors) {
                    validation.addError(error);
                }
                System.debug('Invalid seat map request: ' + validation.getSummary());
                // For seat map, we need aircraft type from other source since request doesn't have it
                return new SeatMapData(); // Return empty seat map data
            }
            
            // For seat map, aircraft type comes from AirRetrieveSeatMap.Result, not request
            // Try to get real-time seat availability from API first to get aircraft type
            SeatMapResult apiResult = getSeatMapFromAPI(request);

            System.debug(apiResult);
            
            if (apiResult != null && apiResult.isValid()) {
                // Use API data if available
                return apiResult.toSeatMapData();
            } else {
                // Fall back to basic configuration - aircraft type will be set later
                System.debug('Using basic seat map configuration');
                return new SeatMapData();
            }
            
        } catch (Exception e) {
            System.debug('Error in getSeatMap: ' + e.getMessage());
            // Return basic configuration on error
            return new SeatMapData();
        }
    }
    
    /**
     * @description Get aircraft configuration
     * @param aircraftType Aircraft type code
     * @return Aircraft configuration
     */
    public AircraftConfiguration getAircraftConfiguration(String aircraftType) {
        try {
            if (String.isBlank(aircraftType)) {
                return null;
            }
            
            return new AircraftConfiguration(aircraftType);
            
        } catch (Exception e) {
            System.debug('Error in getAircraftConfiguration: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Check if seat is available
     * @param seatCode Seat code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return True if available
     */
    public Boolean isSeatAvailable(String seatCode, String aircraftType, String flightNumber, Date departureDate) {
        try {
            if (String.isBlank(seatCode) || String.isBlank(aircraftType)) {
                return false;
            }
            
            // Check if seat exists in aircraft configuration
            AircraftConfiguration config = getAircraftConfiguration(aircraftType);
            if (config == null || !config.seatExists(seatCode)) {
                return false;
            }
            
            // Create request for API check - derive origin/destination if needed
            SeatMapRequest request = new SeatMapRequest();
            request.flightNumber = flightNumber;
            request.departureDate = departureDate;
            
            // Derive origin and destination from flight number
            Map<String, String> route = deriveFlightRoute(flightNumber, departureDate);
            request.origin = route.get('origin');
            request.destination = route.get('destination');
            
            SeatMapResult apiResult = getSeatMapFromAPI(request);
            
            if (apiResult != null && apiResult.isValid()) {
                return apiResult.isSeatAvailable(seatCode);
            }
            
            // If API is not available, assume seat is available if it exists
            return true;
            
        } catch (Exception e) {
            System.debug('Error in isSeatAvailable: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Get available seats for cabin class
     * @param cabinClass Cabin class code
     * @param aircraftType Aircraft type
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return List of available seat codes
     */
    public List<String> getAvailableSeats(String cabinClass, String aircraftType, String flightNumber, Date departureDate) {
        try {
            List<String> availableSeats = new List<String>();
            
            if (String.isBlank(cabinClass) || String.isBlank(aircraftType)) {
                return availableSeats;
            }
            
            // Get aircraft configuration
            AircraftConfiguration config = getAircraftConfiguration(aircraftType);
            if (config == null) {
                return availableSeats;
            }
            
            // Try to get real-time data from API
            SeatMapRequest request = new SeatMapRequest();
            request.flightNumber = flightNumber;
            request.departureDate = departureDate;
            
            // Derive origin and destination from flight number
            Map<String, String> route = deriveFlightRoute(flightNumber, departureDate);
            request.origin = route.get('origin');
            request.destination = route.get('destination');
            
            SeatMapResult apiResult = getSeatMapFromAPI(request);
            
            if (apiResult != null && apiResult.isValid()) {
                return apiResult.getAvailableSeats(cabinClass);
            }
            
            // Fall back to generating seats from static configuration
            AircraftConfiguration.CabinConfiguration cabinConfig = config.getCabinConfig(cabinClass);
            if (cabinConfig != null) {
                availableSeats = generateAvailableSeatsForCabin(cabinClass, config, new Set<String>());
            }
            
            return availableSeats;
            
        } catch (Exception e) {
            System.debug('Error in getAvailableSeats: ' + e.getMessage());
            return new List<String>();
        }
    }
    
    /**
     * @description Get seat map from external API
     * @param request Seat map request
     * @return Seat map result from API
     */
    public SeatMapResult getSeatMapFromAPI(SeatMapRequest request) {
        try {

            System.debug('getSeatMapFromAPI request: ' + JSON.serializePretty(request));
            if (String.isBlank(request.flightNumber) || request.departureDate == null) {
                // Cannot call API without flight details
                return null;
            }
            
            // Call API client method with individual parameters

            
            AirRetrieveSeatMap.Result apiResult = apiClient.callSeatMapRetrieve(
                formatDateToDDMMYY(request.departureDate), // Convert Date to String in DDMMYY format
                request.origin,
                request.destination,
                request.flightNumber,
                request.bookingClass
            );
            
            if (apiResult == null) {
                System.debug('API call failed for seat map: No result returned');
                return null;
            }
            
            // Convert AirRetrieveSeatMap.Result to SeatMapResult
            return convertAmadeusResultToSeatMapResult(apiResult);
            
        } catch (Exception e) {
            System.debug('Error calling seat map API: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Convert Amadeus API result to SeatMapResult
     * @param apiResult Amadeus API result
     * @return Converted seat map result
     */
    private SeatMapResult convertAmadeusResultToSeatMapResult(AirRetrieveSeatMap.Result apiResult) {
        SeatMapResult result = new SeatMapResult();
        
        try {
            // Extract aircraft type from API result if available
            if (apiResult != null && String.isNotBlank(apiResult.iataAircraftTypeCode)) {
                result = new SeatMapResult(apiResult.iataAircraftTypeCode);
            }
            
            if (apiResult == null) {
                return SeatMapResult.createError('API result is null');
            }
            
            // Parse cabin classes from API result
            if (apiResult.cabinClasses != null && !apiResult.cabinClasses.isEmpty()) {
                for (String cabinClass : apiResult.cabinClasses) {
                    result.addCabinClass(cabinClass);
                }
            }
            
            // Parse blocked seats from API result
            if (apiResult.blockedSeats != null && !apiResult.blockedSeats.isEmpty()) {
                for (String blockedSeat : apiResult.blockedSeats) {
                    result.addDisabledSeat(blockedSeat);
                }
            }
            
            // Generate available seats by cabin class using aircraft configuration
            if (String.isNotBlank(result.aircraftType)) {
                AircraftConfiguration config = getAircraftConfiguration(result.aircraftType);
                if (config != null) {
                    for (String cabinClass : result.cabinClasses) {
                        List<String> availableSeats = generateAvailableSeatsForCabin(
                            cabinClass, 
                            config, 
                            new Set<String>(result.disabledSeats)
                        );
                        result.setAvailableSeats(cabinClass, availableSeats);
                    }
                    
                    // Add no-window seats based on STARLUX specification
                    List<String> noWindowSeats = getNoWindowSeats(result.aircraftType);
                    for (String noWindowSeat : noWindowSeats) {
                        result.addNoWindowSeat(noWindowSeat);
                    }
                }
            }
            
            result.success = true;
            System.debug('Amadeus seat map result converted successfully');
            return result;
            
        } catch (Exception e) {
            System.debug('Error converting Amadeus result: ' + e.getMessage());
            return SeatMapResult.createError('Failed to parse Amadeus seat map data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate available seats for a specific cabin class
     * @param cabinClass Cabin class code
     * @param config Aircraft configuration
     * @param blockedSeats Set of blocked seat codes
     * @return List of available seat codes
     */
    private List<String> generateAvailableSeatsForCabin(String cabinClass, AircraftConfiguration config, Set<String> blockedSeats) {
        List<String> availableSeats = new List<String>();
        
        AircraftConfiguration.CabinConfiguration cabinConfig = config.getCabinConfig(cabinClass);
        if (cabinConfig == null) {
            return availableSeats;
        }
        
        // Generate seats for each row in the cabin
        for (Integer row = cabinConfig.startRow; row <= cabinConfig.endRow; row++) {
            // Get row-specific columns (some rows have different seat configurations)
            List<String> rowColumns = getRowSpecificColumns(row, cabinClass, config.aircraftType);
            
            // Skip rows that don't exist (e.g., A350's gap from 53→58)
            if (!config.rowExists(row)) {
                continue;
            }
            
            for (String column : rowColumns) {
                String seatCode = String.valueOf(row) + column;
                
                // Check if seat should be included (not blocked and not disabled per spec)
                if (!blockedSeats.contains(seatCode) && !isStaticDisabledSeat(seatCode, config.aircraftType)) {
                    availableSeats.add(seatCode);
                }
            }
        }
        
        return availableSeats;
    }
    
    /**
     * @description Get seat columns for specific row (handles row variations per layout)
     * @param rowNumber Row number
     * @param cabinClass Cabin class
     * @param aircraftType Aircraft type
     * @return List of seat columns for this specific row
     */
    private List<String> getRowSpecificColumns(Integer rowNumber, String cabinClass, String aircraftType) {
        List<String> columns = new List<String>();
        
        switch on aircraftType {
            when '32Q' { // A321neo - all rows use standard cabin columns per layout
                columns = getCabinSpecificColumns(cabinClass, aircraftType, null);
            }
            when '339' { // A330neo - all rows use standard cabin columns per layout
                columns = getCabinSpecificColumns(cabinClass, aircraftType, null);
            }
            when '359' { // A350-900 - all rows use standard cabin columns per layout
                columns = getCabinSpecificColumns(cabinClass, aircraftType, null);
            }
            when else {
                columns = getCabinSpecificColumns(cabinClass, aircraftType, null);
            }
        }
        
        return columns;
    }
    
    /**
     * @description Check if seat is statically disabled per STARLUX specification
     * @param seatCode Seat code to check
     * @param aircraftType Aircraft type
     * @return True if seat is disabled per spec
     */
    private Boolean isStaticDisabledSeat(String seatCode, String aircraftType) {
        // Parse row and column from seat code
        if (String.isBlank(seatCode) || seatCode.length() < 2) {
            return false;
        }
        
        String rowStr = seatCode.substring(0, seatCode.length() - 1);
        String column = seatCode.substring(seatCode.length() - 1);
        Integer rowNum;
        
        try {
            rowNum = Integer.valueOf(rowStr);
        } catch (Exception e) {
            return false;
        }
        
        switch on aircraftType {
            when '32Q' { // A321neo - based on feedback corrections
                // Row 4 - all economy seats blocked
                // Rows 14-15 - all economy seats blocked
                if (rowNum == 4 || rowNum == 14 || rowNum == 15) {
                    return true;
                }
            }
            when '339' { // A330neo - no specific blocked seats shown in layout
                // No static disabled seats shown in the layout diagram
                return false;
            }
            when '359' { // A350-900 - based on layout diagram
                // Row 30 - all seats blocked (X marks in diagram)
                if (rowNum == 30) {
                    return true;
                }
                // Row 31 - middle section blocked (D, E, F, G have X marks)
                if (rowNum == 31 && new Set<String>{'D', 'E', 'F', 'G'}.contains(column)) {
                    return true;
                }
                // Row 50 - all seats blocked (X marks in diagram)
                if (rowNum == 50) {
                    return true;
                }
                // Row 51 - side sections blocked (A, B, C, H, J, K have X marks)
                if (rowNum == 51 && new Set<String>{'A', 'B', 'C', 'H', 'J', 'K'}.contains(column)) {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * @description Get seat columns specific to cabin class and layout
     * @param cabinClass Cabin class code
     * @param aircraftType Aircraft type
     * @param seatLayout Seat layout pattern
     * @return List of seat columns for this cabin
     */
    private List<String> getCabinSpecificColumns(String cabinClass, String aircraftType, String seatLayout) {
        List<String> columns = new List<String>();
        
        // Map columns based on aircraft type and cabin class per cabin layout diagrams
        switch on aircraftType {
            when '32Q' { // A321neo
                switch on cabinClass {
                    when 'J' { // Business: A, C, H, K (2-2 layout)
                        columns.addAll(new List<String>{'A', 'C', 'H', 'K'});
                    }
                    when 'Y' { // Economy: A, B, C, H, J, K (3-3 layout)
                        columns.addAll(new List<String>{'A', 'B', 'C', 'H', 'J', 'K'});
                    }
                }
            }
            when '339' { // A330neo
                switch on cabinClass {
                    when 'J' { // Business: C, E, G, K (1-2-1 layout)
                        columns.addAll(new List<String>{'C', 'E', 'G', 'K'});
                    }
                    when 'Y' { // Economy: A, C, D, E, F, G, H, K (2-4-2 layout)
                        columns.addAll(new List<String>{'A', 'C', 'D', 'E', 'F', 'G', 'H', 'K'});
                    }
                }
            }
            when '359' { // A350-900
                switch on cabinClass {
                    when 'F' { // First: A, D, G, K (1-2-1 layout)
                        columns.addAll(new List<String>{'A', 'D', 'G', 'K'});
                    }
                    when 'J' { // Business: A, D, G, K (1-2-1 layout)
                        columns.addAll(new List<String>{'A', 'D', 'G', 'K'});
                    }
                    when 'W' { // Premium Economy: A, C, D, E, F, G, H, K (2-4-2 layout)
                        columns.addAll(new List<String>{'A', 'C', 'D', 'E', 'F', 'G', 'H', 'K'});
                    }
                    when 'Y' { // Economy: A, B, C, D, E, G, H, J, K (3-3-3 layout, no F)
                        columns.addAll(new List<String>{'A', 'B', 'C', 'D', 'E', 'G', 'H', 'J', 'K'});
                    }
                }
            }
            when else {
                // Default fallback - use all available columns
                columns.addAll(new List<String>{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K'});
            }
        }
        
        return columns;
    }
    
    /**
     * @description Check if column should be included based on seat layout
     * @param column Seat column
     * @param seatLayout Seat layout (e.g., "3-3-3", "1-2-1")
     * @return True if column should be included
     */
    private Boolean shouldIncludeColumn(String column, String seatLayout) {
        if (String.isBlank(seatLayout) || String.isBlank(column)) {
            return true;
        }
        
        // Map seat layout patterns to allowed columns
        switch on seatLayout {
            when '2-2' { // Business class narrow body (A321neo)
                return new Set<String>{'A', 'C', 'H', 'K'}.contains(column);
            }
            when '3-3' { // Economy narrow body (A321neo)
                return new Set<String>{'A', 'B', 'C', 'H', 'J', 'K'}.contains(column);
            }
            when '1-2-1' { // Business class wide body (A330neo: C,E,G,K; A350: A,D,G,K)
                return new Set<String>{'A', 'C', 'D', 'E', 'G', 'K'}.contains(column);
            }
            when '2-4-2' { // Premium economy (A330neo and A350)
                return new Set<String>{'A', 'C', 'D', 'E', 'F', 'G', 'H', 'K'}.contains(column);
            }
            when '3-3-3' { // Economy wide body (A350: no F column)
                return new Set<String>{'A', 'B', 'C', 'D', 'E', 'G', 'H', 'J', 'K'}.contains(column);
            }
            when else {
                return true; // Include all if pattern not recognized
            }
        }
    }
    
    /**
     * @description Derive origin and destination from flight number and date
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return Map with 'origin' and 'destination' keys
     */
    private Map<String, String> deriveFlightRoute(String flightNumber, Date departureDate) {
        Map<String, String> route = new Map<String, String>();
        
        // TODO: This would ideally query a flight schedule database/API
        // For now, implement basic STARLUX route mapping based on flight numbers
        
        if (String.isBlank(flightNumber)) {
            return route;
        }
        
        // Extract numeric part of flight number for route determination
        String numericPart = flightNumber.replaceAll('[^0-9]', '');
        Integer flightNum = String.isNotBlank(numericPart) ? Integer.valueOf(numericPart) : 0;
        
        // Basic STARLUX route mapping (this should be replaced with actual flight schedule data)
        if (flightNum >= 800 && flightNum <= 899) {
            // Japan routes
            route.put('origin', 'TPE');
            route.put('destination', 'KIX'); // Default to Kansai
        } else if (flightNum >= 700 && flightNum <= 799) {
            // Korea routes
            route.put('origin', 'TPE');
            route.put('destination', 'ICN');
        } else if (flightNum >= 600 && flightNum <= 699) {
            // Southeast Asia routes
            route.put('origin', 'TPE');
            route.put('destination', 'BKK'); // Default to Bangkok
        } else if (flightNum >= 500 && flightNum <= 599) {
            // China routes
            route.put('origin', 'TPE');
            route.put('destination', 'PVG'); // Default to Shanghai
        } else {
            // Default fallback
            route.put('origin', 'TPE');
            route.put('destination', 'KIX');
        }
        
        System.debug('Derived route for flight ' + flightNumber + ': ' + route.get('origin') + ' -> ' + route.get('destination'));
        return route;
    }
    
    /**
     * @description Get no-window seats per STARLUX specification
     * @param aircraftType Aircraft type
     * @return List of seat codes with no window view
     */
    private List<String> getNoWindowSeats(String aircraftType) {
        List<String> noWindowSeats = new List<String>();
        
        switch on aircraftType {
            when '32Q' { // A321neo
                // Row 25 - no window view (corrected based on feedback)
                noWindowSeats.addAll(new List<String>{'25A', '25B', '25C', '25H', '25J', '25K'});
            }
            when '339' { // A330neo
                // Based on layout diagram, no specific no-window seats are marked
            }
            when '359' { // A350-900
                // Based on layout diagram, no specific no-window seats are marked
                // Would need additional specification to identify actual no-window seats
            }
        }
        
        return noWindowSeats;
    }

    private String formatDateToDDMMYY(Date dateInput) {
        if (dateInput == null) {
            return null;
        }
        
        String day = String.valueOf(dateInput.day()).leftPad(2, '0');
        String month = String.valueOf(dateInput.month()).leftPad(2, '0');
        String year = String.valueOf(dateInput.year()).right(2);
        
        return day + month + year;
    }
}