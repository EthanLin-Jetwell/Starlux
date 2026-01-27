public class LuckyDrawController {
    private ApexPages.StandardController standardController;
    public Id recordId {get; set;} //Lucky_Draw_Setting__c Id
    public String recordName {get; set;}
    public final Integer TICKET_WINNERS_COUNT {get; set;}
    public final Integer FLIGHT_WINNERS_COUNT {get; set;}
    public final Integer ALL_WINNERS_COUNT {get; set;}
    public final Integer TICKET_PARTICIPANTS_COUNT {get; set;}
    public final Integer FLIGHT_PARTICIPANTS_COUNT {get; set;}
    public final Integer ALL_PARTICIPANTS_COUNT {get; set;}
    public Lucky_Draw_Setting__c luckyDrawSetting {get; set;}
    public List<Customer_Satisfaction_Surveys__c > participants {get; set;}
    //lists to show
    public List<Winner__c > winners {get; set;} //Winners after drawing
    public List<Prize__c> prizes {get; set;} //all the prizes for this event
    
    public List<Prize__c> prizes_TICKET {get; set;}
    public List<Prize__c> prizes_FLIGHT {get; set;}
    public List<Prize__c> prizes_ALL {get; set;}
    public Pagereference returnPage {get; set;}
    private Id jobId;
    public Boolean drawing { get; set; }
    public Boolean show { get; set; }
    
    public String errtxt { get; set; }
    
    public Integer page { get; set; }
    
    public LuckyDrawController(ApexPages.StandardController stdController) {
        this.standardController = stdController;
        
        this.recordId = standardController.getId();
        
        //recording pages
        Cookie pager = ApexPages.currentPage().getCookies().get('pager');
        if (pager == null) {
            page = 1;
            pager = new Cookie('pager', '1', null, -1, true);
            ApexPages.currentPage().setCookies(new Cookie[]{pager});
        } else {
            page = Integer.valueOf(pager.getValue());
        }
        
        
        if(recordId != NULL) {
            luckyDrawSetting = [SELECT Id, Number_of_Winner_Ticket__c, Number_of_Winner_Flight__c, Number_of_Winner__c, Drawing_Name__c, Draw__c, Draw_Date__c, (SELECT Id, Name, Email_Address_For_Lucky_Draw__c, Survey_Type__c, Survey_Completed__c FROM Customer_Satisfaction_Surveys__r WHERE Survey_Completed__c = true LIMIT 1000) 
                                FROM Lucky_Draw_Setting__c 
                                WHERE Id =: recordId LIMIT 1];
            recordName = luckyDrawSetting.Drawing_Name__c;
            participants = luckyDrawSetting.Customer_Satisfaction_Surveys__r; 
            TICKET_WINNERS_COUNT = (Integer)luckyDrawSetting.Number_of_Winner_Ticket__c;
            FLIGHT_WINNERS_COUNT = (Integer)luckyDrawSetting.Number_of_Winner_Flight__c;
            ALL_WINNERS_COUNT = (Integer)luckyDrawSetting.Number_of_Winner__c;
            
            winners = [SELECT Id, Name, Email_Address__c, Prize_Name__c, Prize_Amount__c, Unit__c, NO__c FROM Winner__c WHERE LuckyDrawSettingID__c = : recordId ORDER BY No__c ASC];
            System.debug(winners);
            
            TICKET_PARTICIPANTS_COUNT = [SELECT COUNT() FROM Customer_Satisfaction_Surveys__c WHERE Drawing_No__c =: recordId AND Survey_Type__c = 'Ticket buying experience' AND Survey_Completed__c = true];
            FLIGHT_PARTICIPANTS_COUNT = [SELECT COUNT() FROM Customer_Satisfaction_Surveys__c WHERE Drawing_No__c =: recordId AND Survey_Type__c = 'Flight experience' AND Survey_Completed__c = true];
            ALL_PARTICIPANTS_COUNT = [SELECT COUNT() FROM Customer_Satisfaction_Surveys__c WHERE Drawing_No__c =: recordId AND Survey_Completed__c = true];
            
            System.debug(ALL_PARTICIPANTS_COUNT);
            
            prizes = [SELECT Id, (SELECT Id, Type__c, Prize_Amount__c, Name, Prize_Name__c, Unit__c FROM Prize__r ORDER BY F_No__c ASC) 
                      FROM Lucky_Draw_Setting__c 
                      WHERE Id =: recordId LIMIT 1].Prize__r; 
            
            prizes_TICKET = new List<Prize__c>();
            prizes_FLIGHT = new List<Prize__c>();
            prizes_ALL = new List<Prize__c>();
            for(Prize__c prize : prizes) {
                if(prize.Type__c == 'Ticket buying experience') {
                    prizes_TICKET.add(prize);
                } else if(prize.Type__c == 'Flight experience') {
                    prizes_FLIGHT.add(prize);
                } else {
                    prizes_ALL.add(prize);
                }
            }
        }
        System.debug(recordId);
        System.debug(TICKET_WINNERS_COUNT);
        System.debug(FLIGHT_WINNERS_COUNT);
        System.debug(ALL_WINNERS_COUNT);

        this.drawing = false;
        this.show = false;
    }
    
    //Call the Batch_LuckyDraw class to draw out the winners
    //While drawing the page will show a loading icon, 
    //the loading icon will go on untile the batch job is completed
    public void draw() {
        drawing = true;
            
        if(luckyDrawSetting.Draw__c == true) {
            errtxt = '活動已開獎';
            System.debug(errtxt);
        } else if(luckyDrawSetting.Draw__c == false && luckyDrawSetting.Draw_Date__c != date.today()) {
            errtxt = '抽獎尚未開始';
            System.debug(errtxt);
        } else{
            this.winners = new List<Winner__c>();
            drawingHelper();
            System.debug('hello');
        }
        
        drawing = false;
        show = true;
    }
    
    public void drawingHelper() {
        Integer no = 0;
        List<Integer> luckyNumbers = new List<Integer>();
        List<Customer_Satisfaction_Surveys__c> temp;
        While(luckyNumbers.size() < TICKET_WINNERS_COUNT) {
            Integer i = Integer.valueof((Math.random() * TICKET_PARTICIPANTS_COUNT));
            if(!luckyNumbers.contains(i)) {
                luckyNumbers.add(i);
            }
        }
        integer x = 0;
        temp = [SELECT Id, Name, Lucky_No_Ticket__c, Email_Address_For_Lucky_Draw__c  FROM Customer_Satisfaction_Surveys__c WHERE Lucky_No_Ticket__c IN : luckyNumbers AND Drawing_No__c = : recordId];
        for(Prize__c p : prizes_TICKET) {
            for(Integer i = 0; i < p.Prize_Amount__c; i++) {
                no++;
                if(x < temp.size()) {
                    Customer_Satisfaction_Surveys__c record;
                    for(Integer con = 0; con < temp.size(); con++) {
                        record = temp[con];
                        if(temp[con].Lucky_No_Ticket__c == luckyNumbers[x]) {
                            winners.add(new Winner__c(Name = record.Name, Email_Address__c = record.Email_Address_For_Lucky_Draw__c, PrizeID__c = p.Id, Prize_Amount__c = 1, LuckyDrawSettingID__c = recordId, No__c = no));
                            x++;
                            break;
                        }
                    }
                }        
            }
        }
        
        luckyNumbers = new List<Integer>();
        While(luckyNumbers.size() < FLIGHT_WINNERS_COUNT) {
            Integer i = Integer.valueof((Math.random() * FLIGHT_PARTICIPANTS_COUNT));
            if(!luckyNumbers.contains(i)) {
                luckyNumbers.add(i);
            }
        }
        integer y = 0;
        temp = [SELECT Id, Name, Lucky_No_Flight__c, Email_Address_For_Lucky_Draw__c  FROM Customer_Satisfaction_Surveys__c WHERE Lucky_No_Flight__c IN : luckyNumbers AND Drawing_No__c = : recordId];
        for(Prize__c p : prizes_FLIGHT) {
            for(Integer i = 0; i < p.Prize_Amount__c; i++) {
                no++;
                if(y < temp.size()) {
                    Customer_Satisfaction_Surveys__c record;
                    for(Integer con = 0; con < temp.size(); con++) {
                        record = temp[con];
                        if(temp[con].Lucky_No_Flight__c == luckyNumbers[y]) {
                            winners.add(new Winner__c(Name = record.Name, Email_Address__c = record.Email_Address_For_Lucky_Draw__c, PrizeID__c = p.Id, Prize_Amount__c = 1, LuckyDrawSettingID__c = recordId, No__c = no));
                            y++;
                            break;
                        }
                    }
                }       
            }
        }
        
        luckyNumbers = new List<Integer>();
        While(luckyNumbers.size() < ALL_WINNERS_COUNT) {
            Integer i = Integer.valueof((Math.random() * ALL_PARTICIPANTS_COUNT));
            if(!luckyNumbers.contains(i)) {
                luckyNumbers.add(i);
            }
        }

        integer z = 0;
        temp = [SELECT Id, Name, Lucky_No__c, Email_Address_For_Lucky_Draw__c  FROM Customer_Satisfaction_Surveys__c WHERE Lucky_No__c IN : luckyNumbers AND Drawing_No__c = : recordId];
        for(Prize__c p : prizes_ALL) {
            for(Integer i = 0; i < p.Prize_Amount__c; i++) {
                no++;
                if(z < temp.size()) {
                    Customer_Satisfaction_Surveys__c record;
                    for(Integer con = 0; con < temp.size(); con++) {
                        record = temp[con];
                        if(temp[con].Lucky_No__c == luckyNumbers[z]) {
                            winners.add(new Winner__c(Name = record.Name, Email_Address__c = record.Email_Address_For_Lucky_Draw__c, PrizeID__c = p.Id, Prize_Amount__c = 1, LuckyDrawSettingID__c = recordId, No__c = no));
                            z++;
                            break;
                        }
                    }
                }
            }
        }
        
        DELETE [SELECT Id FROM Winner__c WHERE LuckyDrawSettingID__c = : recordId];
        UPSERT winners;
        System.debug(winners);
        System.debug(z);
        winners = [SELECT Id, Name, Email_Address__c, Prize_Name__c, Prize_Amount__c, Unit__c, NO__c FROM Winner__c WHERE LuckyDrawSettingID__c = : recordId ORDER BY No__c ASC];
    }
    
    //Save the drawn winners to records
    public Pagereference save() {
        try{    
            luckyDrawSetting.Draw__c = true;
            UPDATE luckyDrawSetting;
        } 
        catch(exception e) {
            System.debug('error: ' + e);
        }
        //Database.executeBatch(new Batch_LuckyDraw(recordId, 'save'), 500);
        return this.standardController.cancel();
    }
    
    public Pagereference cancel() {
        try{    
            if(luckyDrawSetting.Draw__c == false) {
                DELETE [SELECT Id FROM Winner__c WHERE LuckyDrawSettingID__c = : recordId];
            }
        } 
        catch(exception e) {
            System.debug('error: ' + e);
        }
        return this.standardController.cancel();
    }
    
    public Pagereference nextPage() {
        Cookie pager = ApexPages.currentPage().getCookies().get('pager');
        pager = new Cookie('pager', String.valueOf(page + 1), null, -1, true);
        ApexPages.currentPage().setCookies(new Cookie[]{pager});
        return NULL;
    }
}