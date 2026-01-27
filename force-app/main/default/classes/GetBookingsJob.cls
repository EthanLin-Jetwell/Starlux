/********************************************************************************************************
NAME:			GetBookingsJob
AUTHOR:			Edmond To (eto@salesforce.com)
PURPOSE:		This is the scheduler class for the retrieval of recent flight bookings by specific Accounts, conditionally specified.

UPDATE HISTORY:
DATE            AUTHOR			COMMENTS
-------------------------------------------------------------
27/06/2019      Edmond To		First version
********************************************************************************************************/

global class GetBookingsJob implements Schedulable, Database.Batchable<Sobject>, Database.AllowsCallouts{
    //Application Log 070119
    private static List<System_Settings__mdt> logLevelCMD;
    private static DateTime startTime = DateTime.now();
    private static String processLog;
    private static String payLoad;
    private static Integer totalRecords = 0, errorRecords = 0, successfulRecords = 0;
    private static List<String> failureRecords = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        ID targetCaseRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Feedback').getRecordTypeId();
        String statusValue = 'Closed';
        String passengerType = 'VIP';

        String query = 'SELECT Id, CEM_ID__c FROM Account WHERE Id IN (SELECT AccountId FROM Case WHERE (Status != :statusValue AND RecordTypeID = :targetCaseRecordTypeID) OR Account.Passenger_Type__pc= :passengerType) AND CEM_ID__c != null';
        //String testRecordId = '001N000001TQKZXIA5';
        //String query = 'SELECT Id, CEM_ID__c FROM Account WHERE Id = :testRecordId';
        
		return Database.getQueryLocator(query);
    }
    
    
    global void execute(Database.BatchableContext BC, List<Account> allSelectedAccounts) {
        
        //Application Log 070119
        System_Settings__mdt logLevelCMD = [Select Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Get Bookings Job'
                                            limit 1];
        
        //Create master list of booking details records for upsert later on
        List<Booking_Details__c> recordsToUpsert = new List<Booking_Details__c>();
        
        //Define all required parameters for SOQL and API Callout to CRANE
        Map<String, Object> sourceMap = new Map<String, Object>(); //sourceMap needs to include request payload parameters, like CEM_ID.etc
        
        
        String interfaceConfiguration = 'CRANE';
        String interfaceOperation = 'Get_Bookings_Job';
        
        
        //ID targetCaseRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Feedback').getRecordTypeId();
        //List<Account> allSelectedAccounts = [SELECT Id, CEM_ID__c FROM Account WHERE Id IN (SELECT AccountId FROM Case WHERE (Status != :'Closed' AND RecordTypeID = :targetCaseRecordTypeID) OR Account.Passenger_Type__pc= :'VIP') AND CEM_ID__c != null];
		system.debug('DBG allSelectedAccounts: '+allSelectedAccounts);
        
        //need to iterate the following over the master list of Accounts queried earlier
        for (Account acc : allSelectedAccounts) {
        	
            sourceMap.put('CEM_Id', acc.CEM_ID__c);
            system.debug('DBG Sourcemap: '+sourceMap);
            Map<String,Object> resforInterface = Utility.SendData(interfaceConfiguration, interfaceOperation, sourceMap);
            system.debug('DBG ResforInterface: '+resforInterface);
            //Map<String,Object> resforInterface = doCraneCallOut(interfaceConfiguration, interfaceOperation, sourceMap);
//20190903: Add error handling
Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(resforInterface.get('Response')));
Boolean success = (Boolean) payloadMap.get('success'); 
system.debug('[STARLUX] success: '+success); // TRUE means success
String messageContent = (String) Utility.getVariableValue(payloadMap, 'message.content'); 
system.debug('[STARLUX] messageContent: '+messageContent); // "OK" means success
            Object responseMap;
            Map<String, Object> resultMap = new Map<String, Object>();
            Object responseMap2;
            Map<String, Object> resultMap2 = new Map<String, Object>();
            Object responseMap3;
            List<Object> responseList = new List<Object>();
if (success==TRUE && messageContent=='OK') { // Crane API success criteria
            responseMap = resforInterface.get('Response');
            resultMap = (Map<String, Object>)responseMap;
            responseMap2 = resultMap.get('data');
            resultMap2 = (Map<String, Object>)responseMap2;
            responseMap3 = resultMap2.get('items');
            responseList = (List<Object>)responseMap3;

/*            Object responseMap = resforInterface.get('Response');
            Map<String, Object> resultMap = (Map<String, Object>)responseMap;
            Object responseMap2 = resultMap.get('data');
            Map<String, Object> resultMap2 = (Map<String, Object>)responseMap2;
            Object responseMap3 = resultMap2.get('items');
            List<Object> responseList = (List<Object>)responseMap3;
*/
}
            for (Integer i = 0; i<responseList.size();i++) {
                Map<String, Object> responseSub = (Map<String, Object>)responseList[i];
                String PNRID = (String)responseSub.get('PNR'); 
                String bookingClass = (String)responseSub.get('Booking_class');
                String arrivalLocation = (String)responseSub.get('Arr_Location');
                String departureLocation = (String)responseSub.get('Dep_Location');
                String flightNumber = (String)responseSub.get('Flight_No');
                String ticketNumber = (String)responseSub.get('Ticket_EMD_Number');
                String serviceSSR = (String)responseSub.get('Services_SSR');
                String bookingStatus = (String)responseSub.get('Status');
                String passengerName = (String)responseSub.get('Passenger');
            String arrivalDate = (String)responseSub.get('Arrival_Date__c');
            String arrivalTime = (String)responseSub.get('Arrival_Time__c');
            String departureDate = (String)responseSub.get('Departure_Date__c');
            String departureTime = (String)responseSub.get('Departure_Time__c');
                // Generate the Unique Key for BookingDetails record
                String BookingUID = ticketNumber + departureTime;  
                
                Booking_Details__c newDetails = new Booking_Details__c();
                newDetails.Booking_UID__c = BookingUID;
                newDetails.Passenger_Name__c = passengerName;
                newDetails.Booking_Status__c = bookingStatus; 
                newDetails.Account_ID__c = acc.Id;
                newDetails.Booking_Class__c = bookingClass;
                newDetails.Arrival_Location__c = arrivalLocation;
                newDetails.Departure_Location__c = departureLocation;
            if (arrivalDate!='') newDetails.Arrival_Date__c = date.valueOf(arrivalDate);
            newDetails.Arrival_Time__c = arrivalTime;
            if (departureDate!='') newDetails.Departure_Date__c = date.valueOf(departureDate);
            newDetails.Departure_Time__c = departureTime;
                newDetails.Name = flightNumber;
                newDetails.Ticket_EMD_Number__c = ticketNumber;
                newDetails.Service_SSR__c = serviceSSR;
                newDetails.PNR_ID__c = PNRID;
                
                recordsToUpsert.add(newDetails);
                totalrecords++;
            }
        }
        //system.debug('DBG recordsToUpsert'+recordsToUpsert);
        
        
