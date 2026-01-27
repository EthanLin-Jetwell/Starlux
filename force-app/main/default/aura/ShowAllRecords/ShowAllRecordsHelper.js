({
    //This function is to determine the default value of the "Date fields" for activity history
    //If default date is not null (it is updated), then this function will not run
    CalculateDate: function(component, event, helper){
        var date = new Date();
        var days = 60;
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        
        var pastdate = new Date(date.getTime() - (days * 24 * 60 * 60 * 1000));
        var newday = pastdate.getDate();
        var newmonth = pastdate.getMonth()+1;
        var newyear = pastdate.getFullYear();
        var finaldate = newyear +'-'+ newmonth +'-' + newday;
        
        component.set('v.EndDate', today);
        component.set('v.StartDate', finaldate);
    },
    
    //This function is for spinner purposes
    showSpinner : function (component, event) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
        component.set('v.NoSpinner', true);
    },
    
    //This function is for spinner purposes
    hideSpinner : function (component, event) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
        component.set('v.NoSpinner', false);
    },
    
    //This function is for checking the condition to run the entire callout and calculation
    //This will prevent the components from being continuously reload due to the session
    InitialChecking: function(component, event, helper){
        component.set('v.Error', false);
        component.set('v.DateRangeError', false);
        component.set('v.StateError', false);
        
        var CurrentCaseID = component.get("v.CaseId");
        var RecordID = component.get("v.recordId");
        
        //Check if Case ID from Event and Current record ID is the same, if they are different don't do anything and do not refresh the component
        //If CaseID == undefined && RecordID exists -> It is first time Loading
        if(CurrentCaseID != undefined && CurrentCaseID != RecordID){
            console.log('No changes made')
        }
        else{
            helper.CreateWrapper(component,event, helper);
        }
    },
    
    //This function will call the apex controller and return a wrapper with information needed
    CreateWrapper: function(component, event, helper){
        this.showSpinner(component, event);
        var APIEndPoint = component.get("v.apiEndPoint");
        var TestChildAPI = component.get("v.TestChildAPI");
        var ContentBody = component.get("v.contentbody");
        var ContentSubBody = component.get("v.contentsubbody");
        var ContentSecondSubBody = component.get("v.contentsecondsubbody");
        var RecordID = component.get("v.recordId");
        var useCase = component.get("v.useCase");
        
        var action = component.get("c.doContsructWrapperSubDetails");
        action.setParams({
            APIEndPoint: APIEndPoint,
            ContentBody: ContentBody,
            ContentSubBody: ContentSubBody,
            TestChildAPI: TestChildAPI,
            ContentSecondSubBody: ContentSecondSubBody,
            RecordID: RecordID,
            useCase: useCase
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var allValues = JSON.parse(response.getReturnValue());
                component.set('v.ResponseWrapper', allValues);
                //If error exists, skip the calculation and just show an error on the component
                if(allValues.ErrorMessage != 'Success'){
                    component.set('v.StateError', false); 
                    component.set('v.Error', true);
                }
                else{
                    component.set('v.Error', false);
                    helper.ProcessHeader(component,event, helper);
                }                
            }
            else{
                console.log('State is failure');
                component.set('v.Error', true);
                component.set('v.StateError', false);
            }
            this.hideSpinner(component, event);
        });
        $A.enqueueAction(action);
    },
    
    //This function will process the raw data for the header
    ProcessHeader: function(component, event, helper){
        var temp = [];
        var finaltemp = [];
        var format = component.get("v.format");
        var displayorder = {};
        var displayfinalorder = [];
        var temporary = [];
        var finaltemporary = [];
        try{
            var temporarystorage = component.get("v.ResponseWrapper.FieldsToDisplay");
            
            for (var i = 0; i < temporarystorage.length; i++) {
                
                    temp.push(temporarystorage[i]);
                
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
            helper.ProcessRecords(component,event, helper);
        }
        catch(err){
            component.set('v.Error', true);
            console.log('Process Header Error');
        }   
    },
    
    //This function is for processing the data
    ProcessRecords:  function(component, event, helper){
        var temporarystorage = component.get("v.ResponseWrapper.AllRecords");
        var tableheader = component.get("v.TableHeader");
        var ErrorMessage = component.get("v.ResponseWrapper.ErrorMessage");
        var temporarytypes = component.get("v.ResponseWrapper.FieldsToDisplay");
        var temptypes = {};
        if(ErrorMessage == 'Success'){
            component.set('v.StateError', true);
            component.set('v.Error', false);
        }else{
            component.set('v.StateError', false);
        }
        
        for (var i=0;i<temporarytypes.length;i++) {
            var typename = temporarytypes[i].LTC_Field_Name__c;
            var datatype = temporarytypes[i].LTC_Field_Type__c;
            temptypes[typename] = datatype;
        }
        
        //If callout succeed but there is no data returned, show a "No Record Found" on the UI
        if(temporarystorage.length == 0 || temporarystorage == null || temporarystorage == undefined){
            component.set('v.StateError', true);            
            component.set('v.Error', true);
        }
        
        try{
            //Taking just the API Name and put them into a temporary storage
            var temporary = [];
            for(var x=0; x < tableheader.length; x++){
                temporary.push(tableheader[x].LTC_Field_Name__c);
            }
            
            //Taking the values of each records related to the API Name and store into a storage
            var NewBody = "";
            var FieldType = "";
            var storage = [];
            for (var i=0; i<temporarystorage.length; i++){
                var opt = [];
                for (var ii=0; ii<temporary.length; ii++){
                    NewBody = temporarystorage[i][temporary[ii]];
                    FieldType = temptypes[temporary[ii]];
                    opt.push({
                        header: temporary[ii],
                        value: NewBody,
                        type: FieldType
                    });
                }
                storage.push({
                    recordposition: i,
                    inside: opt
                });
            }
            component.set('v.TableRecords', storage);
        }
        catch(err){
            component.set('v.StateError', true);
            component.set('v.Error', true);
            console.log('Process Record Error');
        }   
    }
})