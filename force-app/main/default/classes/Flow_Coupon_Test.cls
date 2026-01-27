@isTest
public class Flow_Coupon_Test {
    public static testMethod void flowCouponQueryTest() {
		Test.startTest();
        
        Coupon__c C1 = new Coupon__c(Name = 'test');
        INSERT C1;
        Coupon__c C2 = new Coupon__c(Name = 'test');
        INSERT C2;
        Coupon__c C3 = new Coupon__c(Name = 'test');
        INSERT C3;
        
        Flow_CouponQuery.Input input = new Flow_CouponQuery.Input();
        input.startName = C1.Id;
        input.endName = C3.Id;
        
        Flow_CouponQuery.fetchCoupons(new List<Flow_CouponQuery.Input>{input});
        
        Test.stopTest();
    }
    
    public static testMethod void flowCouponUsedTest() {
		Test.startTest();
        
        Coupon__c C1 = new Coupon__c(Coupon_Status__c  = 'Distributed', Distribution_Department__c = 'AOD-TAP', Coupon_Distributed_Date__c = Date.today(), Coupon_Distributed_to_Agent_Date__c  = Date.today(), Distributed_Agent__c = '1213231');
        INSERT C1;
        Coupon__c C2 = new Coupon__c(Coupon_Status__c  = 'Distributed', Distribution_Department__c = 'AOD-TAP', Coupon_Distributed_Date__c = Date.today(), Coupon_Distributed_to_Agent_Date__c  = Date.today(), Distributed_Agent__c = '1213231');
        INSERT C2;
        Coupon__c C3 = new Coupon__c(Coupon_Status__c  = 'Distributed', Distribution_Department__c = 'AOD-TAP', Coupon_Distributed_Date__c = Date.today(), Coupon_Distributed_to_Agent_Date__c  = Date.today(), Distributed_Agent__c = '1213231');
        INSERT C3;
        
        Case c = new Case();
        INSERT c;
        
        Flow_CouponUsed.Input input = new Flow_CouponUsed.Input();
        input.startName = C1.Id;
        input.endName = C3.Id;
        input.CaseId = c.Id;
        input.issueDate = Date.today();
        input.issueReason = 'No Aaron';
        input.frontlineAuthorizationCode = 'AARON1';
        
        Flow_CouponUsed.fetchCoupons(new List<Flow_CouponUsed.Input>{input});
        
        Test.stopTest();
    }
}