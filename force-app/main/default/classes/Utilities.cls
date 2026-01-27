/**
* Using without sharing as need to run query on Organization table
*/

public without sharing class Utilities {
	public static String getAppSettingsMdtValueByKey(String key) {
    	return [Select Value__c from Application_Setting__mdt where Key__c = : key].Value__c;
    }

 	public static Map < String, String > getAppSettings() {
  		Map < String, String > appSettingsMap = new Map < String, String > ();
  		for (Application_Setting__mdt eachAppSettings: [Select Key__c, Value__c from Application_Setting__mdt]) {
   			appSettingsMap.put(eachAppSettings.Key__c, eachAppSettings.Value__c);
  		}
  		return appSettingsMap;
 	}


 	public static System_Settings__mdt getLogLevel(String metadata_label_name) {
  		List < System_Settings__mdt > routingLogSysStngCMD = [Select Id, Label, Date_Field_API_Name__c, Additional_Filter__c, Batch_Size__c, 
                                                              SObject_Api_Name__c, Debug__c, Info__c, Warning__c, Error__c From System_Settings__mdt 
                                                              Where MasterLabel = : metadata_label_name limit 1];
  		if (!routingLogSysStngCMD.isEmpty())
   			return routingLogSysStngCMD[0];
  		
        return null;
 	}

 	public static ApplicationLogWrapper createApplicationLog(String logLevel, String sourceClass, String sourceFunction, String failedRecordId, String applicationName, String processLog, String payLoad, String type, DateTime startTime, System_Settings__mdt logLevelCMD, Exception thrownExeption) {
  		ApplicationLogWrapper appLogWrapper = new ApplicationLogWrapper();
  		appLogWrapper.logLevel = logLevel;
  		appLogWrapper.sourceClass = sourceClass;
  		appLogWrapper.sourceFunction = sourceFunction;
  		appLogWrapper.logMessage = processLog;
  		appLogWrapper.applicationName = applicationName;
  		appLogWrapper.exceptionThrown = thrownExeption;
  		appLogWrapper.startDate = startTime;
  		appLogWrapper.endDate = DateTime.now();
  		appLogWrapper.type = 'Error Log';

  		if (String.isNotEmpty(type))
   			appLogWrapper.type = type;

  		if (String.isNotEmpty(payLoad))
   			appLogWrapper.payLoad = payLoad;

  		if (thrownExeption != null)
   			appLogWrapper.logLevel = 'Error';

  		if (String.isNotEmpty(failedRecordId))
   			appLogWrapper.referenceId = failedRecordId;

  		// Set Log Level
  		if (logLevelCMD != null) {
   			appLogWrapper.isDebug = logLevelCMD.Debug__c;
   			appLogWrapper.isInfo = logLevelCMD.Info__c;
   			appLogWrapper.isError = logLevelCMD.Error__c;
   			appLogWrapper.isWarning = logLevelCMD.Warning__c;
  		}

  		System.debug('appLogWrapper' + appLogWrapper);

  		return appLogWrapper;
 	}

 	public static List < System_Settings__mdt > getLogSettings(String sysMetadataLabelName) {
  		return [Select Id, is_Trigger__c, Number_Of_Retry__c, Debug__c, Info__c, Warning__c, 
                Error__c From System_Settings__mdt Where MasterLabel = : sysMetadataLabelName limit 1];

 	}
 	/*
 	public static String getQueueIdByName(String queueName) {
  		String queueId='';
  		List<Group> groupList = [select Id from Group where Name = : queueName AND Type = 'Queue'];
  		if(groupList!=null && !groupList.isEmpty()){
      		queueId = groupList[0].Id;
  		}
  		return queueId;
 	}
	*/
}