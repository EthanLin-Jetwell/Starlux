({
    doInit: function (component, event, helper) {
        //helper.subscribeEventChange(component,event, helper); //Used to listen to platform event changes
        helper.InitialChecking(component,event,helper);
    },

    recalculate: function (component, event, helper) {
        helper.InitialChecking(component,event,helper);
    },
    
    showAll: function (component, event, helper) {
        helper.ShowAllRecords(component,event, helper);
    },
    
    refreshComponent: function (component, event, helper) {
        component.set('v.pageIndex', 1);
        component.set('v.isMaxRecordsReached', false);
        var a = component.get('c.doInit');
        $A.enqueueAction(a);
    }
    
})