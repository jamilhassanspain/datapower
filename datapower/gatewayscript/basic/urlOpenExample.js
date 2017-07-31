console.info("Starting urlopen Demo");
// Include the urlopen library via the require() method.
var urlopen = require ('urlopen'), // required for urlopen API
sm = require('service-metadata'); // required for reading URL
// TODO replace with url.parse()
var getQueryString = function () {
	var url = sm.URLIn;
	var urlArray = url.split("?");
	var queryString = urlArray[urlArray.length-1].trim();
	return queryString;
};
var encodedRequestorName = getQueryString();
var decodedRequestorName = decodeURIComponent(encodedRequestorName);
var getHTTPResults = function (fileInput) {
// define the urlopen options
var postOptions = {
	target: "",
// if target is https, supply a sslProxyProfile
// sslProxyProfile: 'alice-sslproxy-forward-trusted',
method: 'post',
contentType: 'application/json',
timeout: 60,
data: "{}"
};
postOptions.target = "http://127.0.0.1:2460/creditcheck?" + encodedRequestorName;
console.info("postOptions: %j", postOptions);
urlopen.open(postOptions, function (error, response) {
	if (error) {
		throw new Error('Could not read remote url');
	} else {
		response.readAsJSON(function(readError, httpResponse){
			if (readError) throw new Error('Could not read payload');
			console.info("http responseObject: %j", httpResponse);
			if ((httpResponse.Name === decodedRequestorName) &&
				(httpResponse.Credit > 0) &&
				(fileInput[decodedRequestorName] === "Accept")) {
				session.output.write("Accepted!\n");
		} else {
			session.output.write("Rejected!\n");
		}
		console.info("Urlopen Demo Complete");
	});
	}
});
};
var getFileResults = function() {
	urlopen.open ('local:///accesslist.json', function (error, response) {
		var fileResults = {};
		if (error || response.statusCode === 404)
			return;
		else {
			response.readAsJSON( function (error, jsonObj) {
if (error) // handle error
	throw new Error('Could not read file');
else {
	fileResults = response;
	console.info("File contents: %j", jsonObj);
// get and process the result from another server
getHTTPResults(jsonObj, encodedRequestorName);
}
});
		}
	});
};
getFileResults();
console.info("Urlopen Demo continuing...");