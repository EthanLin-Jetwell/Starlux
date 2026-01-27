/**
 * @description Result of PNR search operation
 * @author STARLUX Development Team
 * @date 2024
 */
public class PNRSearchResult {
    public List<String> validPNRs { get; set; }
    public List<String> invalidPNRs { get; set; }
    public List<PNRData> pnrDetails { get; set; }
    public Boolean hasErrors { get; set; }
    public String errorMessage { get; set; }
    public Integer totalPassengers { get; set; }
    
    /**
     * @description Default constructor
     */
    public PNRSearchResult() {
        this.validPNRs = new List<String>();
        this.invalidPNRs = new List<String>();
        this.pnrDetails = new List<PNRData>();
        this.hasErrors = false;
        this.totalPassengers = 0;
    }
    
    /**
     * @description Constructor with error
     * @param errorMessage Error message
     */
    public PNRSearchResult(String errorMessage) {
        this();
        this.hasErrors = true;
        this.errorMessage = errorMessage;
    }
    
    /**
     * @description Check if has valid PNRs
     * @return True if has valid PNRs
     */
    public Boolean hasValidPNRs() {
        return !validPNRs.isEmpty();
    }
    
    /**
     * @description Check if has invalid PNRs
     * @return True if has invalid PNRs
     */
    public Boolean hasInvalidPNRs() {
        return !invalidPNRs.isEmpty();
    }
    
    /**
     * @description Add valid PNR
     * @param pnrCode PNR code to add
     */
    public void addValidPNR(String pnrCode) {
        if (String.isNotBlank(pnrCode) && !validPNRs.contains(pnrCode)) {
            validPNRs.add(pnrCode);
        }
    }
    
    /**
     * @description Add invalid PNR
     * @param pnrCode PNR code to add
     */
    public void addInvalidPNR(String pnrCode) {
        if (String.isNotBlank(pnrCode) && !invalidPNRs.contains(pnrCode)) {
            invalidPNRs.add(pnrCode);
        }
    }
    
    /**
     * @description Add PNR details
     * @param pnrData PNR data to add
     */
    public void addPNRData(PNRData pnrData) {
        if (pnrData != null) {
            pnrDetails.add(pnrData);
            totalPassengers += pnrData.passengerCount;
        }
    }
    
    /**
     * @description Check if result is successful
     * @return True if successful
     */
    public Boolean isSuccessful() {
        return !hasErrors && hasValidPNRs();
    }
}