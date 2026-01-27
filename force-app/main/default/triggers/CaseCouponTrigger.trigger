trigger CaseCouponTrigger on Case_Coupon__c (before insert, before update) {
    new CaseCouponTriggerHandler().run();
}