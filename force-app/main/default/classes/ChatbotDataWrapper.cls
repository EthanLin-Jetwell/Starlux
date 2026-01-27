//Data schema for chatbot data
public class ChatbotDataWrapper {
    public String Chatbot_ID;
    public String Chatbot_Name;
    public String Chatbot_Mail;
    public String Chatbot_UID;
    public String Chatbot_BookingRef;
    public String Chatbot_Language;
    public String Chatbot_CustomerType;
    public String Chatbot_CallSupportTime;
    public String Ticket_EMD_Number;
    public String Booking_Reference_PNR;
    public String Passenger_Name;
    public String Chatbot_OnlineSupport;

    public static List<ChatbotDataWrapper> deserializeJson(String json) {
        return (List<ChatbotDataWrapper>) System.JSON.deserialize(json, List<ChatbotDataWrapper>.class);
    }

    public Boolean isMissingRequiredFields() {
        if (this.Chatbot_ID == '' || this.Chatbot_Name == '' || this.Chatbot_UID == '') {
            return true;
        }
        return false;
    }
}