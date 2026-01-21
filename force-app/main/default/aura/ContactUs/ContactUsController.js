({
	doInit: function(component, event, helper) {
        // This is url query parameter
		var lang = helper.getParameterByName(component , event, 'language');
//      alert('the value is: '+lang);
        
        // Set the value, assumes you have created attribute "attributename" in your markup
        component.set("v.theLanguage", lang);
    }
})