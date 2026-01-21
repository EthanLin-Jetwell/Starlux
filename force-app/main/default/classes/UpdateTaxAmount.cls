public class UpdateTaxAmount {
    private static Date currentDate = Date.today();
    
	@InvocableMethod(label='Get Tax Amount')
    public static List<Boolean> getTaxAmount(List<ID> SeatAllocationID) {
        List<Boolean> returnResult = new List<Boolean>();
        
        
        //Query for target Seat Allocation Record 
        List<Seat_Allocation_and_Ticketing__c> newSeatAllocationList = [SELECT Id,Tax_Date__c,Final_Sales_Seats__c,Returning_Flight_Date__c,Departing_Flight_Date__c,CreatedDate,Case_ID__c,Departing_Flight_Number__c,
                                                                        Returning_Flight_Number__c,Group_Booking_Route__c,Initial_Unit_Price_Infant__c,Initial_Unit_Price_Child__c,
                                                                        Initial_Unit_Price_Adult__c,Initial_Tax_Infant__c,Initial_Tax_Child__c,Initial_Tax_Adult__c,
                                                                        Final_Unit_Price_Infant__c,Final_Unit_Price_Child__c,Final_Unit_Price_Adult__c,Final_Tax_Infant__c,
                                                                        Final_Tax_Child__c,Final_Tax_Adult__c,Not_in_Fare_Table__c,Not_in_Tax_Table__c,Case_Id__r.Account.IATA_MSO_Code__c 
                                                                        FROM Seat_Allocation_and_Ticketing__c WHERE Id IN :SeatAllocationID];
        
        Seat_Allocation_and_Ticketing__c newSeatAllocation = newSeatAllocationList[0];
        
       	Date TargetDate = newSeatAllocation.Tax_Date__c;
        String DepartureFlightNo = newSeatAllocation.Departing_Flight_Number__c;
        String ReturningFlightNo = newSeatAllocation.Returning_Flight_Number__c;
        Date DepartingFlightDate = newSeatAllocation.Departing_Flight_Date__c;
        Date ReturningFlightDate = newSeatAllocation.Returning_Flight_Date__c;
        Datetime IssueDateTime = datetime.now();
        Date IssueDate = date.newInstance(IssueDateTime.year(),IssueDateTime.month(),IssueDateTime.day());
        String IATACode = newSeatAllocation.Case_Id__r.Account.IATA_MSO_Code__c;
        Decimal FinalSeats = newSeatAllocation.Final_Sales_Seats__c;
        String Route = newSeatAllocation.Group_Booking_Route__c;
        
        //Query for all applicable Tax Table records
        List<Tax_Details__c> allTaxTables = [SELECT Id,CreatedDate,Tax_Amount_Adult__c,Tax_Amount_Child__c,Tax_Amount_Infant__c,Route__c,Tax_Date__c FROM Tax_Details__c 
                                          WHERE Tax_Date__c >= :currentDate-90];
        
        //Store all Tax Table records in a Map
        Map<String, Tax_Details__c> mapTaxTable = new Map<String, Tax_Details__c>();
        Integer taxCount = 1;
        
        for (Tax_Details__c tax : allTaxTables) {
            String taxKey = 'Tax' + String.valueOf(taxCount);
            mapTaxTable.put(taxKey, tax);
            taxCount += 1;
        }
        
						//Final selected records
                        Ticket_Fare_Rule__c selectedTicketFare = new Ticket_Fare_Rule__c();
                        Tax_Details__c selectedTaxTable = new Tax_Details__c();
                        
                        Decimal extraSurcharge = 0;
                        
                        //All shortlisted records after filtering later on
                        List<Ticket_Fare_Rule__c> allSelectedFares = new List<Ticket_Fare_Rule__c>();
                        List<Tax_Details__c> allSelectedTaxes = new List<Tax_Details__c>();
                        
                        //Check if any record in mapTaxTable matches criteria of newSeatAllocation
                        for (String key : mapTaxTable.keySet()) {
                            Tax_Details__c loopTaxTable = mapTaxTable.get(key);
                            
                            if (loopTaxTable.Route__c == Route && loopTaxTable.Tax_Date__c == TargetDate) { 
                                system.debug('DBG selectedTaxTable: '+loopTaxTable);
                            	allSelectedTaxes.add(loopTaxTable);
                            }
                        }
                        
                        //Sorting allSelectedTaxes based on matching outcomes to determine the right Tax Table record to be used
                        if (allSelectedTaxes.size() > 1) {
                            Datetime latestDate = datetime.newInstance(1990,1,1);
                            Tax_Details__c latestTax = new Tax_Details__c();
                            for (Tax_Details__c loopTax : allSelectedTaxes) {
                                if (loopTax.CreatedDate > latestDate) {
                                    latestDate = loopTax.CreatedDate;
                                    latestTax = loopTax;
                                }
                            }
                            returnResult.add(true);
                            selectedTaxTable = latestTax;
                            newSeatAllocation.Not_in_Tax_Table__c = false;
                             
                        } else {
                            if (allSelectedTaxes.size() == 1) {
                                returnResult.add(true);
                                selectedTaxTable = allSelectedTaxes[0];
                                newSeatAllocation.Not_in_Tax_Table__c = false;
                            } 
                            if (allSelectedTaxes.size() == 0) {
                                returnResult.add(false);
                                newSeatAllocation.Not_in_Tax_Table__c = true;
                                newSeatAllocation.Tax_Date__c = null;
                                newSeatAllocation.Final_Tax_Adult__c = null;
                                newSeatAllocation.Final_Tax_Child__c = null;
                                newSeatAllocation.Final_Tax_Infant__c = null;
                            }
                        }
                        
                        //Update tax fields on Seat Allocation records
                        if (selectedTaxTable.Tax_Amount_Adult__c != null) {
                            newSeatAllocation.Final_Tax_Adult__c = selectedTaxTable.Tax_Amount_Adult__c;
                        }
                        if (selectedTaxTable.Tax_Amount_Child__c != null) {
                            newSeatAllocation.Final_Tax_Child__c = selectedTaxTable.Tax_Amount_Child__c;
                        }
                        if (selectedTaxTable.Tax_Amount_Infant__c != null) {
                            newSeatAllocation.Final_Tax_Infant__c = selectedTaxTable.Tax_Amount_Infant__c;
                        }
       
						Database.SaveResult updateResult = database.update(newSeatAllocation, false); 
    	return returnResult;
    }
}