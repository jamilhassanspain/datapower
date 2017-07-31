/*
  Licensed Materials - Property of IBM
  IBM DataPower Gateway
  Copyright IBM Corporation 2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/
var hm = require('header-metadata');

var pattern = new RegExp('forms.*session');

//string to find ltpa token
var ltpaToken = { 'name': 'LtpaToken2', 'path' : '/' };

//get the cookie header
var cookies = hm.original.get('Cookie');

//temporary array to track cookies removed
var removeCookies = [];

if (cookies) {
	//tokenize the cookie header
	var cookiesList = cookies.split(';');

	//search through cookies
	cookiesList.forEach(function(cookie, i) {
		
		console.info("cookie:" + cookie);
		var cookieName = cookie.substr(0, cookie.indexOf("="));

		console.info("searching cookie:" + cookieName);

		//search for ltpa cookie
		if (cookieName == ltpaToken.name) {
			//remove the cookie
			removeCookies.push(ltpaToken.name + '=' + ';Expires=Thu, 01-Dec-94 16:00:00 GMT; Path=' + ltpaToken.path);
			console.warn("deleting cookie:" + cookieName);
		}
		//search for dpSession cookie
		else if (pattern.test(cookieName)) {
			//remove dpSession cookie (assumes path /)
			removeCookies.push(cookieName + '=' + ';Expires=Thu, 01-Dec-94 16:00:00 GMT; Path=/');
			console.warn("deleting cookie:" + cookieName);
			//remove dpSession target cookie (assumes path /j_security_check)
			removeCookies.push(cookieName.substr(0, cookieName.indexOf('session')) + 'FormsTarget' + '=' + ';Expires=Thu, 01-Dec-94 16:00:00 GMT; Path=/j_security_check');
			console.warn("deleting cookie:" + cookieName.substr(0, cookieName.indexOf('session')) + 'FormsTarget');
			//remove dpSession migration cookie (assumes path /)
			removeCookies.push(cookieName.substr(0, cookieName.indexOf('session')) + 'migration' + '=' + ';Expires=Thu, 01-Dec-94 16:00:00 GMT; Path=/');
			console.warn("deleting cookie:" + cookieName.substr(0, cookieName.indexOf('session')) + 'migration');
		}

	});

	if (removeCookies.length > 0) {
		//set the cookie header on the response to delete cookies in the browser
		hm.response.set('Set-Cookie', removeCookies)
		hm.response.statusCode = "200";
	}
}