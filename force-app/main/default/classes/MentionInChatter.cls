public class MentionInChatter {

    public class InputVariables {
        @InvocableVariable
        public String postText;
        
        @InvocableVariable
        public List<String> groupIds; 
        
        @InvocableVariable
        public Id currCase; 
    }

    @InvocableMethod(label = 'Tag someone in Chatter')
    public static void tagSomeone(List<InputVariables> inputVariablesList) {

        InputVariables input = inputVariablesList[0];
        String postText = input.postText;
        List <String> groupIds = input.groupIds;
        Id currCase = input.currCase;

        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
		ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
		ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

		messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

               for(String groupId : groupIds){
                ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
                mentionSegmentInput.id = groupId;
                messageBodyInput.messageSegments.add(mentionSegmentInput);
            }
        
			ConnectApi.TextSegmentInput lineBreakSegment = new ConnectApi.TextSegmentInput();
        	lineBreakSegment.text = '\n';
        	messageBodyInput.messageSegments.add(lineBreakSegment);
        
            textSegmentInput.text = postText;     
            messageBodyInput.messageSegments.add(textSegmentInput);
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = currCase;
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        

    }
}