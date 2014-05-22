BaseStation = require './lib/base-station'
Supervisor = require './lib/supervisor'
config = require './config.json'

baseStation = new BaseStation
supervisor = new Supervisor config.NpmPackageName
