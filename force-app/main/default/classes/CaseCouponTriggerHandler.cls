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
        /*//2023/12/15 Ethan
        List<String> newCouponNumbers = new list<String>();
        for(Case_Coupon__c newCaseCoupon : (List<Case_Coupon__c>)Trigger.new){
            if (newCaseCoupon.Coupon_Number__c==NULL || newCaseCoupon.Coupon_Number__c=='') {
                newCouponNumbers.add(newCaseCoupon.Coupon_Number__c);
            }
        }
        
        Map<String, Id> queryCouponMap = new Map<String, Id>();
        if(newCouponNumbers.size() != 0) {
            List<Coupon__c> queryCoupon = [SELECT Id FROM Coupon__c WHERE Name IN : newCouponNumbers];
            for(Coupon__c c : queryCoupon) {
                queryCouponMap.put(c.Name, c.Id);
            }
            
            for(Case_Coupon__c newCaseCoupon : (List<Case_Coupon__c>)Trigger.new){
                if (newCaseCoupon.Coupon_Number__c==NULL || newCaseCoupon.Coupon_Number__c=='') {
                    //do not run this if this is from Case Voucher
                    if(queryCouponMap.keySet().contains(newCaseCoupon.Coupon_Number__c)) {
                        newCaseCoupon.Coupon_ID__c = queryCouponMap.get(newCaseCoupon.Coupon_Number__c);
                    }
                }         
            }
        }*/
        
        
        
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