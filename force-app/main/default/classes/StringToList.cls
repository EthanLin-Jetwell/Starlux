public class StringToList { 
    @InvocableMethod public static List<String> convertStringToList(List<String> inputStrings) { 
        List<String> outputList = new List<String>(); 
        for (String inputString : inputStrings) { 
            // 假設字串是以逗號分隔 
            List<String> parts = inputString.split(','); 
            outputList.addAll(parts); 
        } 
        return outputList; 
    } 
}