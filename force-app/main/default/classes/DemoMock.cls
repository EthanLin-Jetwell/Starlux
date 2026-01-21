@isTest
public class DemoMock implements System.StubProvider {
    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
        if(stubbedMethodName == 'demoHelperFunction') {
            return true;
        }
        return null;
    }
}