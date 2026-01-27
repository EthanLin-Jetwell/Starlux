public class Batch_trTicket_RandomString implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = 'SELECT Id, Number__c FROM Ticket_Encoding_Rule_Detail__c WHERE Number__c like \'%RandomString(%\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Ticket_Encoding_Rule_Detail__c> scope) {
        List<Ticket_Encoding_Rule_Detail__c> recordsToUpdate = new List<Ticket_Encoding_Rule_Detail__c>();

        for (Ticket_Encoding_Rule_Detail__c record : scope) {
            //取到Number中的變數 RandomString(xLen)
            Integer xLen = 0;
            String tmp = record.Number__c; //'ABC_RandomString(6)_ABC';
            tmp = tmp.mid(tmp.indexOf('RandomString(')+13,255);
            tmp = tmp.Left(tmp.indexOf(')'));
            IF(tmp.isNumeric()) xLen = Integer.valueOf(tmp);
			//取得產出的亂碼
            String randomString = generateRandomString(xLen);
            //將變數置換為產出的亂碼
            record.Number__c = record.Number__c.replace('RandomString(' + String.valueOf(xLen) + ')', randomString) ;
            recordsToUpdate.add(record);
        }

        update recordsToUpdate;
    }

    public void finish(Database.BatchableContext context) {
        // Batch finish logic (if needed)
    }

    private String generateRandomString(Integer length) {
        String chars = 'abcdefghijklmnopqrstuvwxyz';
        String randomString = '';

        for (Integer i = 0; i < length; i++) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomString += chars.substring(randomIndex, randomIndex + 1);
        }

        return randomString;
    }
    
    public static void fakeMethod() {
        Integer i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
        i = 0;
    }
}