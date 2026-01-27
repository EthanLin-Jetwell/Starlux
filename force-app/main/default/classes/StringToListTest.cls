@IsTest
public class StringToListTest {
    
    @IsTest
    static void testConvertStringToList() {
        // Input: a list with one string containing comma-separated values
        List<String> inputStrings = new List<String>{ 'Apple,Banana,Cherry' };

        Test.startTest();
        List<String> result = StringToList.convertStringToList(inputStrings);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(3, result.size(), 'There should be three items in the output list.');
        System.assertEquals('Apple', result[0], 'First item should be Apple.');
        System.assertEquals('Banana', result[1], 'Second item should be Banana.');
        System.assertEquals('Cherry', result[2], 'Third item should be Cherry.');
    }

    @IsTest
    static void testMultipleInputStrings() {
        // Multiple input strings
        List<String> inputStrings = new List<String>{ 'A,B', 'C,D' };

        Test.startTest();
        List<String> result = StringToList.convertStringToList(inputStrings);
        Test.stopTest();

        // Verify that all values were split and combined
        System.assertEquals(4, result.size(), 'Should contain four elements total.');
        System.assertEquals(new List<String>{ 'A', 'B', 'C', 'D' }, result, 'Output list order should match expected sequence.');
    }
}