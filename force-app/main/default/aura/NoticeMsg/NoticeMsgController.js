({
    doInit: function(component, event, helper) {
	  // SHOW modal notice
	  var theCookie = helper.getCookie("iAccept");
//      alert('theCookie='+theCookie);
        
      //if (theCookie!=="TRUE") {
 		component.set("v.isOpen", true);
      //}
      var lang = helper.getParameterByName(component , event, 'language');
//      alert('the value is: '+lang);
        
        // Set the value, assumes you have created attribute "attributename" in your markup
        component.set("v.theLanguage", lang);
    },

    openModel: function(component, event, helper) {
      // for Display Model,set the "isOpen" attribute to "true"
      component.set("v.isOpen", true);
   },
 
   closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
   },
 
   clickAccept: function(component, event, helper) {
      // Display alert message on the click on the "Like and Close" button from Model Footer 
      // and set set the "isOpen" attribute to "False for close the model Box.
      helper.createCookie("iAccept", "TRUE", 7);  // session cookie, don't pass the Days
//      helper.createCookie("iAccept", "TRUE");  // session cookie, don't pass the Days
      component.set("v.isOpen", false);
      var theCookie = helper.getCookie("iAccept");
//      alert('thanks for like Us :) '+theCookie);
	  //Open new tab
      var urlEvent = $A.get("e.force:navigateToURL");
      urlEvent.setParams({
          "url": 'https://www.starlux-airlines.com/'
      });
      urlEvent.fire();
   },
})