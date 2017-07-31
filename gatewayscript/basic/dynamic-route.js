var sm = require('service-metadata'); // required for reading URL
var urlopen = require ('urlopen'); // required for urlopen API

var routeTable = [{ uri: '/OI_Vehicle/A1234', endpoint: 'http://127.0.0.1:8080/OI_Vehicle/A1234' },
					{ uri: '/OI_Vehicle/B1234', endpoint: 'http://127.0.0.1:8080/OI_Vehicle/B1234' },
					{ uri: '/OI_Vehicle/C1234', endpoint: 'http://127.0.0.1:8080/OI_Vehicle/B1234' },
					{ uri: '/OI_Vehicle', endpoint: 'http://127.0.0.1:8080/OI_Vehicle' }];

//get the front-side URI
var serviceURI = sm.URI;
console.info("Incoming service URI is %s", serviceURI);

var found = false;

routeTable.forEach(function(routeItem, i) {
	//found URI in the list
	if (serviceURI == routeItem.uri) {	
		sm.setVar('var://service/routing-url', routeItem.endpoint);
		found = true;

		console.info("Found service URI %s in the routing table.", serviceURI);
	}
});

//front-side URI is not found, then reject the message
if (!found) {
	session.reject("Unable to find backend route for URI " + serviceURI);
}