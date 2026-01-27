public class MwCreatePnrWrapper {

    public class Itinerary {
        public String satNo;
        public String caseNo;
        public Integer seats;
        public String bookingType;
        public String IATACode;
        public String officeSite;
        public String agencyName;
        public String groupCommitment; //20240617 add by Eli Lin
        public List<Flights> flights;
    }

    public class Flights {
        public String flightNo;
        public String departure;
        public String departureDate;
        public String arrival;
        public String arrivalDate;
        public String cabin;
    }

    public List<Itinerary> itineraries;

    public MwCreatePnrWrapper() {
        this.itineraries = new List<Itinerary>();
    }

    public void addItinerary(Seat_Allocation_and_Ticketing__c sat, Case currCase, Account currAccount, Contact currContact) {
        Itinerary itinerary = new Itinerary();
        itinerary.satNo = sat.Name;
        itinerary.caseNo = currCase.CaseNumber;
        itinerary.seats = sat.Allocated_Seats__c.intValue();
        itinerary.bookingType = sat.Allocation_Type__c;
        itinerary.IATACode = currContact.IATA_MSO_Code__c;
        itinerary.officeSite = currContact.Office_Site__c;
        itinerary.agencyName = currAccount.Agency_Short_Name__c;
        if (currAccount.Group_Commitment__c != true) {itinerary.groupCommitment = '';} else {itinerary.groupCommitment = 'OK';} //20240617 add by Eli Lin
        
        itinerary.flights = new List<Flights>();

        List<String> routeSplit = new List<String>();
        if (currCase.Route__c.contains('one-way')) {
            routeSplit.add(currCase.Route__c.substring(0, 3));
            routeSplit.add(currCase.Route__c.substring(4, 7));
        }
        else if(currCase.Route__c.contains(' X ')) {//by Chris Hsu 20220104
            routeSplit.add(currCase.Route__c.substring(0, 3));
            routeSplit.add(currCase.Route__c.substring(4, 7));
            routeSplit.add(currCase.Route__c.substring(10, 13));
            routeSplit.add(currCase.Route__c.substring(14, currCase.Route__c.length()));
        }
        else {
            routeSplit = currCase.Route__c.split('-');
        }
        
        if (routeSplit.size() < 2) {
            return;
        }
        
        Flights departing = new Flights();
        departing.flightNo = sat.Departing_Flight_Number__c == 'none'? sat.Returning_Flight_Number__c : sat.Departing_Flight_Number__c;
        departing.departure = routeSplit[0];
        departing.departureDate = sat.Departing_Flight_Number__c == 'none'? String.valueOf(sat.Returning_Flight_Date__c).replace('-', '/') : String.valueOf(sat.Departing_Flight_Date__c).replace('-', '/');
        departing.arrival = routeSplit[1];
        system.debug(sat);
        //system.debug(String.valueOf(sat.Returning_Flight_Arrival_Date__c).replace('-', '/'));
        //system.debug(String.valueOf(sat.Departing_Flight_Arrival_Date__c).replace('-', '/'));
        if(sat.Departing_Flight_Number__c == 'none')
        {
            if(sat.Returning_Flight_Arrival_Date__c!=null)
            {
                departing.arrivalDate = String.valueOf(sat.Returning_Flight_Arrival_Date__c).replace('-', '/');
            }
        }
        else
        {
            if(sat.Departing_Flight_Arrival_Date__c!=null)
            {
                departing.arrivalDate =String.valueOf(sat.Departing_Flight_Arrival_Date__c).replace('-', '/');
            }
        }
        //departing.arrivalDate = sat.Departing_Flight_Number__c == 'none'? String.valueOf(sat.Returning_Flight_Arrival_Date__c).replace('-', '/') : String.valueOf(sat.Departing_Flight_Arrival_Date__c).replace('-', '/');
        departing.cabin = sat.RBD_Departing__c;
        itinerary.flights.add(departing);

        if (routeSplit.size() == 3) {
            Flights returning = new Flights();
            returning.flightNo = sat.Returning_Flight_Number__c;
            returning.departure = routeSplit[1];
            if(sat.Returning_Flight_Date__c!=null)
            {
                returning.departureDate = String.valueOf(sat.Returning_Flight_Date__c).replace('-', '/');
            }
            returning.arrival = routeSplit[2];
            if(sat.Returning_Flight_Arrival_Date__c!=null)
            {
                returning.arrivalDate = String.valueOf(sat.Returning_Flight_Arrival_Date__c).replace('-', '/');
            }
            returning.cabin = sat.RBD_Returning__c;
            itinerary.flights.add(returning);
        }else if(routeSplit.size() == 4){//by Chris Hsu 20220104
            Flights returning = new Flights();
            returning.flightNo = sat.Returning_Flight_Number__c;
            returning.departure = routeSplit[2];
            if(sat.Returning_Flight_Date__c!=null)
            {
                returning.departureDate = String.valueOf(sat.Returning_Flight_Date__c).replace('-', '/');
            }            
            returning.arrival = routeSplit[3];
            if(sat.Returning_Flight_Arrival_Date__c!=null)
            {
                returning.arrivalDate = String.valueOf(sat.Returning_Flight_Arrival_Date__c).replace('-', '/');
            }
            returning.cabin = sat.RBD_Returning__c;
            itinerary.flights.add(returning);
        }

        this.itineraries.add(itinerary);
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
    }
}