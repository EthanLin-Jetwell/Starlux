@IsTest(SeeAllData=true)
private class MentionInChatter_Test {

    @IsTest
    static void testTagSomeone() {
        // 建立測試用資料
        Case testCase = new Case(Subject = 'Test Case', Status = 'New');
        insert testCase;

        String testPostText = 'This is a test post';
        List<String> testGroupIds = new List<String>();
        List<CollaborationGroup> groupsList = [SELECT Id, IsArchived FROM CollaborationGroup WHERE IsArchived = False AND CollaborationType = 'Public' LIMIT 1];
        For(CollaborationGroup groupList : groupsList)
        	{testGroupIds.add(groupList.Id);}

        // 建立Flow輸入的變數資料
        MentionInChatter.InputVariables inputVariables = new MentionInChatter.InputVariables();
        inputVariables.postText = testPostText;
        inputVariables.groupIds = testGroupIds;
        inputVariables.currCase = testCase.Id;

        List<MentionInChatter.InputVariables> inputVariablesList = new List<MentionInChatter.InputVariables>{ inputVariables };

        // 開始測試
        Test.startTest();

        // 呼叫MentionInChatter.tagSomeone
        MentionInChatter.tagSomeone(inputVariablesList);

        Test.stopTest();

    }


}