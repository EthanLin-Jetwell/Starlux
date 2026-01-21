public with sharing class Flow_CouponUsed {
    public class Input {
        @InvocableVariable(label='Start Name' required=true)
        public String startName; //其實Flow傳來的是ID
        @InvocableVariable(label='End Name' required=true)
        public String endName;   //其實Flow傳來的是ID
        @InvocableVariable(label='Case Id' required=true)
        public String CaseId;
        @InvocableVariable(label='Issue Date' required=true)
        public Date issueDate;
        @InvocableVariable(label='Issue Reason' required=true)
        public String issueReason;
        //@InvocableVariable(label='Frontline Authorization Code' required=true) 23-11-23 Aaron
        @InvocableVariable(label='Frontline Authorization Code')
        public String frontlineAuthorizationCode;
    }
    
    public class Output {
        @InvocableVariable(label='Error Message')
        public String errMsg;
    }

    @InvocableMethod
    public static Void fetchCoupons(List<Input> inputList) {
        try {
            List<Coupon__c> couponsToUpdate = new List<Coupon__c>();
            List<Case_Coupon__c> Create_Case_Coupon = new List<Case_Coupon__c>();
            String UserId = UserInfo.getUserId();
            User CurrentUser = [SELECT Id, Department, Name, LastName, FirstName FROM User where Id = :UserId];
            for (Input input : inputList) {
                /*
                Coupon__c C1 = [SELECT Id, Name FROM Coupon__c WHERE Id = :input.startName];
                Coupon__c C2 = [SELECT Id, Name FROM Coupon__c WHERE Id = :input.endName];
                */
                String CurrentCaseId = input.CaseId;
                // 查詢符合條件的所有Coupon__c记录
                //List<Coupon__c> AllC = [SELECT Id, Name, Coupon_Status__c, Case_ID__c FROM Coupon__c WHERE Name >= :C1.Name AND Name <= :C2.Name AND Coupon_Status__c = 'Distributed']; 
                List<Coupon__c> AllC = [SELECT Id, Name, Coupon_Status__c, Case_ID__c FROM Coupon__c WHERE Name >= :input.startName AND Name <= :input.endName AND Coupon_Status__c = 'Distributed']; 
                
                //System.debug(C1);
                //System.debug(C2);
                System.debug(AllC);
                System.debug(CurrentCaseId);
                
                for (Coupon__c coupon : AllC) {
                    // 修改 Coupon__c狀態
                    coupon.Coupon_Status__c = 'Used';
                    coupon.Case_ID__c = CurrentCaseId;
                    //coupon.Coupon_Distributed_Date__c = system.today();
                    //coupon.Coupon_Distributed_to_Agent_Date__c = system.today();
                    //coupon.Distributed_Agent__c = CurrentUser.Id;
                    //coupon.Distributed_Department__c= 'AOD-TAP';
                    //couponsToUpdate.add(coupon);
                    //建一筆 Case_Coupon__c
                    Case_Coupon__c temp_Case_Coupon = new Case_Coupon__c();
                    temp_Case_Coupon.Case_ID__c = CurrentCaseId;
                    temp_Case_Coupon.Coupon_ID__c = coupon.Id;
                    temp_Case_Coupon.Coupon_Issue_Date__c = input.issueDate;
                    temp_Case_Coupon.Coupon_Number__c = coupon.Name;
                    temp_Case_Coupon.Issue_Reason__c = input.issueReason;
                    temp_Case_Coupon.Frontline_Authorization_Code__c = input.frontlineAuthorizationCode;
                    System.debug(temp_Case_Coupon);
                    Create_Case_Coupon.add(temp_Case_Coupon);
                }
            }
            
            // 更新所有已修改的Coupon__c記錄
            /*
            if (!couponsToUpdate.isEmpty()) {
                update couponsToUpdate;
                System.debug(couponsToUpdate);
            }*/
            if (!Create_Case_Coupon.isEmpty()) {
                Insert Create_Case_Coupon;
                System.debug(Create_Case_Coupon);
            }
            System.debug(Create_Case_Coupon);
        } catch(exception e) {
            Output output = new Output();
            output.errMsg = 'failed, error: ' + e + 'at line: ' + e.getLineNumber();
            System.debug(output);
        }

    }
}