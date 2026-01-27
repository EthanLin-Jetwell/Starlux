/********************************************************************************************************
NAME:           CouponInsertAction
AUTHOR:         Edmond To (eto@salesforce.com)
PURPOSE:        To perform creation of Coupon records based on input parameters from the screen flow.

UPDATE HISTORY:
DATE            AUTHOR          COMMENTS
-------------------------------------------------------------
24/06/2019      Edmond To       First version
27/11/2019      Chris Hsu       Insert CreateDate and change Coupon Number rule
26/12/2019      Chris Hsu       Generate iPOS_Base64 and checkSum
06/08/2020      Chris Hsu       Prevent hitting SOQL limit
********************************************************************************************************/

public class CouponInsertAction {
    
    //Application Log 062419
    private static List<System_Settings__mdt> logLevelCMD;
    private static DateTime startTime = DateTime.now();
    private static String processLog;
    private static String payLoad;
    private static Integer totalRecords = 0, errorRecords = 0, successfulRecords = 0;
    private static List<String> failureRecords = new List<String>();
    
    @InvocableMethod(label='Insert Coupons' description='Creates a set of pre-generated coupon records based on the input values.')
    public static List<String> createCoupons(List<String> CouponParameters) { //Integer CouponValue, Integer CouponNumber, String CouponCurrency, String DistributionValue, String PICValue
       
        //Application Log 062419
        System_Settings__mdt logLevelCMD = [Select Id, MasterLabel, Debug__c, Info__c, Warning__c, Error__c From
                                            System_Settings__mdt
                                            Where MasterLabel = 'Coupon Insert Action'
                                            limit 1];
        
        //Prepare month
        String sequentialMonth = string.valueOf(System.Today().Month()); 
        while (sequentialMonth.length() < 2) {
            sequentialMonth = '0' + sequentialMonth;
        }    
        
        //Prepare day
        String sequentialDay = String.valueOf(system.today().day());
        while (sequentialDay.length() < 2) {
            sequentialDay = '0' + sequentialDay;
        }
         
        //Prepare the batch time stamp for Batch Number
        String batchDate = String.valueOf(system.today().year()) + sequentialMonth + sequentialDay;
        String queryBatchString= 'BATCH-' + batchDate + '-%'; 
        Integer batchNumber = 1;
        
        //Prepare the Coupon Create Date: Chris Hsu 2019-11-27
        Date CouponCreatedDate  = Date.valueOf(String.valueOf(system.today().year())+'-'+
                                             String.valueOf(system.today().Month())+'-'+String.valueOf(system.today().day()));
        
        //Querying all existing Coupon records with target batch number
        //Prevent hitting SOQL limit : Chris 20200806-Start		       
        //List<Coupon__c> existingBatches = [SELECT Id, Batch_No__c FROM Coupon__c WHERE Batch_No__c LIKE :queryBatchString];
        List<Coupon__c> existingBatches = [SELECT Id, Batch_No__c FROM Coupon__c WHERE Batch_No__c LIKE :queryBatchString Order by Batch_No__c DESC limit 1]; 
        //Chris 20200806-End
        for (Integer i = 0; i<existingBatches.size(); i++) {
            Integer currentBatchNumber = Integer.valueOf(existingBatches[i].Batch_No__c.remove('BATCH-' + batchDate + '-'));
            if (currentBatchNumber >= batchNumber) {
                batchNumber = currentBatchNumber + 1;
            }
        }
        
        //Prepare batch number value for Coupon record batch
        String batchNumberString = String.valueOf(batchNumber);
        while (batchNumberString.length() == 1) {
            batchNumberString = '0' + batchNumberString;
        }
        String batchString = 'BATCH-' + batchDate + '-' + batchNumberString;
        
        //String for querying existing Coupon records
        //Remove 'C' : Chris 2019-11-27
        String queryString = String.valueOf(system.today().year()) + sequentialMonth + '%';
        
        //Querying all existing Coupon records with target prefix
        // Prevent hitting SOQL limit : Chris 20200806-Start 
        	//List <Coupon__c> existingCoupons = [SELECT Id FROM Coupon__c WHERE Name LIKE :queryString]; 
        	//Integer existingSize = existingCoupons.size(); //Determine starting numbering for new batch of Coupon records
        Integer existingSize = 0;//Determine starting numbering for new batch of Coupon records
        List<AggregateResult> ars_count = [SELECT count(Id) total FROM Coupon__c WHERE Name LIKE :queryString];
        for (AggregateResult ar : ars_count) {
            existingSize=Integer.valueOf(ar.get('total'));
        }     
        // Chris 20200806-End
        
        //Retrieve Coupon parameters for record creation
        List<String> CouponParametersSplit = CouponParameters[0].split(','); 
        Integer CouponNumber = Integer.valueOf(CouponParametersSplit[0]);        
        Integer CouponValue = Integer.valueOf(CouponParametersSplit[1]);
        String CouponCurrency = CouponParametersSplit[2];
        //String DistributionValue = CouponParametersSplit[3];
        //String PICValue = CouponParametersSplit[4];
        
        List<Coupon__c> recordsToInsert = new List<Coupon__c>();
        List<String> outputList = new List<String>();
        String DMLErrorString = '';
        
        //Iterate through target batch size for record creation
        for (Integer i = existingSize; i<CouponNumber+existingSize; i++) {
            String sequentialNumber = String.valueOf(i);
            
            while (sequentialNumber.length() < 6) {
                sequentialNumber = '0' + sequentialNumber;
            }
            
            //Provide field values for record creation
            Coupon__c newCoupon = new Coupon__c();	
            newCoupon.Coupon_Currency__c = CouponCurrency;
            newCoupon.Coupon_Value__c = CouponValue;
            //newCoupon.Coupon_Status__c= 'Created';
            newCoupon.Coupon_Type__c = 'Pre-Generated';
            newCoupon.Name = String.valueOf(System.Today().year())+sequentialMonth+sequentialNumber;//Remove 'C': Chris Hsu 2019-11-27
            newCoupon.BATCH_No__c = batchString;
            //newCoupon.Distribution_Department__c = DistributionValue;
            //newCoupon.PIC_of_Distribution_Department__c = PICValue;
            //newCoupon.Coupon_Created_Date__c = CouponCreatedDate;//Generate CreateDate automatically: Chris Hsu 2019-11-27
            
            //Chris Hsu 2019-12-26
            Long lon_name = Long.valueOf(newCoupon.Name);
            newCoupon.Coupon_Checksum__c=math.mod(lon_name,7);
            newCoupon.Base64_No_from_iPOS_No__c=newCoupon.Name+'|'+CouponValue+'|'+newCoupon.Coupon_Checksum__c;
            String encodedPassword = EncodingUtil.base64Encode(blob.valueof(newCoupon.Base64_No_from_iPOS_No__c));
            newCoupon.Base64_No_from_iPOS_No__c=encodedPassword;
            //system.debug('********encodedPassword:' + encodedPassword);
            //blob decodedPasswordBlob = EncodingUtil.base64Decode(encodedPassword);
            //system.debug('********decodedPassword Blob:' + decodedPasswordBlob);
            //system.debug('********decodedPassword:' + decodedPasswordBlob.tostring());
           
            recordsToInsert.add(newCoupon);
            totalRecords++;
        }    
        
        //Try catch to insert records
        try {
            Database.SaveResult[] SaveResult = database.insert(recordsToInsert, false);
            for (Integer i = 0; i < SaveResult.size(); i++) {
                if (!SaveResult[i].isSuccess()) {
                    for (Database.Error err : SaveResult[i].getErrors()) {
                        errorRecords++;
                        failureRecords.add(SaveResult[i].Id);
                        processLog += 'Unable to insert Record ID: ' + SaveResult[i].Id + '\r\n';
                        processLog += 'Root Cause: ' + err.getStatusCode() + ':' + err.getMessage() + '\r\n';
                        processLog += 'Fields that caused this error: ' + err.getFields() + '\r\n';
                    }
                } else {
                    //system.debug('DBG SaveResult[i]: '+ SaveResult[i]);
                    successfulRecords++;
                }
            }
            
            processLog = '#########################\r\n' +
            'Job Name: ' + logLevelCMD.MasterLabel + '\r\n' +
            'Start Date Time: ' + string.valueof(startTime) + '\r\n' +
            'End Date Time: ' + string.valueof(DateTime.Now()) + '\r\n' +
            'Total Processed Records: ' + totalRecords + '\r\n' +
            'Total Successful Inserted Records: ' + successfulRecords + '\r\n' +
            'Total Failed Records: ' + errorRecords + '\r\n' + 
            'List of Failed Records: ' + failureRecords + '\r\n' +
            '#########################\r\n' + processLog;
            
            system.debug('DBG ProcessLog: '+processLog);
            
            //Application Log 062419
            GlobalUtility.logMessage(Utilities.createApplicationLog('Info', 'CouponInsertAction', 'createCoupons', null, 'Pre-Generated Coupons Creation', processLog, payLoad, 'Job Log', startTime, logLevelCMD, null));
        
        } catch (DmlException DMLError) {
            
            DMLErrorString = String.valueOf(DMLError);
            //Application Log 062419
            GlobalUtility.logMessage(Utilities.createApplicationLog('Error', 'CouponInsertAction', 'createCoupons', null, 'Pre-Generated Coupons Creation', processLog, payLoad, 'Error Log', startTime, logLevelCMD, DMLError));
        }
        
        if (errorRecords != 0) {
                outputList.add(DMLErrorString);
            } else {
                outputList.add('Success');
            }
        
        return outputList;
    }
}