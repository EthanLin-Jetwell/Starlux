@isTest
private class ResponseModel_Test {

    @isTest
    static void testResponseModelCreation() {
        // Arrange
        Integer resultCode = 200;
        String traceID = '12345';
        String objectID = 'Record001';
        String SF_Return_BG_No = 'BG001';
        String resultMessage = 'Success';

        // Act
        ResponseModel response = new ResponseModel(resultCode, traceID, objectID, SF_Return_BG_No, resultMessage);

        // Assert
        System.assertEquals(traceID, response.traceID);
        System.assertEquals(true, response.success);
        System.assertEquals('success', response.data.status);
        System.assertEquals(objectID, response.data.recordId);
        System.assertEquals(SF_Return_BG_No, response.data.SF_Return_BG_No);
        System.assertEquals(resultCode, response.message.code);
        System.assertEquals('OK', response.message.content);
        System.assertEquals(null, response.message.details);
    }

    @isTest
    static void testHttpMessageFor200() {
        // Arrange
        Integer resultCode = 200;
        String resultMessage = 'Success';

        // Act
        ResponseModel response = new ResponseModel(resultCode, '123', 'Record001', 'BG001', resultMessage);

        // Assert
        System.assertEquals('OK', response.getHttpMessage(resultCode, resultMessage));
    }

    @isTest
    static void testHttpMessageFor404() {
        // Arrange
        Integer resultCode = 404;
        String resultMessage = 'Not Found';

        // Act
        ResponseModel response = new ResponseModel(resultCode, '123', 'Record001', 'BG001', resultMessage);

        // Assert
        System.assertEquals('Not Found, ' + resultMessage, response.getHttpMessage(resultCode, resultMessage));
    }
}