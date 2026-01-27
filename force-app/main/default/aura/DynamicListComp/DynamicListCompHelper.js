({

    callServer : function(component, method, params, callback) {
        console.log('DBG callServer');
        
        this.showSpinner(component);
        var action = component.get(method);
        try {
            
            if (params) {
                action.setParams(params);
            }
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    // Pass returned value to callback function
                    callback.call(this, response.getReturnValue());
                    this.hideSpinner(component);
                } else if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors[0].message) {
                        //console.log('DBG error in call server: ' + errors[0].message);
                        this.showToast('error', 'Error Message: ', errors[0].message);
                    }
                    this.hideSpinner(component);
                }
            });
        } catch(err) {
            alert('This is an Intermittent Error: ', JSON.stringify(err));
        }
        $A.enqueueAction(action);
    },

    //This function is for spinner purposes
    showSpinner : function (component, event) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },

    //This function is for spinner purposes
    hideSpinner : function (component, event) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    },

    //This function is for checking the condition to run the entire callout and calculation
    //This will prevent the components from being continuously reload due to the session
    InitialChecking: function(component, event, helper){
        component.set('v.Error', false);
        component.set('v.StateError', false);
		
        var CurrentCaseID = component.get("v.CaseId");
        var RecordID = component.get("v.recordId");
		
        //Check if Case ID from Event and Current record ID is the same, if they are different don't do anything and do not refresh the component
        //If CaseID == undefined && RecordID exists -> It is first time Loading'
        /* //Commented out since no more platform event is used for listening
            if (CurrentCaseID == undefined) {
                helper.CreateWrapper(component,event, helper, false);
            } else {
                if(CurrentCaseID != RecordID){
                    //console.log('No changes made');
                } else {
                    helper.CreateWrapper(component,event, helper, false);
                }
            }    */        
        
        if (component.get('v.useCase') == 'Case') {
			helper.CreateWrapper(component,event, helper, false);
        }
        
        if (component.get('v.useCase') == 'Account') {
        	helper.CreateAccountWrapper(component,event, helper, false);            
        }

    },

    //This function will call the apex controller and return a wrapper with information needed, only for Case records
    CreateWrapper: function(component, event, helper, addMore){
        this.showSpinner(component, event);
        component.set('v.NoSpinner', true);

        var APIEndPoint = component.get("v.apiEndPoint"); //DIH
        var interfaceName = component.get("v.interfaceName"); //Get Recent Bookings
        var ContentBody = component.get("v.contentbody");
        var ContentSubBody = component.get("v.contentsubbody");
        var ContentSecondSubBody = component.get("v.contentsecondsubbody");
        var RecordIDString = component.get("v.recordId");

        var runningPageIndex;
        if (addMore) {
            runningPageIndex = this.incrementPageIndex(component, event, helper);
        } else {
            runningPageIndex = component.get('v.pageIndex');
        }

        var useCaseString = component.get('v.useCase');
        
        /*
         console.log("-----------Do Apex Callout-----------");
         console.log('APIEndPoint: '+ APIEndPoint);
         console.log('interfaceName: '+ interfaceName);
         console.log('ContentBody: '+ ContentBody);
         console.log('ContentSubBody: '+ ContentSubBody);
         console.log('ContentSecondSubBody: '+ ContentSecondSubBody);
         console.log('RecordID: '+ RecordIDString);
         console.log('pageIndex: '+ runningPageIndex);
         console.log('useCase: '+ useCaseString);
         console.log("-----------Do Apex Callout-----------");*/
        
        if (APIEndPoint === undefined || interfaceName === undefined || ContentBody === undefined || ContentSubBody === undefined ||
            ContentSecondSubBody === undefined || RecordIDString === undefined || runningPageIndex === undefined || useCaseString === undefined) {
            return;
        }
		
        var action = component.get("c.doContsructWrapper");
        
            action.setParams({
                APIEndPoint: APIEndPoint,
                ContentBody: ContentBody,
                ContentSubBody: ContentSubBody,
                interfaceName: interfaceName,
                ContentSecondSubBody: ContentSecondSubBody,
                RecordID: RecordIDString,
                pageIndex: runningPageIndex,
                useCase: useCaseString
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state == "SUCCESS") {
                    var allValues = JSON.parse(response.getReturnValue());
                    component.set('v.ResponseWrapper', allValues);
                    //If error exists, skip the calculation and just show an error on the component
                    if(allValues.ErrorMessage != 'Success'){
                        component.set('v.Error', true);
                    }
                    else{
                        helper.ProcessHeader(component,event, helper, addMore);
                    }
                }
                else {
                    //console.log('APEX Callout Failed');
                    component.set('v.StateError', true);
                    component.set('v.Error', true);
                }
                this.hideSpinner(component, event);
                component.set('v.NoSpinner', false);
            });
        	
        	$A.enqueueAction(action);
        /* //Commented out for reference, purge when deploying to Prod
        // delay by bit to avoid concurrency issues on Active and Inactive
        if (component.get('v.useCase') == 'Inactive Entitlements') {
            setTimeout(function() {
                $A.enqueueAction(action);
            }, 200);
        } else {
            
        }*/
    },
    
    //This function will call the apex controller and return a wrapper with information needed, only for Account records
    CreateAccountWrapper: function(component, event, helper, addMore){
        this.showSpinner(component, event);
        component.set('v.NoSpinner', true);

        var APIEndPoint = component.get("v.apiEndPoint"); //DIH
        var interfaceName = component.get("v.interfaceName"); //Get Recent Bookings
        var ContentBody = component.get("v.contentbody");
        var ContentSubBody = component.get("v.contentsubbody");
        var ContentSecondSubBody = component.get("v.contentsecondsubbody");
        var RecordIDString = component.get("v.recordId");

        var runningPageIndex;
        if (addMore) {
            runningPageIndex = this.incrementPageIndex(component, event, helper);
        } else {
            runningPageIndex = component.get('v.pageIndex');
        }

        var useCaseString = component.get('v.useCase');
        
        // console.log("-----------Do Apex Callout-----------");
        // console.log('APIEndPoint: '+ APIEndPoint);
        // console.log('interfaceName: '+ interfaceName);
        // console.log('ContentBody: '+ ContentBody);
        // console.log('ContentSubBody: '+ ContentSubBody);
        // console.log('ContentSecondSubBody: '+ ContentSecondSubBody);
        // console.log('RecordID: '+ RecordIDString);
        // console.log('pageIndex: '+ runningPageIndex);
        // console.log('useCase: '+ useCaseString);
        // console.log("-----------Do Apex Callout-----------");
        
        if (APIEndPoint === undefined || interfaceName === undefined || ContentBody === undefined || ContentSubBody === undefined ||
            ContentSecondSubBody === undefined || RecordIDString === undefined || runningPageIndex === undefined || useCaseString === undefined) {
            return;
        }
		
        var action = component.get("c.doContsructAccountWrapper");
            action.setParams({
                APIEndPoint: APIEndPoint,
                ContentBody: ContentBody,
                ContentSubBody: ContentSubBody,
                interfaceName: interfaceName,
                ContentSecondSubBody: ContentSecondSubBody,
                RecordID: RecordIDString,
                pageIndex: runningPageIndex,
                useCase: useCaseString
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state == "SUCCESS") {
                    var allValues = JSON.parse(response.getReturnValue());
                    component.set('v.ResponseWrapper', allValues);
                    //If error exists, skip the calculation and just show an error on the component
                    if(allValues.ErrorMessage != 'Success'){
                        component.set('v.Error', true);
                    }
                    else{
                        helper.ProcessHeader(component,event, helper, addMore);
                    }
                }
                else {
                    //console.log('APEX Callout Failed');
                    component.set('v.StateError', true);
                    component.set('v.Error', true);
                }
                this.hideSpinner(component, event);
                component.set('v.NoSpinner', false);
            });
        
        	$A.enqueueAction(action);
        
        /* //Commented out for reference, purge when deploying to Prod
        // delay by bit to avoid concurrency issues on Active and Inactive
        if (component.get('v.useCase') == 'Inactive Entitlements') {
            setTimeout(function() {
                $A.enqueueAction(action);
            }, 200);
        } else {
            
        }*/
    },


    //This function will process the raw data for the header
    ProcessHeader: function(component, event, helper, addMore){
        var temp = [];
        var finaltemp = [];
        var temporarystorage = component.get("v.ResponseWrapper.FieldsToDisplay");
        var format = component.get("v.format");
        var displayorder = {};
        var displayfinalorder = [];
        var temporary = [];
        var finaltemporary = [];

        try {
            for (var i = 0; i < temporarystorage.length; i++) {
                if(temporarystorage[i].Show__c == true){
                    temp.push(temporarystorage[i])
                }
            }
            for(var x=0; x < temp.length; x++){
                    temporary.push(temp[x].LTC_Field_Name__c);
                    displayorder[temp[x].LTC_Field_Name__c] = temp[x].Display_Order__c;
                    displayfinalorder.push(temp[x].Display_Order__c);
                }
            
            displayfinalorder = displayfinalorder.sort(function(a,b) {return a-b;});
            
            //Sort the tableheader into display order
                for (var i=0; i<temporary.length;i++) {
                    var currentorder = displayfinalorder[i];
                    for (var key in displayorder) {
                        var value = displayorder[key];
                        if (value == currentorder) {
                            finaltemporary.push(key)
                        }
                    }
                    
                }
          
            //Push sorted labels into final array
            for (var i=0; i<displayfinalorder.length;i++) {
                for (var x=0; x<temp.length;x++) {
                    if (temp[x].Display_Order__c == displayfinalorder[i]) {
                        finaltemp.push(temp[x]);
                    }
                }
            }
            component.set('v.TableHeader', finaltemp);

            //There are 2 formats available: Table and Form
            //Choose the correct function to process the record
            if (format =='Table') {
                console.log('processing table records')
                helper.ProcessTableRecords(component,event, helper, addMore);
            } else {
                //helper.ProcessFormRecords(component,event, helper);
            }
        } catch(err) {
            component.set('v.Error', true);
        }
    },

    //This function is for processing the data when the user choose "Table" format
    ProcessTableRecords:  function(component, event, helper, addMore){
        var temporarystorage = component.get("v.ResponseWrapper.AllRecords");
        var temporarytypes = component.get("v.ResponseWrapper.FieldsToDisplay");
        var tableheader = component.get("v.TableHeader");
        //var entitlementRows = component.get("v.entitlementRows");
        var temptypes = {};
        var ErrorMessage = component.get("v.ResponseWrapper.ErrorMessage");
        if (ErrorMessage == 'Success') {
            component.set('v.StateError', true);
        }else{
            component.set('v.StateError', false);
        }

        // console.log("-----------Do Table Records-----------");
        //console.log(temporarystorage);
        // console.log('temporarytypes: '+ JSON.stringify(temporarytypes));
        // console.log('TableHeader: '+ JSON.stringify(tableheader));
        // console.log('errorMessage: '+ component.get('v.StateError'));
        // console.log('addMore: '+ addMore);
        // console.log("-----------Do Table Records-----------");

        var subsequentRecords;
        if (addMore) {
            subsequentRecords = component.get("v.ResponseWrapper.AllRecords");
            //console.log('DBG subsequentRecords.length: ' + subsequentRecords.length);
            if (subsequentRecords.length == 0) {
                component.set('v.isMaxRecordsReached', true);
                // return the page index to the last index where there is still value returned (not used for now, will be useful
                // if after Cancel Entitlement, will refresh the same number of rows on the UI and not go back to page index 1)
                // var lastPageIndex = component.get('v.pageIndex');
                // lastPageIndex = lastPageIndex - 1;
                // component.set('v.pageIndex', lastPageIndex);
                return;
            }
        }
        
        for (var i=0;i<temporarytypes.length;i++) {
            var typename = temporarytypes[i].LTC_Field_Name__c;
            var datatype = temporarytypes[i].LTC_Field_Type__c;
            temptypes[typename] = datatype;
        }

        //If callout succeed but there is no data returned, show a "No Record Found" on the UI
        if (temporarystorage.length == 0 || temporarystorage.length == null) {
            component.set('v.Error', true);
        } else {
            try {
                //Taking just the API Name and put them into a temporary storage
                var temporary = [];
                for(var x=0; x < tableheader.length; x++){
                    temporary.push(tableheader[x].LTC_Field_Name__c);
                }
                //Taking the values of each records related to the API Name and store into a storage
                var NewBody = "";
                var FieldType = "";
                var storage = [];
                var currSign = "";

                if (addMore) {
                    var temporarystorage2 = component.get('v.TableRecords');
                    for (var i=0; i<temporarystorage2.length; i++){
                        storage.push(temporarystorage2[i]);
                    }

                    for (var i=0; i<subsequentRecords.length; i++){
                        var opt = [];
                        for (var ii=0; ii<temporary.length; ii++){
                            var tempBody = new Map(Object.entries(subsequentRecords[i][temporary[ii]]));
                            if (tempBody.get('amount') != null || tempBody.get('amount') != undefined) {
                                NewBody = tempBody.get('amount');
                                currSign = tempBody.get('currencySign');
                            } else {
                                NewBody = subsequentRecords[i][temporary[ii]];
                                currSign = null;
                            }
                            FieldType = temptypes[temporary[ii]];
                            opt.push({
                                header: temporary[ii],
                                value: NewBody,
                                type: FieldType,
                                currency: currSign
                            });
                        }
                        storage.push({
                            recordposition: i,
                            inside: opt
                        });
                    }

                } else {
                    for (var i=0; i<temporarystorage.length; i++){
                        var opt = [];
                        for (var ii=0; ii<temporary.length; ii++){
                            var mapKey = temporary[ii];
                            NewBody = temporarystorage[i][mapKey]; 
                            currSign = null;
                            /*
                            var tempBody = new Map(Object.entries(temporarystorage[i][temporary[ii]]));
                            console.log(tempBody);
                            if (tempBody.get('amount') != null || tempBody.get('amount') != undefined) {
                                NewBody = tempBody.get('amount');
                                currSign = tempBody.get('currencySign');
                            } else {
                                NewBody = temporarystorage[i][temporary[ii]];
                                currSign = null;
                            }*/
                            FieldType = temptypes[temporary[ii]];
                            opt.push({
                                header: temporary[ii],
                                value: NewBody,
                                type: FieldType,
                                currency: currSign
                            });
                        }
                        storage.push({
                            recordposition: i,
                            inside: opt
                        });
                    }
                }
                console.log(storage);
                component.set('v.TableRecords', storage);
            } catch(err) {
                console.log(err);
                component.set('v.Error', true);
                component.set('v.StateError', true);
            }
        }
    },
    
    //Navigate to a subtab and pass the necessary parameters
    ShowAllRecords: function(component, event, helper){
        var workspaceAPI = component.find("workspace");
        var navService = component.find("navService");
        // set the pageReference object used to navigate to the component. Include any parameters in the state key.
        var pageReference = {
            "type": "standard__component",
            "attributes": {
                "componentName": "c__ShowAllRecords" //This is the name of the component
            },
            "state": { //This is what you are passing as parameters
                "c__params": component.get("v.apiEndPoint"),
                "c__TestChildAPI": component.get("v.interfaceName"),
                "c__title": component.get("v.cmpTitle"),
                "c__icon": component.get("v.cmpLtIcon"),
                "c__contentbody": component.get("v.contentbody"),
                "c__contentsubbody": component.get("v.contentsubbody"),
                "c__contentsecondsubbody": component.get("v.contentsecondsubbody"),
                "c__recordId": component.get("v.recordId"),
                "c__useCase": component.get("v.useCase")
            }
        };
        var parentSubTabId;
        var childSubTabId;
        // handles checking for console and standard navigation and then navigating to the component appropriately
        workspaceAPI
        .isConsoleNavigation()
        .then(function(isConsole) {
            if (isConsole) {
                //in a console app - generate a URL and then open a subtab of the currently focused parent tab
                navService.generateUrl(pageReference).then(function(cmpURL) {
                    workspaceAPI
                    .getEnclosingTabId()
                    .then(function(tabId) {
                        parentSubTabId = tabId;
                        return workspaceAPI.openSubtab({
                            parentTabId: tabId,
                            url: cmpURL,
                            focus: true
                        });
                    })
                    .then(function(subTabId) {
                        childSubTabId = subTabId;
                        // the subtab has been created, use the Id to set the label
                        workspaceAPI.setTabLabel({
                            tabId: subTabId,
                            label: component.get("v.cmpTitle")
                        });
                        workspaceAPI.setTabIcon({
                            tabId: subTabId,
                            icon: component.get("v.cmpLtIcon")
                        });
                        // to fix the stuck "Loading..." title on browser tab name
                        workspaceAPI.focusTab({tabId : parentSubTabId});
                        workspaceAPI.focusTab({tabId : childSubTabId});
                    });
                });
            } else {
                // this is standard navigation, use the navigate method to open the component
                navService.navigate(pageReference, false);
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    

    // show display of success or error message
    showToast: function (type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissible',
            title: title,
            message: message,
            type: type,
            duration: 3000
        });
        toastEvent.fire();
    },

    // this is used in Add More requests
    incrementPageIndex: function(component, event, helper) {
        var currentPageIndex = component.get('v.pageIndex');
        var runningPageIndex = currentPageIndex + 1;
        component.set('v.pageIndex', runningPageIndex);
        return runningPageIndex;
    },


})