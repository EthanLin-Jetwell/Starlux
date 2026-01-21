@isTest
public class APIEndPointDesignAttributesTest {

	static APIEndPointDesignAttributes instantiateClass() {
		return new APIEndPointDesignAttributes();
	}

	@isTest static void getDefaultValueTest() {
		System.assertEquals('None', String.valueOf(instantiateClass().getDefaultValue().getLabel()));
	}

	@isTest static void getValuesTest() {
		// Check number of Interface Configurations
		System.assertEquals(1, instantiateClass().getValues().size());
	}

}