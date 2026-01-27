/**
 * @description PNR Service Implementation
 * @author STARLUX Development Team
 * @date 2024
 */
public class PNRService implements IPNRService {
    private ITravellerRepository travellerRepository;
    private IAmadeusAPIClient apiClient;
    
    /**
     * @description Constructor with dependencies
     */
    public PNRService() {
        // this.travellerRepository = ServiceFactory.getTravellerRepository();
        this.travellerRepository = new TravellerRepository();
        // this.apiClient = ServiceFactory.getAmadeusAPIClient();
        this.apiClient = new AmadeusAPIClient();
    }
    
    /**
     * @description Constructor for testing with mocks
     * @param travellerRepository Mock repository
     * @param apiClient Mock API client
     */
    public PNRService(ITravellerRepository travellerRepository, IAmadeusAPIClient apiClient) {
        this.travellerRepository = travellerRepository;
        this.apiClient = apiClient;
    }
    
    /**
     * @description Search for PNRs by criteria
     * @param criteria Search criteria
     * @return Search results
     */
    public PNRSearchResult searchPNRs(SearchCriteria criteria) {
        try {
            // Validate input
            List<ValidationError> validationErrors = criteria.validate();
            if (!validationErrors.isEmpty()) {
                ValidationResult validation = new ValidationResult(false);
                for (ValidationError error : validationErrors) {
                    validation.addError(error);
                }
                return new PNRSearchResult(validation.getSummary());
            }
            
            // Create repository query
            RepositoryQuery query = new RepositoryQuery();
            for (String pnrCode : criteria.pnrCodes) {
                query.addPNRCode(pnrCode);
            }
            query.departureDate = criteria.departureDate;
            query.departureLocation = criteria.departureLocation;
            query.limitSize = 100; // Reasonable limit for UI
            
            // Query database
            List<TravellerInfo__c> travellers = travellerRepository.findTravellers(query);
            
            if (travellers.isEmpty()) {
                return new PNRSearchResult('No PNR records found matching the search criteria');
            }
            
            // Group travellers by PNR
            Map<String, List<TravellerInfo__c>> pnrGroups = groupTravellersByPNR(travellers);
            
            // Convert to PNR data objects
            PNRSearchResult result = new PNRSearchResult();
            for (String pnrCode : pnrGroups.keySet()) {
                PNRData pnrData = convertTravellersToPNRData(pnrCode, pnrGroups.get(pnrCode));
                if (pnrData != null) {
                    result.addPNRData(pnrData);
                    result.addValidPNR(pnrCode);
                }
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in searchPNRs: ' + e.getMessage());
            return new PNRSearchResult('An error occurred while searching for PNRs: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get detailed PNR information
     * @param pnrCode PNR code
     * @return PNR data
     */
    public PNRData getPNRDetails(String pnrCode) {
        try {
            if (String.isBlank(pnrCode)) {
                return null;
            }
            
            // Query repository
            RepositoryQuery query = new RepositoryQuery();
            query.addPNRCode(pnrCode);
            
            List<TravellerInfo__c> travellers = travellerRepository.findTravellers(query);
            
            if (travellers.isEmpty()) {
                return null;
            }
            
            // Convert to PNR data
            return convertTravellersToPNRData(pnrCode, travellers);
            
        } catch (Exception e) {
            System.debug('Error in getPNRDetails: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Validate PNR exists and is accessible
     * @param pnrCode PNR code
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return Validation result
     */
    public ValidationResult validatePNR(String pnrCode, String flightNumber, Date departureDate) {
        ValidationResult result = new ValidationResult();
        
        try {
            // Basic validation
            if (String.isBlank(pnrCode)) {
                result.addError(new ValidationError('pnrCode', 'PNR code is required'));
                return result;
            }
            
            // Check if PNR exists in database
            RepositoryQuery query = new RepositoryQuery();
            query.addPNRCode(pnrCode);
            if (departureDate != null) {
                query.departureDate = departureDate;
            }
            
            List<TravellerInfo__c> travellers = travellerRepository.findTravellers(query);
            
            if (travellers.isEmpty()) {
                result.addError(new ValidationError('pnrCode', 'PNR not found or does not match flight criteria'));
                return result;
            }
            
            // Validate flight information consistency - using correct field names
            Set<String> flightNumbers = new Set<String>();
            Set<String> departureDateStrings = new Set<String>(); // Handle as strings
            
            for (TravellerInfo__c traveller : travellers) {
                if (String.isNotBlank(traveller.FlightNumber__c)) {
                    flightNumbers.add(traveller.FlightNumber__c);
                }
                if (traveller.DepartureDate__c != null) {
                    departureDateStrings.add(String.valueOf(traveller.DepartureDate__c));
                }
            }
            
            if (flightNumbers.size() > 1) {
                result.addError(new ValidationError('flightNumber', 'PNR contains multiple flight numbers'));
            }
            
            if (departureDateStrings.size() > 1) {
                result.addError(new ValidationError('departureDate', 'PNR contains multiple departure dates'));
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in validatePNR: ' + e.getMessage());
            result.addError(new ValidationError('system', 'System error during PNR validation'));
            return result;
        }
    }
    
    /**
     * @description Refresh PNR data from external system
     * @param pnrCode PNR code
     * @return Updated PNR data
     */
    public PNRData refreshPNRData(String pnrCode) {
        try {
            if (String.isBlank(pnrCode)) {
                return null;
            }
            
            // Call external API to get latest PNR data using new interface
            List<TravellerInfo__c> travellers = apiClient.retrievePNR('', pnrCode); // Default departure location
            
            if (travellers == null || travellers.isEmpty()) {
                System.debug('Failed to refresh PNR data: No travellers found');
                // Fall back to database data
                return getPNRDetails(pnrCode);
            }
            
            // Update database with fresh data
            try {
                upsert travellers External_ID__c;
                System.debug('Updated ' + travellers.size() + ' traveller records from API');
            } catch (Exception e) {
                System.debug('Error updating traveller records: ' + e.getMessage());
            }
            
            // Return updated data from database
            return getPNRDetails(pnrCode);
            
        } catch (Exception e) {
            System.debug('Error in refreshPNRData: ' + e.getMessage());
            // Fall back to database data
            return getPNRDetails(pnrCode);
        }
    }
    
    /**
     * @description Group travellers by PNR code
     * @param travellers List of traveller records
     * @return Map of PNR code to travellers
     */
    private Map<String, List<TravellerInfo__c>> groupTravellersByPNR(List<TravellerInfo__c> travellers) {
        Map<String, List<TravellerInfo__c>> groups = new Map<String, List<TravellerInfo__c>>();
        
        for (TravellerInfo__c traveller : travellers) {
            String pnrCode = traveller.PNR__c; // Correct field name
            if (String.isNotBlank(pnrCode)) {
                if (!groups.containsKey(pnrCode)) {
                    groups.put(pnrCode, new List<TravellerInfo__c>());
                }
                groups.get(pnrCode).add(traveller);
            }
        }
        
        return groups;
    }
    
    /**
     * @description Convert traveller records to PNR data object
     * @param pnrCode PNR code
     * @param travellers List of travellers
     * @return PNR data object
     */
    private PNRData convertTravellersToPNRData(String pnrCode, List<TravellerInfo__c> travellers) {
        if (travellers.isEmpty()) {
            return null;
        }
        
        // Use first traveller for flight information
        TravellerInfo__c firstTraveller = travellers[0];
        
        // Create PNR data using constructor with basic info
        PNRData pnrData = new PNRData(pnrCode);
        
        // Set flight details manually
        pnrData.flightNumber = firstTraveller.FlightNumber__c;
        pnrData.departureDate = parseDepartureDateString(firstTraveller.DepartureDate__c);
        pnrData.origin = firstTraveller.DepartureLocation__c;
        pnrData.destination = firstTraveller.Destination__c;
        
        // Note: aircraftType should come from AirRetrieveSeatMap.Result
        // It's not stored in individual traveller records
        // This will be set by the seat map service when needed
        
        // Add passenger IDs
        for (TravellerInfo__c traveller : travellers) {
            if (String.isNotBlank(traveller.External_ID__c)) {
                pnrData.addPassengerId(traveller.External_ID__c);
            }
            
            // Check for US bound passengers
            if (traveller.US_Bound__c) {
                pnrData.hasUSBoundPassengers = true;
            }
        }
        
        return pnrData;
    }
    
    /**
     * @description Parse departure date string from various formats
     * @param dateString Date string (could be DDMMYY, YYYY-MM-DD, etc.)
     * @return Parsed Date object or null if parsing fails
     */
    private Date parseDepartureDateString(String dateString) {
        if (String.isBlank(dateString)) {
            return null;
        }
        
        try {
            // Try standard ISO format first (YYYY-MM-DD)
            if (dateString.contains('-')) {
                return Date.valueOf(dateString);
            }
            
            // Handle DDMMYY format (e.g., "250625" = 25/06/25)
            if (dateString.length() == 6 && dateString.isNumeric()) {
                String day = dateString.substring(0, 2);
                String month = dateString.substring(2, 4);
                String year = dateString.substring(4, 6);
                
                // Convert YY to YYYY (assuming 20YY for years 00-99)
                Integer yearInt = Integer.valueOf(year);
                if (yearInt >= 0) {
                    year = '20' + year;
                }
                
                String formattedDate = year + '-' + month + '-' + day;
                return Date.valueOf(formattedDate);
            }
            
            // Handle DDMMYYYY format (e.g., "25062025")
            if (dateString.length() == 8 && dateString.isNumeric()) {
                String day = dateString.substring(0, 2);
                String month = dateString.substring(2, 4);
                String year = dateString.substring(4, 8);
                
                String formattedDate = year + '-' + month + '-' + day;
                return Date.valueOf(formattedDate);
            }
            
            // Handle other formats if needed
            System.debug('Unknown date format: ' + dateString + ', attempting direct parsing');
            return Date.valueOf(dateString);
            
        } catch (Exception e) {
            System.debug('Error parsing date string "' + dateString + '": ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Update traveller records from API data
     * @param pnrCode PNR code
     * @param apiData API response data
     */
    private void updateTravellersFromAPI(String pnrCode, Map<String, Object> apiData) {
        // This would be implemented based on actual API structure
        // For now, just log that refresh was attempted
        System.debug('PNR refresh attempted for: ' + pnrCode);
        
        // In real implementation, would:
        // 1. Parse API response structure
        // 2. Update TravellerInfo__c records
        // 3. Handle any data conflicts
        // 4. Commit changes to database
    }
    
    /**
     * @description Get PNR details from external system
     * @param pnrCode PNR code
     * @return PNR data
     */
    private PNRData getPNRFromAPI(String pnrCode) {
        try {
            if (String.isBlank(pnrCode)) {
                return null;
            }
            
            // Call new API client method
            List<TravellerInfo__c> travellers = apiClient.retrievePNR('', pnrCode); // Default departure location
            
            if (travellers == null || travellers.isEmpty()) {
                System.debug('No traveller data found for PNR: ' + pnrCode);
                return null;
            }
            
            // Convert to PNRData using our existing method
            return convertTravellersToPNRData(pnrCode, travellers);
            
        } catch (Exception e) {
            System.debug('Error calling PNR API: ' + e.getMessage());
            return null;
        }
    }
}