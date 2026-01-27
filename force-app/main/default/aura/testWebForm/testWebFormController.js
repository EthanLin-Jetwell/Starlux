({
    handleSuccess : function(component, event, helper) {
    	console.log(event.getParams().response);
        for (let key of Object.keys(event.getParams().response)) {
            console.log(key + event.getParams().response[key]);
        }
        console.log(event.getParams().response.id);
        //console.log(component.find("name").get("v.value"));
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been created successfully.",
            "type": "success"
        });
        toastEvent.fire();
    },
    
    handleSubmit : function(component, event, helper) {
        console.log('Submit Event' + JSON.stringify(event.getParams()));

		// HANDLE Field Value OVERRIDE BEFORE submit
        event.preventDefault(); // stop form submission 
        
        // EXAPLE: Concat first & last names
        var givenName = component.find("GivenName").get("v.value");
        var familyName = component.find("FamilyName").get("v.value");
        
        var eventFields = event.getParam("fields"); 
        eventFields["SuppliedName"] = familyName + " " + givenName; 
        component.find("testWebForm").submit(eventFields);
    },
    
    handleOnload : function(component, event, helper) {
        console.log('Load Event' + JSON.stringify(event.getParams()));
        
        // PRESET Picklist Item
        component.find("Origin").set("v.value", "Web Form");
        component.find("Case_Sub_type__c").set("v.value", "Invoice");
    }, 
    
})