/*
  Licensed Materials - Property of IBM
  IBM DataPower Gateway
  Copyright IBM Corporation 2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/
var hm = require('header-metadata');
var sm = require('service-metadata');

//string to find token
var token = { 'name': 'dp.token', 'value': ''};
var endpoint = { 'google': 'https://www.googleapis.com/oauth2/v3/userinfo?scope=openid%20email%20profile',
                 'facebook': 'https://graph.facebook.com/v2.2/me',
                 'twitter': 'https://api.twitter.com/1.1/users/show.json'
             	};

//get the cookie header
var cookies = hm.original.get('Cookie');

if (cookies) {
	//tokenize the cookie header
	var cookiesList = cookies.split(';');

	//search through cookies
	cookiesList.forEach(function(cookie, i) {
		
		console.info("cookie:" + cookie);
		var cookieName = cookie.substr(0, cookie.indexOf("="));
		var cookieValue = cookie.substr(cookie.indexOf("=")+1, cookie.length);
		
		console.info("cookie name %s and cookie value %s", cookieName, cookieValue);
		console.info("matching against %s", token.name);
		
		//search for cookie name
		if (token.name === cookieName.trim()) {
			token.value = cookieValue;
			console.info("Found cookie:" + cookieName + " with value " + cookieValue);
		}
		else {
			console.info("cookie not found %s ", cookieName);
		}
		

	});

	if (token.value == '') {
		console.error('Unable to find cookie name '+ token.name);
		sm.mpgw.skipBackside = true;
	}
	else {
		console.info('Setting Authorization header for social provider.')
		hm.current.set('Authorization', 'Bearer ' + token.value);
		sm.setVar('var://service/routing-url', endpoint['google']);	
	}
	
}