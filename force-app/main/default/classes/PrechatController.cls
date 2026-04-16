public without sharing class PrechatController {
    /**
     * Returns the number of work items currently queued in Omni-Channel.
     * Uses without sharing so guest/unauthenticated users in Experience Cloud
     * can call this before starting a chat session.
     */
    @AuraEnabled(cacheable=false)
    public static void validateQueue(String language) {

        if (String.isBlank(language)) return;

        // --- Working Hours Check ---
        // e.g. Work_Hour__c has Start_Time__c, End_Time__c
        List<Work_Hour__c> workHours = [
            SELECT Max_Queue_Waiting__c, Max_Queue_Message__c,
                IsOnline__c
            FROM Work_Hour__c
            WHERE language__c = :language
            LIMIT 1
        ];

        if (workHours.isEmpty()) {
            throw new AuraHandledException('NOT_WORKING_HOURS');
        }

        Work_Hour__c wh = workHours[0];
        if (!wh.IsOnline__c) {
            throw new AuraHandledException('NOT_WORKING_HOURS');
        }

        // --- Queue Size Check ---
        String queueName = 'Call_Center_Chat_Queue_';
        switch on language {
            when 'English'  { queueName += 'EN'; }
            when 'Mandarin' { queueName += 'TW'; }
            when 'Japanese' { queueName += 'JP'; }
            when else       { return; }
        }

        List<Group> queues = [
            SELECT Id FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = :queueName
            LIMIT 1
        ];
        if (queues.isEmpty()) return;

        Integer pendingCount = [
            SELECT COUNT()
            FROM MessagingSession
            WHERE OwnerId = :queues[0].Id
            AND Status != 'Ended'
        ];

        Integer maxQueueWaiting = (wh.Max_Queue_Waiting__c != null)
            ? wh.Max_Queue_Waiting__c.intValue()
            : 10;

        if (pendingCount >= maxQueueWaiting) {
            throw new AuraHandledException('QUEUE_FULL');
        }
    }

    @AuraEnabled(cacheable=false)
    public static String getMessage(String language, String type) {
        if (String.isBlank(language) || String.isBlank(type)) {
            return '';
        }

        List<Work_Hour__c> workHours = [
            SELECT Max_Queue_Message__c, OffLineMSG__c, EmailErrorMSG__c
            FROM Work_Hour__c
            WHERE language__c = :language
            LIMIT 1
        ];

        if (workHours.isEmpty()) return '';

        Work_Hour__c wh = workHours[0];

        switch on type {
            when 'QUEUE_FULL'        { return wh.Max_Queue_Message__c ?? ''; }
            when 'NOT_WORKING_HOURS' { return wh.OffLineMSG__c ?? ''; }
            when 'EMAIL_ERROR' { return wh.EmailErrorMSG__c ?? ''; }
            when else                { return ''; }
        }
    }

    @AuraEnabled(cacheable=false)
    public static void validateEmail(String language, String email) {
        if (String.isBlank(email)) return;

        Pattern emailPattern = Pattern.compile(
            '^[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$'
        );

        if (emailPattern.matcher(email.trim()).matches()) return;

        // Email is invalid — fetch the error message from Work_Hour__c
        throw new AuraHandledException('EMAIL_ERROR');
    }
}