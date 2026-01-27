public class Queue_CalculateContractIncentive implements Queueable {
    public List<CGD_Sub_Contract__c> subs;
    //public List<CGD_Join_Account__c> joins;
    public List<String> joinNames;
    public Id recordTypeId = Schema.SObjectType.CGD_Raw_Data__c.getRecordTypeInfosByDeveloperName().get('Contract_Incentive').getRecordTypeId();
    
    
    public Queue_CalculateContractIncentive(List<CGD_Sub_Contract__c> subs, List<String> joinNames) {
        this.subs = subs;
        this.joinNames = joinNames;
    }
    
    public void execute(QueueableContext context) {
        try {
            if (!(subs.isEmpty() || joinNames.isEmpty())) {
                List<String> externalKeys = new List<String>();
                CGD_Sub_Contract__c sub = subs[0];
                for (String joinAccName : joinNames) {
                    String accountCode = joinAccName;
                    String airports = sub.Incentive_Origin_Airport__c != null ? sub.Incentive_Origin_Airport__c : '';
                    String dest = sub.Incentive_Destination_Airport__c != null ? sub.Incentive_Destination_Airport__c : '';
					String yearStr = sub.Target_Year__c != null ? String.valueOf(sub.Target_Year__c) : '';
                    //String monthStr = sub.Target_Month__c != null ? String.valueOf(sub.Target_Month__c) : '';
                    
                    for (String airport : airports.split(';')) {
                        for (String des : dest.split(';')) {
                            String key = String.join(
                                new List<String>{accountCode, airport, des, yearStr},
                                '_'
                            );
                            externalKeys.add(key);
                        }
                    }
                  
                    
                    AggregateResult[] results = [
                        /* 2025/11/14 針對有All的組法新增Raw Data三種有All的Key值組合。因為如果用Flow Mapping全部場站都要塞到Incentive欄位裡面，會有9420個場站名稱要塞，欄位塞不下，Flow也跑不動。
                        SELECT SUM(Chargeable_Weight_in_kg__c) sumTotal
                        FROM CGD_Raw_Data__c 
                        WHERE RecordTypeId = :recordTypeId AND Incentive_Key__c IN :externalKeys AND LastModifiedDate = TODAY
						*/
                        
                        SELECT SUM(Chargeable_Weight_in_kg__c) sumTotal
                        FROM CGD_Raw_Data__c 
                        WHERE RecordTypeId = :recordTypeId 
                          AND (Incentive_Key__c IN :externalKeys
                             OR Incentive_All_Destination_Key__c IN :externalKeys
                             OR Incentive_All_All_Key__c IN :externalKeys
                             OR Incentive_Origin_All_Key__c IN :externalKeys)
                          
                    ];
                    
                    //Decimal total = (Decimal)results[0].get('sumTotal'); 2025/11/14 調整沒有抓到值null，回傳0
                    Decimal total = (results.size() > 0 && results[0].get('sumTotal') != null)? (Decimal)results[0].get('sumTotal') : 0;

                    
                    update new CGD_Sub_Contract__c(Id = sub.Id, Actual_Chargeable_Weight__c = total);
                }
                
                subs.remove(0);
            }
            
			if (!subs.isEmpty()) System.enqueueJob(new Queue_CalculateContractIncentive(subs, joinNames));            
        } catch (Exception e) {
            
        }
    }
}