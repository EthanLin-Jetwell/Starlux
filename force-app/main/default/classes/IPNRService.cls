/**
 * @description Interface for PNR (Passenger Name Record) operations
 * @author STARLUX Development Team
 * @date 2024
 */
public interface IPNRService {
    
    /**
     * @description Search for PNRs by criteria
     * @param criteria Search criteria
     * @return Search results
     */
    PNRSearchResult searchPNRs(SearchCriteria criteria);
    
    /**
     * @description Get detailed PNR information
     * @param pnrCode PNR code
     * @return PNR data
     */
    PNRData getPNRDetails(String pnrCode);
    
    /**
     * @description Validate PNR exists and is accessible
     * @param pnrCode PNR code
     * @param flightNumber Flight number
     * @param departureDate Departure date
     * @return Validation result
     */
    ValidationResult validatePNR(String pnrCode, String flightNumber, Date departureDate);
    
    /**
     * @description Refresh PNR data from external system
     * @param pnrCode PNR code
     * @return Updated PNR data
     */
    PNRData refreshPNRData(String pnrCode);
}