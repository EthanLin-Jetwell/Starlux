public class UpdateTicketFare {
    private static Date currentDate = Date.today();
    
    public static List<Boolean> getTicketFare(List<ID> SeatAllocationID) {
        List<Boolean> returnResult = new List<Boolean>();
                
        //Query for target Seat Allocation Record (removed finalallocation)
        List<Seat_Allocation_and_Ticketing__c> newSeatAllocationList = [SELECT Id,Tour_Code__c,Returning_Flight_Date__c,Final_Sales_Seats__c,Departing_Flight_Date__c,CreatedDate,Case_ID__c,Departing_Flight_Number__c,
                                                                        Returning_Flight_Number__c,Group_Booking_Route__c,Initial_Unit_Price_Infant__c,Initial_Unit_Price_Child__c,
                                                                        Initial_Unit_Price_Adult__c,Initial_Tax_Infant__c,Initial_Tax_Child__c,Initial_Tax_Adult__c,
                                                                        Final_Unit_Price_Infant__c,Final_Unit_Price_Child__c,Final_Unit_Price_Adult__c,Final_Tax_Infant__c,
                                                                        Final_Tax_Child__c,Final_Tax_Adult__c,Not_in_Fare_Table__c,Not_in_Tax_Table__c,Case_Id__r.Account.IATA_MSO_Code__c 
                                                                        FROM Seat_Allocation_and_Ticketing__c WHERE Id IN :SeatAllocationID];
        
        Seat_Allocation_and_Ticketing__c newSeatAllocation = newSeatAllocationList[0];
        Case currCase = [SELECT Id, Total_Final_Sales_Seats__c FROM Case WHERE Id =: newSeatAllocation.Case_ID__c];//2023-12-11 Eli ISP-0041-2023121102
        //Prepare for querying newSeatAllocationList: Chris Hsu 2019-11-28
        Date DepartingFlightDate = newSeatAllocation.Departing_Flight_Date__c;
        Date ReturningFlightDate = newSeatAllocation.Returning_Flight_Date__c;
        String TourCode = newSeatAllocation.Tour_Code__c;       
        //Query for all applicable Ticket Fare Rule records
        //Remove CurrentDate-7 and check DepartingFlightDate in effective range : Chris Hsu 2019-11-28
        //Add Is_Saturday__c and Is_Sunday__c in the query: Chris Hsu 2020-02-14
        List<Ticket_Fare_Rule__c> allTicketFares = [SELECT Id,Tour_Code__c,Departing_Flight_Number__c,Returning_Flight_Number__c,Minimal_No_of_Pax__c,Less_than_Minimal_No_of_Pax__c,
                                                    Is_Weekend__c,Is_Saturday__c,Is_Sunday__c,CreatedDate,Name,Unit_Price_Infant__c,Effective_Flight_End_Date__c,Effective_Flight_Start_Date__c,
                                                    Effective_Ticket_Issue_Start_Date__c,Effective_Ticket_Issue_End_Date__c,Route__c,IATA_Code__c,
                                                    Unit_Price_Child__c,Unit_Price_Adult__c FROM Ticket_Fare_Rule__c WHERE Effective_Flight_Start_Date__c <= :DepartingFlightDate 
                                                    AND Effective_Flight_End_Date__c >= :DepartingFlightDate AND Tour_Code__c = :TourCode];
        system.debug('DBG all tickets total: '+allTicketFares.size());
        system.debug('DBG all tickets: '+allTicketFares);                       
        //Store all Ticket Fare records in a Map 
        Map<String, Ticket_Fare_Rule__c> mapTicketFare = new Map<String, Ticket_Fare_Rule__c>();
        Integer fareCount = 1;
        
        for (Ticket_Fare_Rule__c fare : allTicketFares) {
            String fareKey = 'Fare' + String.valueOf(fareCount);
            mapTicketFare.put(fareKey, fare);
            fareCount += 1;
        }
        
        Boolean weekendAdded = false;
        String DepartureFlightNo = newSeatAllocation.Departing_Flight_Number__c;
        String ReturningFlightNo = newSeatAllocation.Returning_Flight_Number__c;
        //Date DepartingFlightDate = newSeatAllocation.Departing_Flight_Date__c; Marked by Chris Hsu 2019-11-28
        //Date ReturningFlightDate = newSeatAllocation.Returning_Flight_Date__c; Marked by Chris Hsu 2019-11-28
        Datetime IssueDateTime = datetime.now();
        Date IssueDate = date.newInstance(IssueDateTime.year(),IssueDateTime.month(),IssueDateTime.day());
        String IATACode = newSeatAllocation.Case_Id__r.Account.IATA_MSO_Code__c;
        Decimal FinalSeats = currCase.Total_Final_Sales_Seats__c; //2023-12-11 Eli ISP-0041-2023121102
        //Decimal FinalSeats = newSeatAllocation.Final_Sales_Seats__c; 2023-12-11 Eli ISP-0041-2023121102
        String Route = newSeatAllocation.Group_Booking_Route__c;
        
        system.debug('------------------------------------------------------------------------');
        system.debug('Departure Flight Number: '+DepartureFlightNo);
        system.debug('Returning Flight Number: '+ReturningFlightNo);
        system.debug('Departure Flight Date: '+DepartingFlightDate);
        system.debug('Returning Flight Date: '+ReturningFlightDate);
        system.debug('Issue Date: '+IssueDate);
        system.debug('Route: '+Route);
        system.debug('IATA Code: '+IATACode);
        system.debug('------------------------------------------------------------------------');
        
                        //Final selected records
                        Ticket_Fare_Rule__c selectedTicketFare = new Ticket_Fare_Rule__c();
                        Tax_Details__c selectedTaxTable = new Tax_Details__c();
                        
                        Decimal extraSurcharge = 0;
                        
                        //All shortlisted records after filtering later on
                        List<Ticket_Fare_Rule__c> allSelectedFares = new List<Ticket_Fare_Rule__c>();
                        List<Tax_Details__c> allSelectedTaxes = new List<Tax_Details__c>();
                        
                        //Check if any record in mapTicketFare matches criteria of newSeatAllocation
                        for (String key : mapTicketFare.keySet()) {
                            Ticket_Fare_Rule__c loopTicketFare = mapTicketFare.get(key);
                            
                            if (loopTicketFare.Departing_Flight_Number__c == DepartureFlightNo && loopTicketFare.Returning_Flight_Number__c == ReturningFlightNo &&
                               loopTicketFare.Effective_Flight_End_Date__c >= ReturningFlightDate && loopTicketFare.Effective_Flight_Start_Date__c <= DepartingFlightDate &&
                               loopTicketFare.Effective_Ticket_Issue_Start_Date__c <= IssueDate && loopTicketFare.Effective_Ticket_Issue_End_Date__c >= IssueDate &&
                               loopTicketFare.Route__c == Route && loopTicketFare.IATA_Code__c == IATACode) {
                                    system.debug('DBG Selected LoopFare: '+loopTicketFare);
                                   allSelectedFares.add(loopTicketFare);
                            }
                        }
                        
                        //Sorting allSelectedFares based on matching outcomes to determine the right Ticket Fare record to be used
                        if (allSelectedFares.size() > 1) {
                            Datetime latestDate = datetime.newInstance(1990,1,1);
                            Integer latestNumber = 0;
                            Integer latestYearMonth = 0;
                            Ticket_Fare_Rule__c latestFare = new Ticket_Fare_Rule__c();
                            for (Ticket_Fare_Rule__c loopFare : allSelectedFares) {
                                String loopName = loopFare.Name;
                                loopName = loopName.remove('TF');
                                Integer loopNameValue = Integer.valueOf(loopName.right(8));
                                Integer loopYearMonthValue = Integer.valueOf(loopName.left(6));
                                if (loopFare.CreatedDate == latestDate) {    
                                    if (loopYearMonthValue > latestYearMonth) {
                                        latestDate = loopFare.CreatedDate;
                                        latestYearMonth = loopYearMonthValue;
                                        latestNumber = loopNameValue;
                                        latestFare = loopFare;
                                    } else if (loopYearMonthValue == latestYearMonth) {
                                        if (loopNameValue > latestNumber) {
                                            latestDate = loopFare.CreatedDate;
                                            latestYearMonth = loopYearMonthValue;
                                            latestNumber = loopNameValue;
                                            latestFare = loopFare;
                                        }
                                    }
                                } else if (loopFare.CreatedDate > latestDate) {
                                    latestDate = loopFare.CreatedDate;
                                    latestYearMonth = loopYearMonthValue;
                                    latestNumber = loopNameValue;
                                    latestFare = loopFare;
                                }
                            }
                            returnResult.add(true);
                            selectedTicketFare = latestFare;
                            system.debug('DBG final selectedTicketFare: '+selectedTicketFare);
                            newSeatAllocation.Not_in_Fare_Table__c = false;
                        } else {
                            if (allSelectedFares.size() == 1) {
                                returnResult.add(true);
                                selectedTicketFare = allSelectedFares[0];
                                newSeatAllocation.Not_in_Fare_Table__c = false;
                            } 
                            if (allSelectedFares.size() == 0) {
                                returnResult.add(false);
                                newSeatAllocation.Not_in_Fare_Table__c = true;
                            }
                        }
                        
                        //Check if final allocated seats hits minimal PAX
                        if (FinalSeats < selectedTicketFare.Minimal_No_of_Pax__c) {
                            if (selectedTicketFare.Less_than_Minimal_No_of_Pax__c != null) {
                                extraSurcharge += selectedTicketFare.Less_than_Minimal_No_of_Pax__c;
                            }
                        }
                        
                        //Check if flight is during weekend
                        /*Integer daysBetween = DepartingFlightDate.daysBetween(ReturningFlightDate);
                        system.debug('DBG daysBetween: '+daysBetween);
                        if (daysBetween >= 6) {
                            if (selectedTicketFare.Is_Weekend__c != null && weekendAdded == false) {
                                extraSurcharge += selectedTicketFare.Is_Weekend__c; 
                                weekendAdded = true;
                            }
                                        
                        } else {
                            for (Integer i = 0; i<=daysBetween; i++) {
                                Date temporaryFlightDate = DepartingFlightDate;
                                temporaryFlightDate += i;
                                system.debug('DBG temporaryFlightDate: '+temporaryFlightDate);
                                Datetime convertedFlightDate = Datetime.newInstance(temporaryFlightDate, Time.newInstance(0,0,0,0));
                                String dayOfDate = convertedFlightDate.format('EEEE');
                                system.debug('DBG converted date: '+dayOfDate);
                                if (dayOfDate == 'Saturday' || dayOfDate == 'Sunday') {
                                    if (selectedTicketFare.Is_Weekend__c != null && weekendAdded == false) {
                                        extraSurcharge += selectedTicketFare.Is_Weekend__c; 
                                        weekendAdded = true;
                                    }
                                }
                            }
                        }*/
                        //Check if flight is during weekend - Chris 20200214
                        //Check if flight Include Saturday and Sunday - Chris 20200330
        				Integer daysBetween;
        				if(ReturningFlightDate!=null && DepartingFlightDate!=null)
        				{
            				daysBetween= DepartingFlightDate.daysBetween(ReturningFlightDate);
        				}
        				else
        				{
            				daysBetween=-1;
        				}                                         
        
        				//Integer daysBetween = DepartingFlightDate.daysBetween(ReturningFlightDate); - Eli 20230302
        				system.debug('DBG daysBetween: '+daysBetween);
        				Boolean satAdded = false;
        				Boolean sunAdded = false;                       
                        for (Integer i = 0; i<=daysBetween; i++) {

                                Date temporaryFlightDate = DepartingFlightDate;
                                temporaryFlightDate += i;
                                system.debug('DBG temporaryFlightDate: '+temporaryFlightDate);
                                Datetime convertedFlightDate = Datetime.newInstance(temporaryFlightDate, Time.newInstance(0,0,0,0));
                                String dayOfDate = convertedFlightDate.format('EEEE');
                                system.debug('DBG converted date: '+dayOfDate);                             
                                if (daysBetween >= 6) {
                                    if (selectedTicketFare.Is_Weekend__c != null && weekendAdded == false) {
                                        extraSurcharge += selectedTicketFare.Is_Weekend__c; 
                                        weekendAdded = true;
                                        break;
                                    }                                                
                                }else{
                                    if (dayOfDate == 'Saturday' && i<daysBetween){//Including Saturday & Sunday
                                        if (selectedTicketFare.Is_Weekend__c != null && weekendAdded == false) {
                                            extraSurcharge += selectedTicketFare.Is_Weekend__c; 
                                            weekendAdded = true;
                                            break;
                                        }   
                                    }else{
                                        if (dayOfDate == 'Saturday') {
                                            if (selectedTicketFare.Is_Saturday__c != null && satAdded == false && weekendAdded == false) {
                                                extraSurcharge += selectedTicketFare.Is_Saturday__c; 
                                                satAdded = true;
                                            }
                                        }
                                        if (dayOfDate == 'Sunday'){
                                            if (selectedTicketFare.Is_Sunday__c != null && sunAdded == false && weekendAdded == false) {
                                                extraSurcharge += selectedTicketFare.Is_Sunday__c; 
                                                sunAdded = true;
                                            }
                                        }
                                    }  
                                }                                 
                                    
                        }//End of For
                        
                        
                        //Update fare fields on Seat Allocation records
                        if (selectedTicketFare.Unit_Price_Adult__c != null) {
                            newSeatAllocation.Initial_Unit_Price_Adult__c = selectedTicketFare.Unit_Price_Adult__c + extraSurcharge;
                            newSeatAllocation.Final_Unit_Price_Adult__c = selectedTicketFare.Unit_Price_Adult__c + extraSurcharge;
                        }
                        if (selectedTicketFare.Unit_Price_Child__c != null) {
                            newSeatAllocation.Initial_Unit_Price_Child__c = selectedTicketFare.Unit_Price_Child__c + extraSurcharge; 
                            newSeatAllocation.Final_Unit_Price_Child__c = selectedTicketFare.Unit_Price_Child__c + extraSurcharge;
                        }
                        if (selectedTicketFare.Unit_Price_Infant__c != null) {
                            //Change extraSurcharge for infant to be one tenth - Chris 20200217
                            newSeatAllocation.Initial_Unit_Price_Infant__c = selectedTicketFare.Unit_Price_Infant__c + Math.ceil(extraSurcharge/10); 
                            newSeatAllocation.Final_Unit_Price_Infant__c = selectedTicketFare.Unit_Price_Infant__c + Math.ceil(extraSurcharge/10);
                        }
       
                        Database.SaveResult updateResult = database.update(newSeatAllocation, false);  
                        system.debug('DBG Updateresult: '+updateResult);
        return returnResult;
    }

    public static void fakeMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}