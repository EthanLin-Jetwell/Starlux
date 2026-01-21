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
        var CommentsFields = component.get('v.CommentsList');
        var AcknowledgementFields = component.get('v.AcknowledgementList');
        var EmptyFields = [];
        var CommentsEmptyFields = [];
        
        try {
            for (var i = 0; i<RequiredFields.length; i++ ) {
                var fieldValue = component.find(RequiredFields[i]).get('v.value');
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
            
            for (var i = 0; i<CommentsFields.length; i++ ) {
                var fieldValue = component.find(CommentsFields[i]).get('v.value');
                if (!fieldValue || fieldValue == '') {
                    CommentsEmptyFields.push(component.find(CommentsFields[i]).get('v.fieldName'));
                } else if (fieldValue.length < 20) {
                	CommentsEmptyFields.push(component.find(CommentsFields[i]).get('v.fieldName'));
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
        
        if (CommentsEmptyFields.length == 0) {
            component.set('v.CommentsValidStatus', true);
        } else {
            component.set('v.CommentsValidStatus', false);
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
        var CommentsValidStatus = component.get('v.CommentsValidStatus');
        var ConsentCheckStatus = component.get('v.ConsentCheckStatus');
        try {
            var eventFields = event.getParam("fields");
            console.log(eventFields);
            //Description
            var comments = component.find("OtherComments").get("v.value");
            eventFields["Description"] = comments;
            
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
                                   
            //Fire error toast if there are unpopulated required fields
            try{
                if (CommentsValidStatus == false && ValidStatus == false) {
                    if (ConsentCheckStatus == false) {
                        var toastErrorEvent = $A.get("e.force:showToast");
                        toastErrorEvent.setParams({
                            "title": $A.get("$Label.c.webForm_message_Error"),
                            "message": $A.get("$Label.c.webForm_message_ConsentUnchecked"),
                            "type": "error"
                        });
                        toastErrorEvent.fire();
                        return;
                    } else {
                        var toastErrorEvent = $A.get("e.force:showToast");
                        toastErrorEvent.setParams({
                            "title": $A.get("$Label.c.webForm_message_Error"),
                            "message": $A.get("$Label.c.webForm_message_ValidationError"),
                            "type": "error"
                        });
                        toastErrorEvent.fire();
                        return;
                    }
                    
                } 
                if (CommentsValidStatus == true && ValidStatus == false) {
                    if (ConsentCheckStatus == false) {
                        var toastErrorEvent = $A.get("e.force:showToast");
                        toastErrorEvent.setParams({
                            "title": $A.get("$Label.c.webForm_message_Error"),
                            "message": $A.get("$Label.c.webForm_message_ConsentUnchecked"),
                            "type": "error"
                        });
                        toastErrorEvent.fire();
                        return;
                    } else {
                        var toastErrorEvent = $A.get("e.force:showToast");
                        toastErrorEvent.setParams({
                            "title": $A.get("$Label.c.webForm_message_Error"),
                            "message": $A.get("$Label.c.webForm_message_ValidationError"),
                            "type": "error"
                        });
                        toastErrorEvent.fire();
                        return;
                    }
                }
                if (CommentsValidStatus == false && ValidStatus == true) {
                    var toastErrorEvent = $A.get("e.force:showToast");
                    toastErrorEvent.setParams({
                        "title": $A.get("$Label.c.webForm_message_Error"),
                        "message": $A.get("$Label.c.webForm_message_CommentsTooShort"),
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
            if (ValidStatus == true && CommentsValidStatus == true) {
                component.find("formFeedback").submit(eventFields);
                //window.open('/s/formSuccess','_top')//For know issue workaround by Chris 20200724
            }
            
        } catch (err) {
            console.log(err);
        }
        
    }
})