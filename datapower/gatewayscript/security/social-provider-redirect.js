/*
  Licensed Materials - Property of IBM
  IBM DataPower Gateway
  Copyright IBM Corporation 2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/
var sm = require('service-metadata');
var hm = require('header-metadata');

var callback = '/#/social'

//only perform check if social login redirection is not occuring
if (session.name('AAA').getVariable('social-login-redirection') != 'yes') {
	var wsmContext = session.name('WSM').getVariable('identity/username');
	var provider;

	if (wsmContext) {
		console.log('username = %s', wsmContext);

		var idToken = session.name('AAA').getVariable('social-login-id-token');
		var accessToken = session.name('AAA').getVariable('social-login-access-token');

		provider = {
			'status': 'SUCCESS',
			'provider' : 'google',
			'strategy' : 'oidc',
			'username' : wsmContext,
			//'idToken' : idToken,
			'accessToken' : accessToken
		};
	}
	else {
		provider = {
			'status': 'FAILED',
			'provider' : 'google',
			'strategy' : 'oidc',
		};		
	}

	session.output.write(provider);
	hm.response.set('Location', callback);
	hm.response.set('Set-Cookie', 'dp.token=' + provider.accessToken + ';path=/');
	hm.response.statusCode = "302";
	sm.mpgw.skipBackside = true;

	console.info('Set cookie value %s',  provider.accessToken);
	console.info('Redirecting to %s', callback);
}