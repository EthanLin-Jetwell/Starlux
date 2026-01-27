/**
 * @description Interface for Amadeus API integration
 * @author STARLUX Development Team
 * @date 2024
 */
public interface IAmadeusAPIClient {
    
    /**
     * @description Call PNR list API to get PNRs for a flight
     * @param flightNumber Flight number (format: "8123" or "8123D")
     * @param departureDate Departure date in yyyy/mm/dd format
     * @return Set of PNR codes
     */
    Map<String, String> listPNRByFlight(String flightNumber, String departureDate);
    
    /**
     * @description Call PNR retrieve API to get passenger details
     * @param departureLocation Origin airport code
     * @param pnrCode PNR code
     * @return List of TravellerInfo__c records
     */
    List<TravellerInfo__c> retrievePNR(String departureLocation, String pnrCode);
    
    /**
     * @description Call seat map retrieve API
     * @param departureDate Departure date in yyyy/mm/dd format
     * @param departureLocation Origin airport code
     * @param destination Destination airport code
     * @param flightNumber Flight number
     * @param bookingClass Booking class
     * @return Seat map result from Amadeus API
     */
    AirRetrieveSeatMap.Result callSeatMapRetrieve(String departureDate, String departureLocation, String destination, String flightNumber, String bookingClass);
    
    /**
     * @description Call document upload API for travellers
     * @param departureLocation Origin airport code
     * @param pnrCode PNR code
     * @param travelerData List of traveller information
     */
    void uploadDocuments(String departureLocation, String pnrCode, List<TravellerInfo__c> travelerData);
    
    /**
     * @description Call delete dropped OT API
     * @param departureLocation Origin airport code
     * @param pnrCode PNR code
     * @param droppedOTNumbers List of OT numbers to delete
     */
    void deleteDroppedOT(String departureLocation, String pnrCode, List<String> droppedOTNumbers);
}