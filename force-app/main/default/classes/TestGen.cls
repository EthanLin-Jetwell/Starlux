public class TestGen {/*
    public string GeneratedDate {get;set;}
    public Boolean isExport {get;set;}
    public string xmlheader {get;set;}
    public string endfile {get;set;}
    public string dateOutput {get;set;}
    private ApexPages.StandardController std;
    private Blob excelData;
    
    public List<Group_By_Agency__c> records {get;set;}
    
    public String title {get;set;}
    public static Integer titleLength {get; set;}
    
    public List<String> year_months {get;set;}
    public Map<String, List<String>> year_monthMap {get;set;}
    public Map<String, String> originMap {get;set;}
    
    //maps and 2D array for data rows
    public Map<String, List<String>> agencies {get;set;}
    public Map<String, List<String>> areas {get;set;}
    public Map<String, Map<String, Integer>> areaColumnLen {get;set;}
    public Map<String, Map<String, List<String>>> areaMap {get;set;}
    public Map<String, Map<String, List<String>>> waypointMap {get;set;}
    
    public Map<String, Map<String, Map<String, List<String>>>> dataRows {get;set;}
    public Map<String, Map<String, Map<String, String>>> areaTotal {get;set;}
    public Map<String, Map<String, String>> total {get;set;}
    public Map<String, Map<String, List<String>>> subTotal {get;set;}
    public Map<String, Map<String, String>> areaSubTotal {get;set;}
    public Map<String, String> grandTotal {get;set;}
        
    public TestGen(ApexPages.StandardController controller){
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        endfile = '</Workbook>';
        std = controller;
        //obj = (AgencyReport__c)std.getRecord();
        //obj.id = ApexPages.currentPage().getParameters().get('Id');
        GeneratedDate =date.today().format();
    }
    
    public void GetExcelData(){
        
        title = '台北出發航線對團表 (業者)  (對團日: ' + GeneratedDate + ')';
        
        records = [SELECT Id, Area__c, Agency__c, WaypointOutside__c, Total_Seat_Sales__c, Year__c, Month__c, WaypointTaiwan__c FROM Group_By_Agency__c ORDER BY Year__c, Month__c];
        year_months = new List<String>();
        year_monthMap = new Map<String, List<String>>();
        originMap = new Map<String, String>();
        agencies = new Map<String, List<String>>();
        areas = new Map<String, List<String>>();
        areaMap = new Map<String, Map<String, List<String>>>();
        areaColumnLen = new Map<String, Map<String, Integer>>();
        waypointMap = new Map<String, Map<String, List<String>>>();
        dataRows = new Map<String, Map<String, Map<String, List<String>>>>();
        areaTotal = new Map<String, Map<String, Map<String, String>>>();
        total = new Map<String, Map<String, String>>();
        subTotal = new Map<String, Map<String, List<String>>>();
        areaSubTotal = new Map<String, Map<String, String>>();
        grandTotal = new Map<String, String>();
        
        for(Group_By_Agency__c record : records) {
            String year_month = String.valueOf(record.Year__c) + String.valueOf(record.Month__c);
            List<String> dateList = new List<String>();
            dateList.add(String.valueOf(record.Year__c));
            dateList.add(String.valueOf(record.Month__c));
            if(!originMap.keySet().contains(year_month)) {
                year_months.add(year_month);
                year_monthMap.put(year_month, dateList);
                
                originMap.put(year_month, record.WaypointTaiwan__c);
                agencies.put(year_month, new List<String>());
                areas.put(year_month, new List<String>());
                areaMap.put(year_month, new Map<String, List<String>>());
                areaColumnLen.put(year_month, new Map<String, Integer>());
                waypointMap.put(year_month, new Map<String, List<String>>());
                dataRows.put(year_month, new Map<String, Map<String, List<String>>>());
                areaTotal.put(year_month, new Map<String, Map<String, String>>());
                total.put(year_month, new Map<String, String>());
                subTotal.put(year_month, new Map<String, List<String>>());
                areaSubTotal.put(year_month, new Map<String, String>());
                grandTotal.put(year_month, '-');
            }
        }
            
        
        for(Group_By_Agency__c record : records) {
            for(String year_month : year_months) {
                if(!agencies.get(year_month).contains(record.Agency__c)) {
                    agencies.get(year_month).add(record.Agency__c);
                    areaTotal.get(year_month).put(record.Agency__c, new Map<String, String>());
                    total.get(year_month).put(record.Agency__c, '-');
                }
                
                if(!areas.get(year_month).contains(record.Area__c)) {
                    areas.get(year_month).add(record.Area__c);
                    areaMap.get(year_month).put(record.Area__c, new List<String>());
                }
                
                if(!areaMap.get(year_month).get(record.Area__c).contains(record.WaypointOutside__c)) {
                    areaMap.get(year_month).get(record.Area__c).add(record.WaypointOutside__c);
                }
            }
        }
        
        for(String year_month : year_months) {
            for(String agency : agencies.get(year_month)) {
                Map<String, List<String>> tempMap = new Map<String, List<String>>();
                for(String area : areas.get(year_month)) {
                    List<String> tempList = new List<String>();
                    Integer length = 0;
                    for(String waypoint : areaMap.get(year_month).get(area)) {
                        tempList.add('-');
                        length++;
                    }
                    tempMap.put(area, tempList);
                    areaColumnLen.get(year_month).put(area, length - 1);
                    areaTotal.get(year_month).get(agency).put(area, '-');
                    subTotal.get(year_month).put(area, new List<String>(tempList));
                    areaSubTotal.get(year_month).put(area, '-');
                }
                dataRows.get(year_month).put(agency, tempMap);
            }
        }
        
        for(Group_By_Agency__c record : records) {
            String year_month = String.valueOf(record.Year__c) + String.valueOf(record.Month__c);
            Integer pos = areaMap.get(year_month).get(record.Area__c).indexOf(record.WaypointOutside__c);
            dataRows.get(year_month).get(record.Agency__c).get(record.Area__c)[pos] = (record.Total_Seat_Sales__c == 0)? '-' : String.valueOf(record.Total_Seat_Sales__c);
            areaTotal.get(year_month).get(record.Agency__c).put(record.Area__c, calTotal(areaTotal.get(year_month).get(record.Agency__c).get(record.Area__c), (Integer)record.Total_Seat_Sales__c));
            total.get(year_month).put(record.Agency__c, calTotal(total.get(year_month).get(record.Agency__c), (Integer)record.Total_Seat_Sales__c));
            subTotal.get(year_month).get(record.Area__c)[pos] = calTotal(subTotal.get(year_month).get(record.Area__c)[pos], (Integer)record.Total_Seat_Sales__c);
            areaSubTotal.get(year_month).put(record.Area__c, calTotal(areaSubTotal.get(year_month).get(record.Area__c), (Integer)record.Total_Seat_Sales__c));
            grandTotal.put(year_month, calTotal(grandTotal.get(year_month), (Integer)record.Total_Seat_Sales__c));
        }
        
        titleLength = subTotal.get(year_months[0]).size() + areaSubTotal.get(year_months[0]).size() + grandTotal.size() + 1;
            
        System.debug(agencies);
        System.debug(areaMap);
        System.debug(waypointMap);
        System.debug(dataRows);
        System.debug(areaTotal);
        System.debug(total);
        
        System.debug(subTotal);
        System.debug(areaSubTotal);
    }
    
    public String calTotal(String original, Integer value) {
        System.debug(value);
        if(value == 0) {
            return original;
        } else if(original == '-') {
            return String.valueOf(value);
        }
        return String.valueOf(Integer.valueOf(original) + value);
    }*/
}