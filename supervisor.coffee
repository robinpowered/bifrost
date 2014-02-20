# request = require 'request'
winston = require 'winston'
{EventEmitter} = require 'events'
# request = require 'request'
fs = require 'fs'
mkdirp = require 'mkdirp'
unzip = require 'unzip'
rimraf = require 'rimraf'
semver = require 'semver'
forever = require 'forever-monitor'
NPM = require 'npm'
config = require './config.json'




class Supervisor extends EventEmitter

	constructor: (@packageName)->
		@log.info 'Started supervisor!'
		@log.info "Watching url #{@url} for release updates"

		# Polling interval!
		@interval = 30000

		NPM.load (err, @npm) =>
			console.log @npm.prefix
			@watchReleases()

	log: winston

	# Gets the tag of the currently running os
	getCurrentRelease: ->
		try
			currentPjson = require "./node_modules/#{@packageName}/package.json"
			@currentTag = currentPjson.version
		catch err
			@log.error err
			@log.warn 'Package does not exist, so this must be the first run.'
			@currentTag = null

	# Watches github for new releases
	watchReleases: ->
		# TODO - add a timer here...
		setInterval =>
			@getCurrentRelease()
			@getReleases()
		, @interval

		# Check for releases right away
		@getCurrentRelease()
		@getReleases()

	# Gets the tag of the latest release
	getReleases: ->
		@log.info 'checking releases...'
		@npm.commands.show [@packageName,'version'], (err, tags) =>
			unless err
				# Grab the latest tag - key
				latestTag = Object.keys(tags)[0]

				@log.info "Current tag is #{@currentTag}, latest tag is #{latestTag}"
				# If already exists, update!
				if @currentTag
					# If this version is newer than current version
					# Download if newer
					if semver.gt latestTag, @currentTag
						# Stop the current os
						@stopRunning =>
							@log.info 'os stopped successfully!'
							# Update!
							@update()
					else
						# Start unless already started
						@startRunning
				else
					# Doesn't exist yet, install!
					@install()
			else
				@log.error err
				@log.error "Couldn't find `#{@packageName}` in the npm repository. Are you sure it's published?" if err.code is 'E404'

	update: ->
		# Update the npm module
		@npm.commands.update [@packageName], (err) =>
			console.log err
			unless err
				@log.info "Updated successfully!"
				@startRunning()
			else
				@log.error "Error updating"
				console.log err

	install: ->
		# Install the module
		@log.info 'installing!'
		@npm.commands.install [@packageName], (err) =>
			@log.info 'installed!'
			unless err
				@log.info "Installed successfully!"
				@startRunning()
			else
				@log.error "Error installing"
				console.log err

	stopRunning: (callback=null) ->
		# Stop any running software.
		# Kill with a stop code that allows the os to emit an "updating" event before exiting
		@log.info 'stopping old os...'
		if @running
			emitter = @running.stop()
			emitter.on 'stop', =>
				callback()
		else
			callback() if callback
		

	startRunning: ->
		# Start the software in the current directory
		@log.info 'starting os...'

		pjson = require "./node_modules/#{@packageName}/package.json"

		startScript = pjson.scripts?.start

		if startScript

			@running = new forever.Monitor "./node_modules/#{@packageName}/#{startScript}",
				silent: @silent

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