/*
* This is the global utilities to insert record into Application Log object
*/
global without sharing class GlobalUtility {
    @TestVisible
    global static Integer LONG_TXT_AREA_MAX_SIZE = 131072;
    
    global static void logMessage(String logLevel, String sourceClass, String sourceFunction, String referenceId,String referenceInfo, String logMessage, String payLoad, String applicationName, Exception exceptionThrown,  DateTime startTime, DateTime endTime, String Type, Boolean isDebugEnabled, Boolean isInfoEnabled,   Boolean isWarningEnabled, Boolean isErrorEnabled) {
        Application_Log__c appLog = new Application_Log__c();
        appLog.Debug_Level__c = logLevel;
        appLog.Module__c = sourceClass;
        appLog.Source_Function__c = sourceFunction;
        appLog.Reference_Id__c = referenceId;
        appLog.Reference_Info__c = referenceInfo;
        appLog.Description__c = logMessage;
        appLog.Integration_Payload__c = payLoad;
        appLog.Application_Name__c = applicationName;
        
        if (exceptionThrown != null && exceptionThrown.getStackTraceString() != null) {
            appLog.Stack_Trace__c = exceptionThrown.getStackTraceString();
        }
        
        appLog.Start_Date__c = startTime;
        appLog.End_Date__c = endTime;
        appLog.Type__c = Type;
        
        if (isLoggingEnabled(logLevel, isDebugEnabled, isInfoEnabled, isWarningEnabled, isErrorEnabled)) {
            //insert trimFieldLength(appLog);
            insert createAppLogChunks(appLog);
        }
    } // end logMessage
    
    global static void logMessage(ApplicationLogWrapper applicationLogWrapper) {
        
        if (isLoggingEnabled(applicationLogWrapper)) {
            //insert trimFieldLength(applicationLogWrapper.applicationLog);
            insert createAppLogChunks(applicationLogWrapper.applicationLog);
        }
        
    } // end logMessage
    
    global static void logMessage(List < ApplicationLogWrapper > applicationLogWrapperList) {
        
        List < Application_Log__c > appLogList = new List < Application_Log__c > ();
        for (ApplicationLogWrapper eachAppLogWrapper: applicationLogWrapperList) {
            if (isLoggingEnabled(eachAppLogWrapper)) {
                //appLogList.add(trimFieldLength(eachAppLogWrapper.applicationLog));
                appLogList.addAll(createAppLogChunks(eachAppLogWrapper.applicationLog));
            }
        } // end for
        
        insert appLogList;
    } // end logMessage
    
    @TestVisible
    private static boolean isLoggingEnabled(ApplicationLogWrapper appLogWrapper) {
        String logLevel = appLogWrapper.logLevel;
        if (String.isNotEmpty(logLevel)) {
            if (logLevel.equals('Debug') && appLogWrapper.isDebug)
                return true;
            if (logLevel.equals('Info') && appLogWrapper.isInfo)
                return true;
            if (logLevel.equals('Warning') && appLogWrapper.isWarning)
                return true;
            if (logLevel.equals('Error') && appLogWrapper.isError)
                return true;
        }
        
        return false;
        
    } // end isLoggingEnabled
    
    @TestVisible
    private static boolean isLoggingEnabled(String logLevel, Boolean isDebugEnabled, Boolean isInfoEnabled,
                                            Boolean isWarningEnabled, Boolean isErrorEnabled) {
                                                if (String.isNotEmpty(logLevel)) {
                                                    if (logLevel.equals('Debug') && isDebugEnabled)
                                                        return true;
                                                    if (logLevel.equals('Info') && isInfoEnabled)
                                                        return true;
                                                    if (logLevel.equals('Warning') && isWarningEnabled)
                                                        return true;
                                                    if (logLevel.equals('Error') && isErrorEnabled)
                                                        return true;
                                                }
                                                
                                                return false;
                                                
                                            } // end isLoggingEnabled
    
    global static List < Application_Log__c > createAppLogChunks(Application_Log__c applicationLog) {
        System.debug('trimFieldLength: ' + applicationLog.Description__c);
        
        Map < String, String > logDesciptionMap = new Map < String, String > ();
        Integer numberOfAppLogToBeCreated = 0;
        
        // adjust Description__c
        if (applicationLog != null && String.isNotEmpty(applicationLog.Description__c) && (applicationLog.Description__c).length() > LONG_TXT_AREA_MAX_SIZE) {
            String logDescription = applicationLog.Description__c;
            System.debug('logDescription:'+logDescription);
            Integer remainder = Math.Mod(logDescription.length(), LONG_TXT_AREA_MAX_SIZE);
            Integer quotient = (logDescription.length()) / LONG_TXT_AREA_MAX_SIZE;
            System.debug('logDescription:remainder: ' + remainder);
            System.debug('logDescription:quotient: ' + quotient);
            if (quotient > 0) {
                numberOfAppLogToBeCreated = quotient;
                for (Integer i = 0; i < quotient; i++) {
                    logDesciptionMap.put('Description__c#' + i, logDescription.substring(LONG_TXT_AREA_MAX_SIZE * i, LONG_TXT_AREA_MAX_SIZE * (i + 1)));
                }
                
                if (remainder > 0) {
                    numberOfAppLogToBeCreated++;
                    logDesciptionMap.put('Description__c#' + quotient, logDescription.substring(LONG_TXT_AREA_MAX_SIZE * quotient, (LONG_TXT_AREA_MAX_SIZE * quotient) + remainder));
                }
            }
        }
        
        // adjust Integration_Payload__c
        if (applicationLog != null && String.isNotEmpty(applicationLog.Integration_Payload__c) && (applicationLog.Integration_Payload__c).length() > LONG_TXT_AREA_MAX_SIZE) {
            String logPayload = applicationLog.Integration_Payload__c;
            System.debug('logPayload:'+logPayload);
            Integer remainder = Math.Mod(logPayload.length(), LONG_TXT_AREA_MAX_SIZE);
            Integer quotient = (logPayload.length()) / LONG_TXT_AREA_MAX_SIZE;
            System.debug('logPayload:remainder: ' + remainder);
            System.debug('logPayload:quotient: ' + quotient);
            if (quotient > 0) {
                
                if (numberOfAppLogToBeCreated < quotient) {
                    numberOfAppLogToBeCreated = quotient;
                    if (remainder > 0) {
                        numberOfAppLogToBeCreated++;
                    }
                }
                
                for (Integer i = 0; i < quotient; i++) {
                    logDesciptionMap.put('Integration_Payload__c#' + i, logPayload.substring(LONG_TXT_AREA_MAX_SIZE * i, LONG_TXT_AREA_MAX_SIZE * (i + 1)));
                }
                
                if (remainder > 0) {
                    logDesciptionMap.put('Integration_Payload__c#' + quotient, logPayload.substring(LONG_TXT_AREA_MAX_SIZE * quotient, (LONG_TXT_AREA_MAX_SIZE * quotient) + remainder));
                }
            }
        }
        
        
        // adjust Stack_Trace__c
        if (applicationLog != null && String.isNotEmpty(applicationLog.Stack_Trace__c) && (applicationLog.Stack_Trace__c).length() > LONG_TXT_AREA_MAX_SIZE) {
            String logStacktrace = applicationLog.Stack_Trace__c;
            System.debug('logStacktrace:'+logStacktrace);
            Integer remainder = Math.Mod(logStacktrace.length(), LONG_TXT_AREA_MAX_SIZE);
            Integer quotient = (logStacktrace.length()) / LONG_TXT_AREA_MAX_SIZE;
            System.debug('logStacktrace:remainder: ' + remainder);
            System.debug('logStacktrace:quotient: ' + quotient);
            
            if (quotient > 0) {
                
                if (numberOfAppLogToBeCreated < quotient) {
                    numberOfAppLogToBeCreated = quotient;
                    if (remainder > 0) {
                        numberOfAppLogToBeCreated++;
                    }
                }
                
                for (Integer i = 0; i < quotient; i++) {
                    logDesciptionMap.put('Stack_Trace__c#' + i, logStacktrace.substring(LONG_TXT_AREA_MAX_SIZE * i, LONG_TXT_AREA_MAX_SIZE * (i + 1)));
                }
                
                if (remainder > 0) {
                    logDesciptionMap.put('Stack_Trace__c#' + quotient, logStacktrace.substring(LONG_TXT_AREA_MAX_SIZE * quotient, (LONG_TXT_AREA_MAX_SIZE * quotient) + remainder));
                }
            }
        }
        
        // create N application log
        System.debug('numberOfAppLogToBeCreated:length: ' + numberOfAppLogToBeCreated);
        List < Application_Log__c > adjustedAppLogList = new List < Application_Log__c > ();
        if (numberOfAppLogToBeCreated > 0) {
            for (Integer i = 0; i < numberOfAppLogToBeCreated; i++) {
                Application_Log__c newAppLog = applicationLog.clone();
                newAppLog.Description__c = logDesciptionMap.containsKey('Description__c#' + i) ? logDesciptionMap.get('Description__c#' + i) : '';
                newAppLog.Integration_Payload__c = logDesciptionMap.containsKey('Integration_Payload__c#' + i) ? logDesciptionMap.get('Integration_Payload__c#' + i) : '';
                newAppLog.Stack_Trace__c = logDesciptionMap.containsKey('Stack_Trace__c#' + i) ? logDesciptionMap.get('Stack_Trace__c#' + i) : '';
                
                newAppLog.Sequence__c = (i + 1);
                adjustedAppLogList.add(newAppLog);
            }
        } else {
            adjustedAppLogList.add(applicationLog);
        }
        
        return adjustedAppLogList;
    }
}