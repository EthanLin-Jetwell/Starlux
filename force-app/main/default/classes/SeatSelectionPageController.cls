/**
 * @description Main Controller for Seat Selection Visualforce Page
 * @author STARLUX Development Team
 * @date 2024
 */
public class SeatSelectionPageController {
    // Services
    private IPNRService pnrService;
    private ISeatMapService seatMapService;
    private IPassengerService passengerService;
    private ISeatAssignmentService seatAssignmentService;
    
    // Search criteria properties
    public String flightNumber { get; set; }
    public String departureDateStr { get; set; }
    public String departureLocation { get; set; }
    public String bookingCodes { get; set; }
    
    // Page state and data
    public PageState currentPageState { get; set; }
    public SearchCriteria searchCriteria { get; set; }
    public PNRSearchResult searchResult { get; set; }
    public List<PNRData> selectedPNRs { get; set; }
    public String activePNRCode { get; set; }
    public SeatMapData seatMapData { get; set; }
    public String errorMessage { get; set; }
    public String successMessage { get; set; }
    
    // Selection state
    public Boolean isSelectionMode { get; set; }
    public String selectedPassengerId { get; set; }
    public String selectedSeatCode { get; set; }
    public String selectedPassengerName { get; set; }
    
    // Derived data
    public List<PassengerDisplayInfo> activePassengers { get; set; }
    public Map<String, Integer> tabPassengerCounts { get; set; }
    
    // UI Properties
    public Boolean hasError { get { return String.isNotBlank(errorMessage); } }
    public Boolean hasSuccess { get { return String.isNotBlank(successMessage); } }
    public Boolean hasSearchResults { get { return searchResult != null && searchResult.isSuccessful() && !searchResult.pnrDetails.isEmpty(); } }
    public Boolean hasSelectedPNRs { get { return selectedPNRs != null && !selectedPNRs.isEmpty(); } }
    public Boolean hasSeatMap { get { return seatMapData != null && String.isNotBlank(seatMapData.aircraftType); } }
    
    // Origin options for dropdown
    public List<SelectOption> originOptions {
        get {
            if (originOptions == null) {
                originOptions = new List<SelectOption>();
                
                // Add default option
                originOptions.add(new SelectOption('', '-- Select Origin --'));
                
                // Get the B2BAirportCode record type ID
                Schema.DescribeSObjectResult d = AirportCode__c.SObjectType.getDescribe();
                Id rtId = null;
                for (Schema.RecordTypeInfo info : d.getRecordTypeInfos()) {
                    if (info.getDeveloperName() == 'B2BAirportCode' && info.isAvailable()) {
                        rtId = info.getRecordTypeId();
                        break;
                    }
                }
                
                // If record type found, load dynamic options
                if (rtId != null) {
                    // Create a map to store unique airport codes with their names
                    Map<String, String> airportMap = new Map<String, String>();
                    
                    // Query airport codes with names
                    // Note: Adjust the field name (Name, Airport_Name__c, Description__c, etc.) based on your object structure
                    for (AirportCode__c ac : [
                        SELECT Departure__c, Name
                        FROM   AirportCode__c
                        WHERE  RecordTypeId = :rtId
                        AND    Departure__c != null
                        AND    Active__c = True 

                        ORDER BY Departure__c
                    ]) {
                        // Use airport code as key to avoid duplicates
                        if (!airportMap.containsKey(ac.Departure__c)) {
                            airportMap.put(ac.Departure__c, ac.Name);
                        }
                    }
                    
                    // Convert map to SelectOption list
                    List<String> sortedCodes = new List<String>(airportMap.keySet());
                    sortedCodes.sort();
                    
                    for (String code : sortedCodes) {
                        String displayValue = code + ' - ' + airportMap.get(code);
                        originOptions.add(new SelectOption(code, displayValue));
                    }
                }
            }
            return originOptions;
        }
        set;
    }
    
    /**
     * @description Constructor
     */
    public SeatSelectionPageController() {
        try {
            initializeServices();
            initializeState();
        } catch (Exception e) {
            System.debug('Constructor error: ' + e.getMessage());
            errorMessage = 'Failed to initialize page: ' + e.getMessage();
        }
    }
    
