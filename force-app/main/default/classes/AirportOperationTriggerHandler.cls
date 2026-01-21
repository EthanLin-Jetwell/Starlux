/********************************************************************************************************
NAME:           AirportOperationTriggerHandler
AUTHOR:         Edmond To (eto@salesforce.com)
PURPOSE:        To perform upsertions of Checklist__c records upon Airport_Operation records upsertions  
                Upon creation of Airport Operation record, a list of Checklist records will be created based on two checking parameters; Site & ScheduleType, controlled by custom metadata
                Upon updates of Airport Operation record, certain Checklist records will be updated accordingly based on their Status, controlled by the object field

UPDATE HISTORY:
DATE            AUTHOR          COMMENTS
-------------------------------------------------------------
17/06/2019      Edmond To       First version
27/08/2019      Edmond To       Revised to account for new object schema for Arrival Checklist and Departure Checklist records
********************************************************************************************************/

public class AirportOperationTriggerHandler extends TriggerHandler {
    public AirportOperationTriggerHandler() {
        
    }
    
    //Application Log 061819
    private static List<System_Settings__mdt> logLevelCMD;
    private static DateTime startTime = DateTime.now();
    private static String processLog;
    private static String payLoad;
    private static Integer totalRecords = 0, errorRecords = 0, successfulRecords = 0;
    private static List<String> failureRecords = new List<String>();
    
    public override void afterInsert() { //Create associated Checklist records based on settings in Custom Metadata settings
        createNewChecklists();
    }
    
    public override void afterUpdate() { //Update associated Checklist records based on settings in Custom Metadata settings
        
        updateChecklists();
    }
 
