({
	doInit : function(component, event, helper) {
		var utcSeconds = component.get('v.epoch');
        var myDate = new Date(utcSeconds*1000);
        var d = myDate.toLocaleString();
		//console.log('utcSeconds: ' + utcSeconds);
		//var d = new Date(0); // The 0 there is the key, which sets the date to the epoch
		//if (utcSeconds != undefined && utcSeconds != null && utcSeconds != 0) {
		//	d.setUTCSeconds(utcSeconds);
		//component.set('v.convertedValue', d.toISOString().toString());
		component.set('v.convertedValue', d);
		}
	},
    
    


})