BaseStation = require './base-station'
Supervisor = require './supervisor'

module.exports =
class Bifrost
  constructor: ->
    baseStation = new BaseStation
    supervisor = new Supervisor
