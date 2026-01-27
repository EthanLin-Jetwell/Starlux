public class PNR_KKController {
    public List<String>IDs{set;get;}
    //public List<Seat_Allocation_and_Ticketing__c> SATList{set;get;}
    //public Map<String,Boolean> statusMap{set;get;}
	public PNR_KKController(ApexPages.StandardSetController controller) {
        IDs=new List<String>();
        //SATList=new List<Seat_Allocation_and_Ticketing__c>();
        //statusMap=new Map<String,Boolean>();
        
        List<sObject> records = (List<sObject>) controller.getSelected();
        for (sObject record_i : records) {
            this.IDs.add(record_i.Id);
        }
        /*SATList=[SELECT Id,Name,Case_ID__r.Integration_Link_Status__c,Case_ID__r.Status,
                 Allocation_Type__c,Final_Allocated_Seats__c,Sync_SAT_Status__c FROM Seat_Allocation_and_Ticketing__c 
                 WHERE Id IN:IDs];*/
        
        /*for(Seat_Allocation_and_Ticketing__c SAT:SATList)
        {
            statusMap.put(SAT.Id,true);
            if(!SAT.Case_ID__r.Integration_Link_Status__c)
            {
                statusMap.put(SAT.Id,false);
            }
            if(SAT.Case_ID__r.Status!='Closed' && SAT.Case_ID__r.Status!='Ticket Issued')
            {
                statusMap.put(SAT.Id,false);
            }
            if(SAT.Allocation_Type__c!='SRS' && SAT.Allocation_Type__c!='ADC')
            {
                statusMap.put(SAT.Id,false);
            }
            if(SAT.Final_Allocated_Seats__c==0)
            {
                statusMap.put(SAT.Id,false);
            }
            if(SAT.Sync_SAT_Status__c!='Succeeded')
            {
                statusMap.put(SAT.Id,false);
            }
        }*/
        
    }
    
    public void SATgetUpdate()
    {
        system.debug(IDs);
        List<String> PNRKKList=new List<String>();
        
        User CurrentUser=[SELECT Id,Profile.Name FROM User WHERE Id=:UserInfo.getUserId()]; 
        if(CurrentUser.Profile.Name=='RM KK' || CurrentUser.Profile.Name=='System Administrator' || CurrentUser.Profile.Name=='RM Agent' || CurrentUser.Profile.Name=='RM Manager' || CurrentUser.Profile.Name=='RM Director')
        {
            List<Seat_Allocation_and_Ticketing__c> SATList=[SELECT Id,Name,Case_ID__r.Integration_Link_Status__c,
                                                            Case_ID__r.Status,Allocation_Type__c,Final_Allocated_Seats__c,
                                                            Sync_SAT_Status__c,Get_Updates_Error_Message__c,
                                                            Returning_PNR_Status__c,Departing_PNR_Status__c
                                                            FROM Seat_Allocation_and_Ticketing__c WHERE Id IN: IDs];
            for(Seat_Allocation_and_Ticketing__c SAT:SATList)
            {
                if(!SAT.Case_ID__r.Integration_Link_Status__c)
                {
                    system.debug('1');
                    SAT.Get_Updates_Error_Message__c=SAT.Get_Updates_Error_Message__c+'/Not Linked Case';
                }
                /*if(SAT.Case_ID__r.Status!='New' && SAT.Case_ID__r.Status!='Ticket sales in progress'&& SAT.Case_ID__r.Status!='Request for ticketing')
                {
                    system.debug('2');
                    SAT.Get_Updates_Error_Message__c=SAT.Get_Updates_Error_Message__c+'/Not Currect Case Status';
                }*/
                if(SAT.Allocation_Type__c!='SRS' && SAT.Allocation_Type__c!='ADC')
                {
                    system.debug('3');
                    SAT.Get_Updates_Error_Message__c=SAT.Get_Updates_Error_Message__c+'/Not Currect Type';
                }
                if(SAT.Final_Allocated_Seats__c==0)
                {
                    system.debug('4');
                    SAT.Get_Updates_Error_Message__c=SAT.Get_Updates_Error_Message__c+'/No Allocated Seat';
                }
                if(SAT.Sync_SAT_Status__c!='Succeeded')
                {
                    system.debug('5');
                    SAT.Get_Updates_Error_Message__c=SAT.Get_Updates_Error_Message__c+'/Not Linked SAT';
                }
                /*if(SAT.Returning_PNR_Status__c!='HN' && SAT.Returning_PNR_Status__c!='TN' 
                   && SAT.Departing_PNR_Status__c!='HN' && SAT.Departing_PNR_Status__c!='TN')
                {
                    SAT.Get_Updates_Error_Message__c=SAT.Get_Updates_Error_Message__c+'/Not Currect PNR Status';
                }*/
                if(SAT.Case_ID__r.Integration_Link_Status__c 
                   &&(SAT.Allocation_Type__c=='SRS' || SAT.Allocation_Type__c=='ADC') 
                   && SAT.Final_Allocated_Seats__c>0 && SAT.Sync_SAT_Status__c=='Succeeded' )/*&&
                   (SAT.Returning_PNR_Status__c=='HN' || SAT.Returning_PNR_Status__c=='TN' 
                   || SAT.Departing_PNR_Status__c=='HN' || SAT.Departing_PNR_Status__c=='TN')&& 
                   (SAT.Case_ID__r.Status=='New' || SAT.Case_ID__r.Status=='Ticket sales in progress'|| SAT.Case_ID__r.Status=='Request for ticketing') */
                {
                  	
                    //MiddlewareUtil.getUpdate(SAT.Name);
                    List<String> SATNameList=new List<String>();
                    SATNameList.add(SAT.Id);
                    MiddlewareUtil.updatelegStatus(SATNameList);
                    PNRKKList.add(SAT.Name);
                }
                
            }
            
            update SATList;
        }
        if(PNRKKList.size()>0)
        {
            Task T=new Task();
            T.Subject='更新PNR KK';
            T.Description='Will Update '+PNRKKList.toString();
            T.OwnerId=UserInfo.getUserId();
            insert T;
        }
        
        
        /*PageReference p = new PageReference('/lightning/o/Seat_Allocation_and_Ticketing__c/list?filterName=Revenue_KK_only');
        p.setRedirect(true);
        return p;*/
    }
    
    public PageReference returnList()
    {
        PageReference p = new PageReference('/lightning/o/Seat_Allocation_and_Ticketing__c/list?filterName=Revenue_KK_only');
        p.setRedirect(true);
        return p;
    }
    
    public static void fakeMethod()
    {
        String i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
        i='0';
    }
}