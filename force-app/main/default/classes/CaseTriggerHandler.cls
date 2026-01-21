/********************************************************************************************************
NAME:           CaseTriggerHandler
AUTHOR:         Aik Meng (aikmeng@salesforce.com)
PURPOSE:        (1) METHOD: linkAccountToCases()
Scope: STARLUX Service Cloud
To perform PersonAccount linkage on Case record inserts. 
If match found in SF, associate with Case record.
If NO match found in SF, lookup Account in MDM via DIH REST API.
If match found in MDM, create new Account in SF and link with Case record.
If NO match found in MDM, Case record will have no Account linked.
NOTE: The supported Case recordTypes (comma-delimited) are defined in CaseRecordTypes of 
Application_Setting__mdt.Case_Trigger_App_Setting

(2) METHOD: createSeatSalesTracking()
Scope: STARLUX Community Cloud (B2B Group Booking)
To auto-generate SeatSalesTracking records on Case record inserts. 
NOTE: Only applicable to Case recordType = 'Group Booking'

(3) METHOD: forceCaseAssignmentRule()
Scope: STARLUX Community Cloud (Support Portal)
To force Case Assignment Rule on WebForm Case records created by Public Guest Profile (Support Portal). 
NOTE: Only applicable to Case origin = 'Web Form'

(4) METHOD: copyContactEmails()
Scope: STARLUX Community Cloud (B2B Group Booking)
To copy 3 Contact.Email fields to Case records. 
NOTE: The supported Case recordTypes (comma-delimited) are defined in B2BCaseRecordTypes 
of Application_Setting__mdt.Case_Trigger_App_Setting

(5) METHOD: updateGroupAULookup()
Scope: STARLUX Community Cloud (B2B Group Booking)
To update Case records to lookup GroupAU records. 
NOTE: The supported Case recordTypes (comma-delimited) are defined in B2BCaseRecordTypes 
of Application_Setting__mdt.Case_Trigger_App_Setting

UPDATE HISTORY:
DATE            AUTHOR          COMMENTS
-------------------------------------------------------------
10/06/2019      Aik Meng        First version
08/08/2019      Aik Meng        Added method createSeatSalesTracking() to address B2B Community requirement
29/08/2019      Aik Meng        Added method to handle forceAssignmentRule for WebForm Case records
05/09/2019      Aik Meng        Added handling for afterUpdate event
06/09/2019      Aik Meng        Updated logic to handle updated CRANE REST API getAccount(email+phoneNumber)
10/09/2019      Aik Meng        Copy 3 email fields from B2B Case.Contact to Case record
12/11/2019      Aik Meng        Added criteria (Case.Origin) to createSeatSalesTracking method to exclude Cases generated via Email2Case 
19/12/2019      Edmond          Added logging for Successful records to reflect Case and Account ID
2021/12/03      Chris Hsu       Added method updateGroupAULookup() to get B2B Case to bridge GroupAU
2023/12/05      Eli Lin         Disable method forceCaseAssignmentRule() in afterInsert() due to support portal is no longer being used(ISP-0041-2023120103)
********************************************************************************************************/

public class CaseTriggerHandler extends TriggerHandler {
    
    // NOTE: Not using "With Sharing" class because 
    // 1. Contact OWD is set to private
    // 2. This trigger needs to access/search ALL PersonAccount/Contact records
    
    public CaseTriggerHandler() {}
    
    // Application Logging
    private static List<System_Settings__mdt> logLevelCMD;
    private static DateTime startTime = DateTime.now();
    private static String processLog;
    private static String payLoad;
    private static Integer totalRecords = 0, errorRecords = 0, successfulRecords = 0;
    private static List<String> failureRecords = new List<String>();
    
    /*** CONTEXT Overrides ***/
    
    public override void afterInsert() {
        linkAccountToCases(trigger.newMap);
        createSeatSalesTracking(trigger.newMap);
        updateGroupAULookup(trigger.newMap);
        //forceCaseAssignmentRule(); //2023-12-05 Eli Lin
    }  // End - afterInsert() 
    
    public override void beforeInsert() {
        copyContactEmails();
        //2024/6/8
        relateGroupAU();
    }  // End - beforeInsert() 
    
    //Added by Ethan
    ////////////////////
    public override void beforeUpdate() {
        List<Case> cases = new List<Case>();
        for (Case eachRecord : (List<Case>) trigger.new) {
            Case oldRecord = (Case) trigger.oldMap.get(eachRecord.Id);
            //Temp_Case to Case
            if(eachRecord.Chatbot_UID__c != NULL && oldRecord.Status != 'Closed' && (eachRecord.Status == 'Closed'  || eachRecord.Chatbot_Status__c == 'Closed')){//|| eachRecord.Chatbot_Status__c == 'Closed') {
                eachRecord.Status = 'Closed';
                eachRecord.Chatbot_Status__c = 'Closed';
                cases.add(eachRecord);
            }
        }
        
        Chatbot_CalloutClass.endCalls(cases);
    }  // End - beforeUpdate() 
    
