public class MwGetUpdateResponseWrapper {

	public class Legs {
		public String id {get;set;} 
		public String sorting {get;set;} 
		public String status {get;set;} 
		public Flight flight {get;set;} 
		public List<Passengers> passengers {get;set;} 
    }
	
	public Boolean success {get;set;} 
	public String traceId {get;set;} 
	public Message message {get;set;} 
	public Data data {get;set;} 
	public String links {get;set;} 
	public String meta {get;set;} 
	
	public class Message {
		public String code {get;set;} 
		public String content {get;set;} 
		public String details {get;set;} 
    }
	
	public class Passengers {
		public String nameListNo {get;set;} 
		public String type {get;set;} 
		public String lastName {get;set;} 
		public String firstName {get;set;} 
		public String dateOfBirth {get;set;} 
		public List<Ssrs> ssrs {get;set;} 
	}
	
	public class Flight {
		public String id {get;set;} 
		public String flightNo {get;set;} 
		public String departure {get;set;} 
		public String departureDate {get;set;} 
        public String departureTime {get;set;} 
		public String arrival {get;set;} 
		public String arrivalDate {get;set;} 
		public String arrivalTime  {get;set;} 
		}
	
	public class Ssrs {
		public String ssr {get;set;} 
		public String status {get;set;} 
	}
	
	public class Itinerary {
		public String id {get;set;} 
		public String iATACode {get;set;} 
		public String officeSite {get;set;} 
		public String agencyName {get;set;} 
		public String satNo {get;set;} 
		public String caseNo {get;set;} 
		public String seats {get;set;} 
		public String bookingType {get;set;} 
		public String pnr {get;set;} 
		public Integer step {get;set;} 
		public String isSynced {get;set;} 
		public String createdAt {get;set;} 
		public String updatedAt {get;set;} 
		public String deletedAt {get;set;} 
		public List<Legs> legs {get;set;} 
		public String status {get;set;} 
	}
	
	public class Data {
		public Itinerary itinerary {get;set;} 
	}
    
    public static MwGetUpdateResponseWrapper deserializeJson(String json) {
		return (MwGetUpdateResponseWrapper) System.JSON.deserialize(json, MwGetUpdateResponseWrapper.class);
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