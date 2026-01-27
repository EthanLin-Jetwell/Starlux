/**
 * @description Amadeus API Client Implementation - Simple wrapper for AmadeusUtil
 * @author STARLUX Development Team
 * @date 2024
 */
public class AmadeusAPIClient implements IAmadeusAPIClient {
    
    /**
     * @description Call PNR list API to get PNRs for a flight
     * @param flightNumber Flight number (format: "8123" or "8123D")
     * @param departureDate Departure date in yyyy/mm/dd format
     * @return Set of PNR codes
     */
    public Map<String, String> listPNRByFlight(String flightNumber, String departureDate) {
        return AmadeusUtil.listPNRByFlight(flightNumber, departureDate);
    }
    
    /**
     * @description Call PNR retrieve API to get passenger details
     * @param departureLocation Origin airport code
     * @param pnrCode PNR code
     * @return List of TravellerInfo__c records
     */
    public List<TravellerInfo__c> retrievePNR(String departureLocation, String pnrCode) {
        return AmadeusUtil.retrievePNR(departureLocation, pnrCode);
    }
    
    /**
     * @description Call seat map retrieve API
     * @param departureDate Departure date in yyyy/mm/dd format
     * @param departureLocation Origin airport code
     * @param destination Destination airport code
     * @param flightNumber Flight number
     * @param bookingClass Booking class
     * @return Seat map result from Amadeus API
     */
    public AirRetrieveSeatMap.Result callSeatMapRetrieve(String departureDate, String departureLocation, String destination, String flightNumber, String bookingClass) {
        try {
            // Validate required fields
            if (String.isBlank(flightNumber) || String.isBlank(departureDate) || 
                String.isBlank(departureLocation) || String.isBlank(destination)) {
                System.debug('Missing required fields for seat map retrieval');
                return null;
            }
            
            // Call the actual AmadeusUtilRetrieveSeatMap method
            AirRetrieveSeatMap.Result result = AmadeusUtilRetrieveSeatMap.Air_RetrieveSeatMap(
                departureDate,
                departureLocation,
                destination, 
                flightNumber,
                bookingClass != null ? bookingClass : 'Y' // Default to economy if not specified
            );
            
            if (result != null) {
                System.debug('Successfully retrieved seat map from Amadeus API');
                return result;
            } else {
                System.debug('AmadeusUtilRetrieveSeatMap returned null result');
                return null;
            }
            
        } catch (Exception e) {
            System.debug('Error in callSeatMapRetrieve: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Call document upload API for travellers
     * @param departureLocation Origin airport code
     * @param pnrCode PNR code
     * @param travelerData List of traveller information
     */
    public void uploadDocuments(String departureLocation, String pnrCode, List<TravellerInfo__c> travelerData) {
        AmadeusUtil.uploadDocuments(departureLocation, pnrCode, travelerData);
    }
    
    /**
     * @description Call delete dropped OT API
     * @param departureLocation Origin airport code
     * @param pnrCode PNR code
     * @param droppedOTNumbers List of OT numbers to delete
     */
    public void deleteDroppedOT(String departureLocation, String pnrCode, List<String> droppedOTNumbers) {
        AmadeusUtil.deleteDroppedOT(departureLocation, pnrCode, droppedOTNumbers);
    }
}