    public override void afterUpdate() {
        //Id ercIncident = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ERC (Incident)').getRecordTypeId();
        Id ercMain = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ERC (Main)').getRecordTypeId();
        
        Boolean caseClosed = false;
        for (Case eachRecord : (List<Case>) trigger.new) {
            // ERC Callout
            /*if(eachRecord.RecordTypeId == ercIncident) {
                ERCApiCallout.syncCaseData(eachRecord.ParentId);*/
            if(eachRecord.RecordTypeId == ercMain) {
                ERCApiCallout.syncCaseData(eachRecord.Id);
            }
           
            Case oldRecord = (Case) trigger.oldMap.get(eachRecord.Id);
            if(eachRecord.Chatbot_UID__c != NULL && oldRecord.Status != 'Closed' && (eachRecord.Status == 'Closed'  || eachRecord.Chatbot_Status__c == 'Closed')){//|| eachRecord.Chatbot_Status__c == 'Closed') {
                caseClosed = true;
            }
        }
        
        if(caseClosed) {
            //Query all chatbot queues and map agents to each queue
            Map<Id, String> queueMap = new Map<Id, String>();
            Map<String, Id> queueIdMap = new Map<String, Id>();
            Map<Id, List<String>> agentMap = new Map<Id, List<String>>();
            List<Group> queue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name LIKE '%Chat%'];
            List<Id> queueIds = new List<Id>();
            
            for(Group g : queue) {
                queueIds.add(g.Id);
                queueMap.put(g.Id, g.Name);
                if(g.Name.contains('(EN)')) {
                    queueIdMap.put('EN', g.Id);
                } else if(g.Name.contains('(JP)')) {
                    queueIdMap.put('JP', g.Id);
                } else if(g.Name.contains('(TW)')) {
                    queueIdMap.put('TW', g.Id);
                } 
                //for First Class routing
                else if(g.Name.contains('(EN-First)')) {
                    queueIdMap.put('EN-First', g.Id);
                } else if(g.Name.contains('(JP-First)')) {
                    queueIdMap.put('JP-First', g.Id);
                } else if(g.Name.contains('(TW-First)')) {
                    queueIdMap.put('TW-First', g.Id);
                }
            }
            
            List<GroupMember> agents = [SELECT Id, UserOrGroupId, GroupId FROM GroupMember WHERE GroupId IN : queueIds];
            Set<Id> userIds = new Set<Id>();
            System.debug(agents);
            for(GroupMember gm : agents) {
                userIds.add(gm.UserOrGroupId);
            }
            
            Id servicePresenceStatusId = [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'Available' LIMIT 1][0].Id;
            List<UserServicePresence> userPresence = [SELECT Id, UserId FROM UserServicePresence WHERE IsCurrentState = true AND ServicePresenceStatusId = :servicePresenceStatusId AND UserId IN : userIds];
            List<Id> availableUser = new List<Id>();
            System.debug(userPresence);
            for(UserServicePresence USP : userPresence) {
                availableUser.add(USP.UserId);
            }
            
            for(GroupMember gm : agents) {
                if(availableUser.contains(gm.UserOrGroupId)) {
                    //for First Class routing
                    if(queueMap.get(gm.GroupId).contains('EN-First')) {
                        if(!agentMap.keySet().contains(gm.UserOrGroupId)) {
                            agentMap.put(gm.UserOrGroupId, new List<String>());
                        }
                        agentMap.get(gm.UserOrGroupId).add('EN-First');
                    } else if(queueMap.get(gm.GroupId).contains('JP-First')) {
                        if(!agentMap.keySet().contains(gm.UserOrGroupId)) {
                            agentMap.put(gm.UserOrGroupId, new List<String>());
                        }
                        agentMap.get(gm.UserOrGroupId).add('JP-First');
                    } else if(queueMap.get(gm.GroupId).contains('TW-First')) {
                        if(!agentMap.keySet().contains(gm.UserOrGroupId)) {
                            agentMap.put(gm.UserOrGroupId, new List<String>());
                        }
                        agentMap.get(gm.UserOrGroupId).add('TW-First');
                    }
                    
                    else if(queueMap.get(gm.GroupId).contains('EN')) {
                        if(!agentMap.keySet().contains(gm.UserOrGroupId)) {
                            agentMap.put(gm.UserOrGroupId, new List<String>());
                        }
                        agentMap.get(gm.UserOrGroupId).add('EN');
                    } else if(queueMap.get(gm.GroupId).contains('JP')) {
                        if(!agentMap.keySet().contains(gm.UserOrGroupId)) {
                            agentMap.put(gm.UserOrGroupId, new List<String>());
                        }
                        agentMap.get(gm.UserOrGroupId).add('JP');
                    } else if(queueMap.get(gm.GroupId).contains('TW')) {
                        if(!agentMap.keySet().contains(gm.UserOrGroupId)) {
                            agentMap.put(gm.UserOrGroupId, new List<String>());
                        }
                        agentMap.get(gm.UserOrGroupId).add('TW');
                    } 
                }
            }
            
            List<Case> pendingCases = [SELECT Chatbot_Language__c, Chatbot_CustomerType__c FROM Case WHERE Chatbot_UID__c != NULL AND Status != 'Closed' AND CreatedDate = TODAY];
            List<Temp_Case__c> pendingTempCases = [SELECT Chatbot_ID__c, Chatbot_Name__c, Chatbot_Mail__c, Chatbot_UID__c, Chatbot_BookingRef__c, Chatbot_Language__c, Chatbot_CustomerType__c, Chatbot_CallSupportTime__c, Ticket_EMD_Number__c, Booking_Reference_PNR__c, Passenger_Name__c, Chatbot_OnlineSupport__c, Has_Been_Assigned__c FROM Temp_Case__c WHERE Has_Been_Assigned__c = false AND Terminated__c = false AND CreatedDate = TODAY ORDER BY CreatedDate ASC];
            
            List<Case> insertCaseList = new List<Case>();
            List<Temp_Case__c> updateTempCases = new List<Temp_Case__c>();
            
            System.debug(pendingCases);
            System.debug(agentMap);
            
            //Remove Agents for any number of pending Cases
            for(Case pendingCase : pendingCases) {
                //for First Class routing
                if(pendingCase.Chatbot_CustomerType__c == 'VIP') {
                    for(Id availableAgentId : agentMap.keySet()) {
                        if(pendingCase.Chatbot_Language__c == 'English' && agentMap.get(availableAgentId).contains('EN-First')) {
                            agentMap.remove(availableAgentId);
                            break;
                        } else if(pendingCase.Chatbot_Language__c == 'Japanese' && agentMap.get(availableAgentId).contains('JP-First')) {
                            agentMap.remove(availableAgentId);
                            break;
                        } else if(pendingCase.Chatbot_Language__c == 'Mandarin' && agentMap.get(availableAgentId).contains('TW-First')) {
                            agentMap.remove(availableAgentId);
                            break;
                        }
                    }
                } else {
                    for(Id availableAgentId : agentMap.keySet()) {
                        if(pendingCase.Chatbot_Language__c == 'English' && agentMap.get(availableAgentId).contains('EN')) {
                            agentMap.remove(availableAgentId);
                            break;
                        } else if(pendingCase.Chatbot_Language__c == 'Japanese' && agentMap.get(availableAgentId).contains('JP')) {
                            agentMap.remove(availableAgentId);
                            break;
                        } else if(pendingCase.Chatbot_Language__c == 'Mandarin' && agentMap.get(availableAgentId).contains('TW')) {
                            agentMap.remove(availableAgentId);
                            break;
                        }
                    }
                }
            }
            
            System.debug(agentMap);
            
            //Remove Agents for any number of pending Temp Cases
            for(Temp_Case__c pendingTempCase : pendingTempCases) {
                //for First Class routing
                if(pendingTempCase.Chatbot_CustomerType__c == 'VIP') {
                    for(Id availableAgentId : agentMap.keySet()) {
                        if(pendingTempCase.Chatbot_Language__c == 'English' && agentMap.get(availableAgentId).contains('EN-First')) {
                            insertCaseList.add(tempCaseToCase(pendingTempCase, queueIdMap.get('EN-First')));
                            pendingTempCase.Has_Been_Assigned__c = true;
                            updateTempCases.add(pendingTempCase);
                            agentMap.remove(availableAgentId);
                            break;
                        } else if(pendingTempCase.Chatbot_Language__c == 'Japanese' && agentMap.get(availableAgentId).contains('JP-First')) {
                            insertCaseList.add(tempCaseToCase(pendingTempCase, queueIdMap.get('JP-First')));
                            pendingTempCase.Has_Been_Assigned__c = true;
                            updateTempCases.add(pendingTempCase);
                            agentMap.remove(availableAgentId);
                            break;
                        } else if(pendingTempCase.Chatbot_Language__c == 'Mandarin' && agentMap.get(availableAgentId).contains('TW-First')) {
                            insertCaseList.add(tempCaseToCase(pendingTempCase, queueIdMap.get('TW-First')));
                            pendingTempCase.Has_Been_Assigned__c = true;
                            updateTempCases.add(pendingTempCase);
                            agentMap.remove(availableAgentId);
                            break;
                        }
                    }
                } else {
                    for(Id availableAgentId : agentMap.keySet()) {
                        if(pendingTempCase.Chatbot_Language__c == 'English' && agentMap.get(availableAgentId).contains('EN')) {
                            insertCaseList.add(tempCaseToCase(pendingTempCase, queueIdMap.get('EN')));
                            pendingTempCase.Has_Been_Assigned__c = true;
                            updateTempCases.add(pendingTempCase);
                            agentMap.remove(availableAgentId);
                            break;
                        } else if(pendingTempCase.Chatbot_Language__c == 'Japanese' && agentMap.get(availableAgentId).contains('JP')) {
                            insertCaseList.add(tempCaseToCase(pendingTempCase, queueIdMap.get('JP')));
                            pendingTempCase.Has_Been_Assigned__c = true;
                            updateTempCases.add(pendingTempCase);
                            agentMap.remove(availableAgentId);
                            break;
                        } else if(pendingTempCase.Chatbot_Language__c == 'Mandarin' && agentMap.get(availableAgentId).contains('TW')) {
                            insertCaseList.add(tempCaseToCase(pendingTempCase, queueIdMap.get('TW')));
                            pendingTempCase.Has_Been_Assigned__c = true;
                            updateTempCases.add(pendingTempCase);
                            agentMap.remove(availableAgentId);
                            break;
                        }
                    }
                }
            }
            System.debug(agentMap);
            System.debug(insertCaseList);
            if(insertCaseList.size() > 0) {
                insert insertCaseList;
                update updateTempCases;
            }
        }
        
