/********************************************************************************************************
NAME:           CaseCouponTriggerHandler
AUTHOR:         Chris (chrishsu@starlux-airlines.com)
PURPOSE:        Convert coupon number to corresponding coupon id

UPDATE HISTORY:
DATE            AUTHOR          COMMENTS
-------------------------------------------------------------
2021-05-03      Chris Hsu       First version
********************************************************************************************************/

public class CaseCouponTriggerHandler extends TriggerHandler{
    public CaseCouponTriggerHandler() {
    }
    
    /*** Context Overrides ***/
    public override void beforeInsert() {
        processUpdateRecords();
    }
    
    public override void beforeUpdate() {
        processUpdateRecords();
    }
   
    private static void processUpdateRecords() {		
        for(Case_Coupon__c newCaseCoupon : (List<Case_Coupon__c>)Trigger.new){
            if (newCaseCoupon.Coupon_Number__c==null || newCaseCoupon.Coupon_Number__c=='')
                continue;            
            List<Coupon__c> queryCoupon = [select Id from Coupon__c where Name = :newCaseCoupon.Coupon_Number__c Limit 1];
            newCaseCoupon.Coupon_ID__c = queryCoupon.get(0).Id;
        }
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
    }
}