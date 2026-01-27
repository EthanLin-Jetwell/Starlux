window._snapinsSnippetSettingsFile = (function() {
  console.log("Snippet settings file loaded."); // Logs that the snippet settings file was loaded successfully

  embedded_svc.snippetSettingsFile.autoOpenPostChat = true;

  embedded_svc.snippetSettingsFile.extraPrechatInfo = [{
    "entityName": "Contact",
    "saveToTranscript": "ContactId",
    "entityFieldMaps": [{
      "doCreate": false,
      "doFind": false,
      "fieldName": "LastName",
      "isExactMatch": false,
      "label": "Last Name"
    }, {
      "doCreate": false,
      "doFind": false,
      "fieldName": "FirstName",
      "isExactMatch": false,
      "label": "First Name"
    }, {
      "doCreate": false,
      "doFind": true,
      "fieldName": "Email",
      "isExactMatch": true,
      "label": "Web Email"
    }]
  }];

  embedded_svc.snippetSettingsFile.extraPrechatFormDetails = [{
    "label": "First Name",
    "transcriptFields": ["FirstName__c"]
  }, {
    "label": "Last Name",
    "transcriptFields": ["LastName__c"]
  }];
  
  embedded_svc.snippetSettingsFile.directToButtonRouting = function(prechatFormData) {
	//console.log(prechatFormData[1].value);
	//console.log(prechatFormData[2].value);
	//console.log(prechatFormData[3].value);
	if(prechatFormData[3].value === "Chinese") {
	//console.log("direct to TW button routing initiated.");
	//alert("Alert: direct to TW button routing initiated!");
	return "5732u000000TN1Z";
	}
	else if(prechatFormData[3].value === "English") {
	//console.log("direct to TW button routing initiated.");
	//alert("Alert: direct to TW button routing initiated!");
	return "5732u000000TN1e";
	}
	else if(prechatFormData[3].value === "Japanese") {
	//console.log("direct to JP button routing initiated.");
	//alert("Alert: direct to JP button routing initiated!");
	return "5732u000000TN1U";
	}
	
	}

})();