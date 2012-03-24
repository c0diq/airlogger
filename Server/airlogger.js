#!/usr/bin/env node

try {
    var mdns = require('mdns');
} catch(err) {
    console.log('Error: missing mdns module');
    console.log('install via: npm install mdns');
    process.exit(1);
}

try {
    var fanout = require('fanout');
} catch(err) {
    console.log('Error: missing fanout module');
    console.log('install via: npm install fanout');
    process.exit(1);
}

var ad = mdns.createAdvertisement(mdns.tcp('airlogger'), 1986);
ad.start();