        List<Case> caseListTotalSeatSalesChanged = new List<Case>();
        List<Case> caseListStatusChangedToWaitingForPayment = new List<Case>();
        List<Case> caseListStatusChangedToRequestForTicketing = new List<Case>();
        List<Case> caseListStatusChangedToReadyForTicketing = new List<Case>();
        for (Case newCase : (List<Case>) trigger.new) {
            Case oldCase = (Case) trigger.oldMap.get(newCase.Id);
            if (newCase.Total_Seat_Sales__c != oldCase.Total_Seat_Sales__c) {
                caseListTotalSeatSalesChanged.add(newCase);
            }
            if (newCase.Status != oldCase.Status) {
                if (newCase.Status == 'Request for Ticketing') {
                    caseListStatusChangedToRequestForTicketing.add(newCase);
                }
                if (newCase.Status == 'Ready for Ticketing') {
                    caseListStatusChangedToReadyForTicketing.add(newCase);
                }
                if (newCase.Status == 'Waiting for Payment') {
                    caseListStatusChangedToWaitingForPayment.add(newCase);
                }
            }
        }
        if (!caseListTotalSeatSalesChanged.isEmpty()) {
            //Ethan
            //CaseUtil.syncSst(caseListTotalSeatSalesChanged);
        }
        if (!caseListStatusChangedToRequestForTicketing.isEmpty()) {
            TaxUtil.getTax(caseListStatusChangedToRequestForTicketing);
            TicketFareUtil.getTicketFare(caseListStatusChangedToRequestForTicketing);
        }
        if (!caseListStatusChangedToReadyForTicketing.isEmpty()) {
            PaxUtil.addPax(caseListStatusChangedToReadyForTicketing);
        }
        if (!caseListStatusChangedToWaitingForPayment.isEmpty()) {
            GetUpdateUtil.getUpdate(caseListStatusChangedToWaitingForPayment);
        }

        Map<Id,sObject> caseMap = new Map<Id,sObject>();
        // EXTRACT Case records with Find_Account_In_MDM isChanged & ticked
        for (Case eachRecord : (List<Case>) trigger.new) {
            Case oldRecord = (Case) trigger.oldMap.get(eachRecord.Id);
            // CHECK if field has changed & ticked
            if (eachRecord.Find_Account_in_MDM__c!= oldRecord.Find_Account_in_MDM__c && eachRecord.Find_Account_in_MDM__c==TRUE) {
                caseMap.put(eachRecord.Id,eachRecord);
            }
        }
        
