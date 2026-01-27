trigger LuckyDrawSetting_Trigger on Lucky_Draw_Setting__c (after insert, after update) {
    /*uncomment before out bound
    for(Id ids : trigger.newMap.keySet()) {
        if(trigger.newMap.get(ids).Draw_Date__c != NULL && ((trigger.isInsert) || (trigger.oldMap != NULL && trigger.newMap.get(ids).Draw_Date__c != trigger.oldMap.get(ids).Draw_Date__c))) {
            Datetime d;
            if(trigger.newMap.get(ids).Draw_Date__c == Date.today()) {
                d = Datetime.now().addMinutes(1);
            } else {
                d = Datetime.newInstance(trigger.newMap.get(ids).Draw_Date__c, Time.newInstance(00, 00, 00, 00));
            }
            Schedule_LuckDraw sch = new Schedule_LuckDraw(ids);
            System.schedule('Assign lucky number', d.format('s m H d M ? yyyy'), sch);
        }
    }
*/
}