//20190903: Add error handling            
if (!recordsToUpsert.isEmpty()) {
        try {
            system.debug('DBG recordsToUpsert');
            Database.UpsertResult[] result = Database.upsert(recordsToUpsert, Booking_Details__c.Booking_UID__c, false);
        	system.debug('DBG upsertresult: '+result);
            for (Integer i = 0; i < result.size(); i++) {
                if (!result[i].isSuccess()) {
                    for (Database.Error err : result[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(result[i].Id);
                        processLog += 'Unable to insert Record ID: ' + result[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    //system.debug('DBG result[i]: '+ result[i]);
                    successfulRecords++;
                }
            }
            
            processLog = '#########################\r\n' +
            'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
            'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
            'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
            'Total Processed Records: ' + totalRecords + '\r\n' +
            'Total Successful Inserted Records: ' + successfulRecords + '\r\n' +
            'Total Failed Records: ' + errorRecords + '\r\n' + 
            'List of Failed Records: ' + failureRecords + '\r\n' +
            '#########################\r\n' + processLog;
            
            system.debug('DBG ProcessLog: '+processLog);
            
            //Application Log 070119
            GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'GetBookingsJob', 'execute', null, 'Booking Details Records Creation', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
            
            
        } catch (DMLException DMLError){
            //Application Log 070119
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'GetBookingsJob', 'execute', null, 'Booking Details Records Creation', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
        }
} //20190903
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
    global void execute(SchedulableContext ctx) {
        GetBookingsJob newJob = new GetBookingsJob();
        database.executeBatch(newJob);
        
        
        /*
        List<Account> allAccounts = new List<Account>();
        //Query for desired account records
        List<Account> VIPAccounts = [SELECT Id, CEM_ID__c FROM Account WHERE Passenger_Type__pc = :'VIP'];
        //system.debug('DBG VIPAccount: '+VIPAccounts);
        List<Case> openCases = [SELECT Id, Status, AccountId FROM Case WHERE Status != :'Closed' AND RecordTypeId = :targetCaseRecordTypeID];
        //system.debug('DBG OpenCases: '+openCases);
        List<ID> openAccountsID = new List<ID>();
        
        
        for (Case c:openCases) {
            if (!openAccountsID.contains(c.AccountId)) {
                openAccountsID.add(c.AccountId);
            }
        }
            
        List<Account> openAccounts = [SELECT Id, CEM_ID__c FROM Account WHERE Id IN :openAccountsID];
        //system.debug('DBG OpenAccounts: '+openAccounts);
        allAccounts.addAll(VIPAccounts);
        
        //Dump all accounts into one master set
        for (Account acc : openAccounts) {
            if (!allAccounts.contains(acc)) {
                allAccounts.add(acc);
                //system.debug('DBG acc added: '+acc);
            }
        }
        //system.debug('DBG AllAccounts: '+allAccounts);
        */
        
        
        
        /*
        //Query for all existing booking details for PNR ID
        List<Booking_Details__c> existingBookings = [SELECT Id, PNR_ID__c FROM Booking_Details__c];
        Map<String, Booking_Details__c> existingBookingsSet = new Map<String, Booking_Details__c>();
        for (Booking_Details__c book : existingBookings) {
            existingBookingsSet.put(book.PNR_ID__c, book);
        }
        
        //Iterate over recordsToUpsert to check for duplicate bookings using PNR_ID as external ID
        for (Booking_Details__c booking : pendingRecordsToUpsert) {
            if (!existingBookingsSet.containsKey(booking.PNR_ID__c)) {
                recordsToUpsert.add(booking);
                totalRecords++;
            }
        }
        */
        
        
        
        
    
        //Needs to store the following fields in the Booking record (Fields currently captured denoted by *)
        //Account ID* (Salesforce)
        //Arrival Location* (API)
        //Arrival Time
        //Booking Class* (API)
        //Booking Status
        //Departure Location* (API)
        //Departure Time
        //Flight Date
        //Flight Day
        //Flight Number* (API)
        //Passenger Name* (Salesforce? What if its non Person Account?)
        //Service(SSR)* (API)
        //Ticket/EMD Number* (API)
    
    	//ID BatchId = Database.executeBatch(new Batch_GlobalPurgeData(query, sysSettingMD[0]), batchSize);
        
    }
	
	
   	
}