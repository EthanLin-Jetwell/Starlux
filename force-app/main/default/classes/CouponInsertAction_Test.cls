@isTest
public class CouponInsertAction_Test {
    public static testMethod void createCouponsWithValidParameters() {
        Coupon__c existingCoupon = new Coupon__c(Coupon_Currency__c = 'USD');
        String batchMonth = String.valueOf(system.today().month());
        while (batchMonth.length() == 1) {
            batchMonth = '0' + batchMonth;
        }
        
        String batchDay = String.valueOf(system.today().day());
        while (batchDay.length() == 1) {
            batchDay = '0' + batchDay;
        }
        String batchPrefix = 'BATCH-' + String.valueOf(system.today().year()) + batchMonth + batchDay;
        String batchString = batchPrefix + '-10';
        existingCoupon.BATCH_No__c = batchString;
        insert existingCoupon;
        
        List<String> couponParameters = new List<String>();
        couponParameters.add('5,2500,USD,PMD,TESTNAME');
        
        test.startTest();
        CouponInsertAction.createCoupons(couponParameters);
        test.stopTest();
        
        List<Coupon__c> createdCoupons = [SELECT Id, Coupon_Value__c, Coupon_Currency__c, Batch_No__c FROM Coupon__c WHERE Coupon_Value__c = 2500]; 
        system.assertEquals(5, createdCoupons.size());
        system.assertEquals(batchPrefix+'-11', createdCoupons[0].Batch_No__c);
        system.assertEquals('USD', createdCoupons[0].Coupon_Currency__c);
        system.assertEquals(2500, createdCoupons[0].Coupon_Value__c);
    }
    
    public static testMethod void createCouponsWithInvalidParameters() {
        List<String> couponParameters = new List<String>();
        couponParameters.add('5,TWENTY,NTD,PMD,TESTNAME'); //Coupon value needs to be numeric integer
        
        test.startTest();
        try {
            CouponInsertAction.createCoupons(couponParameters);
        } catch (TypeException TypeError) {
        }
        test.stopTest();
        
        List<Coupon__c> createdCoupons = [SELECT Id, Coupon_Value__c, Coupon_Currency__c FROM Coupon__c];
        system.assertEquals(0, createdCoupons.size());
        
    }
}