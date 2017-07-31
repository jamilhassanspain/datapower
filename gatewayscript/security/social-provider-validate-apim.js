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
var urlopen = require ('urlopen');

//TODO: scope parameters are hardcoded in google api but should be pulled from configuration
var endpoint = { 'google': 'https://www.googleapis.com/oauth2/v3/userinfo?scope=openid%20email',
                 'facebook': 'https://graph.facebook.com/v2.2/me',
                 'twitter': 'https://api.twitter.com/1.1/users/show.json'
             	};

//get the cookie header
var authorizationHeader = hm.original.get('Authorization');
var authorizationValue = authorizationHeader.substring(authorizationHeader.indexOf('Basic')+6, authorizationHeader.length).trim();

console.info("User Credentials (before base64): "+ authorizationValue);

if (authorizationValue) {
	
	//decode authorization header
	var buffer = new Buffer(authorizationValue,"base64");
	console.info("User Credentials (after base64): "+ buffer.toString());

	//split the token in the header
	var authTokens = buffer.toString().split(':');
	console.info('authTokens:' + authTokens.toString());

	var headerParams = {
		'Authorization' : 'Bearer ' + authTokens[1]
	}

	//using google for now
	var postOptions = {
		target: endpoint['google'],
		//use ssl proxy profile from user agent
		//sslProxyProfile: 'google', 
		method: 'get',
		contentType: 'application/json',
		timeout: 60,
		headers: headerParams
	};
	
	urlopen.open (postOptions, function (err, resp) {
            if (err) throw err;
            resp.readAsJSON (function (err, json) {
                //validate the email from the social provider
                if (json && json.email == authTokens[0]) {
					console.info('Successfully validated response from social provider');
					hm.response.statusCode = "200";
                }
                else {
                	if (err) throw err;
					console.info('Error validating response from social provider with reason '+ JSON.stringify(json));
					hm.response.statusCode = "500";
                }
            });
        });
	
	sm.mpgw.skipBackside = true;

}