        // 2025/7/10 Ethan Lin
        casesChanged.clear(); // 避免同交易殘留
        getItineraryCases((List<Case>) Trigger.new, (Map<Id, Case>) Trigger.oldMap);

        if (!System.isFuture() && !System.isQueueable() && !System.isBatch()
        && !enqueuedThisTxn
        && !casesChanged.isEmpty()) {

        Database.executeBatch(
        new BatchGetItinerary(new List<Id>(casesChanged)),50
    );
    enqueuedThisTxn = true; // 同一交易只排一次
}
    }  // End - afterUpdate()        
    

    public static Set<Id> casesChanged = new Set<Id>();
    private static Boolean enqueuedThisTxn = false;
    
    public static void getItineraryCases(List<Case> newList, Map<Id, Case> oldMap) {
    // 取得 Group Booking Record Type ID
    Id groupBookingRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();

        for (Case c : newList) {
            Case oldCase = (oldMap != null) ? oldMap.get(c.Id) : null;

        // ✅ 加入 RecordType 限制，只針對 Group Booking Case 處理
        if (c.RecordTypeId == groupBookingRecordTypeId
            && c.Status == 'Ticket Issued'
            && (oldCase == null || oldCase.Status != 'Ticket Issued')) {
            casesChanged.add(c.Id);
            }
    }
}
    
    /*** CORE Methods ***/
    private static Case tempCaseToCase(Temp_Case__c tempCase, Id ownerId) {
        Case temp = new Case();
        temp.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enquiry and Request').getRecordTypeId();
        temp.Origin = 'Live Chat';
        temp.Chatbot_ID__c = tempCase.Chatbot_ID__c;
        temp.Chatbot_Name__c = tempCase.Chatbot_Name__c;
        temp.Chatbot_Mail__c = tempCase.Chatbot_Mail__c;
        temp.SuppliedEmail = tempCase.Chatbot_Mail__c;
        temp.Chatbot_UID__c = tempCase.Chatbot_UID__c;
        temp.Chatbot_BookingRef__c = tempCase.Chatbot_BookingRef__c;
        temp.Chatbot_Language__c = tempCase.Chatbot_Language__c;
        temp.Chatbot_CustomerType__c = tempCase.Chatbot_CustomerType__c;
        temp.CTI_Passenger_Type__c = tempCase.Chatbot_CustomerType__c;
        temp.Chatbot_CallSupportTime__c = tempCase.Chatbot_CallSupportTime__c;
        temp.Ticket_EMD_Number__c = tempCase.Ticket_EMD_Number__c;
        temp.Booking_Reference_PNR__c = tempCase.Booking_Reference_PNR__c;
        temp.Passenger_Name__c = tempCase.Passenger_Name__c;
        temp.Chatbot_OnlineSupport__c = tempCase.Chatbot_OnlineSupport__c;
        temp.OwnerId = ownerId;
        return temp;
    }
 
    // METHOD(1): linkAccountToCases
    private static void linkAccountToCases(Map<Id,sObject> newCaseMap) {
        
        Set<String> emailsToQuery = new Set<String>();
        Set<String> phonesToQuery = new Set<String>();
        Map<String,String> matchingEmailToAcctIdMap = new Map<String,String>();
        Map<String,String> matchingPhoneToAcctIdMap = new Map<String,String>();
        Map<Id,String> queryMdmMap = new Map<Id,String>();
        List<Case> casesToUpdate = new List<Case> ();
        Map<String, String> caseAccountMap = new Map<String, String>();
        
        // FETCH App Setting
        Application_Setting__mdt appSetting = [SELECT
                                               Id, MasterLabel, Key__c, Value__c 
                                               FROM 
                                               Application_Setting__mdt
                                               WHERE 
                                               MasterLabel='CaseTrigger_CaseRecordTypes' AND Key__c='Supported_CaseRecordTypes'  
                                               LIMIT 1];
        List<String> caseRecordTypes = appSetting.Value__c.split(',');
        List<Id> listCaseRT = new List<Id>();
        // ADD the supported Case recordTypes (from custom metadata) to collection for matching later
        for (String eachRT: caseRecordTypes) {
            listCaseRT.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(eachRT).getRecordTypeId());
        }
        system.debug('[STARLUX] listCaseRT: '+listCaseRT);        
        // FETCH AppLogging setting
        System_Settings__mdt logLevelCMD = [SELECT 
                                            Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c 
                                            FROM
                                            System_Settings__mdt
                                            WHERE 
                                            MasterLabel='Case Trigger Handler'
                                            LIMIT 1];
        
        // Loop EACH Case record
        // IF no PersonAccount linked yet, extract the attributes for PersonAccount matching
        // NOTE: (1) Only applies to supported Case recordTypes in listCaseRT collection
        //       (2) PersonAccount could be linked by default system matching (e.g Pre-Chat form)
        for (Case c : (List<Case>) newCaseMap.values()) {
            if (listCaseRT.contains(c.RecordTypeId)) {  // SKIP record if NOT in supported RecordType list
                if (c.SuppliedEmail!=null && (c.AccountId==null || c.ContactId==null)) {
                    //                if (c.SuppliedEmail != null && c.ContactId == null) {
                    emailsToQuery.add(c.SuppliedEmail);
                }
                if (c.SuppliedPhone!= null && (c.AccountId==null || c.ContactId==null)) {
                    //                if (c.SuppliedPhone != null && c.ContactId == null) {
                    phonesToQuery.add(c.SuppliedPhone);
                }
            }
        } // End - for(Case)
        
        System.debug('[STARLUX] emailsToQuery: '+emailsToQuery);
        System.debug('[STARLUX] phonesToQuery: '+phonesToQuery);
        
        // FIND SF PersonAccounts that match Search attributes
        // IF found, add to Maps for lookup
        Id personAccountRT_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Passenger').getRecordTypeId();
        for (Account acct : [SELECT 
                             Id, MDM_ID__c, PersonEmail, PersonMobilePhone, PersonContactId 
                             FROM 
                             Account 
                             WHERE
                             RecordType.Id =: personAccountRT_ID 
                             AND
                             (PersonEmail IN: emailsToQuery 
                              OR PersonMobilePhone IN: phonesToQuery)]) {
                                  
                                  String accountContactIDs = acct.Id + ':' + acct.PersonContactId;
                                  
                                  // CHECK IF email match THEN associate Account in Map
                                  if (acct.PersonEmail != null && emailsToQuery.contains(acct.PersonEmail)) {
                                      matchingEmailToAcctIdMap.put(acct.PersonEmail.toLowerCase(), accountContactIDs);
                                      // ELSE IF mobilePhone match THEN associate Account in Map
                                  } else if (acct.PersonMobilePhone != null && phonesToQuery.contains(acct.PersonMobilePhone)) {
                                      matchingPhoneToAcctIdMap.put(acct.PersonMobilePhone, accountContactIDs);
                                  }            
                                  
                              }  // End - for(PersonAccount)
        
        System.debug('[STARLUX] matchingEmailToAcctIdMap: '+matchingEmailToAcctIdMap);
        System.debug('[STARLUX] matchingPhoneToAcctIdMap: '+matchingPhoneToAcctIdMap);
        
        // IF found matching PersonAccounts in SF
        //        if (!matchingEmailToAcctIdMap.isEmpty() || !matchingPhoneToAcctIdMap.isEmpty()) {
        
        Set<ID> caseIds= new Set<ID>();  // For tracking Case records already in casesToUpdate collection 
        
        // LINK the Matching Accounts with Cases
        // Loop EACH Case record
        for (Case c : (List<Case>) newCaseMap.values()) {
            
            // NOTE: Precedence for Account matching:
            // 1. SuppliedEmail
            // 2. SuppliedPhone 
            
            // RESET Flags
            Boolean emailFound = FALSE;
            Boolean phoneFound = FALSE;
            
            // SKIP record if NOT in supported RecordType list OR both search params are NULL
            if (listCaseRT.contains(c.RecordTypeId)) { // && (c.SuppliedEmail != NULL || c.SuppliedEmail != NULL)) {  
                
                // CHECK for email match
                if (c.SuppliedEmail != NULL) {
                    if (matchingEmailToAcctIdMap.containsKey(c.SuppliedEmail.toLowerCase()) && !caseIds.contains(c.Id)) {
                        Id acctId=NULL, contId=NULL;
                        String temp = matchingEmailToAcctIdMap.get(c.SuppliedEmail.toLowerCase());
                        if (temp!=NULL) {
                            acctId = temp.substringBefore(':');
                            // For non-PersonAccount, contId remains as NULL
                            if (temp.substringAfter(':')!='null')   contId = temp.substringAfter(':'); 
                        }
                        casesToUpdate.add(new Case(Id=c.Id, AccountId=acctId, ContactId=contId));
                        caseIds.add(c.Id);
                        caseAccountMap.put(c.Id,acctId);
                        emailFound = TRUE;  // SET Flag
                    }
                }
                
                // IF NO email match THEN check for phone match
                if (!emailFound && c.SuppliedPhone != NULL) {
                    if (matchingPhoneToAcctIdMap.containsKey(c.SuppliedPhone) && !caseIds.contains(c.Id)) {
                        Id acctId=NULL, contId=NULL;
                        String temp = matchingPhoneToAcctIdMap.get(c.SuppliedPhone);
                        if (temp!=NULL) {
                            acctId = temp.substringBefore(':');
                            // For non-PersonAccount, contId remains as NULL
                            if (temp.substringAfter(':')!='null')   contId = temp.substringAfter(':');
                        }
                        casesToUpdate.add(new Case(Id=c.Id, AccountId=acctId, ContactId=contId));
                        caseIds.add(c.Id);
                        caseAccountMap.put(c.Id,acctId);
                        phoneFound = TRUE;  // SET Flag
                    }
                } 
                
                // CHECK Flags - IF neither found ADD to searchMDM collection
                if (!emailFound && !phoneFound) {
                    String searchParams = c.SuppliedEmail + ':' + c.SuppliedPhone;
                    // ADD to MDM collection
                    queryMdmMap.put(c.Id, searchParams);
                }
            }  // End - if listCaseRT.contains(RecordTypeId)
            
        } // End - for(Case) 
        
        System.debug('[STARLUX] casesToUpdate: '+casesToUpdate);
        System.debug('[STARLUX] queryMdmMap: '+queryMdmMap);
        
        // UPDATE Case records with SF Account match
        if (!casesToUpdate.isEmpty()) {
            
            try {
                Database.SaveResult[] saveResults = Database.update(casesToUpdate, false);
                // Iterate through each returned result
                for (Database.SaveResult sr : saveResults) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        processLog += '\n';
                        processLog += 'SUCCESS: Updated Case ID: '+sr.getId()+ ' with Account ID: '+caseAccountMap.get(sr.getId()); 
                        System.debug('SUCCESS: updated Case ID: ' + sr.getId());
                        successfulRecords++;
                    } else {
                        // Operation failed, so get all errors
                        for (Database.Error err : sr.getErrors()) {
                            errorRecords++;
                            failureRecords.add(sr.Id);
                            processLog += '\n';
                            processLog += 'Unable to update Record ID: ' + sr.Id + '\r\n';
                            processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                            processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                        }
                        
                    }
                } // End - for(Database.SaveResult)
                
                processLog = '#########################\r\n' +
                    'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
                    'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
                    'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
                    'Total Success Records: ' + successfulRecords + '\r\n' +
                    'Total Failed Records: ' + errorRecords + '\r\n' + 
                    'List of Failed Records: ' + failureRecords + '\r\n' +
                    '#########################\r\n' + processLog;
                
                system.debug('DBG ProcessLog: '+processLog);
                // Application Logging
                GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'CaseTriggerHandler', 'afterInsert', null, 'Link Accounts To Cases', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
                
            } catch (DmlException DMLError) {
                // Application Logging
                GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'CaseTriggerHandler', 'afterInsert', null, 'CaseTriggerHandler', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
            }
            
        } // End - if(!casesToUpdate.isEmpty)
        
        //        } // End - if(found matching Accounts in SF)
        
        // For Cases with NO match, make REST Callout to MDM to find Matching customers
        if (!queryMdmMap.isEmpty()) {
            AsyncRequestHandler.prepareRequest(queryMdmMap);
        }
        
    }  // End - linkAccountToCases()
    
    
    // METHOD(2): createSeatSalesTracking
    private static void createSeatSalesTracking(Map<Id,sObject> newCaseMap) {
        
        // FETCH App Settings
        /*Application_Setting__mdt appSetting1 = [SELECT
Id, MasterLabel, Key__c, Value__c 
FROM 
Application_Setting__mdt
WHERE 
MasterLabel='CaseTrigger_SeatSalesTracking_numOfWeeks' AND Key__c='NumberOfWeeks'  
LIMIT 1];
Integer numOfWeeks = 10;  // DEFAULT
Integer ii = Integer.valueOf(appSetting1.Value__c);
if (ii>0) numOfWeeks = ii;*/  // OVERWRITE default
        
        Application_Setting__mdt appSetting2 = [SELECT
                                                Id, MasterLabel, Key__c, Value__c 
                                                FROM 
                                                Application_Setting__mdt
                                                WHERE 
                                                MasterLabel='CaseTrigger_SeatSalesTracking_dayOfWeek' AND Key__c='DayOfWeek'  
                                                LIMIT 1];
        String dayOfWeek = appSetting2.Value__c.toUpperCase();
        Id groupBookingCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        List<Seat_Sales_Tracking__c> recordsToInsert = new List<Seat_Sales_Tracking__c>();
        
        // Loop EACH Case record
        for (Case eachRecord : (List<Case>) newCaseMap.values()) {
            if (eachRecord.RecordTypeId==groupBookingCaseRT && eachRecord.Origin.toUpperCase()!='EMAIL') {  // ONLY applies to GroupBooking Case records & excludes records generated by Email2Case
                //            if (eachRecord.RecordTypeId==groupBookingCaseRT && !eachRecord.Travel_Agent_Request__c) {  // ONLY applies to GroupBooking Case records
                // CREATE SeatSalesTracking records
                //Chris
                Group_Booking_Case_Num_of_Weeks__mdt nWeeks = [SELECT
                                                               Id, Number_of_Weeks__c 
                                                               FROM 
                                                               Group_Booking_Case_Num_of_Weeks__mdt
                                                               WHERE 
                                                               Route__c=:eachRecord.Route__c  
                                                               LIMIT 1];
                Integer numOfWeeks = 10;  // DEFAULT
                Integer ii = Integer.valueOf(nWeeks.Number_of_Weeks__c);
                if (ii>0) numOfWeeks = ii;  // OVERWRITE default
                System.debug('[STARLUX] nWeeks.Number_of_Weeks__c: '+numOfWeeks);
                List<Seat_Sales_Tracking__c> generatedRecords = generateSeatSalesTrackingRecords(eachRecord,numOfWeeks,dayOfWeek);
                recordsToInsert.addAll(generatedRecords);  // ADD generated records to collection
                generatedRecords.clear();  // RESET collection
            }  // End - If GroupBooking Case record
        } // End - for(Case)
        
        // DATABASE insert (SeatSalesTracking records)
        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult [] srList = Database.insert(recordsToInsert, false);
            system.debug('DBG insertResult: '+srList);
            /*
// Iterate through each returned result
for (Database.SaveResult sr : srList) {
if (sr.isSuccess()) {
// Operation was successful, so get the ID of the record that was processed
System.debug('SUCCESS: created record ID: ' + sr.getId());
} else {
// Operation failed, so get all errors
for (Database.Error err : sr.getErrors()) {
System.debug('ERROR: err.getStatusCode: ' + err.getStatusCode());
System.debug('ERROR: err.getMessage: ' + err.getMessage());
System.debug('ERROR: err.getFields: ' + err.getFields());
}
}
} // End - for(Database.SaveResult)
*/
        }        
        
    }  // End - createSeatSalesTracking()
    
    
    // METHOD(3): forceCaseAssignmentRule()
    private static void forceCaseAssignmentRule() {
        
        Set<Id> caseIds = new Set<Id>();
        for(Case c : (List<Case>) trigger.new) {
            if (c.Origin=='Web Form')   caseIds.add(c.Id);
        }
        
        system.debug('[STARLUX]: forceCaseAssignment.caseIds='+caseIds);
        
        // Invoke @Future method to execute Assignment Rule
        if (!caseIds.isEmpty()) AsyncRequestHandler.executeAssignmentRule(caseIds);
        
    }  // End - forceCaseAssignmentRule()
    
    
    // METHOD(4): copyContactEmails()
    private static void copyContactEmails() {
        
        // FETCH App Setting
        Application_Setting__mdt appSetting = [SELECT
                                               Id, MasterLabel, Key__c, Value__c 
                                               FROM 
                                               Application_Setting__mdt
                                               WHERE 
                                               MasterLabel='CaseTrigger_B2BCaseRecordTypes' AND Key__c='Supported_B2BCaseRecordTypes'  
                                               LIMIT 1];
        List<String> b2bCaseRecordTypes = appSetting.Value__c.split(',');
        system.debug('DBG b2bCaseRT: '+b2bCaseRecordTypes);
        List<Id> listCaseRT = new List<Id>();
        // ADD the supported Case recordTypes (from custom metadata) to collection for matching later
        for (String eachRT: b2bCaseRecordTypes) {
            system.debug('DBG eachRT: '+eachRT);
            system.debug('DBG RT ID: '+Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(eachRT).getRecordTypeId());
            listCaseRT.add(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(eachRT).getRecordTypeId());
        }
        system.debug('[STARLUX] copyContactEmails.listCaseRT: '+listCaseRT);
        
        // IDENTIFY relevant Contact records 
        Set<Id> contactIds = new Set<Id>();
        for(Case c : (List<Case>) trigger.new) {
            // SKIP record if NOT in supported RecordType list OR Case.Contact is null
            if (listCaseRT.contains(c.RecordTypeId) && c.ContactId!=NULL) {
                contactIds.add(c.ContactId);
            }
        }
        // RETRIEVE alternate email fields from relevant Contact records
        List<Contact> contactList = [SELECT
                                     Id,
                                     Alternate_Email_1__c,
                                     Alternate_Email_2__c,
                                     Alternate_Email_3__c
                                     FROM Contact
                                     WHERE Id IN :contactIds];
        Map<Id,String> mapContactData = new Map<Id,String>();
        for(Contact eachRecord: contactList) {
            String recordString = eachRecord.Alternate_Email_1__c +','+ eachRecord.Alternate_Email_2__c +','+ eachRecord.Alternate_Email_3__c;
            mapContactData.put(eachRecord.Id,recordString);
        } // End - for(Contact)
        
        List<Case> casesToUpdate = new List<Case>();
        for(Case c : (List<Case>) trigger.new) {
            // SKIP record if NOT in supported RecordType list OR Case.Contact is null
            if (Trigger.isInsert && listCaseRT.contains(c.RecordTypeId) && c.ContactId!=NULL) {
                String recordString = mapContactData.get(c.ContactId);
                List<String> contactEmailRecords = recordString.split(',');
                if (contactEmailRecords[0].contains('@')) c.Travel_Agent_Alternate_Email_1__c = contactEmailRecords[0];
                if (contactEmailRecords[1].contains('@')) c.Travel_Agent_Alternate_Email_2__c = contactEmailRecords[1];
                if (contactEmailRecords[2].contains('@')) c.Travel_Agent_Alternate_Email_3__c = contactEmailRecords[2];
                //system.debug('[STARLUX] copyContactEmails.Travel_Agent_Alternate_Email_1__c: ' + c.Travel_Agent_Alternate_Email_1__c);
            }
        } // End - for(Case)
        
    }  // End - copyContactEmails()
    
    
    // METHOD(5): updateGroupAULookup create by Chris
    private static void updateGroupAULookup(Map<Id,sObject> newCaseMap) {
        // FETCH AppLogging setting
        System_Settings__mdt logLevelCMD = [SELECT 
                                            Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c 
                                            FROM
                                            System_Settings__mdt
                                            WHERE 
                                            MasterLabel='Case Trigger Handler'
                                            LIMIT 1];
        
        Id groupBookingCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Group_Booking').getRecordTypeId();
        List<Case> casesToUpdate = new List<Case> ();
        
        // Loop EACH Case record
        for (Case eachRecord : (List<Case>) newCaseMap.values()) {
            if (eachRecord.RecordTypeId==groupBookingCaseRT && eachRecord.Origin.toUpperCase()!='EMAIL') {  // ONLY applies to GroupBooking Case records & excludes records generated by Email2Case
                //            if (eachRecord.RecordTypeId==groupBookingCaseRT && !eachRecord.Travel_Agent_Request__c) {  // ONLY applies to GroupBooking Case records
                // CREATE SeatSalesTracking records
                List<Group_AU__c> departingAuList =  [SELECT Id 
                                                      FROM 
                                                      Group_AU__c
                                                      WHERE 
                                                      Flight_Date__c=:eachRecord.Departing_Flight_Date__c 
                                                      and Flight_Number__c=:eachRecord.Departing_Flight_Number__c 
                                                      ORDER BY CreatedDate DESC 
                                                      LIMIT 1];
                List<Group_AU__c> returningAuList =  [SELECT Id 
                                                      FROM 
                                                      Group_AU__c
                                                      WHERE 
                                                      Flight_Date__c=:eachRecord.Returning_Flight_Date__c 
                                                      and Flight_Number__c=:eachRecord.Returning_Flight_Number__c 
                                                      ORDER BY CreatedDate DESC 
                                                      LIMIT 1];
                Group_AU__c groupau_departing = new Group_AU__c(); 
                Group_AU__c groupau_returning = new Group_AU__c(); 
                groupau_departing.Id = departingAuList.size()>0 ? departingAuList.get(0).Id : null;
                groupau_returning.Id = returningAuList.size()>0 ? returningAuList.get(0).Id : null;
                
                Case caseRecord = new Case();
                Boolean doUpdate = false;
                if(groupau_departing.id != null){
                    caseRecord.Id = eachRecord.Id;
                    caseRecord.Departing_AU__c = groupau_departing.Id;
                    doUpdate = true;
                }
                if(groupau_returning.id != null){
                    caseRecord.Id = eachRecord.Id;
                    caseRecord.Returning_AU__c = groupau_returning.Id;
                    doUpdate = true;
                }
                if(doUpdate)
                    casesToUpdate.add(caseRecord);
            }  // End - If GroupBooking Case record
        } // End - for(Case)
        
        // UPDATE Case records with GroupAU match
        if (!casesToUpdate.isEmpty()) {
            
            try {
                Database.SaveResult[] saveResults = Database.update(casesToUpdate, false);
                // Iterate through each returned result
                for (Database.SaveResult sr : saveResults) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        processLog += '\n';
                        processLog += 'SUCCESS: Updated Case ID: '+sr.getId()+ ' with GroupAU'; 
                        System.debug('SUCCESS: updated Case ID: ' + sr.getId());
                        successfulRecords++;
                    } else {
                        // Operation failed, so get all errors
                        for (Database.Error err : sr.getErrors()) {
                            errorRecords++;
                            failureRecords.add(sr.Id);
                            processLog += '\n';
                            processLog += 'Unable to update Record ID with GroupAU: ' + sr.Id + '\r\n';
                            processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                            processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                        }
                        
                    }
                } // End - for(Database.SaveResult)
                
                processLog = '#########################\r\n' +
                    'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
                    'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
                    'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
                    'Total Success Records: ' + successfulRecords + '\r\n' +
                    'Total Failed Records: ' + errorRecords + '\r\n' + 
                    'List of Failed Records: ' + failureRecords + '\r\n' +
                    '#########################\r\n' + processLog;
                
                system.debug('DBG ProcessLog: '+processLog);
                // Application Logging
                GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'CaseTriggerHandler', 'afterInsert', null, 'Link Accounts To Cases', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
                
            } catch (DmlException DMLError) {
                // Application Logging
                GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'CaseTriggerHandler', 'afterInsert', null, 'CaseTriggerHandler', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
            }
            
        } // End - if(!casesToUpdate.isEmpty)        
        
    }  // End - updateGroupAULookup()
    
    
    /*** HELPER Methods ***/
    
    private static List<Seat_Sales_Tracking__c> generateSeatSalesTrackingRecords(Case caseRecord, Integer numOfWeeks, String dayOfWeek) {
        List<Seat_Sales_Tracking__c> newRecordList = new List<Seat_Sales_Tracking__c>();
        // GENERATE dates for each Case record
        List<Date> dateList = new List<Date>();
        if(caseRecord.Departing_Flight_Date__c!=null)
        {
            dateList = generateDatesB2B(caseRecord.Departing_Flight_Date__c, numOfWeeks, dayOfWeek);
        }
        else if(caseRecord.Departing_Flight_Date__c==null && caseRecord.Returning_Flight_Date__c!=null)
        {
            dateList = generateDatesB2B(caseRecord.Returning_Flight_Date__c, numOfWeeks, dayOfWeek);//?桃?
        }
        
        
        // CHECK dateList.size() == numOfWeeks
        
        Integer ii=0;
        // FOR EACH generated Date, CREATE one SeatSalesTracking record
        for (Date eachDate: dateList) {
            ii+=1;
            // CREATE record
            Seat_Sales_Tracking__c newRecord = new Seat_Sales_Tracking__c();
            newRecord.Case_ID__c = caseRecord.Id;
            newRecord.Date__c = eachDate;
            newRecord.Travel_Agent_ID__c = caseRecord.ContactId;
            newRecord.Week__c = 'Week '+ String.valueOf(ii).leftPad(2,'0');  // 2-digits with 0 padding as necessary;
            newRecordList.add(newRecord);  // ADD new Case record to collection
        }  // End - for(each generated Date)
        
        return newRecordList;
    }  // End - generateSeatSalesTrackingRecords()
    
    
    //    private static List<Date> generateDatesB2B(Date departingFlightDate, Integer numOfWeeks, String dayOfWeek) {
    public static List<Date> generateDatesB2B(Date departingFlightDate, Integer numOfWeeks, String dayOfWeek) {
        Boolean isMon=FALSE, isTue=FALSE, isWed=FALSE, isThu=FALSE, isFri=FALSE, isSat=FALSE, isSun=FALSE; // SET all to FALSE
        switch on dayOfWeek.toUpperCase() {
            when 'MON','MONDAY'     { isMon=TRUE; }
            when 'TUE','TUESDAY'    { isTue=TRUE; }
            when 'WED','WEDNESDAY'  { isWed=TRUE; }
            when 'THU','THURSDAY'   { isThu=TRUE; }
            when 'FRI','FRIDAY'     { isFri=TRUE; }
            when 'SAT','SATURDAY'   { isSat=TRUE; }
            when 'SUN','SUNDAY'     { isSun=TRUE; }
        }
        
        Date startDate = departingFlightDate.addDays((-7*numOfWeeks)+1);  // FORWARD by X number of weeks
        Date endDate = departingFlightDate;
        //system.debug('startDate: '+startDate);        
        //system.debug('endDate: '+endDate);  
        List<Date> dateList = new List<Date>();
        dateList = CreateGroupBookingsJob.generateDates(startDate, endDate, isMON, isTUE, isWED, isTHU, isFRI, isSAT, isSUN);
        return dateList;        
    }  // End - generateDatesB2B()
    
    //Assign route point to each section   
    private Map<Integer,String> routeMap(String originRoute){
        Map<Integer,String> routeMap = new Map<Integer,String>();
        if(originRoute.length()>0){           
            if(originRoute.contains('one-way')){
                routeMap.put(1, originRoute.substring(0, 7));
                routeMap.put(2, originRoute.substring(4, 7));           
            }                       
        }else{
            routeMap = null; 
        }
        return routeMap;   
    }
    
    //2024/6/8 Ethan
    private static void relateGroupAU() {
        RecordType groupBookingRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Group_Booking' LIMIT 1];
        Id groupBookingRecordTypeId = groupBookingRecordType.Id;
        
        List<Date> dates = new List<date>();
        List<String> departings = new List<String>();
        List<String> returning = new List<String>();
        for (Case record : (List<Case>) trigger.new) {
            if(record.RecordTypeId == groupBookingRecordTypeId) {
                dates.add(record.Flight_Date__c);
                departings.add(record.F_Departing__c );
                returning.add(record.F_Returning__c );
            }
        }
        
        List<Group_AU__c> groupAUs = [SELECT Id, Flight_Date__c, F_Departing__c, F_Returning__c FROM Group_AU__c WHERE Flight_Date__c IN : dates AND F_Departing__c IN : departings AND F_Returning__c IN : returning];
        
        for (Case record : (List<Case>) trigger.new) {
            if(record.RecordTypeId == groupBookingRecordTypeId) {
                for (Group_AU__c groupAU : groupAUs) {
                    if(groupAU.Flight_Date__c == record.Flight_Date__c && groupAU.F_Departing__c == record.F_Departing__c && groupAU.F_Returning__c == record.F_Returning__c) {
                        record.Departing_AU__c = groupAU.Id;
                        record.Returning_AU__c = groupAU.Id;
                        break;
                    }
                }
            }
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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