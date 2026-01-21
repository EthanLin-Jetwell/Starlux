public class lib_UtilityHelper {

    public static List<sObject> getSObjectRecords(String SObject_API_Name, String condition, Boolean onlyOne) {
        String query = generateAllFieldSOQL(SObject_API_Name);
        system.debug(condition);
        if (!String.isEmpty(condition))
        {
            query += ' where ' + condition;
        }
        if (onlyOne)
        {
            query += ' limit 1';
        }
        System.debug('DBG lib_UtilityHelper query: ' + query);
        return Database.query(query);

    }

    public static String generateAllFieldSOQL(String SObject_API_Name)
    {

        String query = 'Select ' + generateAllFieldStr(SObject_API_Name) + ' From ' + SObject_API_Name;
        return query;
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
}