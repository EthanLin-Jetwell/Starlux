/*******************************************************************
Description: This class is used to wrap the creation of Application Log record
*******************************************************************/
global without sharing class ApplicationLogWrapper {
    global Application_Log__c applicationLog;
    
    // constructor
    global ApplicationLogWrapper() {
        applicationLog = new Application_Log__c();
    }
    
    global String logLevel {
        get {
            return applicationLog.Debug_Level__c;
        }
        
        set {
            logLevel = value;
            applicationLog.Debug_Level__c = logLevel;
        }
    } // end logLevel
    
    global String sourceClass {
        get {
            return applicationLog.Module__c;
        }
        
        set {
            sourceClass = value;
            applicationLog.Module__c = sourceClass;
        }
    } // end sourceClass
    
    global String sourceFunction {
        get {
            return applicationLog.Source_Function__c;
        }
        
        set {
            sourceFunction = value;
            applicationLog.Source_Function__c = sourceFunction;
        }
    } // end sourceFunction
    
    global String referenceId {
        get {
            return applicationLog.Reference_Id__c;
        }
        
        set {
            referenceId = value;
            applicationLog.Reference_Id__c = referenceId;
        }
    } // end referenceId
    
    global String referenceInfo {
        get {
            return applicationLog.Reference_Info__c;
        }
        
        set {
            referenceInfo = value;
            applicationLog.Reference_Info__c = referenceInfo;
        }
    } // end referenceInfo
    
    global String logMessage {
        get {
            return applicationLog.Description__c;
        }
        
        set {
            logMessage = value;
            applicationLog.Description__c = logMessage;
        }
    } // end logMessage
    
    global String payLoad {
        get {
            return applicationLog.Integration_Payload__c;
        }
        
        set {
            payLoad = value;
            applicationLog.Integration_Payload__c = payLoad;
        }
    } // end payLoad
    
    global String applicationName {
        get {
            return applicationLog.Application_Name__c;
        }
        
        set {
            applicationName = value;
            applicationLog.Application_Name__c = applicationName;
        }
    } // end applicationName
    
    global Exception exceptionThrown {
        get;
        
        set {
            exceptionThrown = value;
            if (exceptionThrown != null) {
                applicationLog.Stack_Trace__c = 'Root Cause: '+exceptionThrown.getMessage()+'\r\n';
                applicationLog.Stack_Trace__c = applicationLog.Stack_Trace__c + exceptionThrown.getStackTraceString();
            } // end if    
        }
    } // end exception
    
    global DateTime startDate {
        get {
            return applicationLog.Start_Date__c;
        }
        
        set {
            startDate = value;
            applicationLog.Start_Date__c = startDate;
        }
    } // end startDate
    
    global DateTime endDate {
        get {
            return applicationLog.End_Date__c;
        }
        
        set {
            endDate = value;
            applicationLog.End_Date__c = endDate;
        }
    } // end endDate
    
    global String type {
        get {
            return applicationLog.Type__c;
        }
        
        set {
            type = value;
            applicationLog.Type__c = type;
        }
    } // end type
    
    global boolean isDebug {
        get;
        set;
    }
    
    global boolean isInfo {
        get;
        set;
    }
    
    global boolean isWarning {
        get;
        set;
    }
    
    global boolean isError {
        get;
        set;
    }
} // end ApplicationLogWrapper