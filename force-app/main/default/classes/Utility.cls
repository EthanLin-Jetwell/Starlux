public class Utility {

    /*
    public static sObject ConvertObject(String MapName, sObject destination, sObject source) {
        return ConvertObject(MapName, destination, source, new Map<String, Object> ());
    }
    public static sObject ConvertObject(String MapName, sObject source) {

        List<sObject> destinations = ConvertObjects(MapName, source, new Map<String, Object> ());
        return destinations[0];

    }
    public static sObject ConvertObject(String MapName, sObject source, Map<String, Object> variables) {

        List<sObject> destinations = ConvertObjects(MapName, source, variables);
        return destinations[0];

    }
    public static List<sObject> ConvertObjects(String MapName, List<sObject> sources, Map<String, Object> variables) {
        List<sObject> destinations = new List<sObject> ();
        for (sObject obj : sources)
        {
            destinations.add(ConvertObject(MapName, obj, variables));
        }
        return destinations;
    }
	*/

    public class MyException extends Exception { }

    /*
    public static List<sObject> ConvertObjects(String MapName, sObject source, Map<String, Object> variables) {
        Map<Integer, sObject> destinations = ConvertObjectsWithIndex(MapName, source, variables);
        return destinations.values();
    }
    public static sObject ConvertObject(String MapName, sObject destination, sObject source, Map<String, Object> variables) {
        List<Object_Conversion_Map__mdt> objMap = [Select Verify_Field__c, Destination_Object__c, No_of_Records__c, one_to_Many__c, Destination_Record_Type_Name__c from Object_Conversion_Map__mdt where DeveloperName = :MapName];
        if (objMap.size() == 0) throw new MyException('Map(' + MapName + ') does not exist');

        List<Object_Conversion_Field_Map__mdt> convMap = getObjectMapping(MapName);
        String recTypeId = null;
        if (String.isNotEmpty(objMap[0].Destination_Object__c) && String.isNotEmpty(objMap[0].Destination_Record_Type_Name__c))
        {
            recTypeId = Utility.GetRecordTypeId(objMap[0].Destination_Object__c, objMap[0].Destination_Record_Type_Name__c);
        }
        if (convMap.size() == 0) throw new MyException('There is no Conversion Mapping (' + MapName + ').');
        destination = makeConvRec(convMap, destination, source, false, 1, recTypeId, variables);
        return destination;
    }
    public static Map<Integer, sObject> ConvertObjectsWithIndex(String MapName, sObject source, Map<String, Object> variables) {
        Map<Integer, sObject> destinations = new Map<Integer, sObject> ();
        List<Object_Conversion_Map__mdt> objMap = [Select Verify_Field__c, Destination_Object__c, No_of_Records__c, one_to_Many__c, Destination_Record_Type_Name__c from Object_Conversion_Map__mdt where DeveloperName = :MapName];
        if (objMap.size() == 0) throw new MyException('Map(' + MapName + ') does not exist');

        List<Object_Conversion_Field_Map__mdt> convMap = getObjectMapping(MapName);

        String recTypeId = null;
        if (String.isNotEmpty(objMap[0].Destination_Object__c) && String.isNotEmpty(objMap[0].Destination_Record_Type_Name__c))
        {
            recTypeId = Utility.GetRecordTypeId(objMap[0].Destination_Object__c, objMap[0].Destination_Record_Type_Name__c);
        }
        if (convMap.size() == 0) throw new MyException('There is no Conversion Mapping (' + MapName + ').');
        Integer noOfRec = 1;
        if (objMap[0].one_to_Many__c) noOfRec = Integer.valueOf(objMap[0].No_of_Records__c);

        String destObjName = objMap[0].Destination_Object__c;
        for (Integer i = 1; i <= noOfRec; i++)
        {
            boolean procRec = true;
            if (String.isNotEmpty(objMap[0].Verify_Field__c))
            {
                String verField = objMap[0].Verify_Field__c;
                verField = verField.replace('{#}', String.valueOf(i));
                if (String.isEmpty((String) source.get(verField))) procRec = false;
            }
            if (procRec)
            {
                sObject dest = Schema.getGlobalDescribe().get(destObjName).newSObject();
                dest = makeConvRec(convMap, dest, source, true, i, recTypeId, variables);
                destinations.put(i, dest);
            }
        }

        return destinations;
    }
    public static sObject makeConvRec(List<Object_Conversion_Field_Map__mdt> convMap, sObject desObjct, sObject source, Boolean isMulti, integer seq, String recTypeId, Map<String, Object> variables)
    {
        if (String.isNotEmpty(recTypeId)) desObjct.put('RecordTypeId', recTypeId);
        for (Object_Conversion_Field_Map__mdt covField : convMap)
        {
            boolean isSetValue = true;
            String sourceField = covField.Source_Field__c;
            if (covField.Same_Field_Name__c) sourceField = covField.Destination_Field__c;
            if (isMulti) sourceField = sourceField.replace('{#}', String.valueOf(seq));
            if (String.isNotBlank(covField.Condition_Field__c))
            {
                String condField = covField.Condition_Field__c;
                if (isMulti) condField = condField.replace('{#}', String.valueOf(seq));
                if (covField.Condition_Field_Type__c == 'Boolean')
                {
                    isSetValue = (source.get(condField) == Boolean.valueOf(covField.Condition_Field_Value__c));
                }
                else if (covField.Condition_Field_Type__c == 'Variable')
                {

                    isSetValue = (getVariableValue(variables, condField) == covField.Condition_Field_Value__c);
                }
                else if (covField.Condition_Field_Type__c == 'in List')
                {
                    String valStr = covField.Condition_Field_Value__c;
                    List<String> valList = valStr.split('\\,');
                    isSetValue = (valList.contains(String.valueOf(source.get(condField))));
                } else if (covField.Condition_Field_Type__c == 'contains')
                {
                    String condValueStr = String.valueOf(source.get(condField));
                    String valStr = covField.Condition_Field_Value__c;
                    isSetValue = (condValueStr.contains(valStr));
                }
                else
                {
                    isSetValue = (source.get(condField) == covField.Condition_Field_Value__c);
                }
                if (covField.Not_equal_Condition__c) isSetValue = !isSetValue;
            }
            if (isSetValue)
            {
                Object variableValue = sourceField;
                try {
                    if (covField.Fixed_Value__c)
                    {
                        if (covField.Fixed_Value_Type__c == 'Boolean')
                        {
                            variableValue = Boolean.valueOf(sourceField);

                        }
                        else if (covField.Fixed_Value_Type__c == 'Variable')
                        {
                            String variableName = sourceField;
                            variableValue = getVariableValue(variables, variableName);

                        }
                        else if (covField.Fixed_Value_Type__c == 'Date')
                        {
                            Date datevalue = Date.today();
                            if (String.isNotEmpty(sourceField))
                            {
                                try {
                                    integer gap = integer.valueOf(sourceField);
                                    datevalue = datevalue.addDays(gap);
                                } catch(Exception e)
                                {
                                    datevalue = Date.parse(sourceField);
                                }
                            }
                            variableValue = datevalue;

                        }
                    } else
                    {
                        variableValue = source.get(sourceField);
                    }
                    variableValue = valueConversion(covField.Value_Conversion__c, variableValue, covField.NullToZero__c);
                    if (covField.Fixed_Value_Type__c == 'Boolean') desObjct.put(covField.Destination_Field__c, Boolean.valueOf(variableValue));
                    ELSE desObjct.put(covField.Destination_Field__c, variableValue);

                } catch(Exception e)
                {
                    throw(New MyException('Error during setting ' + sourceField + ' ' + variableValue + ' into ' + covField.Destination_Field__c + ' from Map(' + covField.Object_Conversion_Map__r.DeveloperName + ').  '
                                          + e.getMessage() + ' '
                                          + e.getStackTraceString()));
                }

            }
        }
        return desObjct;
    }
*/

    public static String GenerateMessage(String MapName, Map<String, Object> source, Boolean EnableURLParam) {
		Map<String, Object> desObject = makeIntMessage(MapName, null, source);
        system.debug('DEBUGOBJECT HERE');
        system.debug(desObject);
                    
        if (EnableURLParam == True) {
            String paramURL = '?';
            for (String key : desObject.keySet()) {
            	String subparam = (String)desObject.get(key);
                String substring = key + '=' + subparam + '&';
                paramURL += substring;    
            }
            
            String finalparamURL = paramURL.removeEnd('&');
            system.debug('DBG paramURL: '+ finalparamURL);
            return finalparamURL;
            //String TestURL = '?cemId=123456780'; //NEED TO REMOVE THIS AND REVERT TO CORRECT FORMAT 
            //return TestURL;
        } else {
            
            return JSON.serialize(desObject);
        }
            
        
    }

    /*
    public static String GenerateMessage(Id MapId, Map<String, Object> source) {
        List<Object_Conversion_Field_Map__mdt> convMap = getObjectMapping(MapId);
        Map<String, Object> desObject = makeIntMessage(convMap, null, source);
        return JSON.serialize(desObject);
    } */

    /* Commented on 3/7/19 for code coverage
    Public static object chekCondition(String ConvType, object input, Boolean NullToZero)
    {
        Object rtn = input;
        if (ConvType == 'STR.UPPER')
        {
            rtn = (String.valueOf(input)).toUpperCase();

        } else if (ConvType == 'STR.LOWER')
        {	// not sure if this is the correct conversion; my guess is, this should convert to lower case
            rtn = (String.valueOf(input)).toUpperCase();
        } else if (ConvType == 'DATE.GMT')
        {
            rtn = (String.valueOfGmt(Date.valueOf(input)));

        } else if (ConvType == 'NUMBERSTR')
        {
            rtn = convStr(String.valueOf(input), true);

        }
        if (NullToZero && input == null) input = 0;
        return rtn;

    }
	*/	

    Public static object valueConversion(String ConvType, object input, Boolean NullToZero)
    {
        Object rtn = input;
        if (ConvType == 'STR.UPPER')
        {
            if (input == null) return null;
            rtn = (String.valueOf(input)).toUpperCase();

        } else if (ConvType == 'STR.LOWER')
        {
            if (input == null) return null;
            rtn = (String.valueOf(input)).toLowerCase();
        } else if (ConvType == 'DATE.GMT')
        {
            if (input == null) return null;
            rtn = (String.valueOfGmt(Date.valueOf(input)));

        } else if (ConvType == 'NUMBERSTR')
        {
            rtn = convStr(String.valueOf(input), true);

        }
        if (NullToZero && input == null) input = 0;
        return rtn;

    }


    public static List<Object_Conversion_Field_Map__mdt> getObjectMapping(String MapName)
    {
        List<Object_Conversion_Map__mdt> objMap = [Select Verify_Field__c, Destination_Object__c, No_of_Records__c, one_to_Many__c, Destination_Record_Type_Name__c from Object_Conversion_Map__mdt where DeveloperName = :MapName];
        if (objMap.size() == 0) throw new MyException('Map(' + MapName + ') does not exist');
        List<Object_Conversion_Field_Map__mdt> convMap = [Select Condition_Field__c,
                                                              Value_Conversion__c,
                                                              Condition_Field_Value__c,
                                                              Destination_Field__c,
                                                              Same_Field_Name__c,
                                                              Fixed_Value__c,
                                                              Object_Conversion_Map__c,
                                                              Fixed_Value_Type__c,
                                                              Condition_Field_Type__c,
                                                              Object_Conversion_Map__r.DeveloperName,
                                                              NullToZero__c, Not_equal_Condition__c,
                                                              Is_Array__c, Reference_Map__c,
                                                              Source_Field__c
                                                              from Object_Conversion_Field_Map__mdt
                                                              where Object_Conversion_Map__r.DeveloperName = :MapName
                                                              and Inactive__c != true
                                                              ORDER BY Condition_Field__c DESC NULLS LAST
                                                             ];
        return convMap;

    }
    /*
    public static List<Object_Conversion_Field_Map__mdt> getObjectMapping(Id MapId)
    {
        List<Object_Conversion_Map__mdt> objMap = [Select Verify_Field__c, Destination_Object__c, No_of_Records__c,
                                                       one_to_Many__c, Destination_Record_Type_Name__c
                                                       from Object_Conversion_Map__mdt where Id = :MapId];
        if (objMap.size() == 0) throw new MyException('Map(' + MapId + ') does not exist');
        List<Object_Conversion_Field_Map__mdt> convMap = [Select Condition_Field__c,
                                                              Value_Conversion__c,
                                                              Condition_Field_Value__c,
                                                              Destination_Field__c,
                                                              Same_Field_Name__c,
                                                              Fixed_Value__c,
                                                              Object_Conversion_Map__c,
                                                              Fixed_Value_Type__c,
                                                              Condition_Field_Type__c,
                                                              Object_Conversion_Map__r.DeveloperName,
                                                              NullToZero__c, Not_equal_Condition__c,
                                                              Is_Array__c, Reference_Map__c,
                                                              Source_Field__c
                                                              from Object_Conversion_Field_Map__mdt
                                                              where Object_Conversion_Map__r.Id = :MapId
                                                              and Inactive__c != true
                                                              ORDER BY Condition_Field__c DESC NULLS LAST
                                                             ];
        return convMap;

    }


    public static Map<String, Object> makeIntMessage(Id MapId, Map<String, Object> desObject, Map<String, Object> source)
    {
        List<Object_Conversion_Field_Map__mdt> convMap = getObjectMapping(MapId);
        return makeIntMessage(convMap, desObject, source);

    }  */

    public static Map<String, Object> makeIntMessage(String MapName, Map<String, Object> desObject, Map<String, Object> source)
    {
        List<Object_Conversion_Field_Map__mdt> convMap = getObjectMapping(MapName);
        return makeIntMessage(convMap, desObject, source);

    }


    public static Map<String, Object> makeIntMessage(List<Object_Conversion_Field_Map__mdt> convMap, Map<String, Object> desObject, Map<String, Object> source)
    {
        if (desObject == null) desObject = new Map<String, Object> ();

        for (Object_Conversion_Field_Map__mdt covField : convMap)
        {
            boolean isSetValue = true;
            String sourceField = covField.Source_Field__c;
            if (covField.Same_Field_Name__c) sourceField = covField.Destination_Field__c;

            if (String.isNotBlank(covField.Condition_Field__c))
            {
               /* Object condValue = getVariableValue(source, covField.Condition_Field__c);
                if (covField.Condition_Field_Type__c == 'Boolean')
                {
                    isSetValue = (condValue == Boolean.valueOf(covField.Condition_Field_Value__c));
                } else if (covField.Condition_Field_Type__c == 'in List')
                {
                    String valStr = covField.Condition_Field_Value__c;
                    List<String> valList = valStr.split('\\,');
                    isSetValue = (valList.contains(String.valueOf(condValue)));
                } else if (covField.Condition_Field_Type__c == 'contains')
                {
                    String condValueStr = String.valueOf(condValue);
                    String valStr = covField.Condition_Field_Value__c;
                    isSetValue = (condValueStr.contains(valStr));
                }
                else
                {
                    isSetValue = (condValue == covField.Condition_Field_Value__c);
                }
               if (covField.Not_equal_Condition__c) isSetValue = !isSetValue; */
            }
            if (isSetValue)
            {
                Object variableValue = '';

                try {
                    if (covField.Fixed_Value__c)
                    {
                        variableValue = sourceField;
                        if (covField.Fixed_Value_Type__c == 'Boolean')
                        {
                            variableValue = Boolean.valueOf(sourceField);
                            putValueByPath(desObject, covField.Destination_Field__c, Boolean.valueOf(sourceField));
                        }
                        else if (covField.Fixed_Value_Type__c == 'Reference')
                        {
                            if (covField.Destination_Field__c == '#ROOT#')
                            {

                                makeIntMessage(covField.Reference_Map__c, desObject, source);
                            }
                            else
                            { /*
                             object out = null;
                                if (covField.Is_Array__c)
                                {
                                    List<Object> outlist = new List<Object> ();
                                    if (String.isNotblank(sourceField))
                                    {
                                        Object arrayobj = getVariableValue(source, sourceField);
                                        if (arrayobj instanceof List<Object>)
                                        {
                                            List<Object> sourceArray = (List<Object>) arrayobj;
                                            for (Object obj : sourceArray)
                                            {
                                                out = null;
                                                Map<String, Object> tempsource = source.clone();

                                                putValueByPath(tempsource, sourceField, obj);
                                                out = makeIntMessage(covField.Reference_Map__c, null, tempsource);
                                                outlist.add(out);
                                            }
                                        } else
                                        {
                                            out = makeIntMessage(covField.Reference_Map__c, null, source);
                                            outlist.add(out);
                                        }
                                    } else
                                    {
                                        out = makeIntMessage(covField.Reference_Map__c, null, source);
                                        outlist.add(out);
                                    }
                                    out = outlist;


                                } else
                                {
                                    out = makeIntMessage(covField.Reference_Map__c, null, source);
                                }
                                putValueByPath(desObject, covField.Destination_Field__c, out);*/
                            }
                        }
                        else if (covField.Fixed_Value_Type__c == 'Date')
                        {
                            Date datevalue = Date.today();
                            if (String.isNotEmpty(sourceField))
                            {
                                try {
                                    integer gap = integer.valueOf(sourceField);
                                    datevalue = datevalue.addDays(gap);
                                } catch(Exception e)
                                {
                                    datevalue = Date.parse(sourceField);
                                }
                            }
                            variableValue = datevalue;
                        }
                    } else
                    {
                        System.debug('DBG Variablevalue1:'+variableValue);	
                        variableValue = getVariableValue(source, sourceField);
                    }
                    if (covField.Fixed_Value_Type__c != 'Reference')
                    {
                        System.debug('DBG Variablevalue2:'+variableValue);	
                        variableValue = valueConversion(covField.Value_Conversion__c, variableValue, covField.NullToZero__c);

                        System.debug(covField.Destination_Field__c + ':' + variableValue);
                        putValueByPath(desObject, covField.Destination_Field__c, variableValue);
                    }

                } catch(Exception e)
                {
                    throw(New MyException('Error during setting ' + sourceField + ' ' + variableValue + ' into ' + covField.Destination_Field__c + ' from Map(' + covField.Object_Conversion_Map__r.DeveloperName + ').  '
                                          + e.getMessage() + ' '
                                          + e.getStackTraceString()));
                }
//
            }
        }
        system.debug('DBG desObject' + desObject);
        return desObject;
    }
    public static Object getVariableValue(Map<String, Object> variables, String variableName)
    {
        system.debug('DBG HI'+variables);
        system.debug('DBG HI2'+variableName);
        Object variableValue = null;
        // if(String.isBlank(variableName)) return variableValue;
        if (variableName.contains('.'))
        {
            	
            String objName = variableName.substringBefore('.');
            String valName = variableName.substringAfter('.');
            Object obj = variables.get(objName);
            system.debug('DBG OBJ: '+obj);
            if (obj == null) return null;
            if (valName.contains('.'))
            {
                Map<String, Object> objvariable = (Map<String, Object>) obj;
                return getVariableValue(objvariable, valName);
            } else
            {
                try {
                    variableValue = ((sObject) obj).get(valName);
                    system.debug('DBG variableValue1: '+variableValue);
                } catch(Exception e)
                {
                    variableValue = ((Map<String, Object>) obj).get(valName);
                }
            }

        } else
        {
            variableValue = variables.get(variableName);
            system.debug('DBG variableValue2: '+variableValue);
        }
        return variableValue;
    }
    public static Map<String, Object> putValueByPath(Map<String, Object> variables, String path, Object value)
    {
        if (variables == null) variables = new Map<String, Object> ();
        if (path.contains('.'))
        {
            String objName = path.substringBefore('.');
            String valName = path.substringAfter('.');
            Object obj = variables.get(objName);
            if (obj == null)
            {
                obj = new Map<String, Object> ();
                variables.put(objName, obj);
            }
            if (valName.contains('.'))
            {
                //more child
                putValueByPath((Map<String, Object>) obj, valName, value);
                return variables;
            } else
            {
                ((Map<String, Object>) obj).put(valName, value);
            }

        } else
        {
            variables.put(path, value);
        }
        return variables;
    }

    /*
    public static List<sObject> getSObjectRecords(String SObject_API_Name, String condition) {
        return getSObjectRecords(SObject_API_Name, condition, false);
    }
    public static String generateAllFieldStr(String SObject_API_Name)
    {
        String query = '';
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(SObject_API_Name).getDescribe().fields.getMap();
        Set<String> fieldsSet = new Set<String> ();

        for (Schema.SObjectField sfield : fieldMap.Values())
        {
            schema.describefieldresult dfield = sfield.getDescribe();
            if (dfield.isAccessible() && dfield.getname() != 'isDeleted') fieldsSet.add(dfield.getname());

        }
        if (fieldsSet.size() > 0)
        {
            query = String.join(new List<String> (fieldsSet), ',');
            if (!fieldsSet.contains('Id')) query += ',Id';
        }
        return query;

    }
    public static String generateAllFieldSOQL(String SObject_API_Name)
    {

        String query = 'Select ' + generateAllFieldStr(SObject_API_Name);
        query += ' From ' + SObject_API_Name;
        return query;
    }
    public static List<sObject> getSObjectRecords(String SObject_API_Name, String condition, Boolean onlyOne) {
        String query = generateAllFieldSOQL(SObject_API_Name);
        //        System.debug('Query before condition : ' + query);
        if (!String.isEmpty(condition))
        {
            query += ' where ' + condition;
        }
        if (onlyOne)
        {
            query += ' limit 1';
        }
        //        System.debug('Query after condition : ' + query);
        //    System.debug(query);
        return Database.query(query);

    }
    public static List<sObject> getSObjectRecords(String SObject_API_Name, String keyField, Set<Id> keySet) {
        String query = generateAllFieldSOQL(SObject_API_Name);
        //    System.debug('Query before condition : ' + query);
        query += ' where ' + keyField + ' in :keySet';
        //    System.debug('Query after condition : ' + query);
        return Database.query(query);
    }


    public static Id GetRecordTypeId(String pObjName, String Name) {

        Map<String, Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        if (!objGlobalMap.containsKey(pObjName)) return null;

        Schema.SObjectType pType = objGlobalMap.get(pObjName);
        Return pType.getDescribe().getRecordTypeInfosByName().get(Name).getRecordTypeId();
    }
    public static void sendEmail(String[] receipents, String subject, String msg) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = receipents;
        message.subject = subject;
        message.plainTextBody = msg;
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> { message };
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: '
                         + results[0].errors[0].message);
        }
    }
    public static Object getValuefromPath(String path, Map<String, Object> valueMap)
    {
        if (String.isBlank(path)) return '';
        String[] pathElements = path.split('\\.');
        Object val = '';
        String progressPath = '';
        if (pathElements.size() == 1)
        {
            val = valueMap.get(path);
        } else
        {
            Object obj = (Object) valueMap;
            for (String el : pathElements)
            {
                progressPath += '.' + el;
                if (obj instanceof Map<String, Object>)
                {

                    obj = ((Map<String, Object>) obj).get(el);
                } else if (obj instanceof sObject)
                {
                    obj = ((sObject) obj).get(el);
                } else
                {

                    obj = null;
                    // throw(New MyException(progressPath +' is not in Map ( ' + PRDOUT + ')'));
                    // raise Error
                }
            }
            val = obj;
        }
        return val;
    }
*/

    public static String convStr(String val, Boolean isNum)
    {
        if (val == null)
        {
            if (isNum) return '0';
            else return '';
        }
        else return val;
    }

    public static Map<String,Object> SendData(String interfaceMapName, String childInterfaceName, Map<String,Object> interfaceData) {
		// find conversion mapping from child interface
        System.debug('DBG SendData: interfaceMapName: ' + interfaceMapName + '---childInterfaceName: ' + childInterfaceName + '---interfaceData: ' + JSON.serializePretty(InterfaceData));
        List<Interface_Operation_Setting__mdt> findConversionMapList = [SELECT DeveloperName, Msg_Mapping__r.DeveloperName, Enable_URL_Param__c FROM Interface_Operation_Setting__mdt where Interface_Operation_Setting__mdt.DeveloperName = :childInterfaceName Limit 1];
        //System.debug('DBG findConversionMapList: ' + findConversionMapList);
        
        String findConversionMap = findConversionMapList[0].Msg_Mapping__r.DeveloperName;
        Boolean enableURLParam = findConversionMapList[0].Enable_URL_Param__c;
        system.debug('DBG enableURL: '+enableURLParam);
        
        //System.debug('DBG findConversionMap: ' + findConversionMap);
		// call the GenerateMessage method to get the message
       
        String MessageGenerated = GenerateMessage(findConversionMap, InterfaceData, enableURLParam);
        //String MessageGenerated = '{"CEM_ID":123456789}';
        system.debug('DBG Message' + MessageGenerated);
        
        // call the TransportLayer method, with MessageGenerated as the parameter 
        Map<String,Object> MessageReceived = TransportLayer.makeCallout(InterfaceMapName, childInterfaceName, MessageGenerated);
        system.debug('DBG MessageReceived' + JSON.serializePretty(MessageReceived)); 
        
		return MessageReceived;
    }

    // store org cache based on cacheName as label and cacheValue as the value to be stored and Time-To-Live in seconds
    // Assumes that Cache Visibility is for all namespace, and is immutable as indicated by 'true'
    public static void storeOrgCache(String cachePartitionName, String cacheName, String cacheValue, Integer timeToLiveSec) {
        System.debug('DBG Utility storeOrgCache: ' + cachePartitionName + '---' + cacheName + '---' + cacheValue + '---' + timeToLiveSec);
        //Cache.OrgPartition orgPartition = Cache.Org.getPartition(cachePartitionName);
        String cachedKeyStr = 'local.' + cachePartitionName + '.' + cacheName;
        System.debug('DBG cache key: ' + cachedKeyStr);
        Cache.Org.put(cachedKeyStr, cacheValue, timeToLiveSec, Cache.Visibility.ALL, false);
    }

    // return null if no existing org cache based on the cacheName
    public static String fetchOrgCache(String cachePartitionName, String cacheName) {
        String storedCache;
        System.debug('DBG Utility fetchOrgCache: ' + cachePartitionName + '---' + cacheName);
        Cache.OrgPartition orgPart = Cache.Org.getPartition(cachePartitionName);

        if (orgPart != null && orgPart.contains(cacheName)) {
            storedCache = (String) orgPart.get(cacheName);
            System.debug('DBG Utility fetchOrgCache: ' + storedCache);
        }

        return storedCache;
    }

}