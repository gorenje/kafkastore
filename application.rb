require 'oj_mimic_json'

require 'rack'
require 'sinatra'
require 'omniauth'
require 'omniauth-google-oauth2'

require 'timeout'
require 'ipaddr'
require 'addressable/uri'
require 'tilt/erb'

if File.exists?(".env")
  require 'dotenv'
  Dotenv.load
end

set(:environment,   ENV['RACK_ENV']) unless ENV['RACK_ENV'].nil?

Dir[File.join(File.dirname(__FILE__),'config', 'initializers','*.rb')].
  each { |a| require_relative a }

%w[lib routes].each do |path|
  Dir[File.join(File.dirname(__FILE__), path, "*.rb")].each do |lib|
    require lib.gsub(/\.rb$/, '')
  end
end
