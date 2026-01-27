({
    doInit : function(component, event, helper) {
        var device = $A.get("$Browser.formFactor");
        component.set('v.Device',device);

        var action = component.get("c.getEnquiryRecordTypeId");
        action.setCallback(this, function(response) {
        	var state = response.getState();
			if (state === "SUCCESS") {
                component.set("v.EnquiryRecordTypeId", response.getReturnValue() );
                console.log( response.getReturnValue() );
            } 
            else if (state === "INCOMPLETE") {
            }
            else if (state === "ERROR") {
                var errors = response.getError();
				console.log( errors );
            }
        });
        
        $A.enqueueAction(action);
    
    },
    
    handleSuccess : function(component, event, helper) {
    	//console.log(event.getParams().response);
    	console.log('handling success submit');
        //console.log(event.getParams().response.id);
        //console.log(component.find("SuppliedPhone").get("v.value"));
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title":  $A.get("$Label.c.webForm_message_Success"),
            "message": $A.get("$Label.c.webForm_message_RecordCreationSuccess"),
            "type": "success"
        });
        toastEvent.fire();
        
     
        var address = '/formSuccess';
        var urlEvent = $A.get("e.force:navigateToURL");
            
        urlEvent.setParams({
          "url": address
        });
        urlEvent.fire();
        
    },
    
    handleError : function(component, event, helper) {
        console.log('handling error');
        var error = event.getParams();
        console.log(event.getParam('output'));
        console.log(error);
        var errorMessage = event.getParam("message");
        console.log(errorMessage);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": $A.get("$Label.c.webForm_message_Error"),
            "message": errorMessage,
            "type": "error"
        });
        toastEvent.fire();
    },
    
    handleSubmit : function(component, event, helper) {
        //console.log('Submit Event' + JSON.stringify(event.getParams()));
		
		// HANDLE Field Value OVERRIDE BEFORE submit
        event.preventDefault(); // stop form submission 
		
        helper.isFormValid(component,event, helper);
    },
    
    handleOnload : function(component, event, helper) {
        component.find('TicketNumber').set('v.value', '189-');
        
        var values = [
            {'label': $A.get("$Label.c.webForm_formEnquiry_isNotPassengerCheck"), 'value': "trustee" },
          {'label': $A.get("$Label.c.webForm_formEnquiry_isPassengerCheck"), 'value': "passenger" }                                           
          ,
        ];

    	component.set('v.options', values);
        //console.log('Load Event' + JSON.stringify(event.getParams()));
        
        // PRESET Picklist Item
        component.find("Origin").set("v.value", "Web Form");
        //component.find("Case_Sub_type__c").set("v.value", "Invoice");
    }, 
            
    //Dialog GuideInfo
    getGuideInfo : function(cmp, event) { 
            var values = $A.get("$Label.c.webForm_formEnquiry_Dep_Guide");
            alert(values); 
    },
	         
    
})