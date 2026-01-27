global class APIEndPointDesignAttributes extends VisualEditor.DynamicPickList {
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('None', 'None');
        return defaultValue;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        return getIntegrationComponentPickList();
    }

    private VisualEditor.DynamicPickListRows getIntegrationComponentPickList() {
        VisualEditor.DynamicPickListRows listForSelection = new VisualEditor.DynamicPickListRows();
        String queryCondition = 'Object_to_Display__c  =' + '\'' + 'CRANE' + '\'';
        List<Interface_Configuration__mdt> customMetadataList = lib_UtilityHelper.getSObjectRecords('Interface_Configuration__mdt', queryCondition, false);
        for (Interface_Configuration__mdt pickVal : customMetadataList) {
            listForSelection.addRow(new VisualEditor.DataRow((String)pickVal.Label, (String) pickVal.DeveloperName));
        }
        return listForSelection;
    }
}