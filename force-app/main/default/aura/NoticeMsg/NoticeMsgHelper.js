({
    createCookie: function(name, value, days) {
    	var expires;
        
        if (days) {
            var date = new Date();
            date.setTime(date.getTime() + (days*24*60*60*1000));
            expires = "; expires=" + date.toGMTString(); 
        } else {
            expires = "";
        }
        document.cookie = name + "=" + escape(value) + expires + "; path=/";
console.log(document.cookie);
	},
    
    getCookie: function(name) {
		var regexp = new RegExp("(?:^" + name + "|;\s*"+ name + ")=(.*?)(?:;|$)", "g");
      	var result = regexp.exec(document.cookie);
      	return (result === null) ? null : result[1];        
    },
    
    getParameterByName: function(component, event, name) {
    	name = name.replace(/[\[\]]/g, "\\$&");
    	var url = window.location.href;
    	var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
    	var results = regex.exec(url);
    	if (!results) return null;
    	if (!results[2]) return '';
    	return decodeURIComponent(results[2].replace(/\+/g, " "));
	}
})