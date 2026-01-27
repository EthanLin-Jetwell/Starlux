({
    doInit : function(component, event, helper) {
        var device = $A.get("$Browser.formFactor");
        component.set('v.Device',device);
        
        var action = component.get("c.getRefundRecordTypeId");
        action.setCallback(this, function(response) {
        	var state = response.getState();
			if (state === "SUCCESS") {
                component.set("v.RefundRecordTypeId", response.getReturnValue() );
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
        for (let key of Object.keys(event.getParams().response)) {
            console.log(key + event.getParams().response[key]);
        }
        //console.log(event.getParams().response.id);
        //console.log(component.find("SuppliedPhone").get("v.value"));
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": $A.get("$Label.c.webForm_message_Success"),
            "message": $A.get("$Label.c.webForm_message_RecordCreationSuccess"),
            "type": "success"
        });
        toastEvent.fire();
        
        var address = '/formSuccess';
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": address,
          "isredirect" :false
        });
        urlEvent.fire();
    },
    
    handleError : function(component, event, helper) {
        var error = event.getParams();
        var errorMessage = event.getParam("message");
        
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
    
    handleChange: function(component, event, helper) {
        
        var selectedOptionsList = event.getParam("value");
        console.log(event.getParam("value"));
        
        var currentSelectedOptions = component.get("v.medicalValue");
        currentSelectedOptions.add(selectedOptionsList);
        component.set("v.medicalValue",currentSelectedOptions);
    },
    
    handleOnload : function(component, event, helper) {
        component.find('FlightNumber').set('v.value', 'JX');
        component.find('TicketNo').set('v.value', '189-');
        
        var values = [
            {'label': $A.get("$Label.c.webForm_formEnquiry_isNotPassengerCheck"), 'value': "trustee" },
          {'label': $A.get("$Label.c.webForm_formEnquiry_isPassengerCheck"), 'value': "passenger" }                                           
          ,
        ];
            
       	var medicalvalues = [
            {'label': $A.get("$Label.c.webForm_formSpecialMEDA_MedicalReasonOptionPregnant"), 'value': "Pregnant Passenger" },
          	{'label': $A.get("$Label.c.webForm_formSpecialMEDA_MedicalReasonOptionStretcher"), 'value': "Stretcher Passenger" }, 
            //{'label': $A.get("$Label.c.webForm_formSpecialMEDA_MedicalReasonOptionOxygen"), 'value': "Oxygen Equipment" },
            {'label': $A.get("$Label.c.webForm_formSpecialMEDA_MedicalReasonOptionEquipment"), 'value': "Medical Portable Electronic Devices" },
            {'label': $A.get("$Label.c.webForm_formSpecialMEDA_MedicalReasonOptionAnimal"), 'value': "Emotional Support Animal (ESAN)" },
            {'label': $A.get("$Label.c.webForm_formSpecialMEDA_MedicalReasonOptionOthers"), 'value': "Others" }
        ];     
        
        component.set('v.options', values);
        component.set('v.medicalOptions', medicalvalues);    
        //console.log('Load Event' + JSON.stringify(event.getParams()));
        
        // PRESET Picklist Item
        component.find("Origin").set("v.value", "Web Form");
        component.find("CaseSubType").set("v.value", "Special Service Enquiry");
        component.find("CaseSubTypeDetails").set("v.value", "Medical Case");    
        //component.find("Case_Sub_type__c").set("v.value", "Invoice");
    }, 
            
    //Dialog GuideInfo
    getGuideInfo : function(cmp, event) { 
            var values = $A.get("$Label.c.webForm_formEnquiry_Dep_Guide");
            alert(values); 
    },          
    
})