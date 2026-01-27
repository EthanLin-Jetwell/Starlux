global class ScheduleSendSurveyEDM implements Schedulable{
	global void execute(SchedulableContext SC) 
    {
        BatchSendEDM b = new BatchSendEDM();
		Database.executeBatch(b, 1000);
    }
}