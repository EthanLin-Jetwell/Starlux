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
    }
})