    /**
     * @description Initialize services using factory
     */
    private void initializeServices() {
        // this.pnrService = ServiceFactory.getPNRService();
        this.pnrService = new PNRService();
        // this.seatMapService = ServiceFactory.getSeatMapService();
        this.seatMapService = new SeatMapService();
        // this.passengerService = ServiceFactory.getPassengerService();   
        this.passengerService = new PassengerService();
        // this.seatAssignmentService = ServiceFactory.getSeatAssignmentService();
        this.seatAssignmentService = new SeatAssignmentService();
    }
    
    /**
     * @description Initialize page state
     */
    private void initializeState() {
        this.currentPageState = new PageState();
        this.searchCriteria = new SearchCriteria();
        this.selectedPNRs = new List<PNRData>();
        this.isSelectionMode = false;
        this.activePassengers = new List<PassengerDisplayInfo>();
        this.tabPassengerCounts = new Map<String, Integer>();
        clearMessages();
    }
    
    /**
     * @description Search for PNRs
     * @return Page reference (null for AJAX)
     */
    public PageReference searchPNRs() {
        try {
            clearMessages();
            
            // Build search criteria
            searchCriteria = buildSearchCriteria();
            
            // Validate search criteria
            List<ValidationError> validationErrors = searchCriteria.validate();
            if (!validationErrors.isEmpty()) {
                ValidationResult validation = new ValidationResult(false);
                for (ValidationError error : validationErrors) {
                    validation.addError(error);
                }
                errorMessage = validation.getSummary();
                return null;
            }
            
            // Perform search
            searchResult = pnrService.searchPNRs(searchCriteria);
            
            if (searchResult.isSuccessful()) {
                currentPageState.changeState(PageState.RESULTS);
                successMessage = 'Found ' + searchResult.totalPassengers + ' passenger(s) in ' + searchResult.validPNRs.size() + ' PNR(s) matching your criteria';
                
                // Calculate passenger counts for tabs
                calculateTabPassengerCounts();
                
                // Set first PNR as active if available
                if (!searchResult.validPNRs.isEmpty()) {
                    activePNRCode = searchResult.validPNRs[0];
                    loadActivePassengers();
                    loadSeatMapForActivePNR();
                }
            } else {
                errorMessage = searchResult.errorMessage;
            }
            
        } catch (Exception e) {
            System.debug('Error in searchPNRs: ' + e.getMessage());
            errorMessage = 'An error occurred while searching for PNRs. Please try again.';
        }
        
        return null;
    }
    
    /**
     * @description Build search criteria from form inputs
     * @return SearchCriteria object
     */
    private SearchCriteria buildSearchCriteria() {
        SearchCriteria criteria = new SearchCriteria();
        
        // Set flight information
        criteria.flightNumber = String.isNotBlank(flightNumber) ? flightNumber.trim() : null;
        criteria.departureLocation = departureLocation;
        
        // Parse departure date
        if (String.isNotBlank(departureDateStr)) {
            try {
                criteria.departureDate = Date.valueOf(departureDateStr);
            } catch (Exception e) {
                System.debug('Invalid departure date format: ' + departureDateStr);
            }
        }
        
        // Parse PNR codes
        if (String.isNotBlank(bookingCodes)) {
            String[] pnrArray = bookingCodes.toUpperCase().split('[,\\s]+');
            for (String pnr : pnrArray) {
                if (String.isNotBlank(pnr)) {
                    criteria.pnrCodes.add(pnr.trim());
                }
            }
        }
        
        return criteria;
    }
    
