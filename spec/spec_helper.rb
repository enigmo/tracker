require 'tracker'
require 'rack/test'
require 'pry-byebug'

Tracker::API.logger(Logger.new('/dev/null'))
