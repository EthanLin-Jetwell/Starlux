@isTest(SeeAllData=FALSE)
public class FlightTime_Test {
    public static testMethod Void testAll() {
        MiddlewareUtil.fakeMethod();
        ReceiveResponseUpdateFlightTime.fakeMethod();
        MwGetUpdateResponseWrapper.fakeMethod();
        ReceiveResponseCreatePnrApi.fakeMethod();
    }
}