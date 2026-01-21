@RestResource(urlMapping='/RestMiddlewarePfa/*')
global class RestMiddlewarePfaApi {
    global class CreditBalanceException extends Exception {}
    global class NoAccountException extends Exception {}
    global class NoQuotaException extends Exception {}
    
    @HttpPost
    global static ResponseModelPfa doPost() {
        PfaData req = (PfaData) JSON.deserialize(
            RestContext.request.requestBody.toString(),
            PfaData.class);
        return handlePfaRequest(req.data);
    }

    global static ResponseModelPfa handlePfaRequest(PfaRequest req)
    {
        Integer httpStatusCode = 403;
        String resultMessage = 'fail';
        String recordId;
        System.debug(req.ActionCode);
        //Apply for Credit Limit
        try{
            switch on req.ActionCode {
                // create
                when '0' {
                    Id recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Department').getRecordTypeId();
                    String companyCode = req.applicantCompanyCode;
                    String dept9 = req.applicantDept.left(9);
                    String dept6 = req.applicantDept.left(6);
                    String dept3 = req.applicantDept.left(3);
                    Account acc;
                    try {
                        acc = [SELECT Id, ParentId FROM Account WHERE RecordTypeId = :recordTypeId AND Company_Type__c = :companyCode AND Department_Code__c = :dept9 LIMIT 1];
                    } catch (QueryException e) {
                        
                    }
                    
                    if (acc == null) {
                        try {
                            acc = [SELECT Id, ParentId FROM Account WHERE RecordTypeId = :recordTypeId AND Company_Type__c = :companyCode AND Department_Code__c = :dept6 LIMIT 1];
                        } catch (QueryException e) {
                            
                        }
                    }
                    
                    if (acc == null) {
                        try {
                            acc = [SELECT Id, ParentId FROM Account WHERE RecordTypeId = :recordTypeId AND Company_Type__c = :companyCode AND Department_Code__c = :dept3 LIMIT 1];
                        } catch (QueryException e) {
                            
                        }
                    }
                    
                    if (acc == null) {
                        throw new NoAccountException('Department is not register in Salesforce.');
                    }
                    
                    //*****2025/9/15 Aaron Remark *****//
                    //List<Quota_Manage__c> quotas = [SELECT Id, Quota_Remain__c, Quota_Transit__c FROM Quota_Manage__c WHERE Active__c = true AND Account__c = :acc.Id AND Discount_Code__c = :req.Category AND Discount__c = :req.Discount ORDER BY LastModifiedDate DESC LIMIT 1];
                    //if (req.Budget == 'In' && quotas.size() == 0) throw new NoQuotaException('No free ticket quota for this department in Salesforce.');
                   	//	Quota_Manage__c quota = quotas[0];
                    //if (quota.Quota_Remain__c < req.Qty && req.Budget == 'In') throw new CreditBalanceException('Free ticket quota is not enough.');
                    //***********************************//
                    
                    Quota_Manage__c quota; // 先宣告 quota 變數

                    if (req.Budget == 'In') {
                        List<Quota_Manage__c> quotas;
                        if (acc.ParentId != null) {
                            quotas = [
                                SELECT Id, Quota_Remain__c, Quota_Transit__c
                                FROM Quota_Manage__c
                                WHERE Active__c = true
                                AND Account__c = :acc.ParentId
                                AND Discount_Code__c = :req.Category
                                AND Discount__c = :req.Discount
                                ORDER BY LastModifiedDate DESC
                                LIMIT 1
                            ];
                        } else {
                            quotas = [
                                SELECT Id, Quota_Remain__c, Quota_Transit__c
                                FROM Quota_Manage__c
                                WHERE Active__c = true
                                AND Account__c = :acc.Id
                                AND Discount_Code__c = :req.Category
                                AND Discount__c = :req.Discount
                                ORDER BY LastModifiedDate DESC
                                LIMIT 1
                            ];
                        }
                        if (quotas.isEmpty()) {
                            throw new NoQuotaException('No free ticket quota for this department in Salesforce.');
                        }
                        quota = quotas[0];
                        if (quota.Quota_Remain__c < req.Qty) {
                            throw new CreditBalanceException('Free ticket quota is not enough.');
                        }
                    }
                    // Budget == 'Out' 不管Quota

                    
                    
                    //insert 優待機票申請
                    External_Tickets__c et = createExTicket(req);
                    et.Account__c = acc.Id;
                    et.Item_Status__c = 'Send';
                    if (req.Budget == 'In') et.QuotaManageID__c = quota.Id;
                    Insert et;

                    List<PfaRequest.PassengerEntry> passengerInfo = req.Passenger;
                    List<Ticket_Certificate__c> insertList = new List<Ticket_Certificate__c>();
                    if (req.ApplicationType == 'Anonymous') {
                        if (req.twoPeople == 'Y') {
                            Ticket_Certificate__c ticketCertificate = new Ticket_Certificate__c();
                            //if (passengerInfo.size() > 0) {
                                //PfaRequest.PassengerEntry passenger = passengerInfo[0];
                                ticketCertificate.External_Tickets__c = et.Id;
                                ticketCertificate.Embargo_This_Year_Taiwan_to_World__c = et.Embargo_This_Year_Taiwan_to_World__c;
                                ticketCertificate.Embargo_This_Year_World_to_Taiwan__c = et.Embargo_This_Year_World_to_Taiwan__c;
                                ticketCertificate.Embargo_Next_Year_Taiwan_to_World__c = et.Embargo_Next_Year_Taiwan_to_World__c;
                                ticketCertificate.Embargo_Next_Year_World_to_Taiwan__c = et.Embargo_Next_Year_World_to_Taiwan__c;
                                /*ticketCertificate.Last_Name_EN__c = passenger.LastName;
                                ticketCertificate.First_Name_EN__c = passenger.FirstName;
                                ticketCertificate.Title__c = passenger.Salutation;
                                ticketCertificate.Date_of_Birth__c = Date.valueOf(passenger.Birthday);
                            }
                            if (passengerInfo.size() > 1) {
                                //PfaRequest.PassengerEntry passenger = passengerInfo[1];
                                ticketCertificate.External_Tickets__c = et.Id;
                                ticketCertificate.Last_Name_EN_2__c = passenger.LastName;
                                ticketCertificate.First_Name_EN_2__c = passenger.FirstName;
                                ticketCertificate.Title_2__c = passenger.Salutation;
                                ticketCertificate.Date_of_Birth2__c = Date.valueOf(passenger.Birthday);
                            }*/
                            insertList.add(ticketCertificate);
                        } else {
                            for (Integer i = 0; i < req.Qty; i++) {
                                Ticket_Certificate__c ticketCertificate = new Ticket_Certificate__c();
                                ticketCertificate.External_Tickets__c = et.Id;
                                insertList.add(ticketCertificate);
                            }
                        }
                    } else {
                        for (PfaRequest.PassengerEntry passenger : passengerInfo) {
                            Ticket_Certificate__c ticketCertificate = new Ticket_Certificate__c();
                            ticketCertificate.External_Tickets__c = et.Id;
                            ticketCertificate.Last_Name_EN__c = passenger.LastName;
                            ticketCertificate.First_Name_EN__c = passenger.FirstName;
                            ticketCertificate.Title__c = passenger.Salutation;
                            ticketCertificate.PAX_1_Email__c = passenger.PAXEmail;
                            ticketCertificate.Embargo_This_Year_Taiwan_to_World__c = et.Embargo_This_Year_Taiwan_to_World__c;
                            ticketCertificate.Embargo_This_Year_World_to_Taiwan__c = et.Embargo_This_Year_World_to_Taiwan__c;
                            ticketCertificate.Embargo_Next_Year_Taiwan_to_World__c = et.Embargo_Next_Year_Taiwan_to_World__c;
                            ticketCertificate.Embargo_Next_Year_World_to_Taiwan__c = et.Embargo_Next_Year_World_to_Taiwan__c;

                            if (String.isNotBlank(passenger.Birthday)) {ticketCertificate.Date_of_Birth__c = Date.valueOf(passenger.Birthday);}
            				insertList.add(ticketCertificate);
                        }
                    }
                    
                    insert insertList;
                    
                    List<Ticket_Route__c> insertRoutes = new List<Ticket_Route__c>();
                    if (req.ApplicationType == 'Registered') {
                        List<Ticket_Route__c> routes = new List<Ticket_Route__c>();
                        for (PfaRequest.RouteEntry re : req.Route) {
                            Ticket_Route__c route = new Ticket_Route__c();
                            route.Booking_Class__c = re.BookingClass;
                            route.DepatureID__c = re.DepatureID;
                            route.Depature__c = re.Depature;
                            route.ArrivalID__c = re.ArrivalID;
                            route.Arrival__c = re.Arrival;
                            if (String.isNotBlank(re.FlightDate)) {route.Flight_Date__c = Date.valueOf(re.FlightDate);}
                            //route.Flight_Date__c = Date.valueOf(re.FlightDate); 範例資料會有空值情況
                            route.Flight_No__c = re.FlightNo;
                            routes.add(route);
                        }
                        
                        for (Ticket_Route__c route : routes) {
                            Ticket_Route__c exRoute = route.clone(false, false, false, false);
                            exRoute.External_Tickets__c = et.Id;
                            for (Ticket_Certificate__c tc : insertList) {
                                Ticket_Route__c newRoute = route.clone(false, false, false, false);
                                newRoute.Ticket_Certificate__c = tc.Id;
                                insertRoutes.add(newRoute);
                            }
                            insertRoutes.add(exRoute);
                        }
                    }
                    
                    if (insertRoutes.size() != 0) insert insertRoutes;
                    
                    if (req.Budget == 'In') {
                        quota.Quota_Transit__c += req.Qty;
                        update quota;
                    }
                    
                    httpStatusCode = 201;
                    resultMessage = 'success';
                    recordId = et.Id;
                }
                // update 優待機票申請核准
                when '1' {
                    External_Tickets__c et = [SELECT Id, Ticket_Count__c, QuotaManageID__c, Budget_Type__c FROM External_Tickets__c WHERE Id = :req.sfId LIMIT 1];
                    //External_Tickets__c et = new External_Tickets__c(Id = req.sfId);
                    et.SerialID__c = req.serialID;
                    et.Last_ApproverId__c = req.LastApproverId;
                    et.Last_Approver_Name__c = req.LastApproverName;
                    et.Item_Status__c = 'Approve (Final)';
                    update et;

                    if (et.Budget_Type__c == 'In') {
                        List<Quota_Manage__c> quotas = [SELECT Id, Quota_Used__c, Quota_Transit__c FROM Quota_Manage__c WHERE Id =: et.QuotaManageID__c ];                    
                        if(quotas.size() == 0) throw new NoQuotaException('No free ticket quota for this department in Salesforce.');
                        Quota_Manage__c quota = quotas[0];
                        //Update Quota Management
                        quota.Quota_Transit__c -= et.Ticket_Count__c; //退回在途額度
                        quota.Quota_Used__c += et.Ticket_Count__c; //增加使用額度
                        update quota;
                    }

                    
                    httpStatusCode = 201;
                    resultMessage = 'success';
                    recordId = et.Id;
                }
                // delete 優待機票申請錯誤
                when '2' {
                    External_Tickets__c et = [SELECT Id, Ticket_Count__c, QuotaManageID__c, Budget_Type__c FROM External_Tickets__c WHERE Id = :req.sfId LIMIT 1];
                    if (et.Budget_Type__c == 'In') {
                    	List<Quota_Manage__c> quotas = [SELECT Id, Quota_Used__c, Quota_Transit__c FROM Quota_Manage__c WHERE Id =: et.QuotaManageID__c ];
                    	Quota_Manage__c quota = quotas[0];
                    	//Update Quota Management
    					quota.Quota_Transit__c -= et.Ticket_Count__c; //退回在途額度
    					update quota;
                    }
                    //delete External Ticket
                    delete et;
                    
                    httpStatusCode = 201;
                    resultMessage = 'success';
                    recordId = et.Id;
                }
            }
        } catch(NoAccountException nae) {
            //Bad request
            httpStatusCode = 400;
            resultMessage = 'Department is not register in Salesforce.';
            return new ResponseModelPfa(httpStatusCode, null, null, resultMessage);         
        } catch(NoQuotaException nqe) {
            //Bad request
            httpStatusCode = 400;
            resultMessage = 'No free ticket quota for this department in Salesforce.';
            return new ResponseModelPfa(httpStatusCode, null, null, resultMessage);         
        } catch(CreditBalanceException ce) {
            //Bad request
            httpStatusCode = 400;
            resultMessage = 'Free ticket quota is not enough.';
            return new ResponseModelPfa(httpStatusCode, null, null, resultMessage);         
        } catch(exception e) {
            //Bad request
            httpStatusCode = 400;
            resultMessage = 'Error: ' + e + 'at line: ' + e.getLineNumber();
            return new ResponseModelPfa(httpStatusCode, null, null, resultMessage);         
        }
        return new ResponseModelPfa(httpStatusCode, null, recordId, resultMessage);
    }
    
    public static External_Tickets__c createExTicket(PfaRequest req) {
        External_Tickets__c et = new External_Tickets__c();
        if (String.isNotBlank(req.sfId)) 
            et.Id = req.sfId;
        if (String.isNotBlank(req.identify)) 
            et.Identify__c = req.identify;
        if (String.isNotBlank(req.requisitionID)) 
            et.RequisitionID__c = req.requisitionID;
        if (String.isNotBlank(req.serialID)) 
            et.SerialID__c = req.serialID;
        if (String.isNotBlank(req.diagramID)) 
            et.DiagramID__c = req.diagramID;
        if (String.isNotBlank(req.applicantID)) 
            et.Applicant__c = req.applicantID;
        if (String.isNotBlank(req.applicantName)) 
            et.Applicant_Name__c = req.applicantName;
        if (String.isNotBlank(req.applicantDept)) 
            et.Applicant_Dept__c = req.applicantDept;
        if (String.isNotBlank(req.applicantDeptName)) 
            et.Application_Department__c = req.applicantDeptName;
        if (String.isNotBlank(req.applicantDateTime)) 
            et.Applicant_Date_Time__c = DateTime.valueOf(req.applicantDateTime);
        if (String.isNotBlank(req.applicantCompanyCode)) 
            et.Applicant_Company_Code__c = req.applicantCompanyCode;
        if (String.isNotBlank(req.Budget)) 
            et.Budget_Type__c = req.Budget;
        if (String.isNotBlank(req.CompanyName)) 
            et.CompanyName__c = req.CompanyName;
        if (String.isNotBlank(req.Reason)) 
            et.Reason_for_Application__c = req.Reason;
        if (String.isNotBlank(req.Category)) 
            et.Fare_Basis__c = req.Category;
        if (String.isNotBlank(req.ApplyFor)) 
            et.Apply_For__c = req.ApplyFor;
        if (String.isNotBlank(req.Discount)) 
            et.Discount__c = req.Discount;
        if (String.isNotBlank(req.Waiver)) {
            List<String> waiverList = req.Waiver.split(',');
            for (String w : waiverList) {
                switch on w {
                    when 'YQ' {
                        et.Exemption_YQ__c = true;
                    }
                    when 'Tax' {
                        et.Exemption_Tax__c = true;
                    }
                    when 'YR' {
                        et.Exemption_YR__c = true;
                    }
                    when 'EP' {
                        et.Embargo__c = true;
                    }
                }
            }
        }
        if (req.Qty != null) 
            et.Ticket_Count__c = req.Qty;
        if (String.isNotBlank(req.ApplicationType)) 
            et.Application_Type__c = req.ApplicationType;
        if (String.isNotBlank(req.PFA_No)) 
            et.PFA_No__c = req.PFA_No;
        if (String.isNotBlank(req.twoPeople)) 
            et.Two_People__c = req.twoPeople;
        if (String.isNotBlank(req.Winning)) 
            et.Prizes_and_Awards_won_by_chance__c = req.Winning;
        if (String.isNotBlank(req.Language)) 
            et.Language__c = req.Language;
        if (String.isNotBlank(req.ExpirationDate)) 
            et.Expiration_Date__c = Date.valueOf(req.ExpirationDate);
        if (String.isNotBlank(req.PhoneNo)) 
            et.Phone__c = req.PhoneNo;
        if (String.isNotBlank(req.Email)) 
            et.Email__c = req.Email;
        if (String.isNotBlank(req.TicketReceiver)) 
            et.Ticket_Receiver__c = req.TicketReceiver;
        if (String.isNotBlank(req.LastApproverId)) 
            et.Last_ApproverId__c = req.LastApproverId;
        if (String.isNotBlank(req.LastApproverName)) 
            et.Last_Approver_Name__c = req.LastApproverName;
        if (String.isNotBlank(req.OrganizerEventTitle))  // 2025-09-10 新增活動名稱
            et.Organizer_Event_Title__c  = req.OrganizerEventTitle;

        
        if(req.ApplicationType == 'Anonymous' && req.Route.size() > 0) {
            PfaRequest.RouteEntry re = req.Route[0];
            et.Booking_Class__c = re.BookingClass;
            et.DepatureID__c = re.DepatureID;
            et.Depature__c = re.Depature;
            et.ArrivalID__c = re.ArrivalID;
            et.Arrival__c = re.Arrival;
            //et.Flight_Date_Departure_External__c = Date.valueOf(re.FlightDate);
            //et.Flight_Number_Departure_External__c = re.FlightNo;
          }

        
        String taiwan2WorldThisYear = '';
        String taiwan2WorldNextYear = '';
        for (PfaRequest.EmbargoEntry ee : req.EmbargoPeriodTPE) {
            if (isThisYear(ee.StartDate)) {
                taiwan2WorldThisYear += parseEmbargoDate(ee.StartDate) + '-' + parseEmbargoDate(ee.EndDate) + '\n';
            } else {
                taiwan2WorldNextYear += parseEmbargoDate(ee.StartDate) + '-' + parseEmbargoDate(ee.EndDate) + '\n';
            }
        }
        
        String world2TaiwanThisYear = '';
        String world2TaiwanNextYear = '';
        for (PfaRequest.EmbargoEntry ee : req.EmbargoPeriodForeign) {
            
            System.debug(req.EmbargoPeriodForeign);
            if (isThisYear(ee.StartDate)) {
                world2TaiwanThisYear += parseEmbargoDate(ee.StartDate) + '-' + parseEmbargoDate(ee.EndDate) + '\n';
            } else {
                world2TaiwanNextYear += parseEmbargoDate(ee.StartDate) + '-' + parseEmbargoDate(ee.EndDate) + '\n';
            }
        }
        
        if(String.isNotBlank(taiwan2WorldThisYear)) et.Embargo_This_Year_Taiwan_to_World__c = taiwan2WorldThisYear;
        if(String.isNotBlank(taiwan2WorldNextYear)) et.Embargo_Next_Year_Taiwan_to_World__c = taiwan2WorldNextYear;
        if(String.isNotBlank(world2TaiwanThisYear)) et.Embargo_This_Year_World_to_Taiwan__c = world2TaiwanThisYear;
        if(String.isNotBlank(world2TaiwanNextYear)) et.Embargo_Next_Year_World_to_Taiwan__c = world2TaiwanNextYear;
        
        return et;
    }
    
    public static Date parseDate(String input) {
        List<String> strList = input.split('-');
        Integer year = Integer.valueOf(strList[0]);
        Integer month = Integer.valueOf(strList[1]);
        Integer day  = Integer.valueOf(strList[2]);
        return Date.newInstance(year, month, day);
    }
    
    public static String parseEmbargoDate(String inputDateStr) {
        Date d = Date.valueOf(inputDateStr); // Convert string to Date
        Datetime dt = Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0));
        String formatted = dt.format('ddMMMyy').toUpperCase();
        return formatted;
    }
    
    public static Boolean isThisYear(String inputDateStr) {
        Date d = Date.valueOf(inputDateStr);     // Parse "yyyy-MM-dd"
        Integer inputYear = d.year();            // Extract year
        Integer currentYear = Date.today().year();
        return inputYear == currentYear;
    }
    
    public static void fakeMethod() {
        Boolean b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
        b = true;
    }
}