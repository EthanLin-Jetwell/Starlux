({
   doinitChange : function (component) {

      // Assign current record ID to a variable
      var recId = component.get('v.recordId');

      // Find the component whose aura:id is "flowData"
      var flow = component.find("flowData");

      // Assign current record ID to flow input variables
      var inputVariables = [
         { name : "fetch_RecordID", type : "String", value: this.recordId},         
       ];

      // In that component, start your flow. Reference the flow's API Name.
       flow.startFlow("Fetch_RecordId", inputVariables);

   }
})