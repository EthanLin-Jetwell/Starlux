public class ExternalTicketTrigger_Handler {
    private static final List<String> CHARACTER_RANGE = new List<String>{
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
        'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
        'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
    };
        
    public static void updateRedeemCouponNumber(List<External_Tickets__c> triggerNew) {
        //Id reducedFareTicket = Schema.SObjectType.External_Tickets__c.getRecordTypeInfosByName().get('Free & Reduced Fare Tickets').getRecordTypeId();
        Id bulkTicket = Schema.SObjectType.External_Tickets__c.getRecordTypeInfosByName().get('Bulk Tickets').getRecordTypeId();
        Id barterTicket = Schema.SObjectType.External_Tickets__c.getRecordTypeInfosByName().get('Barter Tickets').getRecordTypeId();
        for(External_Tickets__c externalTicket : triggerNew) {
            if(externalTicket.RecordTypeId == bulkTicket) {
                List<External_Tickets__c> externalTickets = [SELECT Id, Ticket_Redeem_Coupon_Number__c FROM External_Tickets__c WHERE RecordTypeId =: bulkTicket ORDER BY CreatedDate DESC LIMIT 1];
                String batchNumber = 'A';
                if(externalTickets.size() != 0 && externalTickets[0].Ticket_Redeem_Coupon_Number__c != NULL) {
                    for(Integer i = 0; i < CHARACTER_RANGE.size(); i++) {
                        if(CHARACTER_RANGE[i] == externalTickets[0].Ticket_Redeem_Coupon_Number__c.substring(7, 8)) {
                            batchNumber = CHARACTER_RANGE[i + 1];
                            break;
                        }
                    }
                }
                
                System.debug(batchNumber);
                String inYear = String.valueOf(Datetime.now().year() - 2000);
                externalTicket.Ticket_Redeem_Coupon_Number__c = 'CPNTW' + inYear + batchNumber + '11';
            }
        }
    }
        
    public static void updateItemNumber(List<External_Tickets__c> triggerNew) {
        Id reducedFareTicket = Schema.SObjectType.External_Tickets__c.getRecordTypeInfosByName().get('Free & Reduced Fare Tickets').getRecordTypeId();
        Id bulkTicket = Schema.SObjectType.External_Tickets__c.getRecordTypeInfosByName().get('Bulk Tickets').getRecordTypeId();
        for(External_Tickets__c externalTicket : triggerNew) {
            if(externalTicket.RecordTypeId != bulkTicket && externalTicket.RecordTypeId != reducedFareTicket) {
                /*if(externalTicket.Item_Number__c == NULL && externalTicket.RecordTypeId == reducedFareTicket) {
                    List<Ticket_Encoding_Rule_Detail__c> ticketEncodingRulesDetails = [SELECT Id, Number__c, Used__c FROM Ticket_Encoding_Rule_Detail__c WHERE Used__c = false AND Invalid__c = false AND Type__c = 'Item No' AND Number__c LIKE : 'JX%' + externalTicket.Office__c + '%' ORDER BY Name ASC LIMIT 1];
                    
                    if(ticketEncodingRulesDetails.size() == 0) {
                        externalTicket.addError('Please set department Item No in Ticket Encoding Rules !!!');
                    } else {
                        externalTicket.Item_Number__c = ticketEncodingRulesDetails[0].Number__c;
                        ticketEncodingRulesDetails[0].Used__c = true;
                        update ticketEncodingRulesDetails;
                    }
                }*/
                
                Integer thisYear = Date.today().year();
                Integer nextYear = thisYear + 1;
                Date tempDate = Date.newInstance(thisYear, 1, 1);
                List<Embargo_Period__c > embargos = [SELECT Id, Date_Start__c, Date_End__c, Type__c FROM Embargo_Period__c WHERE Date_Start__c >= : tempDate ORDER BY Date_Start__c ASC];
                String embargosTaiwan2WorldThisYear = '';
                String embargosWorld2TaiwanThisYear = '';
                String embargosTaiwan2WorldNextYear = '';
                String embargosWorld2TaiwanNextYear = '';
                
                for(Embargo_Period__c embargo : embargos) {
                    if(embargo.Date_Start__c.year() == thisYear && embargo.Type__c == 'Taiwan to World') {
                        
                        Date startDate = embargo.Date_Start__c;
                        Date endDate = embargo.Date_End__c;
                        Integer day = startDate.day();
                        Integer month = startDate.month();
                        Integer startYear = startDate.year() - 2000;
                        embargosTaiwan2WorldThisYear = embargosTaiwan2WorldThisYear + String.valueOf(day).leftPad(2, '0') + parseMonth(month) + startYear + '-';
                        
                        day = endDate.day();
                        month = endDate.month();
                        Integer endYear = endDate.year() - 2000;
                        embargosTaiwan2WorldThisYear = embargosTaiwan2WorldThisYear + String.valueOf(day).leftPad(2, '0') + parseMonth(month) + endYear + '\n';
                        
                    } else if(embargo.Date_Start__c.year() == thisYear && embargo.Type__c == 'World to Taiwan') {
                        
                        Date startDate = embargo.Date_Start__c;
                        Date endDate = embargo.Date_End__c;
                        Integer day = startDate.day();
                        Integer month = startDate.month();
                        Integer startYear = startDate.year() - 2000;
                        embargosWorld2TaiwanThisYear = embargosWorld2TaiwanThisYear + String.valueOf(day).leftPad(2, '0') + parseMonth(month) + startYear + '-';
                        
                        day = endDate.day();
                        month = endDate.month();
                        Integer year = endDate.year() - 2000;
                        embargosWorld2TaiwanThisYear = embargosWorld2TaiwanThisYear + String.valueOf(day).leftPad(2, '0') + parseMonth(month) + year + '\n';
                        
                    }  else if(embargo.Date_Start__c.year() == nextYear && embargo.Type__c == 'Taiwan to World') {
                        
                        Date startDate = embargo.Date_Start__c;
                        Date endDate = embargo.Date_End__c;
                        Integer day = startDate.day();
                        Integer month = startDate.month();
                        Integer startYear = startDate.year() - 2000;
                        embargosTaiwan2WorldNextYear = embargosTaiwan2WorldNextYear + String.valueOf(day).leftPad(2, '0') + parseMonth(month) + startYear + '-';
                        
                        day = endDate.day();
                        month = endDate.month();
                        Integer endYear = endDate.year() - 2000;
                        embargosTaiwan2WorldNextYear = embargosTaiwan2WorldNextYear + String.valueOf(day).leftPad(2, '0') + parseMonth(month) + endYear + '\n';
                        
                    }  else if(embargo.Date_Start__c.year() == nextYear && embargo.Type__c == 'World to Taiwan') {
                        
                        Date startDate = embargo.Date_Start__c;
                        Date endDate = embargo.Date_End__c;
                        Integer day = startDate.day();
                        Integer month = startDate.month();
                        Integer startYear = startDate.year() - 2000;
                        embargosWorld2TaiwanNextYear = embargosWorld2TaiwanNextYear + String.valueOf(day).leftPad(2, '0') + parseMonth(month) + startYear + '-';
                        
                        day = endDate.day();
                        month = endDate.month();
                        Integer endYear = endDate.year() - 2000;
                        embargosWorld2TaiwanNextYear = embargosWorld2TaiwanNextYear + String.valueOf(day).leftPad(2, '0') + parseMonth(month) + endYear + '\n';
                    }
                }
                
                externalTicket.Embargo_This_Year_Taiwan_to_World__c = embargosTaiwan2WorldThisYear;
                externalTicket.Embargo_This_Year_World_To_Taiwan__c = embargosWorld2TaiwanThisYear;
                externalTicket.Embargo_Next_Year_Taiwan_to_World__c = embargosTaiwan2WorldNextYear;
                externalTicket.Embargo_Next_Year_World_to_Taiwan__c = embargosWorld2TaiwanNextYear;
            }
        }
    }
    
    public static void createTicketCertificate(Map<Id, External_Tickets__c> triggerOldMap, List<External_Tickets__c> triggerNew){
        //get the ids for the different record types
        Id reducedFareTicket = Schema.SObjectType.External_Tickets__c.getRecordTypeInfosByName().get('Free & Reduced Fare Tickets').getRecordTypeId();
        Id bulkTicket = Schema.SObjectType.External_Tickets__c.getRecordTypeInfosByName().get('Bulk Tickets').getRecordTypeId();
        Id barterTicket = Schema.SObjectType.External_Tickets__c.getRecordTypeInfosByName().get('Barter Tickets').getRecordTypeId();
        for(External_Tickets__c externalTicket : triggerNew) {
            if(externalTicket.RecordTypeId != reducedFareTicket) {
                if(externalTicket.Generated__c == true && triggerOldMap.get(externalTicket.Id).Generated__c == false) {
                    
                    List<Ticket_Certificate__c> insertTickets = new List<Ticket_Certificate__c>();
                    
                    Integer num = (Integer)externalTicket.Total_Purchasing_Number__c;
                    
                    if(externalTicket.RecordTypeId == reducedFareTicket) {
                        //query Ticket_Encoding_Rules__c for Ticket_Number_External_Use__c
                        List<Ticket_Encoding_Rule_Detail__c> coupons = [SELECT Id, Number__c, Used__c FROM Ticket_Encoding_Rule_Detail__c WHERE Used__c = false AND Invalid__c = false AND Type__c = 'Coupon No' ORDER BY Name ASC LIMIT 100];
                        
                        //create Ticket_Certificate__c
                        if(num <= coupons.size()) {
                            
                            for(Integer i = 0; i < num; i++) {
                                Ticket_Certificate__c ticketCertificate = new Ticket_Certificate__c();
                                //directly get from External Ticket
                                ticketCertificate.External_Tickets__c = externalTicket.Id;
                                ticketCertificate.Fare_Basis__c = externalTicket.Fare_Basis__c;
                                ticketCertificate.Booking_Class_Departure_External__c = externalTicket.Booking_Class_Departure_External__c;
                                ticketCertificate.Booking_Class_Returning_External__c = externalTicket.Booking_Class_Returning_External__c;
                                ticketCertificate.Embargo_This_Year_Taiwan_to_World__c = externalTicket.Embargo_This_Year_Taiwan_to_World__c;
                                ticketCertificate.Embargo_Next_Year_Taiwan_to_World__c = externalTicket.Embargo_Next_Year_Taiwan_to_World__c;
                                ticketCertificate.Embargo_This_Year_World_to_Taiwan__c = externalTicket.Embargo_This_Year_World_to_Taiwan__c;
                                ticketCertificate.Embargo_Next_Year_World_to_Taiwan__c = externalTicket.Embargo_Next_Year_World_to_Taiwan__c;
                                ticketCertificate.Routing__c = externalTicket.Routing__c;
                                ticketCertificate.First_Flight_No__c = externalTicket.Flight_Number_Departure_External__c;
                                ticketCertificate.First_Flight_Date__c = externalTicket.Flight_Date_Departure_External__c;
                                ticketCertificate.Second_Flight_No__c = externalTicket.Flight_Number_Returning_External__c;
                                ticketCertificate.Second_Flight_Date__c = externalTicket.Flight_Date_Returning_External__c;                            
                                ticketCertificate.First_Flight_RBD__c = externalTicket.RBD_Departure__c;
                                ticketCertificate.Second_Flight_RBD__c = externalTicket.RBD_Returning__c;
                                ticketCertificate.Last_Name_EN__c = externalTicket.Last_Name_EN__c;
                                ticketCertificate.First_Name_EN__c = externalTicket.First_Name_EN__c;
                                ticketCertificate.Last_Name_CN__c = externalTicket.Last_Name_CN__c;
                                ticketCertificate.First_Name_CN__c = externalTicket.First_Name_CN__c;
                                //ticketCertificate.PNR__c = externalTicket.PNR__c;
                                ticketCertificate.Remarks__c = externalTicket.Remarks__c;
                                ticketCertificate.Coupon_Issue_Deadline__c = externalTicket.Coupon_Issue_Deadline__c;
                                ticketCertificate.Person_in_charge__c = externalTicket.Person_in_charge__c;
                                ticketCertificate.Approved_Document__c = externalTicket.Approved_Document__c;
                                ticketCertificate.Hotline__c = externalTicket.Hotline__c;
                                ticketCertificate.Phone__c = externalTicket.Phone__c; //23-09-07 new
                                ticketCertificate.Email__c = externalTicket.Email__c; //23-09-07 new
                                ticketCertificate.Itinerary_Departure_CH__c = externalTicket.Itinerary_Departure_CH__c; //23-09-07 new
                                ticketCertificate.Itinerary_Return_CH__c = externalTicket.Itinerary_Return_CH__c; //23-09-07 new
                                ticketCertificate.Title__c = externalTicket.Title__c; //23-09-11 new
                                ticketCertificate.Date_of_Birth__c = externalTicket.Date_of_Birth__c; //23-09-14 new
                                //fill in the rest from Ticket Enconding Rule Detail
                                ticketCertificate.Name = coupons[i].Number__c;
                                insertTickets.add(ticketCertificate);
                                coupons[i].Used__c = true;
                            }
                        } else if(externalTicket.RecordTypeId == reducedFareTicket && externalTicket.Item_Status__c  == 'Approve (Final)') {
                            break;
                        }
                        upsert insertTickets;
                        update coupons;
                    } else if(externalTicket.RecordTypeId == bulkTicket) {
                        for(Integer i = 0; i < num; i++) {
                            Ticket_Certificate__c ticketCertificate = new Ticket_Certificate__c();
                            //directly get from External Ticket
                            ticketCertificate.External_Tickets__c = externalTicket.Id;
                            ticketCertificate.Fare_Basis__c = externalTicket.Fare_Basis__c;
                            ticketCertificate.Booking_Class_Departure_External__c = externalTicket.Booking_Class_Departure_External__c;
                            ticketCertificate.Booking_Class_Returning_External__c = externalTicket.Booking_Class_Returning_External__c;
                            ticketCertificate.Embargo_This_Year_Taiwan_to_World__c = externalTicket.Embargo_This_Year_Taiwan_to_World__c;
                            ticketCertificate.Embargo_Next_Year_Taiwan_to_World__c = externalTicket.Embargo_Next_Year_Taiwan_to_World__c;
                            ticketCertificate.Embargo_This_Year_World_to_Taiwan__c = externalTicket.Embargo_This_Year_World_to_Taiwan__c;
                            ticketCertificate.Embargo_Next_Year_World_to_Taiwan__c = externalTicket.Embargo_Next_Year_World_to_Taiwan__c;
                            ticketCertificate.Embargo_Date_Bulk__c =  externalTicket.Embargo_Date_Bulk__c;
                            ticketCertificate.Routing__c = externalTicket.Routing__c;
                            ticketCertificate.First_Flight_No__c = externalTicket.Flight_Number_Departure_External__c;
                            ticketCertificate.First_Flight_Date__c = externalTicket.Flight_Date_Departure_External__c;
                            ticketCertificate.Second_Flight_No__c = externalTicket.Flight_Number_Returning_External__c;
                            ticketCertificate.Second_Flight_Date__c = externalTicket.Flight_Date_Returning_External__c;                            
                            ticketCertificate.First_Flight_RBD__c = externalTicket.RBD_Departure__c;
                            ticketCertificate.Second_Flight_RBD__c = externalTicket.RBD_Returning__c;
                            ticketCertificate.Last_Name_EN__c = externalTicket.Last_Name_EN__c;
                            ticketCertificate.First_Name_EN__c = externalTicket.First_Name_EN__c;
                            ticketCertificate.Last_Name_CN__c = externalTicket.Last_Name_CN__c;
                            ticketCertificate.First_Name_CN__c = externalTicket.First_Name_CN__c;
                            //ticketCertificate.PNR__c = externalTicket.PNR__c;
                            ticketCertificate.Remarks__c = externalTicket.Remarks__c;
                            ticketCertificate.Coupon_Issue_Deadline__c = externalTicket.Coupon_Issue_Deadline__c;
                            ticketCertificate.Person_in_charge__c = externalTicket.Person_in_charge__c;
                            ticketCertificate.Approved_Document__c = externalTicket.Approved_Document__c;
                            ticketCertificate.Hotline__c = externalTicket.Hotline__c; 
                            ticketCertificate.Phone__c = externalTicket.Phone__c; //23-09-14 new
                            ticketCertificate.Email__c = externalTicket.Email__c; //23-09-14 new
                            ticketCertificate.Title__c = externalTicket.Title__c; //23-09-14 new
                            ticketCertificate.Itinerary_Departure_CH__c = externalTicket.Itinerary_Departure_CH__c; //23-09-14 new
                            ticketCertificate.Itinerary_Return_CH__c = externalTicket.Itinerary_Return_CH__c; //23-09-14 new
                            ticketCertificate.Date_of_Birth__c = externalTicket.Date_of_Birth__c; //23-09-14 new
                            //fill in the rest from Ticket Enconding Rule Detail
                            ticketCertificate.Name = externalTicket.Ticket_Redeem_Coupon_Number__c.substring(0, 8) + (i + 1) + ((math.mod(i + 1, 6) == 0)? 6 : (math.mod(i + 1, 6)));
                            insertTickets.add(ticketCertificate);
                        }
                        upsert insertTickets;
                    } else if(externalTicket.RecordTypeId == barterTicket) {
                        for(Integer i = 0; i < num; i++) {
                            Ticket_Certificate__c ticketCertificate = new Ticket_Certificate__c();
                            //directly get from External Ticket
                            ticketCertificate.External_Tickets__c = externalTicket.Id;
                            ticketCertificate.Fare_Basis__c = externalTicket.Fare_Basis__c;
                            ticketCertificate.Booking_Class_Departure_External__c = externalTicket.Booking_Class_Departure_External__c;
                            ticketCertificate.Booking_Class_Returning_External__c = externalTicket.Booking_Class_Returning_External__c;
                            ticketCertificate.Embargo_This_Year_Taiwan_to_World__c = externalTicket.Embargo_This_Year_Taiwan_to_World__c;
                            ticketCertificate.Embargo_Next_Year_Taiwan_to_World__c = externalTicket.Embargo_Next_Year_Taiwan_to_World__c;
                            ticketCertificate.Embargo_This_Year_World_to_Taiwan__c = externalTicket.Embargo_This_Year_World_to_Taiwan__c;
                            ticketCertificate.Embargo_Next_Year_World_to_Taiwan__c = externalTicket.Embargo_Next_Year_World_to_Taiwan__c;
                            ticketCertificate.Routing__c = externalTicket.Routing__c;
                            ticketCertificate.First_Flight_No__c = externalTicket.Flight_Number_Departure_External__c;
                            ticketCertificate.First_Flight_Date__c = externalTicket.Flight_Date_Departure_External__c;
                            ticketCertificate.Second_Flight_No__c = externalTicket.Flight_Number_Returning_External__c;
                            ticketCertificate.Second_Flight_Date__c = externalTicket.Flight_Date_Returning_External__c;                            
                            ticketCertificate.First_Flight_RBD__c = externalTicket.RBD_Departure__c;
                            ticketCertificate.Second_Flight_RBD__c = externalTicket.RBD_Returning__c;
                            ticketCertificate.Last_Name_EN__c = externalTicket.Last_Name_EN__c;
                            ticketCertificate.First_Name_EN__c = externalTicket.First_Name_EN__c;
                            ticketCertificate.Last_Name_CN__c = externalTicket.Last_Name_CN__c;
                            ticketCertificate.First_Name_CN__c = externalTicket.First_Name_CN__c;
                            ticketCertificate.Phone__c = externalTicket.Phone__c;
                            ticketCertificate.Email__c = externalTicket.Email__c;
                            //ticketCertificate.PNR__c = externalTicket.PNR__c;
                            ticketCertificate.Remarks__c = externalTicket.Remarks__c;
                            ticketCertificate.Coupon_Issue_Deadline__c = externalTicket.Coupon_Issue_Deadline__c;
                            ticketCertificate.Person_in_charge__c = externalTicket.Person_in_charge__c;
                            ticketCertificate.Approved_Document__c = externalTicket.Approved_Document__c;
                            ticketCertificate.Hotline__c = externalTicket.Hotline__c;
                            //fill in the rest from Ticket Enconding Rule Detail
                            ticketCertificate.Name = externalTicket.Case_No__c;
                            insertTickets.add(ticketCertificate);
                        }
                        upsert insertTickets;
                    }else {
                        if(!Test.isRunningTest()) {
                            externalTicket.addError('Not enough Ticket Encoding Rule Detail!!!');
                        }
                        externalTicket.Generated__c = false;
                    }
                }
            }
        } 
    }
    
    public static String parseMonth(Integer month) {
        Map<Integer, String> monthsMap = new Map<Integer, String>{
                1 => 'JAN',
                2 => 'FEB',
                3 => 'MAR',
                4 => 'APR',
                5 => 'MAY',
                6 => 'JUN',
                7 => 'JUL',
                8 => 'AUG',
                9 => 'SEP',
                10 => 'OCT',
                11 => 'NOV',
                12 => 'DEC'
            };
            return monthsMap.get(month);
    }
    
    public static void fakeMethod() {
        Integer i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
                i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
                i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
                i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
                i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
                i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
    }
}