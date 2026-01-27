public class ResizePnr {

    // Input Wrapper
    public class InputWrapper {
        @InvocableVariable(required=true)
        public String satId;

        @InvocableVariable(required=true)
        public Integer seatResizing;
        
        /*@InvocableVariable(required=true)
        public String satNoResizing;

        @InvocableVariable(required=true)
        public String satNoMaster;

        @InvocableVariable(required=true)
        public String bookingReference;

        @InvocableVariable(required=true)
        public Integer seatResizing;*/
    }

    // Output Wrapper (Optional)
    public class OutputWrapper {
        @InvocableVariable
        public String resultMessage;
    }

    @InvocableMethod(label='Resize PNR')
    public static void resizePnr(List<InputWrapper> inputs) {
        //List<OutputWrapper> results = new List<OutputWrapper>();
        for (InputWrapper input : inputs) {
            Seat_Allocation_and_Ticketing__c originalSat = 
                [SELECT Id, Name, Allocated_Seats__c,
                 Booking_Reference_PNR__c, Total_Seat_Sales__c,
                 Final_Allocated_Seats__c, Final_Allocated_Seats_Amadeus__c, 
                 Final_Sales_Seats__c, Case_ID__c,
                 Allocation_Type__c,
                 tour_Guide_email__c,
                 tour_Guide_phone__c,
                 Initial_Unit_Price_Adult__c,
                 Final_Unit_Price_Adult__c,
                 Initial_Unit_Price_Child__c,
                 Final_Unit_Price_Child__c,
                 Initial_Unit_Price_Infant__c,
                 Final_Unit_Price_Infant__c,
                 Initial_Tax_Adult__c,
                 Final_Tax_Adult__c,
                 Initial_BSC_Adult__c,
                 Final_BSC_Adult__c,
                 Initial_Tax_Child__c,
                 Final_Tax_Child__c,
                 Initial_BSC_Child__c,
                 Final_BSC_Child__c,
                 Initial_Tax_Infant__c,
                 Final_Tax_Infant__c,
                 Initial_BSC_Infant__c,
                 Final_BSC_Infant__c,
                 Not_in_Fare_Table__c,
                 Tour_Code__c,
                 Not_in_Tax_Table__c,
                 Tax_Date__c
                 FROM Seat_Allocation_and_Ticketing__c
                 WHERE Id = :input.satId];
            
            Case originalCase = [SELECT Id, Status, ParentId, Total_Seat_Sales__c, Total_Seat_Sales_By_Date__c,
                                 SST_Mark__c, Sync_SST_Status__c, RecordTypeId, ContactId, AccountId, Route__c,
                                 Departing_Flight_Number__c, Returning_Flight_Number__c, Departing_Flight_Date__c, 
                                 Departing_Flight_Arrival_Date__c, Returning_Flight_Date__c, 
                                 Returning_Flight_Arrival_Date__c FROM Case WHERE Id = :originalSat.Case_ID__c];
            
            // ---- Clone Case ----
            Case newCase = originalCase.clone(false, true, false, false);
            newCase.ParentId = originalCase.Id;
            newCase.Status = 'Ticket Sales In Progress';
            insert newCase;
            newCase = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id];
            
            // ---- Clone SAT ----
            Seat_Allocation_and_Ticketing__c newSat = originalSat.clone(false, true, false, false);
            newSat.Case_ID__c = newCase.Id;
            newSat.Allocated_Seats__c = input.seatResizing;
            newSat.Total_Seat_Sales__c = null;
            newSat.Final_Allocated_Seats__c = input.seatResizing;
            newSat.Final_Allocated_Seats_Amadeus__c = input.seatResizing;
            newSat.Final_Sales_Seats__c = null;

            
            // Additional fields initialized as null
            newSat.Itinerary__c = null;
            newSat.Get_Itinerary_Status__c = null;
            newSat.Get_Itinerary_Error_Message__c = null;
            newSat.Itinerary_Success_Time__c = null;
            newSat.Last_Get_Itinerary_By__c = null;
            newSat.No_of_Adult__c = null;
            newSat.No_of_Infant__c = null;
            newSat.No_of_Child__c = null;
            newSat.Original_Sat__c = originalSat.Id;     
            
            originalSat.Allocated_Seats__c -= input.seatResizing;
            originalSat.Final_Allocated_Seats__c -= input.seatResizing;
            if (originalSat.Final_Sales_Seats__c != null) originalSat.Final_Sales_Seats__c -= input.seatResizing;
            if (originalSat.Total_Seat_Sales__c == null) originalSat.Total_Seat_Sales__c = 0;
            originalSat.Final_Allocated_Seats_Amadeus__c -= input.seatResizing;
            
            /*Decimal temp = 0;
            
            if (originalSat.Final_Allocated_Seats__c < originalSat.Total_Seat_Sales__c) {
                temp = originalSat.Total_Seat_Sales__c - originalSat.Final_Allocated_Seats__c;
                originalSat.Total_Seat_Sales__c = originalSat.Final_Allocated_Seats__c;
            }*/

            insert newSat;
            update originalSat;

            newSat = [SELECT Id,Name,Case_ID__c,RecordTypeId,Allocation_Type__c,Final_Allocated_Seats__c,Sync_SAT_Status__c FROM Seat_Allocation_and_Ticketing__c WHERE Id = :newSat.Id];
            /*newSat.Total_Seat_Sales__c = temp;
            update newSat;*/
            Seat_Allocation_and_Ticketing__c masterSat = [SELECT Id, Name 
                                                          FROM Seat_Allocation_and_Ticketing__c 
                                                          WHERE Case_ID__c =: originalSat.Case_ID__c 
                                                          AND Booking_Reference_PNR__c =: originalSat.Booking_Reference_PNR__c 
                                                          AND (Allocation_Type__c =: Constants.PICKLIST_SAT_ALLOCATION_TYPE_ADC 
                                                               OR Allocation_Type__c =: Constants.PICKLIST_SAT_ALLOCATION_TYPE_SRS) LIMIT 1];
                                                               
                                                               
            //MiddlewareUtil.resizePnr(newSat.Name, masterSat.Name, originalSat.Booking_Reference_PNR__c, input.seatResizing, newCase.CaseNumber);
           System.enqueueJob(new QueueableResizePnr(newSat.Name, masterSat.Name, originalSat.Booking_Reference_PNR__c, input.seatResizing, newCase.CaseNumber), 1);
        }
    }
}