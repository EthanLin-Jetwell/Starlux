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
        var AcknowledgementFields = component.get('v.AcknowledgementList');
        var RequiredFields = component.get('v.RequiredList');
        var RequiredFields2 = component.get('v.RequiredList2');
        var RequiredFields3 = component.get('v.RequiredList3');
        var RequiredTrusteeFields = component.get('v.TrusteeList');
        var EmptyFields = [];
        var FormType = component.get('v.value');
        var currentPetNumber = component.get('v.petNumber');
        
        try {
            for (var i = 0; i<RequiredFields.length; i++ ) {
                var fieldValue = component.find(RequiredFields[i]).get('v.value');
                var checkValue = component.find(RequiredFields[i]).get('v.checked');
                    if (!fieldValue || fieldValue == '') {
                        console.log(RequiredFields[i]);
                        EmptyFields.push(component.find(RequiredFields[i]).get('v.fieldName'));
                    }
            }
            
            for (var i = 0; i<AcknowledgementFields.length; i++ ) {
                var checkValue = component.find(AcknowledgementFields[i]).get('v.checked');
                    if (checkValue == false) {
                        EmptyFields.push(AcknowledgementFields[i]);
                    }
            }
            
            if (currentPetNumber >= 2) {
                for (var i = 0; i<RequiredFields2.length; i++ ) {
                    var fieldValue2 = component.find(RequiredFields2[i]).get('v.value');
                    var checkValue2 = component.find(RequiredFields2[i]).get('v.checked');
                    if (!fieldValue2 || fieldValue2 == '') {
                            console.log(RequiredFields[i]);
                            EmptyFields.push(component.find(RequiredFields[i]).get('v.fieldName'));
                        }
                }
            }
            
            if (currentPetNumber >= 3) {
                for (var i = 0; i<RequiredFields3.length; i++ ) {
                	var fieldValue3 = component.find(RequiredFields3[i]).get('v.value');
                    var checkValue3 = component.find(RequiredFields3[i]).get('v.checked');
                    if (!fieldValue3 || fieldValue3 == '') {
                            console.log(RequiredFields[i]);
                            EmptyFields.push(component.find(RequiredFields[i]).get('v.fieldName'));
                    }   	 
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
        helper.ProcessFormFields(component,event, helper);
    },
    
    ProcessFormFields : function (component, event, helper) {
        var ValidStatus = component.get('v.ValidStatus');
        var currentPetNumber = component.get('v.petNumber');
        var ConsentCheckStatus = component.get('v.ConsentCheckStatus');
        try {
            var eventFields = event.getParam("fields");
            console.log(eventFields);
            //Consent
            var consent = component.find("Consent").get("v.checked");
            eventFields["Consent_to_Collect_Personal_Data__c"] = consent;
            
            //Description
            var pet = component.get('v.pet1');
            var weightUnit = component.get('v.weightValue');
            var sizeUnit = component.get('v.sizeValue');
            var species = component.find("Species").get("v.value");
            var weight = component.find("Weight").get("v.value");
            var size = component.find("Size").get("v.value");
            var additionalDescription = component.find("AdditionalDescription").get("v.value");
            eventFields["Description"] = '\n' + 'First Pet: ' + pet +'('+ species + ')' + '\n' + 'Weight of Cage + Pet: ' + weight + weightUnit + '\n' + 'Size of Cage: ' + size + sizeUnit;
                
            if (currentPetNumber >= 2) {
                var pet2 = component.get('v.pet2');
                var weightUnit2 = component.get('v.weightValue2');
                var sizeUnit2 = component.get('v.sizeValue2');
                var species2 = component.find("Species2").get("v.value");
                var weight2 = component.find("Weight2").get("v.value");
                var size2 = component.find("Size2").get("v.value");
                eventFields["Description"] += '\n' + 'Second Pet: ' + pet2 +'('+ species2 + ')' + '\n'+ 'Weight of Cage + Pet: ' + weight2 + weightUnit2 + '\n' + 'Size of Cage: ' + size2 + sizeUnit2;
            }
            
            if (currentPetNumber >= 3) {
                var pet3 = component.get('v.pet3');
                var weightUnit3 = component.get('v.weightValue3');
            	var sizeUnit3 = component.get('v.sizeValue3');
                var species3 = component.find("Species3").get("v.value");
                var weight3 = component.find("Weight3").get("v.value");
                var size3 = component.find("Size3").get("v.value");
                eventFields["Description"] += '\n' + 'Third Pet: ' + pet3 +'('+ species3 + ')' + '\n' + 'Weight of Cage + Pet: ' + weight3 + weightUnit3 + '\n' + 'Size of Cage: ' + size3 + sizeUnit3;
            }
            
            if (additionalDescription != undefined) {
            	eventFields["Description"] += '\n' + 'Description: ' + additionalDescription;    
            }
            
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
                component.find("formSpecialRequest").submit(eventFields);
                //window.open('/s/formSuccess','_top')//For know issue workaround by Chris 20200724
            }
            
        } catch (err) {
            console.log(err);
        }
        
    }
})