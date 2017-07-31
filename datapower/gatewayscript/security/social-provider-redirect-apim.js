/*
  Licensed Materials - Property of IBM
  IBM DataPower Gateway
  Copyright IBM Corporation 2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/
var sm = require('service-metadata');
var hm = require('header-metadata');
var querystring = require ('querystring');

//only perform check if social login redirection is not occuring
if (session.name('AAA').getVariable('social-login-redirection') != 'yes') {
	//obtain initial URL to social login request
	var intialURL = session.name('AAA').getVariable('social-login-url-in');
	console.info('initial URL:'+ intialURL);

	//extract APIm params attached to original URL
	var apimParams = querystring.parse(intialURL.substring(intialURL.indexOf('?')+1, intialURL.length));
	console.info('apiParams:'+ JSON.stringify(apimParams));
	
	//extract the authenticated user identity
	var wsmContext = session.name('WSM').getVariable('identity/username');

	if (wsmContext) {
		console.info('username = %s', wsmContext);

		//extract social login tokens
		var idToken = session.name('AAA').getVariable('social-login-id-token');
		var accessToken = session.name('AAA').getVariable('social-login-access-token');
		
		//extract name/value pairs from original APIm params
		//TODO: assumed original-url only contains client_id, redirect_URI, and scope
		var originalURL = apimParams['original-url'] + '&client_id=' + apimParams['client_id'] + '&redirect_uri=' + apimParams['redirect_uri'] + '&scope=' + apimParams['scope'];
		var rState = querystring.escape(apimParams['rstate']);
		var appName = apimParams['app-name'];

		//set the redirect URL with original URL, confirmation code and user identity
		hm.response.set('Location', originalURL + '&rstate=' + rState + '&username=' + wsmContext + '&confirmation=' + accessToken + '&app-name=' + appName);
		console.info('Location header:' + originalURL + '&rstate=' + rState + '&username=' + wsmContext + '&confirmation=' + accessToken + '&app-name=' + appName);
	}
	else {
		hm.response.set('Location', originalURL + '&username=' + wsmContext + '&error=Unable to login');
		console.info('Location header:' + originalURL + '&username=' + wsmContext + '&error=Unable to login');
		console.info('Unable to login to social login provider');
	}

	hm.response.statusCode = "302";
	sm.mpgw.skipBackside = true;
}