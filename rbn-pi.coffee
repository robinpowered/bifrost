# request = require 'request'
winston = require 'winston'
{EventEmitter} = require 'events'
# request = require 'request'
semver = require 'semver'
forever = require 'forever-monitor'
NPM = require 'npm'
config = require './config.json'

class Supervisor extends EventEmitter

  constructor: ()->
    @log.info 'Started supervisor!'

    # Polling interval!
    @interval = config.updateInterval * 1000 # Convert to milliseconds

    # Updating flag
    @updating = false

    # Packages
    @packages = {}
    # @loadPackages()

    NPM.load (err, @npm) =>
      # Start the script
      @startRunning()
      # Poll for new releases every once in a while
      if config.autoUpdate
        @log.info "Setting auto update interval: #{@interval} secs"
        @watchReleases()
      else
        @log.info "Auto update not configured"

  log: winston

  # Gets the tag of the currently running os
  getCurrentRelease: (packageName) ->
    try
      pjson = require "./node_modules/#{packageName}/package.json"
      @packages[packageName].current = pjson.version
    catch err
      @log.error err
      @log.warn "Package #{packageName} does not exist, so this must be the first run."
      @packages[packageName].current = null

  # Watches github for new releases
  watchReleases: ->
    # Check on an interval
    setInterval =>
      @checkOutdated()
    , @interval

    # Check for releases right away
    # @checkOutdated()

  # Gets the tag of the latest release
  checkOutdated: ->

    # run the npm outdated command to get a list of outdated packages
    # check for any with the rbn prefix
    # if found, do an npm update
    @log.info 'checking for outdated packages...'
    @npm.commands.outdated (err, outdated) =>
      needsUpdate = false
      unless err
        # console.log outdated
        for pack in outdated
          # If name starts with rbn-
          if pack[1][0...4] is 'rbn-'
            console.log "#{pack[1]}: #{pack[3]} > #{pack[2]}"
            # If version can update
            if semver.valid(pack[2]) and semver.valid(pack[3]) and semver.gt(pack[3], pack[2])
              # Needs an update!
              needsUpdate = true
              break

        # Update if necessary
        if needsUpdate
          @update() unless @updating
      else
        @log.error err

  update: ->
    # Stop the current module if running
    @log.info 'stopping current module...'
    @stopRunning =>
      @updating = true
      # Update the npm modules
      @npm.commands.update (err) =>
        console.log err
        unless err
          @log.info "Updated successfully!"
          @updating = false
          @startRunning()
        else
          @log.error "Error updating"
          console.log err
          @updating = false

  install: (callback=null) ->
    # Install the module
    @log.info 'installing!'
    @updating = true
    @npm.commands.install (err) =>
      unless err
        @log.info "Installed successfully!"
        @startRunning()
        @updating = false
        callback()
      else
        @log.error "Error installing"
        console.log err
        @updating = false

  stopRunning: (callback=null) ->
    # Stop any running software.
    # Kill with a stop code that allows the os to emit an "updating" event before exiting
    @log.info 'stopping old os...'
    if @running
      emitter = @running.stop()
      emitter.on 'stop', =>
        @log.info 'stopped running successfully'
        callback()
    else
      callback() if callback


  startRunning: ->
    # Start the software in the current directory
    @log.info 'starting os...'

    pjson = require "./node_modules/bifrost-hub/package.json"

    startScript = pjson.main

    if startScript

      @running = new forever.Monitor "./node_modules/bifrost-hub/#{startScript}.js",
        silent: false
        command: 'node'

      # Start/stop listeners
      @running.on 'start', (process, data) =>
        @log.info 'script started successfully!'
        @emit 'startedRunning'
      @running.on 'stop', =>
        @emit 'stoppedRunning'

      # Actually start the process
      @running.start()
    else
      @log.error "No start script in package.json - make sure you have a {'scripts':{'start':'someScript.js'}}"

supervisor = new Supervisor config.NpmPackageName