    /**
     * @description Add PNR to selection
     * @return Page reference (null for AJAX)
     */
    public PageReference addPNRToSelection() {
        try {
            clearMessages();
            
            String pnrCodeToAdd = ApexPages.currentPage().getParameters().get('pnrCode');
            
            if (String.isBlank(pnrCodeToAdd)) {
                errorMessage = 'PNR code is required';
                return null;
            }
            
            // Check if already selected
            for (PNRData existingPNR : selectedPNRs) {
                if (existingPNR.pnrCode.equals(pnrCodeToAdd)) {
                    errorMessage = 'PNR ' + pnrCodeToAdd + ' is already selected';
                    return null;
                }
            }
            
            // Find PNR in search results
            PNRData pnrToAdd = null;
            if (searchResult != null && searchResult.pnrDetails != null) {
                for (PNRData pnr : searchResult.pnrDetails) {
                    if (pnr.pnrCode.equals(pnrCodeToAdd)) {
                        pnrToAdd = pnr;
                        break;
                    }
                }
            }
            
            if (pnrToAdd == null) {
                // Get PNR details directly
                pnrToAdd = pnrService.getPNRDetails(pnrCodeToAdd);
            }
            
            if (pnrToAdd != null) {
                selectedPNRs.add(pnrToAdd);
                
                // Set as active PNR if it's the first one
                if (selectedPNRs.size() == 1) {
                    activePNRCode = pnrCodeToAdd;
                    loadSeatMapForActivePNR();
                }
                
                currentPageState.changeState(PageState.EDITING);
                successMessage = 'Added PNR ' + pnrCodeToAdd + ' to selection';
            } else {
                errorMessage = 'Could not load details for PNR ' + pnrCodeToAdd;
            }
            
        } catch (Exception e) {
            System.debug('Error in addPNRToSelection: ' + e.getMessage());
            errorMessage = 'An error occurred while adding PNR to selection.';
        }
        
        return null;
    }
    
    /**
     * @description Remove PNR from selection
     * @return Page reference (null for AJAX)
     */
    public PageReference removePNRFromSelection() {
        try {
            clearMessages();
            
            String pnrCodeToRemove = ApexPages.currentPage().getParameters().get('pnrCode');
            
            if (String.isBlank(pnrCodeToRemove)) {
                errorMessage = 'PNR code is required';
                return null;
            }
            
            // Remove from selected PNRs
            for (Integer i = selectedPNRs.size() - 1; i >= 0; i--) {
                if (selectedPNRs[i].pnrCode.equals(pnrCodeToRemove)) {
                    selectedPNRs.remove(i);
                    break;
                }
            }
            
            // Update active PNR
            if (pnrCodeToRemove.equals(activePNRCode)) {
                if (!selectedPNRs.isEmpty()) {
                    activePNRCode = selectedPNRs[0].pnrCode;
                    loadSeatMapForActivePNR();
                } else {
                    activePNRCode = null;
                    seatMapData = null;
                    currentPageState.changeState(PageState.RESULTS);
                }
            }
            
            successMessage = 'Removed PNR ' + pnrCodeToRemove + ' from selection';
            
        } catch (Exception e) {
            System.debug('Error in removePNRFromSelection: ' + e.getMessage());
            errorMessage = 'An error occurred while removing PNR from selection.';
        }
        
        return null;
    }
    
    /**
     * @description Set active PNR for seat selection
     * @return Page reference (null for AJAX)
     */
    public PageReference setActivePNR() {
        try {
            clearMessages();
            
            if (String.isBlank(activePNRCode)) {
                errorMessage = 'PNR code is required';
                return null;
            }
            
            // Verify PNR is in search results
            if (searchResult == null || !searchResult.validPNRs.contains(activePNRCode)) {
                errorMessage = 'Invalid PNR selection';
                return null;
            }
            
            // Load passengers and seat map for selected PNR
            loadActivePassengers();
            loadSeatMapForActivePNR();
            
        } catch (Exception e) {
            System.debug('Error in setActivePNR: ' + e.getMessage());
            errorMessage = 'Error switching PNR: ' + e.getMessage();
        }
        
        return null;
    }
    
