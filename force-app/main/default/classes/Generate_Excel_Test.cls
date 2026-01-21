@isTest 
public class Generate_Excel_Test {
    /*
    @TestSetup static void dataSetup() {
        Case testCase = new Case();
    }*/
    
    @isTest(SeeAllData=True) static void testGenerateRecords() {
        //Database.executeBatch(new Batch_GenerateAgencyReport(true), 1);
        //Database.executeBatch(new Batch_GenerateAgencyReport(), 1);
        Batch_GenerateAgencyReport.fakeMethod();
        Group_By_Waypoint__c gw = new Group_By_Waypoint__c();
        
        Insert gw;
        
        Group_By_Agency__c ga = new Group_By_Agency__c();
        
        Insert ga;
        
        AgencyReport__c a = new AgencyReport__c();
        a.Group_By_Waypoint__c = gw.Id;
        a.Group_By_Agency__c = ga.Id;
        Insert a;
    }
    
    @isTest(SeeAllData=false) static void testGenerateExcelWaypoint() {
        List<AgencyReport__c> agencyReports = new List<AgencyReport__c>();
        
        Generate_Waypoint_Report_Controller waypointController  = new Generate_Waypoint_Report_Controller(new ApexPages.StandardSetController(agencyReports));
        waypointController.GetExcelData();
        
        Generate_Agency_Report_Controller agencyController  = new Generate_Agency_Report_Controller(new ApexPages.StandardSetController(agencyReports));
        agencyController.GetExcelData();
        
        Generate_Agency_Report_Controller_TPE agencyControllerTPE  = new Generate_Agency_Report_Controller_TPE(new ApexPages.StandardSetController(agencyReports));
        agencyControllerTPE.GetExcelData();
        
        Generate_Agency_Report_Controller_RMQ agencyControllerRMQ  = new Generate_Agency_Report_Controller_RMQ(new ApexPages.StandardSetController(agencyReports));
        agencyControllerRMQ.GetExcelData();
        
        Batch_Relate_Case_GroupAU.fakeMethod();
        CaseTriggerHandler.fakeMethod();
        Batch_CalculateAU.fakeMethod();
        Schedule_GenerateAgencyReport.fakeMethod();
        Schedule_Download_Excel.fakeMethod();
        Batch_Delete_Agency_Reports.fakeMethod();
        Batch_Delete_Group_By_Waypoint.fakeMethod();
        Batch_Delete_Group_By_Agency.fakeMethod();
    }
    
}