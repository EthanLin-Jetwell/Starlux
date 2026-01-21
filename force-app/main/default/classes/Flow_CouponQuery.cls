public with sharing class Flow_CouponQuery {
    public class Input {
        @InvocableVariable(label='Start Name' required=true)
        public String startName; //其實Flow傳來的是ID
        @InvocableVariable(label='End Name' required=true)
        public String endName;   //其實Flow傳來的是ID
    }

    public class Output {
        @InvocableVariable(label='Coupon Ids')
        public List<Id> couponIds;
    }

    @InvocableMethod
    public static List<Output> fetchCoupons(List<Input> inputList) {
        List<Output> outputList = new List<Output>();
        for (Input input : inputList) {
            /*
            Coupon__c C1 = [SELECT Id, Name FROM Coupon__c WHERE Id = :input.startName];
            Coupon__c C2 = [SELECT Id, Name FROM Coupon__c WHERE Id = :input.endName];
            List<Coupon__c> AllC = [SELECT Id, Name FROM Coupon__c WHERE Name >= :C1.Name AND Name <= :C2.Name]; 
            system.debug(C1);
            system.debug(C2);
 			*/
            List<Coupon__c> AllC = [SELECT Id, Name FROM Coupon__c WHERE Name >= :input.startName AND Name <= :input.endName]; 
            system.debug(AllC);
            system.debug(input.startName);
            system.debug(input.endName);
            Output output = new Output();
            output.couponIds = new List<Id>();
            FOR(Coupon__c C: AllC)
            {output.couponIds.add(C.Id);}
            outputList.add(output);
        }

        return outputList;
    }
}