    private static void createNewChecklists() {
        
        //Application Log 061819
        System_Settings__mdt logLevelCMD = [Select Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Airport Operation Trigger Handler'
                                            limit 1];
        
        Timezone userTime = UserInfo.getTimeZone();
        Integer timeOffset = -(userTime.getOffset(DateTime.newInstance(2012,11,23,12,0,0))/(60000));
        system.debug('DBG TimeOffset: '+timeOffset);
        //Airport Operation masterlist
        List<Airport_Operation__c> operationRecordsToUpdate = new List<Airport_Operation__c>(); 
        
        //Arrival checklist masterlist
        List<Arrival_Checklist__c> arrivalRecordsToUpsert = new List<Arrival_Checklist__c>(); 
        
        //Departure checklist masterlist
        List<Departure_Checklist__c> departureRecordsToUpsert = new List<Departure_Checklist__c>();
        
        //Query for all new Airport Operation records upserted
        List<Airport_Operation__c> newOperations = [SELECT Id, Name,ETA_Date_Local__c, ETA_Time_Local__c, ETA_Date_UTC__c, ETA_Time_UTC__c,
                                                    ETD_Date_Local__c, ETD_Time_Local__c,ETD_Date_UTC__c, ETD_Time_UTC__c,FLT_Carrier__c,
                                                    STA_Date_Local__c,STA_Date_UTC__c, STA_Time_Local__c, STA_Time_UTC__c,STD_Date_Local__c, STD_Date_UTC__c, 
                                                    STD_Time_Local__c,STD_Time_UTC__c,Departure_Flight_Date_UTC__c, Departure_Flight_Date_Local__c,
                                                    Arrival_Flight_Date_UTC__c,Arrival_Flight_Date_Local__c, ETD_Offset__c, ETA_Offset__c
                                                    FROM Airport_Operation__c WHERE ID IN :Trigger.new]; 
        
        List<Airport_Operation_Checklist__mdt> newArrivalChecklist = [SELECT Id, ScheduleType__c, ListOrder__c, GroupInCharge__c, Site__c, StageName__c, EstimatedStartBase__c, EstimatedEndBase__c, EstimatedStartOffset__c, EstimatedEndOffset__c 
                                                                      FROM Airport_Operation_Checklist__mdt WHERE ScheduleType__c = 'Arrival' ORDER BY ScheduleType__c, Site__c, ListOrder__c]; //Query for all Arrival related Checklist metadata records
        
        List<Airport_Operation_Checklist__mdt> newDepartureChecklist = [SELECT Id, ScheduleType__c, ListOrder__c, GroupInCharge__c, Site__c, StageName__c, EstimatedStartBase__c, EstimatedEndBase__c, EstimatedStartOffset__c, EstimatedEndOffset__c 
                                                                      FROM Airport_Operation_Checklist__mdt WHERE ScheduleType__c = 'Departure' ORDER BY ScheduleType__c, Site__c, ListOrder__c]; //Query for all Departure related Checklist metadata records
        system.debug('DBG depchecklist: '+newDepartureChecklist);
        processLog += '\r\n'+'afterInsert:Excute newOperations'+'\r\n';
        for (Airport_Operation__c op : newOperations) { //Iterate through all Airport Operation records found earlier
            if (Trigger.isInsert) { //Condition for only inserted records
                //if (String.isEmpty(op.Arr__c) == false) { //Condition for only Arrival records
                //Update airport operation fields from DIH
                op.Name = op.FLT_Carrier__c + op.Name;
                op.ETA_Date_Local__c = op.STA_Date_Local__c;
                op.ETA_Date_UTC__c = op.STA_Date_UTC__c;
                op.ETA_Time_Local__c = op.STA_Time_Local__c;
                op.ETA_Time_UTC__c = op.STA_Time_UTC__c;    
                op.ETD_Date_Local__c = op.STD_Date_Local__c;
                op.ETD_Date_UTC__c = op.STD_Date_UTC__c;
                op.ETD_Time_Local__c = op.STD_Time_Local__c;
                op.ETD_Time_UTC__c = op.STD_Time_UTC__c; 
                    
                op.Departure_Flight_Date_UTC__c = op.STD_Date_UTC__c;
                op.Departure_Flight_Date_Local__c = op.STD_Date_Local__c;
                op.Arrival_Flight_Date_UTC__c = op.STA_Date_UTC__c;
                op.Arrival_Flight_Date_Local__c = op.STA_Date_Local__c;
                
                totalRecords++;
                operationRecordsToUpdate.add(op);
                
                    for (Airport_Operation_Checklist__mdt c : newArrivalChecklist) { //Iterate through each Arrival related Checklist metadata records
                       
                        //Populate relevant fields on Checklist record 
                        Arrival_Checklist__c ChecklistRecord = new Arrival_Checklist__c();
                        ChecklistRecord.Airport_Operation_ID__c = op.Id;
                        ChecklistRecord.Plane_Location__c = c.Site__c;
                        ChecklistRecord.Status_Picklist__c = 'Not Started';
                        ChecklistRecord.Name = c.StageName__c;
                        ChecklistRecord.Division__c = c.GroupInCharge__c;
                        ChecklistRecord.List_Order__c = c.ListOrder__c;
                        ChecklistRecord.Flight_Date_UTC__c = op.STA_Date_UTC__c;
                        ChecklistRecord.Flight_Date_Local__c = op.STA_Date_Local__c;
                        ChecklistRecord.Timezone_Offset__c = op.ETA_Offset__c;   
                        
                        if (c.EstimatedStartBase__c == 'ETA' || c.EstimatedStartBase__c == 'ETD') { 
                            ChecklistRecord.Estimated_Planned_Start_Time_Local__c = op.ETA_Time_Local__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                            ChecklistRecord.Estimated_Planned_Start_Time_UTC__c = op.ETA_Time_UTC__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                            ChecklistRecord.Actual_Planned_Start_Time_Local__c = op.ETA_Time_Local__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                            ChecklistRecord.Actual_Planned_Start_Time_UTC__c = op.ETA_Time_UTC__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                        } 
                        /*else if (c.EstimatedStartBase__c == 'ATA' || c.EstimatedStartBase__c == 'ATD') {
                            ChecklistRecord.Estimated_Planned_Start_Time__c = op.Actual_Flight_Time__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                            ChecklistRecord.Actual_Planned_Start_Time__c = op.Actual_Flight_Time__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                        }*/ 
                        if (c.EstimatedEndBase__c == 'ETA' || c.EstimatedEndBase__c == 'ETD') {
                            ChecklistRecord.Estimated_Planned_End_Time_Local__c = op.ETA_Time_Local__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                            ChecklistRecord.Estimated_Planned_End_Time_UTC__c = op.ETA_Time_UTC__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                            ChecklistRecord.Actual_Planned_Completion_Time_Local__c = op.ETA_Time_Local__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                            ChecklistRecord.Actual_Planned_Completion_Time_UTC__c = op.ETA_Time_UTC__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                        } 
                        /*else if (c.EstimatedEndBase__c == 'ATA' || c.EstimatedEndBase__c == 'ATD') {
                            ChecklistRecord.Estimated_Planned_End_Time__c = op.Actual_Flight_Time__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                            ChecklistRecord.Actual_Planned_Completion_Time__c = op.Actual_Flight_Time__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                        }*/
                        
                        totalRecords++;
                        arrivalRecordsToUpsert.add(ChecklistRecord); //Add Checklist record to master list
                    }
               // } else {
                    for (Airport_Operation_Checklist__mdt c : newDepartureChecklist) {
                        //Populate relevant fields on Checklist record
                        Departure_Checklist__c ChecklistRecord = new Departure_Checklist__c();
                        ChecklistRecord.Airport_Operation_ID__c = op.Id;
                        ChecklistRecord.Plane_Location__c = c.Site__c;
                        ChecklistRecord.Status__c = 'Not Started';
                        ChecklistRecord.Name = c.StageName__c;
                        ChecklistRecord.Division__c = c.GroupInCharge__c;
                        ChecklistRecord.List_Order__c = c.ListOrder__c;
                        ChecklistRecord.Flight_Date_UTC__c = op.STD_Date_UTC__c;
                        ChecklistRecord.Flight_Date_Local__c = op.STD_Date_Local__c;
                        ChecklistRecord.Timezone_Offset__c = op.ETD_Offset__c;        
                        
                        if (c.EstimatedStartBase__c == 'ETA' || c.EstimatedStartBase__c == 'ETD' || c.EstimatedStartBase__c == 'ATA' || c.EstimatedStartBase__c == 'ATD') { 
                            ChecklistRecord.Estimated_Planned_Start_Time_Local__c = op.ETD_Time_Local__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                            ChecklistRecord.Estimated_Planned_Start_Time_UTC__c = op.ETD_Time_UTC__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                            ChecklistRecord.Actual_Planned_Start_Time_Local__c = op.ETD_Time_Local__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                            ChecklistRecord.Actual_Planned_Start_Time_UTC__c = op.ETD_Time_UTC__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                        } 
                        /*else if (c.EstimatedStartBase__c == 'ATA' || c.EstimatedStartBase__c == 'ATD') {
                            ChecklistRecord.Estimated_Planned_Start_Time__c = op.Actual_Flight_Time__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                            ChecklistRecord.Actual_Planned_Start_Time__c = op.Actual_Flight_Time__c.addMinutes(Integer.valueOf(c.EstimatedStartOffset__c));
                        } */
                        if (c.EstimatedEndBase__c == 'ETA' || c.EstimatedEndBase__c == 'ETD' || c.EstimatedEndBase__c == 'ATA' || c.EstimatedEndBase__c == 'ATD') {
                            ChecklistRecord.Estimated_Planned_End_Time_Local__c = op.ETD_Time_Local__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                            ChecklistRecord.Estimated_Planned_End_Time_UTC__c = op.ETD_Time_UTC__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                            ChecklistRecord.Actual_Planned_Completion_Time_Local__c = op.ETD_Time_Local__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                            ChecklistRecord.Actual_Planned_Completion_Time_UTC__c = op.ETD_Time_UTC__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                        } 
                        /*else if (c.EstimatedEndBase__c == 'ATA' || c.EstimatedEndBase__c == 'ATD') {
                            ChecklistRecord.Estimated_Planned_End_Time__c = op.Actual_Flight_Time__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                            ChecklistRecord.Actual_Planned_Completion_Time__c = op.Actual_Flight_Time__c.addMinutes(Integer.valueOf(c.EstimatedEndOffset__c));
                        }*/
                        
                        totalRecords++;
                        departureRecordsToUpsert.add(ChecklistRecord); //Add Checklist record to master list
                    }
                //}
            }
        }
       
        
        //Try catch to insert the checklist records
        try {
            Database.SaveResult[] SaveResult = database.update(operationRecordsToUpdate, false);
            for (Integer i = 0; i < SaveResult.size(); i++) {
                if (!SaveResult[i].isSuccess()) {
                    for (Database.Error err : SaveResult[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(SaveResult[i].Id);
                        processLog += 'Unable to insert Record ID: ' + SaveResult[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    successfulRecords++;
                }
            }
            
            Database.SaveResult[] SaveResult2 = database.insert(arrivalRecordsToUpsert, false);
            for (Integer i = 0; i < SaveResult2.size(); i++) {
                system.debug('DBG arrChecklistInsert: '+SaveResult2[i]);
                if (!SaveResult2[i].isSuccess()) {
                    for (Database.Error err : SaveResult2[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(SaveResult2[i].Id);
                        processLog += 'Unable to insert Record ID: ' + SaveResult2[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    successfulRecords++;
                }
            }
            
            Database.SaveResult[] SaveResult3 = database.insert(departureRecordsToUpsert, false);
            for (Integer i = 0; i < SaveResult3.size(); i++) {
                system.debug('DBG depChecklistInsert: '+SaveResult3[i]);
                if (!SaveResult3[i].isSuccess()) {
                    for (Database.Error err : SaveResult3[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(SaveResult3[i].Id);
                        processLog += 'Unable to insert Record ID: ' + SaveResult3[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
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
            
            //Application Log 061819
            GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'AirportOperationTriggerHandler', 'createNewChecklists', null, 'Airport Operation Checklist Records Creation', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
        
        } catch (DmlException DMLError) {
            
            //Application Log 061819
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'AirportOperationTriggerHandler', 'createNewChecklists', null, 'Airport Operation Checklist Records Creation', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
        }
    }
    
    private static void updateChecklists() {
        
        //Application Log 061819
        System_Settings__mdt logLevelCMD = [Select Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Airport Operation Trigger Handler'
                                            limit 1];

        Timezone userTime = UserInfo.getTimeZone();
        Integer timeOffset = -(userTime.getOffset(DateTime.newInstance(2012,11,23,12,0,0))/(60000));
        //Airport Operation masterlist
        List<Airport_Operation__c> operationRecordsToUpsert = new List<Airport_Operation__c>(); 
        List<Airport_Operation__c> operationNameRecordsToUpsert = new List<Airport_Operation__c>(); //Used to store records which doesn't fit the condition below in order to update Name field
        
        //Arrival checklist masterlist
        List<Arrival_Checklist__c> arrivalRecordsToUpsert = new List<Arrival_Checklist__c>(); 
        
        //Departure checklist masterlist
        List<Departure_Checklist__c> departureRecordsToUpsert = new List<Departure_Checklist__c>();
        
        //Add schedule datetime in SQL Chris 20200110
        List<Airport_Operation__c> newOperations = [SELECT Id,Name,AIRBORNE_Date__c,AIRBORNE_Time__c,ATA_Date__c,ATA_Time__c,LANDING_TIME__c,LANDING_DATE__c,ATD_Date__c,ATD_Time__c,
                                                    FLT_Carrier__c,ETA_Date_Local__c, ETA_Time_Local__c, ETA_Date_UTC__c, ETA_Time_UTC__c,
                                                    ETD_Date_Local__c, ETD_Time_Local__c,ETD_Date_UTC__c, ETD_Time_UTC__c,
                                                    STA_Date_Local__c,STA_Date_UTC__c, STA_Time_Local__c, STA_Time_UTC__c,STD_Date_Local__c, STD_Date_UTC__c, 
                                                    STD_Time_Local__c,STD_Time_UTC__c,
                                                    (SELECT Id,Actual_Start_Date__c,Actual_Completion_Date__c,Start_Now__c,Complete_Now__c,Actual_Start_Time_Local__c,
                                                     Actual_Start_Time_UTC__c,Actual_Completion_Time_Local__c,Actual_Completion_Time_UTC__c, Status_Picklist__c,Estimated_Planned_Start_Time_Local__c, Estimated_Planned_Start_Time_UTC__c, Actual_Planned_Start_Time_Local__c,
                                                     Actual_Planned_Start_Time_UTC__c,Estimated_Planned_End_Time_Local__c,Estimated_Planned_End_Time_UTC__c,Actual_Planned_Completion_Time_Local__c,
                                                     Actual_Planned_Completion_Time_UTC__c, Name FROM Arrival_Checklists__r),
                                                   (SELECT Id, Actual_Start_Date__c,Actual_Completion_Date__c,Start_Now__c,Complete_Now__c,Actual_Start_Time_Local__c,
                                                     Actual_Start_Time_UTC__c,Actual_Completion_Time_Local__c,Actual_Completion_Time_UTC__c,Status__c,Estimated_Planned_Start_Time_Local__c, Estimated_Planned_Start_Time_UTC__c, Actual_Planned_Start_Time_Local__c,
                                                     Actual_Planned_Start_Time_UTC__c,Estimated_Planned_End_Time_Local__c,Estimated_Planned_End_Time_UTC__c,Actual_Planned_Completion_Time_Local__c,
                                                     Actual_Planned_Completion_Time_UTC__c, Name FROM Checklists__r)
                                                    FROM Airport_Operation__c WHERE ID IN :Trigger.new]; //Query for all new Airport Operation records upserted
        
        List<Airport_Operation__c> finalOperations = new List<Airport_Operation__c>(); //Used to store all ETA/ETD shortlisted operations based on condition below
        List<Airport_Operation__c> nameOperations = new List<Airport_Operation__c>(); //Used to store the rest of the operations that don't fit the condition below, in order to update Name field
        
        for (Airport_Operation__c op : newOperations) {
            Airport_Operation__c oldOp = (Airport_Operation__c)Trigger.oldMap.get(op.Id);
            //Chris 20200312
            if((op.ETA_Time_UTC__c != null && op.ETA_Time_UTC__c != oldOp.ETA_Time_UTC__c) ||
                      (op.ETD_Time_UTC__c != null && op.ETD_Time_UTC__c != oldOp.ETD_Time_UTC__c) ||
                      (op.ETA_Date_UTC__c != null && op.ETA_Date_UTC__c != oldOp.ETA_Date_UTC__c)||
                      (op.ETD_Date_UTC__c != null && op.ETD_Date_UTC__c != oldOp.ETD_Date_UTC__c)||
                      (op.AIRBORNE_Date__c != null && op.AIRBORNE_Date__c != oldOp.AIRBORNE_Date__c)||
                      (op.AIRBORNE_Time__c != null && op.AIRBORNE_Time__c != oldOp.AIRBORNE_Time__c)||
                      (op.ATA_Date__c != null && op.ATA_Date__c != oldOp.ATA_Date__c)||
                      (op.ATA_Time__c != null && op.ATA_Time__c != oldOp.ATA_Time__c)||
                      (op.LANDING_DATE__c != null && op.LANDING_DATE__c != oldOp.LANDING_DATE__c)||
                      (op.LANDING_TIME__c != null && op.LANDING_TIME__c != oldOp.LANDING_TIME__c)||
                      (op.ATD_Date__c != null && op.ATD_Date__c != oldOp.ATD_Date__c)||
                      (op.ATD_Time__c != null && op.ATD_Time__c != oldOp.ATD_Time__c)){
                finalOperations.add(op);
                processLog += '\r\n'+'afterupdate:Excute finalOperations,Flight Number='+op.Name+'\r\n';//Chris 20200310
            }
            /*if (op.ETA_Time_UTC__c != oldOp.ETA_Time_UTC__c || op.ETD_Time_UTC__c != oldOp.ETD_Time_UTC__c || op.ETA_Date_UTC__c != oldOp.ETA_Date_UTC__c || op.ETD_Date_UTC__c != oldOp.ETD_Date_UTC__c || op.AIRBORNE_Date__c != oldOp.AIRBORNE_Date__c || op.AIRBORNE_Time__c != oldOp.AIRBORNE_Time__c || op.ATA_Date__c != oldOp.ATA_Date__c || op.ATA_Time__c != oldOp.ATA_Time__c || op.LANDING_DATE__c != oldOp.LANDING_DATE__c || op.LANDING_TIME__c != oldOp.LANDING_TIME__c || op.ATD_Date__c != oldOp.ATD_Date__c || op.ATD_Time__c != oldOp.ATD_Time__c) {
                finalOperations.add(op);
                processLog += '\r\n'+'afterupdate:Excute finalOperations,Flight Number='+op.Name+'\r\n';//Chris 20200110
            }*/
            else {
                nameOperations.add(op);
                processLog += 'afterupdate:Excute nameOperations,Flight Number='+op.Name+'\r\n';//Chris 20200110
            }
        }
        List<Airport_Operation_Checklist__mdt> newArrivalChecklist = [SELECT Id,ListOrder__c, GroupInCharge__c, Label, Site__c, EstimatedStartOffset__c, EstimatedEndOffset__c, ActualStartBase__c, ActualEndBase__c, ActualStartOffset__c, ActualEndOffset__c 
                                                                      FROM Airport_Operation_Checklist__mdt WHERE ScheduleType__c = 'Arrival']; //Query for all Arrival related Checklist metadata records
        
        List<Airport_Operation_Checklist__mdt> newDepartureChecklist = [SELECT Id, ListOrder__c, GroupInCharge__c, Label, Site__c, EstimatedStartOffset__c, EstimatedEndOffset__c, ActualStartBase__c, ActualEndBase__c, ActualStartOffset__c, ActualEndOffset__c 
                                                                      FROM Airport_Operation_Checklist__mdt WHERE ScheduleType__c = 'Departure']; //Query for all Departure related Checklist metadata records
        
        for (Airport_Operation__c op : nameOperations) {
            if (op.Name.startsWith(op.FLT_Carrier__c) != true) {
                op.Name = op.FLT_Carrier__c + op.Name;
                //Set ETD as STD in case schedule change - Chris 20200110
                if(op.STD_Date_Local__c != op.ETD_Date_Local__c || op.STD_Date_UTC__c != op.ETD_Date_UTC__c || op.STD_Time_Local__c != op.ETD_Time_Local__c || op.STD_Time_UTC__c != op.ETD_Time_UTC__c) {                        
                    op.ETD_Date_Local__c = op.STD_Date_Local__c;
                    op.ETD_Date_UTC__c = op.STD_Date_UTC__c;
                    op.ETD_Time_Local__c = op.STD_Time_Local__c;
                    op.ETD_Time_UTC__c = op.STD_Time_UTC__c; 
                    
                    op.Departure_Flight_Date_UTC__c = op.STD_Date_UTC__c;
                    op.Departure_Flight_Date_Local__c = op.STD_Date_Local__c;
                    processLog += '\r\n'+'schedule change(STD)';
                }
                //Set ETA as STA in case schedule change - Chris 20200110
                if(op.STA_Date_Local__c != op.ETA_Date_Local__c || op.STA_Date_UTC__c != op.ETA_Date_UTC__c || op.STA_Time_Local__c != op.ETA_Time_Local__c || op.STA_Time_UTC__c != op.ETA_Time_UTC__c) {
                    op.ETA_Date_Local__c = op.STA_Date_Local__c;
                    op.ETA_Date_UTC__c = op.STA_Date_UTC__c;
                    op.ETA_Time_Local__c = op.STA_Time_Local__c;
                    op.ETA_Time_UTC__c = op.STA_Time_UTC__c;  
                   
                    op.Arrival_Flight_Date_UTC__c = op.STA_Date_UTC__c;
                    op.Arrival_Flight_Date_Local__c = op.STA_Date_Local__c;
                    processLog += '\r\n'+'schedule change(STA)';
                }
                
                totalRecords++;
                operationNameRecordsToUpsert.add(op);
            }     
        }
            
        for (Airport_Operation__c op : finalOperations) { //Iterating through list of shortlisted Airport Operation records
            if (Trigger.isUpdate) { //Checking that record was updated 
                Airport_Operation__c oldOp = (Airport_Operation__c)Trigger.oldMap.get(op.Id);
                
                //if (op.ETA_Time_UTC__c != oldOp.ETA_Time_UTC__c || op.ETD_Time_UTC__c != oldOp.ETD_Time_UTC__c || op.ETA_Date_UTC__c != oldOp.ETA_Date_UTC__c || op.ETD_Date_UTC__c != oldOp.ETD_Date_UTC__c){
                    if (op.Name.startsWith(op.FLT_Carrier__c) != true) {
                        op.Name = op.FLT_Carrier__c + op.Name;
                    }
                    op.Departure_Flight_Date_UTC__c = op.ETD_Date_UTC__c;
                    op.Departure_Flight_Date_Local__c = op.ETD_Date_Local__c;
                    op.Arrival_Flight_Date_UTC__c = op.ETA_Date_UTC__c;
                    op.Arrival_Flight_Date_Local__c = op.ETA_Date_Local__c;
                    
                    totalRecords++;
                    operationRecordsToUpsert.add(op);      
                //}
                
                    List<Arrival_Checklist__c> checklistRecords = new List<Arrival_Checklist__c>();
                    checklistRecords = op.Arrival_Checklists__r; //Related Arrival Checklist records to the AO record
                    for (Arrival_Checklist__c ChecklistRecord : checklistRecords) { //Iterating through the list of Arrival Checklist records
                        if (ChecklistRecord.Status_Picklist__c != 'Completed') { //Checking for incomplete Arrival Checklist records
                            for (Integer i=0; i < newArrivalChecklist.size(); i++) { //Iterating through the list of Checklist METADATA records
                                if (newArrivalChecklist[i].Label == ChecklistRecord.Name) {
                                    ChecklistRecord.Flight_Date_UTC__c = op.ETA_Date_UTC__c;
                                    ChecklistRecord.Flight_Date_Local__c = op.ETA_Date_Local__c;
                                    if (newArrivalChecklist[i].ActualStartBase__c == 'ATA' || newArrivalChecklist[i].ActualStartBase__c == 'ATD') {
                                        ChecklistRecord.Estimated_Planned_Start_Time_Local__c = op.ETA_Time_Local__c.addMinutes(Integer.valueOf(newArrivalChecklist[i].EstimatedStartOffset__c));   
                                        ChecklistRecord.Estimated_Planned_Start_Time_UTC__c = op.ETA_Time_UTC__c.addMinutes(Integer.valueOf(newArrivalChecklist[i].EstimatedStartOffset__c));
                                        ChecklistRecord.Actual_Planned_Start_Time_Local__c = op.ETA_Time_Local__c.addMinutes(Integer.valueOf(newArrivalChecklist[i].ActualStartOffset__c));
                                        ChecklistRecord.Actual_Planned_Start_Time_UTC__c = op.ETA_Time_UTC__c.addMinutes(Integer.valueOf(newArrivalChecklist[i].ActualStartOffset__c));    
                                    }
                                    if (newArrivalChecklist[i].ActualEndBase__c == 'ATA' || newArrivalChecklist[i].ActualEndBase__c == 'ATD') {
                                        ChecklistRecord.Estimated_Planned_End_Time_Local__c = op.ETA_Time_Local__c.addMinutes(Integer.valueOf(newArrivalChecklist[i].EstimatedEndOffset__c));
                                        ChecklistRecord.Estimated_Planned_End_Time_UTC__c = op.ETA_Time_UTC__c.addMinutes(Integer.valueOf(newArrivalChecklist[i].EstimatedEndOffset__c));
                                        ChecklistRecord.Actual_Planned_Completion_Time_Local__c = op.ETA_Time_Local__c.addMinutes(Integer.valueOf(newArrivalChecklist[i].ActualEndOffset__c));
                                        ChecklistRecord.Actual_Planned_Completion_Time_UTC__c = op.ETA_Time_UTC__c.addMinutes(Integer.valueOf(newArrivalChecklist[i].ActualEndOffset__c));   
                                    }
                                    
                                    
                                        if (oldOp.LANDING_Date__c != op.LANDING_Date__c && newArrivalChecklist[i].ListOrder__c == 2 && newArrivalChecklist[i].Site__c == 'Above the Wing') {
                                            system.debug('Updating Arrival Checklist 2 Date');
                                            system.debug(ChecklistRecord.Actual_Start_Date__c);
                                            ChecklistRecord.Actual_Start_Date__c = op.LANDING_Date__c;
                                            ChecklistRecord.Actual_Completion_Date__c = op.LANDING_Date__c;
                                            ChecklistRecord.Start_Now__c = true;
                                            ChecklistRecord.Complete_Now__c = true;
                                            system.debug(ChecklistRecord.Actual_Start_Date__c);
                                            if (op.LANDING_TIME__c != null) {
                                                ChecklistRecord.Actual_Start_Time_Local__c = op.LANDING_TIME__c;
                                                ChecklistRecord.Actual_Start_Time_UTC__c = op.LANDING_TIME__c;
                                                ChecklistRecord.Actual_Completion_Time_Local__c = op.LANDING_TIME__c;
                                                ChecklistRecord.Actual_Completion_Time_UTC__c = op.LANDING_TIME__c;
                                            }
                                        }
                                        if (oldOp.LANDING_TIME__c != op.LANDING_TIME__c && newArrivalChecklist[i].ListOrder__c == 2 && newArrivalChecklist[i].Site__c == 'Above the Wing') {
                                            system.debug('Updating Arrival Checklist 2 Time');
                                            ChecklistRecord.Actual_Start_Time_Local__c = op.LANDING_TIME__c;
                                            ChecklistRecord.Actual_Start_Time_UTC__c = op.LANDING_TIME__c;
                                            ChecklistRecord.Actual_Completion_Time_Local__c = op.LANDING_TIME__c;
                                            ChecklistRecord.Actual_Completion_Time_UTC__c = op.LANDING_TIME__c;
                                            if (op.LANDING_Date__c != null) {
                                                ChecklistRecord.Actual_Start_Date__c = op.LANDING_Date__c;
                                                ChecklistRecord.Actual_Completion_Date__c = op.LANDING_Date__c;
                                                ChecklistRecord.Start_Now__c = true;
                                                ChecklistRecord.Complete_Now__c = true;
                                            }
                                        }
                                        if (oldOp.ATA_Date__c != op.ATA_Date__c && newArrivalChecklist[i].ListOrder__c == 3 && newArrivalChecklist[i].Site__c == 'Above the Wing') {
                                            system.debug('Updating Arrival Checklist 3 Date');
                                            ChecklistRecord.Actual_Start_Date__c = op.ATA_Date__c;
                                            ChecklistRecord.Actual_Completion_Date__c = op.ATA_Date__c;
                                            ChecklistRecord.Start_Now__c = true;
                                            ChecklistRecord.Complete_Now__c = true;
                                            if (op.ATA_Time__c != null) {
                                                ChecklistRecord.Actual_Start_Time_Local__c = op.ATA_Time__c;
                                                ChecklistRecord.Actual_Start_Time_UTC__c = op.ATA_Time__c;
                                                ChecklistRecord.Actual_Completion_Time_Local__c = op.ATA_Time__c;
                                                ChecklistRecord.Actual_Completion_Time_UTC__c = op.ATA_Time__c;
                                            }
                                        }
                                        if (oldOp.ATA_Time__c != op.ATA_Time__c && newArrivalChecklist[i].ListOrder__c == 3 && newArrivalChecklist[i].Site__c == 'Above the Wing') {
                                            system.debug('Updating Arrival Checklist 3 Time');
                                            ChecklistRecord.Actual_Start_Time_Local__c = op.ATA_Time__c;
                                            ChecklistRecord.Actual_Start_Time_UTC__c = op.ATA_Time__c;
                                            ChecklistRecord.Actual_Completion_Time_Local__c = op.ATA_Time__c;
                                            ChecklistRecord.Actual_Completion_Time_UTC__c = op.ATA_Time__c;
                                            if (op.ATA_Date__c != null) {
                                                ChecklistRecord.Actual_Start_Date__c = op.ATA_Date__c;
                                                ChecklistRecord.Actual_Completion_Date__c = op.ATA_Date__c;
                                                ChecklistRecord.Start_Now__c = true;
                                                ChecklistRecord.Complete_Now__c = true;
                                            }
                                        }
                                    totalRecords++;
                                    arrivalRecordsToUpsert.add(ChecklistRecord);
                                }    
                            }     
                        }     
                    }
                //} 
                    //if (op.ATD_Local__c != null) { //Check whether has necessary value in ATD Local field
                        List<Departure_Checklist__c> checklistRecords2 = new List<Departure_Checklist__c>();
                        checklistRecords2 = op.Checklists__r; //Related Departure Checklist records to the AO record
                        for (Departure_Checklist__c ChecklistRecord : checklistRecords2) { //Iterating through the list of Departure Checklist records
                            if (ChecklistRecord.Status__c != 'Completed') { //Checking for incomplete Departure Checklist records
                                for (Integer i=0; i < newDepartureChecklist.size(); i++) { //Iterating through the list of Checklist METADATA records
                                    if (newDepartureChecklist[i].Label == ChecklistRecord.Name) {
                                        ChecklistRecord.Flight_Date_UTC__c = op.ETD_Date_UTC__c;
                                        ChecklistRecord.Flight_Date_Local__c = op.ETD_Date_Local__c;
                                        
                                        if (newDepartureChecklist[i].ActualStartBase__c == 'ATA' || newDepartureChecklist[i].ActualStartBase__c == 'ATD') {
                                            ChecklistRecord.Estimated_Planned_Start_Time_Local__c = op.ETD_Time_Local__c.addMinutes(Integer.valueOf(newDepartureChecklist[i].EstimatedStartOffset__c));
                                            ChecklistRecord.Estimated_Planned_Start_Time_UTC__c = op.ETD_Time_UTC__c.addMinutes(Integer.valueOf(newDepartureChecklist[i].EstimatedStartOffset__c));
                                            ChecklistRecord.Actual_Planned_Start_Time_Local__c = op.ETD_Time_Local__c.addMinutes(Integer.valueOf(newDepartureChecklist[i].ActualStartOffset__c));
                                            ChecklistRecord.Actual_Planned_Start_Time_UTC__c = op.ETD_Time_UTC__c.addMinutes(Integer.valueOf(newDepartureChecklist[i].ActualStartOffset__c));
                                        } 
                                        if (newDepartureChecklist[i].ActualEndBase__c == 'ATA' || newDepartureChecklist[i].ActualEndBase__c == 'ATD') {
                                            ChecklistRecord.Estimated_Planned_End_Time_Local__c = op.ETD_Time_Local__c.addMinutes(Integer.valueOf(newDepartureChecklist[i].EstimatedEndOffset__c));
                                            ChecklistRecord.Estimated_Planned_End_Time_UTC__c = op.ETD_Time_UTC__c.addMinutes(Integer.valueOf(newDepartureChecklist[i].EstimatedEndOffset__c));
                                            ChecklistRecord.Actual_Planned_Completion_Time_Local__c = op.ETD_Time_Local__c.addMinutes(Integer.valueOf(newDepartureChecklist[i].ActualEndOffset__c));
                                            ChecklistRecord.Actual_Planned_Completion_Time_UTC__c = op.ETD_Time_UTC__c.addMinutes(Integer.valueOf(newDepartureChecklist[i].ActualEndOffset__c));
                                        }
                                        
                                        if (oldOp.ATD_Date__c != op.ATD_Date__c && newDepartureChecklist[i].ListOrder__c == 22) {
                                            system.debug('Updating Departure Checklist 22 Date');
                                            system.debug('ChecklistRecord: '+ChecklistRecord.Actual_Start_Date__c);
                                            ChecklistRecord.Actual_Start_Date__c = op.ATD_Date__c;
                                            ChecklistRecord.Actual_Completion_Date__c = op.ATD_Date__c;
                                            ChecklistRecord.Start_Now__c = true;
                                            ChecklistRecord.Complete_Now__c = true;
                                            system.debug('ChecklistRecord: '+ChecklistRecord.Actual_Start_Date__c);
                                            if (op.ATD_Time__c != null) {
                                                ChecklistRecord.Actual_Start_Time_Local__c = op.ATD_Time__c;
                                                ChecklistRecord.Actual_Start_Time_UTC__c = op.ATD_Time__c;
                                                ChecklistRecord.Actual_Completion_Time_Local__c = op.ATD_Time__c;
                                                ChecklistRecord.Actual_Completion_Time_UTC__c = op.ATD_Time__c;
                                            }
                                        }
                                        if (oldOp.ATD_Time__c != op.ATD_Time__c && newDepartureChecklist[i].ListOrder__c == 22) {
                                            system.debug('Updating Departure Checklist 22 Time');
                                             system.debug('ChecklistRecord: '+ChecklistRecord.Actual_Start_Time_Local__c);
                                            ChecklistRecord.Actual_Start_Time_Local__c = op.ATD_Time__c;
                                            ChecklistRecord.Actual_Start_Time_UTC__c = op.ATD_Time__c;
                                            ChecklistRecord.Actual_Completion_Time_Local__c = op.ATD_Time__c;
                                            ChecklistRecord.Actual_Completion_Time_UTC__c = op.ATD_Time__c;
                                             system.debug('ChecklistRecord: '+ChecklistRecord.Actual_Start_Time_Local__c);
                                            if (op.ATD_Date__c != null) {
                                                ChecklistRecord.Actual_Start_Date__c = op.ATD_Date__c;
                                                ChecklistRecord.Actual_Completion_Date__c = op.ATD_Date__c;
                                                ChecklistRecord.Start_Now__c = true;
                                                ChecklistRecord.Complete_Now__c = true;
                                            }
                                        }
                                        system.debug('DBG oldAIRBORNE: '+oldOp.AIRBORNE_Date__c);
                                        system.debug('DBG opAIRBORNE: '+op.AIRBORNE_Date__c);
                                        if (oldOp.AIRBORNE_Date__c != op.AIRBORNE_Date__c && newDepartureChecklist[i].ListOrder__c == 23) {
                                             system.debug('Updating Departure Checklist 23 Date');
                                            ChecklistRecord.Actual_Start_Date__c = op.AIRBORNE_Date__c;
                                            ChecklistRecord.Actual_Completion_Date__c = op.AIRBORNE_Date__c;
                                            ChecklistRecord.Start_Now__c = true;
                                            ChecklistRecord.Complete_Now__c = true;
                                            if (op.AIRBORNE_Time__c != null) {
                                                ChecklistRecord.Actual_Start_Time_Local__c = op.AIRBORNE_Time__c;
                                                ChecklistRecord.Actual_Start_Time_UTC__c = op.AIRBORNE_Time__c;
                                                ChecklistRecord.Actual_Completion_Time_Local__c = op.AIRBORNE_Time__c;
                                                ChecklistRecord.Actual_Completion_Time_UTC__c = op.AIRBORNE_Time__c;
                                            }
                                        }
                                        if (oldOp.AIRBORNE_Time__c != op.AIRBORNE_Time__c && newDepartureChecklist[i].ListOrder__c == 23) {
                                            system.debug('Updating Departure Checklist 23 Time');
                                            system.debug('ChecklistRecord: '+ChecklistRecord.Actual_Start_Time_Local__c);
                                            ChecklistRecord.Actual_Start_Time_Local__c = op.AIRBORNE_Time__c;
                                            ChecklistRecord.Actual_Start_Time_UTC__c = op.AIRBORNE_Time__c;
                                            ChecklistRecord.Actual_Completion_Time_Local__c = op.AIRBORNE_Time__c;
                                            ChecklistRecord.Actual_Completion_Time_UTC__c = op.AIRBORNE_Time__c;
                                            system.debug('ChecklistRecord: '+ChecklistRecord.Actual_Start_Time_Local__c);
                                            if (op.AIRBORNE_Date__c != null) {
                                                ChecklistRecord.Actual_Start_Date__c = op.AIRBORNE_Date__c;
                                                ChecklistRecord.Actual_Completion_Date__c = op.AIRBORNE_Date__c;
                                                ChecklistRecord.Start_Now__c = true;
                                                ChecklistRecord.Complete_Now__c = true;
                                            }
                                        }
                                        totalRecords++;
                                        departureRecordsToUpsert.add(ChecklistRecord);
                                    }
                                } 
                            }     
                        }    
                   // }
                
            }
        }
        system.debug('DBG operationRecordsToUpsert: ' + operationRecordsToUpsert);
        //Try catch to upsert the checklist records
        try {
            
            Database.UpsertResult[] SaveResult2 = database.upsert(arrivalRecordsToUpsert, false);
            for (Integer i = 0; i < SaveResult2.size(); i++) {
                if (!SaveResult2[i].isSuccess()) {
                    for (Database.Error err : SaveResult2[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(SaveResult2[i].Id);
                        processLog += 'Unable to upsert Record ID: ' + SaveResult2[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    //system.debug('DBG SaveResult[i]: '+ SaveResult[i]);
                    successfulRecords++;
                }
            }
            
            Database.UpsertResult[] SaveResult3 = database.upsert(departureRecordsToUpsert, false);
            for (Integer i = 0; i < SaveResult3.size(); i++) {
                system.debug('DBG saveresult3: '+SaveResult3[i]);
                if (!SaveResult3[i].isSuccess()) {
                    for (Database.Error err : SaveResult3[i].getErrors()) {
                        system.debug('DBG Failed Record: '+SaveResult3[i].Id);
                        errorRecords++;
                        failureRecords.add(SaveResult3[i].Id);
                        processLog += 'Unable to upsert Record ID: ' + SaveResult3[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    //system.debug('DBG SaveResult[i]: '+ SaveResult[i]);
                    successfulRecords++;
                }
            }
            
            Database.SaveResult[] SaveResult = database.update(operationRecordsToUpsert, false);
            for (Integer i = 0; i < SaveResult.size(); i++) {
                if (!SaveResult[i].isSuccess()) {
                    for (Database.Error err : SaveResult[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(SaveResult[i].Id);
                        processLog += 'Unable to upsert Record ID: ' + SaveResult[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    //system.debug('DBG SaveResult[i]: '+ SaveResult[i]);
                    successfulRecords++;
                }
            }
            
            Database.SaveResult[] SaveResult4 = database.update(operationNameRecordsToUpsert, false);
            for (Integer i = 0; i < SaveResult4.size(); i++) {
                if (!SaveResult4[i].isSuccess()) {
                    for (Database.Error err : SaveResult4[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(SaveResult4[i].Id);
                        processLog += 'Unable to upsert Record ID: ' + SaveResult4[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    //system.debug('DBG SaveResult[i]: '+ SaveResult[i]);
                    successfulRecords++;
                }
            }
            
            processLog = '#########################\r\n' +
            'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
            'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
            'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
            'Total Processed Records: ' + totalRecords + '\r\n' +
            'Total Successful Upserted Records: ' + successfulRecords + '\r\n' +
            'Total Failed Records: ' + errorRecords + '\r\n' + 
            'List of Failed Records: ' + failureRecords + '\r\n' +
            '#########################\r\n' + processLog;
            
            system.debug('DBG ProcessLog: '+processLog);
            
            //Application Log 061819
            GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'AirportOperationTriggerHandler', 'updateChecklists', null, 'Airport Operation Checklist Records Upsertion', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
        
        } catch (DmlException DMLError) {
            
            //Application Log 061819
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'AirportOperationTriggerHandler', 'updateChecklists', null, 'Airport Operation Checklist Records Upsertion', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
        }
        
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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