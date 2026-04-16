global class Schedule_SendBusinessHoursMessage implements Schedulable {
    private String languageCode;
    
    global Schedule_SendBusinessHoursMessage(String language) {
        // ZH = Mandarin, EN = English, JA = Japanese
        switch on language {
            when 'English' {
                this.languageCode = 'EN';
            }
            when 'Mandarin' {
                this.languageCode = 'ZH';
            }
            when 'Japanese' {
                this.languageCode = 'JA';
            }
        }
    }
    
    global void execute(SchedulableContext sc) {
        // Decide language (hardcoded or dynamic)
        // ZH = Mandarin, EN = English, JA = Japanese

        Map<String, Object> flowParams = new Map<String, Object>{
            'language' => languageCode
        };

            try {
                Flow.Interview.Send_Business_Hours_Message flowInterview =
                    new Flow.Interview.Send_Business_Hours_Message(flowParams);
                
                flowInterview.start();
            } catch(Exception e) {
                
            }
    }
}