rbn
==========

This is a bit of software that was built for the raspberry rbn, but should work on any linux box. It's good at doing things like passing data from bluetooth low energy devices over a websocket connection, or sending data from a connected arduino up to firebase. It consists of two parts - interfaces and transports.

Interfaces
===

Interfaces allow the pi to collect data from other devices. Currently, the following interfaces are supported:

* [rbn-ble](http://github.com/robinpowered/rbn-ble) - bluetooth low energy
* [rbn-rfid](http://github.com/robinpowered/rbn-rfid) - usb-based rfid readers
* [rbn-arduino](http://github.com/robinpowered/rbn-arduino) - arduino over serial

To add an interface, just add the interface's name in the `dependancies` section of your package.json file and run `rbn-base.js`. Make sure to use `latest` for the version if you want the package to auto-update. If your interface has options you can configure, you can set them in config.json.

Transports
===

Got some data from an interface? Awesome. Transports let you send that data somewhere on the internet.

* [rbn-websockets](http://github.com/robinpowered/rbn-websockets) - uses websockets
* [rbn-http](http://github.com/robinpowered/rbn-http) - http POST requests
* [rbn-firebase](http://github.com/robinpowered/rbn-firebase) - firebase

The process for adding a transport is the same as that for an interface.

Easy Mode
===

1. Install raspbian on your Pi.
2. SSH onto your pi.
3. Run `curl -h http://...`
4. Run `sudo node app.js`

Configuration
===

To add or remove interfaces and transports, and configure the behavior of the grid, change the options in config.json. By default, config.json looks like this:

``` json
{
  "autoUpdate": false,
  "runOnBoot": true,
  "transports": {
    "rbn-websocket": {
        "endpoint": "http://robin-grid.omrdev.com"
    }
  },
  "interfaces": {
    "rbn-rfid": {}
  }
}

```

Besides the `interfaces` and `transports` objects, the supported options are:

* `autoUpdate` - update all modules automagically when a new version is released (default: `true`)
* `runOnBoot` - run the grid automatically when the OS boots up using `forever` (default: `true`)

Streaming logs and debugging
===

Every module emits logs on a [debug](github.com/visionmedia/debug) namespace equal to the name of the module. There is also a `base` namespace with the most general logs. To listen on a namespace, run pass a `DEBUG` argument to node, like so:

`sudo DEBUG=base,websocket,ble node app.js`

If you're looking to stream logs out to a service, you should write a transport to do so!

Contributing
===

The Robin OS is designed to make it easy to add custom modules.

(finish this)

Creating an interface
---

Your module should export a single class. Your constructor will be called.
