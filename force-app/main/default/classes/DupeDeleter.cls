public with sharing class DupeDeleter {
    @InvocableMethod(label = 'DupeDeleter')
    public static void deleteDupes(){
        Date systemToday = System.today()-2;
        List<AggregateResult> results = [
                SELECT
                        Email_Address__c,
                        COUNT(Id)
                FROM
                        Customer_Satisfaction_Surveys__c
                WHERE
                        Email_Address__c != NULL
                AND     
                        Departing_Date__c =: systemToday
                GROUP BY Email_Address__c
                HAVING COUNT(Id) > 1
                ORDER BY COUNT(Id) DESC
        ];
        System.debug(results);
        Set<String> emails = new Set<String>();
        for (AggregateResult ag : results) {
            emails.add((String) ag.get('Email_Address__c'));
        }
        Set<String> firsts = new Set<String>();
        List<Customer_Satisfaction_Surveys__c> toDelete = new List<Customer_Satisfaction_Surveys__c>();
        Customer_Satisfaction_Surveys__c[] customers = [SELECT Id, Email_Address__c FROM Customer_Satisfaction_Surveys__c WHERE Email_Address__c IN :emails AND Departing_Date__c =: systemToday  ORDER BY CreatedDate DESC];

        for (Customer_Satisfaction_Surveys__c i : customers) {
            if (!firsts.contains(i.Email_Address__c)) { // retain first
                firsts.add(i.Email_Address__c);
            } else { // delete rest
                toDelete.add(i);
            }
        }
        System.debug(toDelete.size());
        delete toDelete;
    }
}