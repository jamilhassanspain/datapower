var url = require('urlopen'),
    endpoints = [{ 'url': 'http://127.0.0.1:8080/OI_Vehicle' },
                 { 'url': 'http://127.0.0.1:8080/OI_VehicleImg' }],
    count = endpoints.length;
    main(); //invoke the main method

//readJSONFile('local:///urls.json');

//main logic
function main() {

    //Invoke different endpoints in parallel (split) *********

    //Invoke OI_Vehicle service
    url.open (endpoints[0].url, function (err, resp) {
            if (err) throw err;
            resp.readAsJSON (function (err, json) {
                if (err) throw err;

                endpoints[0].data = json.OI_VehicleRs
                
                //console.info("json OI_Vehicle %s", json);
                if (--count === 0) done(endpoints);
            });
        });

    //Invoke OI_VehicleImg service
    url.open (endpoints[1].url, function (err, resp) {
            if (err) throw err;
            resp.readAsJSON (function (err, json) {
                if (err) throw err;
            
                endpoints[1].data = json.OI_VehicleImgRs

                //console.info("json OI_VehicleImg %s", json);
                if (--count === 0) done(endpoints);
            });
        });
} //main

//Merge responses from multiple service call  *********
function done (response) {

    //get the individual responses
    var OI_VehicleRs = response[0].data;
    var OI_VehicleImgRs = response[1].data;

    //temporary variable to store the merged results
    var mergedResults = [];

    //merge the results
    OI_VehicleRs.vehicle.forEach(function(vehicleItem, i) {

        //check if vehicle is image found
        OI_VehicleRs.vehicle.forEach(function(vehicleImgItem, j) {            
            
            if (vehicleItem.id == vehicleImgItem.id) {
                vehicleItem.image = vehicleImgItem.image;
            }
        }); //inner loop
        mergedResults[i] = vehicleItem;;
    }); //outer loop

    var result = { "OI_VehicleRs": { "vehicle" : mergedResults } };
    session.output.write (JSON.stringify(result));
}

//read JSON data from properties file
function readJSONFile(jsonFile) {
    
    urlopen.open (jsonFile, function (error, response) {
        endpoints = {};
        if (error || response.statusCode === 404)
            return;
        else {
            response.readAsJSON( function (error, jsonObj) {
            if (error) // handle error
                throw new Error('Could not read file');
            else {
                endpoints = response;
                console.info("File contents: %j", jsonObj);

                //file is read, so start processing
                main();
            }
            });
        }//else
    });
}    