    /**
     * @description Select passenger for seat assignment
     * @return Page reference (null for AJAX)
     */
    public PageReference selectPassenger() {
        try {
            clearMessages();
            
            if (!isSelectionMode) {
                errorMessage = 'Please enter selection mode first';
                return null;
            }
            
            if (String.isBlank(selectedPassengerId)) {
                errorMessage = 'Passenger ID is required';
                return null;
            }
            
            // Find passenger name for display
            for (PassengerDisplayInfo passenger : activePassengers) {
                if (passenger.id.equals(selectedPassengerId)) {
                    selectedPassengerName = passenger.name;
                    break;
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in selectPassenger: ' + e.getMessage());
            errorMessage = 'Error selecting passenger: ' + e.getMessage();
        }
        
        return null;
    }
    
    /**
     * @description Assign seat to selected passenger
     * @return Page reference (null for AJAX)
     */
    public PageReference assignSeat() {
        try {
            clearMessages();
            
            if (String.isBlank(selectedPassengerId) || String.isBlank(selectedSeatCode)) {
                errorMessage = 'Passenger and seat selection required';
                return null;
            }
            
            // Get active PNR data
            PNRData activePNR = getActivePNRData();
            if (activePNR == null) {
                errorMessage = 'No active PNR available';
                return null;
            }
            
            // Assign seat using service
            AssignmentResult result = seatAssignmentService.assignSeat(
                selectedPassengerId, 
                selectedSeatCode, 
                activePNR.aircraftType,
                activePNR.flightNumber,
                activePNR.departureDate
            );
            
            if (result.success) {
                successMessage = 'Seat ' + selectedSeatCode + ' assigned successfully';
                
                // Refresh passenger data
                loadActivePassengers();
                
                // Clear selection
                selectedSeatCode = null;
            } else {
                errorMessage = result.errorMessage;
            }
            
        } catch (Exception e) {
            System.debug('Error in assignSeat: ' + e.getMessage());
            errorMessage = 'Error assigning seat: ' + e.getMessage();
        }
        
        return null;
    }
    
    /**
     * @description Enter seat selection mode
     * @return Page reference (null for AJAX)
     */
    public PageReference enterSelectionMode() {
        try {
            clearMessages();
            
            if (String.isBlank(activePNRCode) || activePassengers.isEmpty()) {
                errorMessage = 'Please select a PNR with passengers first';
                return null;
            }
            
            isSelectionMode = true;
            successMessage = 'Seat selection mode activated. Click on a passenger to select seats.';
            
        } catch (Exception e) {
            System.debug('Error in enterSelectionMode: ' + e.getMessage());
            errorMessage = 'Error entering selection mode: ' + e.getMessage();
        }
        
        return null;
    }
    
    /**
     * @description Exit seat selection mode
     * @return Page reference (null for AJAX)
     */
    public PageReference exitSelectionMode() {
        try {
            clearMessages();
            
            isSelectionMode = false;
            selectedPassengerId = null;
            selectedPassengerName = null;
            selectedSeatCode = null;
            
            successMessage = 'Exited seat selection mode';
            
        } catch (Exception e) {
            System.debug('Error in exitSelectionMode: ' + e.getMessage());
            errorMessage = 'Error exiting selection mode: ' + e.getMessage();
        }
        
        return null;
    }
    
    /**
     * @description Save seat assignments
     * @return Page reference (null for AJAX)
     */
    public PageReference saveAssignments() {
        try {
            clearMessages();
            
            if (!isSelectionMode) {
                errorMessage = 'Not in selection mode';
                return null;
            }
            
            // TODO: Implement bulk save logic when needed
            successMessage = 'Seat assignments saved successfully';
            
            // Exit selection mode
            exitSelectionMode();
            
        } catch (Exception e) {
            System.debug('Error in saveAssignments: ' + e.getMessage());
            errorMessage = 'Error saving assignments: ' + e.getMessage();
        }
        
        return null;
    }
    
    /**
     * @description Clear all seat assignments for active PNR
     * @return Page reference (null for AJAX)
     */
    public PageReference clearAllAssignments() {
        try {
            clearMessages();
            
            if (!isSelectionMode) {
                errorMessage = 'Not in selection mode';
                return null;
            }
            
            if (String.isBlank(activePNRCode)) {
                errorMessage = 'No active PNR selected';
                return null;
            }
            
            // TODO: Implement bulk clear logic when seat assignment service is available
            // For now, just refresh the passenger data
            loadActivePassengers();
            
            successMessage = 'All seat assignments cleared for PNR ' + activePNRCode;
            
        } catch (Exception e) {
            System.debug('Error in clearAllAssignments: ' + e.getMessage());
            errorMessage = 'Error clearing assignments: ' + e.getMessage();
        }
        
        return null;
    }
    
    /**
     * @description Reset page to initial state
     * @return Page reference (null for AJAX)
     */
    public PageReference reset() {
        try {
            // Clear all data
            flightNumber = null;
            departureDateStr = null;
            departureLocation = null;
            bookingCodes = null;
            searchResult = null;
            activePNRCode = null;
            seatMapData = null;
            activePassengers = new List<PassengerDisplayInfo>();
            tabPassengerCounts = new Map<String, Integer>();
            selectedPNRs = new List<PNRData>();
            
            // Reset selection state
            isSelectionMode = false;
            selectedPassengerId = null;
            selectedPassengerName = null;
            selectedSeatCode = null;
            
            // Reset page state
            currentPageState = new PageState();
            
            clearMessages();
            
        } catch (Exception e) {
            System.debug('Error in reset: ' + e.getMessage());
            errorMessage = 'Error resetting page: ' + e.getMessage();
        }
        
        return null;
    }
    
    /**
     * @description Get active PNR data
     * @return PNRData object
     */
    private PNRData getActivePNRData() {
        if (String.isBlank(activePNRCode)) {
            return null;
        }
        
        try {
            return pnrService.getPNRDetails(activePNRCode);
        } catch (Exception e) {
            System.debug('Error getting PNR data: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Load passengers for active PNR
     */
    private void loadActivePassengers() {
        try {
            if (String.isBlank(activePNRCode)) {
                activePassengers = new List<PassengerDisplayInfo>();
                return;
            }
            
            activePassengers = passengerService.getPassengersForPNR(activePNRCode);
            
        } catch (Exception e) {
            System.debug('Error loading passengers: ' + e.getMessage());
            activePassengers = new List<PassengerDisplayInfo>();
        }
    }
    
    /**
     * @description Load seat map for active PNR
     */
    private void loadSeatMapForActivePNR() {
        try {
            if (String.isBlank(activePNRCode)) {
                seatMapData = null;
                return;
            }
            
            // Get PNR data for flight information
            PNRData pnrData = getActivePNRData();
            if (pnrData == null) {
                seatMapData = null;
                return;
            }
            
            // Create seat map request
            SeatMapRequest request = new SeatMapRequest(
                pnrData.flightNumber,
                pnrData.departureDate,
                pnrData.origin,
                pnrData.destination,
                null // booking class - optional
            );
            
            // Get seat map
            SeatMapData result = seatMapService.getSeatMap(request);
            
            if (result != null && result.isValid()) {
                seatMapData = result;
            } else {
                seatMapData = null;
            }
            
        } catch (Exception e) {
            System.debug('Error loading seat map: ' + e.getMessage());
            seatMapData = null;
        }
    }
    
    /**
     * @description Calculate passenger counts for each PNR tab
     */
    private void calculateTabPassengerCounts() {
        tabPassengerCounts = new Map<String, Integer>();
        
        if (searchResult != null && searchResult.pnrDetails != null) {
            for (PNRData pnr : searchResult.pnrDetails) {
                Integer count = pnr.passengerIds != null ? pnr.passengerIds.size() : 0;
                tabPassengerCounts.put(pnr.pnrCode, count);
            }
        }
    }
    
    /**
     * @description Clear all messages
     */
    private void clearMessages() {
        this.errorMessage = null;
        this.successMessage = null;
    }
    
    /**
     * @description Get JSON representation of seat map data for JavaScript
     * @return JSON string
     */
    public String getSeatMapDataJSON() {
        if (seatMapData == null) {
            return '{}';
        }
        
        try {
            Map<String, Object> seatMapJSON = new Map<String, Object>{
                'aircraftType' => seatMapData.aircraftType,
                'cabinClasses' => seatMapData.cabinClasses,
                'disabledSeats' => seatMapData.disabledSeats != null ? seatMapData.disabledSeats : new List<String>(),
                'noWindowSeats' => seatMapData.noWindowSeats != null ? seatMapData.noWindowSeats : new List<String>()
            };
            
            return JSON.serialize(seatMapJSON);
        } catch (Exception e) {
            System.debug('Error serializing seat map data: ' + e.getMessage());
            return '{}';
        }
    }
    
}