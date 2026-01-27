public class StringToCollections {
    // 輸入String 輸出List
    @InvocableMethod
    public static List<List<String>> convertStringToCollections(List<StringInput> input) {
        List<List<String>> outputCollections = new List<List<String>>();
        
        for (StringInput inputItem : input) {
            // 假設字串是以逗號分隔
            List<String> parts = inputItem.inputString.split(',');
            outputCollections.add(parts);
            System.debug('Processing input: ' + inputItem.inputString + ' -> ' + parts);
        }
        
        // 確保返回的集合大小與輸入的集合大小一致
        while (outputCollections.size() < input.size()) {
            outputCollections.add(new List<String>());
        }
        
        return outputCollections;
    }
    
    public class StringInput {
        @InvocableVariable
        public String inputString;
    }
}