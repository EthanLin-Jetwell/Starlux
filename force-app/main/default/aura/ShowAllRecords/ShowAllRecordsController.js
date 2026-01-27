({
    doInit : function(component, event, helper) {
        //Get the parameters being passed from the main case page
        var pageReference = component.get('v.pageReference');
        component.set("v.apiEndPoint", pageReference.state.c__params);
        component.set("v.TestChildAPI", pageReference.state.c__TestChildAPI);
        component.set("v.cmpTitle", pageReference.state.c__title);
        component.set("v.cmpLtIcon", pageReference.state.c__icon);
        component.set("v.contentbody", pageReference.state.c__contentbody);
        component.set("v.contentsubbody", pageReference.state.c__contentsubbody);
        component.set("v.contentsecondsubbody", pageReference.state.c__contentsecondsubbody);
        component.set("v.recordId", pageReference.state.c__recordId);
        component.set("v.StartDate", pageReference.state.c__startdate);
        component.set("v.useCase", pageReference.state.c__useCase);

        //Run helper class
        helper.InitialChecking(component,event, helper);
    },
    
    Filter : function(component, event, helper) {
        //This function will only run for Activity History
        //Calculate the range of days before processing the callout
        var oneDay = 24*60*60*1000;
        var StartDate = new Date(component.get("v.StartDate"));
        var EndDate = new Date(component.get("v.EndDate"));
        var days = (EndDate-StartDate)/oneDay;
        
        //Number of days is fixed to be 60 days. It should never reach 61 days.
        if(days>60.99){
            component.set('v.DateRangeError', true);
        }
        else{
            component.set('v.DateRangeError', false);
            helper.CreateWrapper(component,event, helper);
        }
    },
    
    RefreshComponent: function (component, event, helper) {
        var a = component.get('c.doInit');
        $A.enqueueAction(a);
    }
})