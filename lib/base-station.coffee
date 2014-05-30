{EventEmitter} = require 'events'
{exec} = require 'child_process'
winston = require "winston"
getmac = require "getmac"
debug = require 'debug'
os = require 'os'

# Currently, transports are auto-detected from the config.json
# In the future, they should be specified in the package.json and auto-loaded
config = require '../config.json'

# Require the transports and interfaces
loadedTransports = {}
for name, options of config.transports
  loadedTransports[name] = require name
loadedInterfaces = {}
for name, options of config.interfaces
  loadedInterfaces[name] = require name

# TODO - refactor debug logging to winston logging for remote logs
winston.remove winston.transports.Console
winston.add winston.transports.Console,
  colorize: true
  timstamp: true

module.exports =
class BaseStation extends EventEmitter

  log:
    base: debug 'base'
    error: debug 'error'

  constructor: () ->

    # Initialize the base metadata object. This will hold transports, ip and mac address, and etc
    # TODO - transports should maintain their own meta objects, and should emit 'meta' events when it should be updated here
    @meta = {}

    # The base station should communicate it's ip address and status every so often
    @reporter =
      timeout: 30000
      interval: null

    # Init transports
    @transports = {}
    @interfaces = {}

    # Wait for the mac address, then load transports
    @on 'macLoaded', =>
      @loadTransports()

    # Every time a transport is loaded, check to see whether they have all been loaded
    @on 'transportLoaded', =>
      @checkAllTransportsReady()

    # When all transports are loaded, load the interfaces
    @on 'allTransportsLoaded', =>
      @loadInterfaces()
      @listenForCommands()

    # Get the Mac Address
    @getMac()

    # Get the ip address
    @getIP()

    # Start reporting
    @startReporting()

  # Load the transports specified in config.json
  loadTransports: () ->
    for name, options of config.transports
      @log.base "Initializing transport: #{name}"
      @loadTransport name, options

  # Load a single transport
  loadTransport: (name, options) ->
    try
      Transport = loadedTransports[name]
      @transports[name] = new Transport options, @
      @transports[name].on 'ready', =>
        @transports[name].ready = true
        @log.base "Initialized transport: #{name}"
        @emit 'transportLoaded'
      @transports[name].on 'disconnected', =>
        @log.base "Transport disconnected: #{name}"
    catch e
      @errorHandler "Error creating transport #{name}.", e

  # Load the hardware specified in config.json
  loadInterfaces: () ->
    for name, options of config.interfaces
      @log.base "Initializing interface: #{name}"
      try
        Interface = loadedInterfaces[name]
        @interfaces[name] = new Interface options, @
        # Set a listener for data to be passed upwards
        @interfaces[name].on 'data', @send
        @log.base "Initialized interface: #{name}"
      catch e
        @errorHandler "Error creating interface #{name}.", e

  checkAllTransportsReady: ->
    allTransportsReady = true
    for name, transport of @transports
      allTransportsReady = false unless transport.ready is true
    #Load hardware once all the transports are ready
    @emit 'allTransportsLoaded' if allTransportsReady

  # Get the MAC address of this raspberry pi
  getMac: () ->
    getmac.getMac (err, mac) =>
      @log.base 'attempting to get mac address...'
      unless err
        @meta.mac = mac.replace /:/g, ''
        @uuid = @meta.mac
        @log.base "MAC address found: #{@meta.mac}"
        @emit 'macLoaded'
      else
        @errorHandler "Could not get MAC address.", err

  # Get the IP address of this raspberry pi (on the local network)
  getIP: () =>
    @log.base 'attempting to get ip address...'
    ifaces = os.networkInterfaces()
    ethernets = ifaces['eth0']
    wifis = ifaces['wlan0']
    networkTypes = []
    if ethernets
      networkTypes = ethernets
    else if wifis
      networkTypes = wifis
    for thing in networkTypes

      if thing.family is 'IPv4'
        @meta.ip = thing.address
        @emit 'report'

    # Try again if you can't find it
    unless @meta.ip
      @errorHandler "Could not get ip address.", "ipError"
      setTimeout @getIP, 10000

  # Send the base's metadata along on the meta channel
  report: =>
    # Send on the meta channel
    @send
      uuid: @meta.mac
      verb: 'meta'
      data: @meta

    # Also send on the universal online channel
    @send
      uuid: 'online'
      verb: 'meta'
      data: @meta

  # Send a report on either an event or every 30 seconds
  startReporting: ->
    # Report every 30 seconds
    @reporter.interval = setInterval @report, 30000
    # Also report on 'report' events
    @on 'report', @report

  # Setup listener for commands sent on the 'command' namespace
  listenForCommands: () ->
    @log.base "Telling transports to listen for commands"

    # Set up command listener for this class
    @on "listeningForCommands", =>
      @listeningForCommands()

    @emit "listenForCommands"

  listeningForCommands: () ->
    @log.base "Listening for commands from transports"

    # Set up listener for command event from Transport
    @on 'command', (data) =>
      @sendCommandToInterface(data)

  sendCommandToInterface: (payload) ->
    @log.base "Command Received"
    @emit "command:#{payload.interface}", payload.data

  # Use the send function on each of the loaded transports
  send: (msg) =>
    # Call each transport's send function to send the data
    for name, transport of @transports
      transport.send msg.uuid, msg.verb, msg.data

  # Reboot the base station
  shutdown: () ->
    @meta.status = 'rebooting'
    @send @meta.mac, 'meta', @meta
    setTimeout ->
      process.kill process.pid, 'SIGUSR2'
    , 2000

  # TODO - actually handle errors
  errorHandler: (message, error, fatal=false) ->
    # Just log for now
    console.error message
    console.error error


  # Physically reboot the pi
  rebootPi: ->
    exec 'sudo reboot'
