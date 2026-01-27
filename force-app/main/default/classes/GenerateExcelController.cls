public class GenerateExcelController {
    public string GeneratedDate {get;set;}
    public Boolean isExport {get;set;}
    public string xmlheader {get;set;}
    public string endfile {get;set;}
    public string dateOutput {get;set;}
    private ApexPages.StandardController std;
    private Blob excelData;
    
    public List<Group_By_Waypoint__c> records {get;set;}
    
    public static Integer titleLength {get; set;}
    public static Integer columns {get; set;}
    public static List<String> nullStrList {get; set;}
    public static List<String> nullDataList {get; set;}
    public Integer repeat {get; set;}
        
    public String title {get;set;}
    public List<Integer> months {get;set;}
    public List<String> fields {get;set;}
    
    public Set<String> origins {get;set;}
    
    //maps and 2D array for data rows
    public Map<String, Set<String>> areas {get;set;}
    public Map<String, Map<String, Set<String>>> areaMap {get;set;}
    public Map<String, Map<String, List<String>>> areaTotal {get;set;}
    public Map<String, Map<String, List<String>>> waypointMap {get;set;}
    //
    public Map<String, List<String>> total {get;set;}
    
    public List<String> grandTotal {get;set;}
    
    public GenerateExcelController(ApexPages.StandardController controller){
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        endfile = '</Workbook>';
        std = controller;
        //obj = (AgencyReport__c)std.getRecord();
        //obj.id = ApexPages.currentPage().getParameters().get('Id');
        GeneratedDate =date.today().format();
    }
    
    public void GetExcelData(){
        columns = 6;
        nullStrList = new String[columns];
        nullStrList.set(0, '0');
        nullStrList.set(1, '0');
        nullStrList.set(2, '0');
        nullStrList.set(3, '0');
        nullStrList.set(4, '-');
        nullStrList.set(5, '-');
        
        nullDataList = new List<String>();
        
        title = '台灣區全航線對團表 (航線)  (對團日: ' + GeneratedDate + ')';
        months = new List<Integer>();
        fields = new List<String>();
        
        origins = new Set<String>();
        
        areas = new Map<String, Set<String>>();
        areaMap = new Map<String, Map<String, Set<String>>>();
        areaTotal = new Map<String, Map<String, List<String>>>();
        waypointMap = new Map<String, Map<String, List<String>>>();
        
        total = new Map<String, List<String>>();
        
        //Date createdDate = 
        
        records = [SELECT Id, Original_AU__c, Month__c, Area__c, WaypointOutside__c, WaypointTaiwan__c, Year__c, Total_Final_Allocated_Seats__c, Total_Final_Allocated_Seats_Y__c, Total_Seat_Sales__c, Total_Seat_Sales_Y__c, Intake__c, AU_Use_Rate__c, Total_Final_Allocated_Seat_Used_Rate__c  FROM Group_By_Waypoint__c WHERE CreatedDate = THIS_YEAR ORDER BY Month__c, Area__c];
        
        Integer month = 0;
        
        //find all the months
        for(Group_By_Waypoint__c record : records) {
            month = Integer.valueOf(record.Month__c);
            if(!months.contains(month)) {
                months.add(month);
                nullDataList.addAll(nullStrList);
                System.debug(nullDataList.size());
            }
            if(month == 12) {
                break;
            }
        }
        
        //set title merge accross length
        titleLength = months.size() * columns;
        
        for(Group_By_Waypoint__c record : records) {
            if(!origins.contains(record.WaypointTaiwan__c)) {
                origins.add(record.WaypointTaiwan__c);
                areas.put(record.WaypointTaiwan__c, new Set<String>());
                areaMap.put(record.WaypointTaiwan__c, new Map<String, Set<String>>());
                areaTotal.put(record.WaypointTaiwan__c, new Map<String, List<String>>());
                waypointMap.put(record.WaypointTaiwan__c, new Map<String, List<String>>());
                total.put(record.WaypointTaiwan__c, new List<String>(nullDataList));
                grandTotal = new List<String>(nullDataList);
            }

            month = Integer.valueOf(record.Month__c);
            
            //interpolate table
            Boolean newArea = false;
            //put area in
            areas.get(record.WaypointTaiwan__c).add(record.Area__c);
            if(!areaMap.get(record.WaypointTaiwan__c).keySet().contains(record.Area__c)) {
                areaMap.get(record.WaypointTaiwan__c).put(record.Area__c, new Set<String>());
                areaTotal.get(record.WaypointTaiwan__c).put(record.Area__c, new List<String>(nullDataList));
            }
            areaMap.get(record.WaypointTaiwan__c).get(record.Area__c).add(record.WaypointOutside__c);
            //put waypoint in
            List<String> tempList = new List<String>();
            
            //fields
            tempList.add(String.valueOf(record.Original_AU__c));
            tempList.add(String.valueOf(record.Total_Final_Allocated_Seats__c));
            tempList.add(String.valueOf(record.Total_Seat_Sales__c));
            tempList.add(String.valueOf(record.Intake__c));
            tempList.add(!(record.AU_Use_Rate__c == NULL)? String.valueOf(record.AU_Use_Rate__c) + '%' : '-');
            tempList.add(!(record.Total_Final_Allocated_Seat_Used_Rate__c == NULL)? String.valueOf(record.Total_Final_Allocated_Seat_Used_Rate__c) + '%' : '-');

            if(!waypointMap.get(record.WaypointTaiwan__c).keySet().contains(record.WaypointOutside__c)) waypointMap.get(record.WaypointTaiwan__c).put(record.WaypointOutside__c, new List<String>(nullDataList));
            //pointer for modify row
            List<String> tempRow = waypointMap.get(record.WaypointTaiwan__c).get(record.WaypointOutside__c);
            
            Integer pos = months.indexOf(month) * columns;
            System.debug(month);
            System.debug(pos);
            for(String val : tempList) {
                tempRow[pos] = val;
                pos++;
            }
        }
        repeat = months.size();
        
        
        System.debug(areas);
        System.debug(areaMap);
        System.debug(waypointMap);
        System.debug(areaTotal);
        System.debug(total);
        calAggrResult();
    }
    
    public void calAggrResult() {
        for(String origin : origins) {
            for(String area : areas.get(origin)) {
                Integer waypointCount = areaMap.get(origin).get(area).size();
                List<String> tempAreaTotal = areaTotal.get(origin).get(area);
                List<String> tempTotal = total.get(origin);
                for(String waypoint : areaMap.get(origin).get(area)) {
                    Integer pos = 0;
                    for(String value : waypointMap.get(origin).get(waypoint)) {
                        String originalAT = tempAreaTotal[pos];
                        String originalT = tempTotal[pos];
                        if(value == '0' || value == '-' || value == NULL) {
                            
                        } else if(originalAT.contains('-') || originalAT.contains('%')) {
                            String tempAT = originalAT.remove('-').remove('%');
                            if(tempAT == '') tempAT = '0'; 
                            originalAT = String.valueOf((Decimal.valueOf(tempAT) * waypointCount + Decimal.valueOf(value.remove('%'))) / waypointCount) + '%';
                            String tempT = originalT.remove('-').remove('%');
                            if(tempT == '') tempT = '0'; 
                            originalT = String.valueOf((Decimal.valueOf(tempAT) * waypointCount + Decimal.valueOf(value.remove('%'))) / waypointCount) + '%';
                        } else {
                            originalAT = String.valueOf(Decimal.valueOf(originalAT) + Decimal.valueOf(value.remove('%')));
                            
                            originalT = String.valueOf(Decimal.valueOf(originalT) + Decimal.valueOf(value.remove('%')));
                        }
                        
                        tempAreaTotal[pos] = originalAT;
                        tempTotal[pos] = originalT;
                        pos++;
                    }
                }
            }
        }
    }
}