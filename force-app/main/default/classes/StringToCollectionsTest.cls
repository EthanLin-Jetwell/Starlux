@IsTest
private class StringToCollectionsTest {
    
    @IsTest
    static void testConvertStringToCollections_NormalCase() {
        // Prepare test data
        StringToCollections.StringInput input1 = new StringToCollections.StringInput();
        input1.inputString = 'A,B,C';
        
        StringToCollections.StringInput input2 = new StringToCollections.StringInput();
        input2.inputString = 'X,Y';
        
        List<StringToCollections.StringInput> inputList = new List<StringToCollections.StringInput>{ input1, input2 };

        // Run the method
        Test.startTest();
        List<List<String>> result = StringToCollections.convertStringToCollections(inputList);
        Test.stopTest();
        
        // Verify the output
        System.assertEquals(2, result.size(), 'The output should have two lists.');
        System.assertEquals(new List<String>{'A','B','C'}, result[0], 'First list should match the expected split values.');
        System.assertEquals(new List<String>{'X','Y'}, result[1], 'Second list should match the expected split values.');
    }
    
    @IsTest
    static void testConvertStringToCollections_SingleValue() {
        // Single, no comma input
        StringToCollections.StringInput input1 = new StringToCollections.StringInput();
        input1.inputString = 'Hello';
        
        List<StringToCollections.StringInput> inputList = new List<StringToCollections.StringInput>{ input1 };

        Test.startTest();
        List<List<String>> result = StringToCollections.convertStringToCollections(inputList);
        Test.stopTest();

        // Verify
        System.assertEquals(1, result.size(), 'Output should have one list.');
        System.assertEquals(new List<String>{'Hello'}, result[0], 'List should contain a single element.');
    }
}