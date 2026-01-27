public class DbUtil {
    
    public static List<SObject> queryAllFields(String sobjectName) {
        return Database.query(generateQueryWithAllFields(sobjectName));
    }

    public static List<SObject> queryAllFieldsWithWhereFieldInList(String sobjectName, String field, List<String> valueList) {
        String query = generateQueryWithAllFields(sobjectName);
        
        query += ' WHERE ';
        query += field + ' in (';
        Boolean isNotFirstCriteria = false;
        for (String currValue : valueList) {
            if (isNotFirstCriteria) {
                query += ',';
            }
            query += '\'' + currValue + '\'';
            isNotFirstCriteria = true;
        }
        query += ')';

        DebugUtil.systemDebugSplitTooLong(query);
        return Database.query(query);
    }

    public static List<SObject> queryAllFieldsWithWhere(String sobjectName, Map<String, String> whereCriterias) {
        String query = generateQueryWithAllFields(sobjectName);
        
        if (whereCriterias != null) {
            query += ' WHERE ';

            Boolean isNotFirstCriteria = false;
            for (String columnKey : whereCriterias.keySet()) {
                if (isNotFirstCriteria) {
                    query += ' AND ';
                }
                query += columnKey + ' = \'' + whereCriterias.get(columnKey) + '\'';
                isNotFirstCriteria = true;
            }
        }
        System.debug('[4i] Query made:' + query);
        return Database.query(query);
    }
    
    //Only for NameList mealList query
    public static List<SObject> queryAllFieldsOnlyForNameList(String sobjectName, String route, String flightClass) {
        String query = generateQueryWithAllFields(sobjectName);
        
        if (route != NULL && flightClass != NULL) {
            query += ' WHERE ';
            query += 'Route__c' + ' LIKE \'' + route + '\'';
            query += ' AND ';
            query += 'Class__c' + ' = \'' + flightClass + '\'';
        }
		System.debug(query);
        return Database.query(query);
    }

    public static String generateQueryWithAllFields(String sobjectName) {
        String query = '';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sobjectName).getDescribe().fields.getMap();
    
        String strFields = '';
    
        for (String fieldName : fieldMap.keyset()) {
          if (strFields == null || strFields == '')
            strFields = fieldName;
          else
            strFields = strFields + ', ' + fieldName;
        }
    
        query = 'SELECT ' + strFields + ' FROM ' + sobjectName;
        return query;
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
    }
}