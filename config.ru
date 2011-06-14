require 'rubygems'
require 'bundler'

Bundler.require

use Rack::NoWWW

require './site'
run Site
