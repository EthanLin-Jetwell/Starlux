/**
 * @File Name          : InterfaceOpsDynamicListCompAttrTest.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 4/4/2019, 12:08:28 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/4/2019, 12:08:28 PM   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
@isTest
public class InterfaceOpsDynamicListCompAttrTest {

	static InterfaceOpsDynamicListCompAttr instantiateClass() {
		return new InterfaceOpsDynamicListCompAttr();
	}

	@isTest static void getDefaultValueTest() {
		System.assertEquals('None', String.valueOf(instantiateClass().getDefaultValue().getLabel()));
	}

	@isTest static void getValuesTest() {
		// Assumes that there is only 4 API Configuration
//20190901		System.assertEquals(6, instantiateClass().getValues().size());
		System.assertEquals(6, instantiateClass().getValues().size());
	}

}