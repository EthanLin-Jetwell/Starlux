global class InterfaceOpsDynamicListCompAttr extends VisualEditor.DynamicPickList {
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('None', 'None');
        return defaultValue;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        return getIntegrationComponentPickList();
    }

    private VisualEditor.DynamicPickListRows getIntegrationComponentPickList() {
        VisualEditor.DynamicPickListRows listForSelection = new VisualEditor.DynamicPickListRows();
        // Hard code to exclude Grant Entitlement for now because it should not be displayed for the Dynamic List component
        String queryCondition = 'Language__c = ' + '\'' + UserInfo.getLanguage() + '\'' + ' AND ' + 'DeveloperName !=' + '\'' + 'Grant_Entitlement' + '\'';
        //Retiring the line below because we are deprecating the Integration Field Display custom metadata for Mediacorp
        //List<Integration_Field_Display__mdt> customMetadataList = lib_UtilityHelper.getSObjectRecords('Integration_Field_Display__mdt', queryCondition, false);
        List<Interface_Operation_Setting__mdt> customMetadataList = lib_UtilityHelper.getSObjectRecords('Interface_Operation_Setting__mdt', queryCondition, false);
        for (Interface_Operation_Setting__mdt pickVal : customMetadataList) {
            listForSelection.addRow(new VisualEditor.DataRow((String) pickVal.Label, (String) pickVal.DeveloperName));
        }

        return listForSelection;
    }
}