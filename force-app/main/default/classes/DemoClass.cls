public class DemoClass {
    public static String demoFunction(DemoHelperClass dh) {
        if(dh.demoHelperFunction()) {
            return('stubbed');
        } else {
            return('real');
        }
    }
}