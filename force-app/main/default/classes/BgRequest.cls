global class BgRequest {
    // Common / identifying info
    public String identify;
    public String requisitionID;
    public String serialID;
    public String diagramID;
    
    // Applicant info
    public String applicantID;
    public String applicantName;
    public String applicantDept;
    public String applicantDeptName;
    public String applicantDateTime;
    
    // TA (Travel Agency or Third-Party) info
    public String TA_Name;
    public String TA_BusinessNumber;
    public String TA_Address;
    public String TA_Phone;
    public String TA_PIC;
    public String TA_PIC_Phone;
    public String PIC_Email;
    
    // BG or Replenishment details
    public String FunctionType;          // A = Apply, W = Withdraw, R = Replenish
    public String Remark;
    public String BG_VaildDate;
    public String BG_ExpiryDate;
    public String BG_Category;
    public String Bank;
    public String BG_Number;
    public String Money;
    public String CityCode;
    public String CreditAmount;
    public String WithdrawBeforeExpiry;
    public String SF_BG_No;
    public String AccountUnlock;
    
    // Optional fields for future modes
    public String otherParam1;
    public String otherParam2;
}