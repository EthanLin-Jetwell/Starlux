public class ApexAccount {
    public String Message_ID {get; set;}
    public String Created_At {get; set;}
    public String Recieve {get; set;}
    public String Send {get; set;}
    public String Message_Type {get; set;}
    public String Device_ID {get; set;}
    public String D_Member_ID {get; set;}
    public String Sender_ID {get; set;}
    
    public ApexAccount() {
        Message_ID = ''; 
        Created_At = ''; 
        Recieve = ''; 
        Send = ''; 
        Message_Type = ''; 
        Device_ID = ''; 
        D_Member_ID = ''; 
        Sender_ID = ''; 
    }

}