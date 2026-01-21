trigger ExternalTicketTrigger on External_Tickets__c (before insert, before update) {
    switch on Trigger.OperationType  {
        when BEFORE_INSERT {
            ExternalTicketTrigger_Handler.updateRedeemCouponNumber(trigger.new); //Herbert 2025/11/27 把註記拔掉
            ExternalTicketTrigger_Handler.updateItemNumber(trigger.new);
        }
        when AFTER_INSERT {
            
        }
        when BEFORE_UPDATE {
            ExternalTicketTrigger_Handler.createTicketCertificate(trigger.oldMap, trigger.new);
        }
        when AFTER_UPDATE {
            
        }
    }
}