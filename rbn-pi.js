(function() {
  var EventEmitter, NPM, Supervisor, config, forever, semver, supervisor, winston,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  winston = require('winston');

  EventEmitter = require('events').EventEmitter;

  semver = require('semver');

  forever = require('forever-monitor');

  NPM = require('npm');

  config = require('./config.json');

  Supervisor = (function(_super) {
    __extends(Supervisor, _super);

    function Supervisor() {
      var _this = this;
      this.log.info('Started supervisor!');
      this.interval = 300000;
      this.updating = false;
      this.packages = {};
      NPM.load(function(err, npm) {
        _this.npm = npm;
        _this.startRunning();
        return _this.watchReleases();
      });
    }

    Supervisor.prototype.log = winston;

    Supervisor.prototype.getCurrentRelease = function(packageName) {
      var err, pjson;
      try {
        pjson = require("./node_modules/" + packageName + "/package.json");
        return this.packages[packageName].current = pjson.version;
      } catch (_error) {
        err = _error;
        this.log.error(err);
        this.log.warn("Package " + packageName + " does not exist, so this must be the first run.");
        return this.packages[packageName].current = null;
      }
    };

    Supervisor.prototype.watchReleases = function() {
      var _this = this;
      return setInterval(function() {
        return _this.checkOutdated();
      }, this.interval);
    };

    Supervisor.prototype.checkOutdated = function() {
      var _this = this;
      this.log.info('checking for outdated packages...');
      return this.npm.commands.outdated(function(err, outdated) {
        var needsUpdate, pack, _i, _len;
        needsUpdate = false;
        if (!err) {
          for (_i = 0, _len = outdated.length; _i < _len; _i++) {
            pack = outdated[_i];
            if (pack[1].slice(0, 4) === 'rbn-') {
              console.log("" + pack[1] + ": " + pack[3] + " > " + pack[2]);
              if (semver.valid(pack[2]) && semver.valid(pack[3]) && semver.gt(pack[3], pack[2])) {
                needsUpdate = true;
                break;
              }
            }
          }
          if (needsUpdate) {
            if (!_this.updating) {
              return _this.update();
            }
          }
        } else {
          return _this.log.error(err);
        }
      });
    };

    Supervisor.prototype.update = function() {
      var _this = this;
      this.log.info('stopping current module...');
      return this.stopRunning(function() {
        _this.updating = true;
        return _this.npm.commands.update(function(err) {
          console.log(err);
          if (!err) {
            _this.log.info("Updated successfully!");
            _this.updating = false;
            return _this.startRunning();
          } else {
            _this.log.error("Error updating");
            console.log(err);
            return _this.updating = false;
          }
        });
      });
    };

    Supervisor.prototype.install = function(callback) {
      var _this = this;
      if (callback == null) {
        callback = null;
      }
      this.log.info('installing!');
      this.updating = true;
      return this.npm.commands.install(function(err) {
        if (!err) {
          _this.log.info("Installed successfully!");
          _this.startRunning();
          _this.updating = false;
          return callback();
        } else {
          _this.log.error("Error installing");
          console.log(err);
          return _this.updating = false;
        }
      });
    };

    Supervisor.prototype.stopRunning = function(callback) {
      var emitter,
        _this = this;
      if (callback == null) {
        callback = null;
      }
      this.log.info('stopping old os...');
      if (this.running) {
        emitter = this.running.stop();
        return emitter.on('stop', function() {
          _this.log.info('stopped running successfully');
          return callback();
        });
      } else {
        if (callback) {
          return callback();
        }
      }
    };

    Supervisor.prototype.startRunning = function() {
      var pjson, startScript,
        _this = this;
      this.log.info('starting os...');
      pjson = require("./node_modules/bifrost-hub/package.json");
      startScript = pjson.main;
      if (startScript) {
        this.running = new forever.Monitor("./node_modules/bifrost-hub/" + startScript + ".js", {
          silent: false,
          command: 'node'
        });
        this.running.on('start', function(process, data) {
          _this.log.info('script started successfully!');
          return _this.emit('startedRunning');
        });
        this.running.on('stop', function() {
          return _this.emit('stoppedRunning');
        });
        return this.running.start();
      } else {
        return this.log.error("No start script in package.json - make sure you have a {'scripts':{'start':'someScript.js'}}");
      }
    };

    return Supervisor;

  })(EventEmitter);

  supervisor = new Supervisor(config.NpmPackageName);

}).call(this);
