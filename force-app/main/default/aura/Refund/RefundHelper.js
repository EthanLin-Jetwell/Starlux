({
    	/*
    isFormValid: function (component, event, helper) {
    return (component.find('customRequired') || [])
        .filter(function (i) {
            var value = i.get('v.value');
            return !value || value == '' || value.trim().length === 0;
        })
        .map(function (i) {
            console.log(i);
            return i.get('v.fieldName');
        });
	},*/
    
    isFormValid : function (component, event, helper) { //Check for any unpopulated required fields
        var RequiredFields = component.get('v.RequiredList');
        var RequiredTrusteeFields = component.get('v.TrusteeList');
        var AcknowledgementFields = component.get('v.AcknowledgementList');
        var EmptyFields = [];
        var FormType = component.get('v.value');

        try {
            for (var i = 0; i<RequiredFields.length; i++ ) {
                var fieldValue = component.find(RequiredFields[i]).get('v.value');
                    if (!fieldValue || fieldValue == '') {
                        EmptyFields.push(component.find(RequiredFields[i]).get('v.fieldName'));
                    }
            }
            
            
            for (var i = 0; i<AcknowledgementFields.length; i++ ) {
                var checkValue = component.find(AcknowledgementFields[i]).get('v.checked');
                    if (checkValue == false) {
                        EmptyFields.push(AcknowledgementFields[i]);
                    }
            }
            
            if (FormType == 'trustee') {
                for (var i = 0; i<RequiredTrusteeFields.length; i++ ) {
                    var fieldValueTrustee = component.find(RequiredTrusteeFields[i]).get('v.value');
                    if (!fieldValueTrustee || fieldValueTrustee == '') {
                            EmptyFields.push(component.find(RequiredTrusteeFields[i]).get('v.fieldName'));
                        }
                }    
            }
            
        } catch (err) {
            console.log(err);
        }
        
        //Set flag to denote whether form is valid or invalid
        if (EmptyFields.length == 0) {
            component.set('v.ValidStatus', true);
        } else {
            component.set('v.ValidStatus', false);
        }
        
        if (EmptyFields.length == 1 && EmptyFields.includes('Consent')) {
            component.set('v.ConsentCheckStatus', false);    
        } else {
            component.set('v.ConsentCheckStatus', true);
        }
        
        //For know issue workaround by Chris 20200724-Start
        //component.set('v.disabled', false);
		//component.set('v.showSpinner', true);
        //For know issue workaround by Chris 20200724-End
        
        console.log('Empty Fields: '+EmptyFields);
         console.log('Empty Fields Size: '+EmptyFields.length);
        helper.ProcessFormFields(component,event, helper);
    },
    
    ProcessFormFields : function (component, event, helper) {
        var ValidStatus = component.get('v.ValidStatus');
        var ConsentCheckStatus = component.get('v.ConsentCheckStatus');
        try {
            var eventFields = event.getParam("fields");
            //console.log(eventFields);
            //Consent
            var consent = component.find("Consent").get("v.checked");
            eventFields["Consent_to_Collect_Personal_Data__c"] = consent;
            
            // SuppliedName
            var title = component.find("ContactSalutation").get("v.value");
            var givenName = component.find("GivenName").get("v.value");
            var familyName = component.find("FamilyName").get("v.value");
            eventFields["SuppliedName"] = title + " " + familyName + " " + givenName; 
            eventFields["Passenger_Name__c"] = familyName + " " + givenName; 
            
            // SuppliedPhone
            var CountryCode = component.find("CountryCode").get("v.value");
            var PhoneNumber = component.find("PhoneNumber").get("v.value");
            if (PhoneNumber[0] == 0) {
                PhoneNumber = PhoneNumber.replace(PhoneNumber[0],'');
            }
            eventFields["SuppliedPhone"] = CountryCode + PhoneNumber;
            eventFields["Passenger_Phone__c"] = CountryCode + PhoneNumber;
            
            // SuppliedEmail
            var ContactEmail = component.find("ContactEmail").get("v.value");
            eventFields["SuppliedEmail"] = ContactEmail;
            
            //Only if form is filled by Trustee
            var formStatus = component.get("v.value");
            
            if (formStatus == "trustee") {
                // Alternate_Contact_Name__c
                var altFamilyName = component.find("AlternateFamilyName").get("v.value");
                var altGivenName = component.find("AlternateGivenName").get("v.value");
                eventFields["Alternate_Contact_Name__c"] = altFamilyName + " " + altGivenName; 
                
                // Alternate_Contact_Phone__c
                var altCountryCode = component.find("AlternateCountryCode").get("v.value");
                var altPhoneNumber = component.find("AlternatePhoneNumber").get("v.value");
                if (altPhoneNumber[0] == 0) {
                    altPhoneNumber = altPhoneNumber.replace(altPhoneNumber[0],'');
                }
                eventFields["Alternate_Contact_Phone__c"] = altCountryCode + altPhoneNumber;
                
                //Designate_Trustee__c
                eventFields['Designate_Trustee__c'] = true;
            }
                                   
            //Fire error toast if there are unpopulated required fields
            try{
                if (ValidStatus == false && ConsentCheckStatus == true) {
                    var toastErrorEvent = $A.get("e.force:showToast");
                    toastErrorEvent.setParams({
                        "title": $A.get("$Label.c.webForm_message_Error"),
                        "message": $A.get("$Label.c.webForm_message_ValidationError"),
                        "type": "error"
                    });
                    toastErrorEvent.fire();
                    return;
                }
                
                if (ValidStatus == false && ConsentCheckStatus == false) {
                    var toastErrorEvent = $A.get("e.force:showToast");
                    toastErrorEvent.setParams({
                        "title": $A.get("$Label.c.webForm_message_Error"),
                        "message": $A.get("$Label.c.webForm_message_ConsentUnchecked"),
                        "type": "error"
                    });
                    toastErrorEvent.fire();
                    return;
                }
                
                //Force alert maintenance message by Chris 20200723-Star
                if(1!=1){
                    var toastErrorEvent = $A.get("e.force:showToast");
                    toastErrorEvent.setParams({
                        "title": $A.get("$Label.c.webForm_message_Error"),
                        "message": $A.get("$Label.c.webForm_message_Maintenance"),
                        "type": "error"
                    });
                    toastErrorEvent.fire();
                    return;
                }
                //Force alert maintenance message by Chris 20200723-End
                //Force block mobile user by Chris 20200728-Star
                //var device = component.get('v.Device');
                //if(device!="DESKTOP"){
                //   var toastErrorEvent = $A.get("e.force:showToast");
                //    toastErrorEvent.setParams({
                //        "title": $A.get("$Label.c.webForm_message_Error"),
                //        "message": $A.get("$Label.c.webForm_message_Maintenance"),
                //        "type": "error"
                //    });
                //    toastErrorEvent.fire();
                //    return;
                //}
				//Force block mobile user by Chris 20200728-End
                
            } catch (err) {
                console.log(err);
            }
            
            //Creates Case record if form is valid
            if (ValidStatus == true) {
                component.find("formRefund").submit(eventFields);
                //window.open('/s/formSuccess','_top')//For know issue workaround by Chris 20200724
            }
            
        } catch (err) {
            console.log(err);
        }
        
    }
})