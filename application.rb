require 'oj_mimic_json'

require 'rack'
require 'sinatra'
require 'omniauth'
require 'omniauth-google-oauth2'

require 'erb'
require 'timeout'

if File.exists?(".env")
  require 'dotenv'
  Dotenv.load
end

require_relative 'config/initializers/ruby_extensions'
require_relative 'config/initializers/librato'
require_relative 'config/initializers/database'
require_relative 'config/initializers/redis'
require_relative 'config/initializers/sidekiq'

%w[lib routes].each do |path|
  Dir[File.join(File.dirname(__FILE__), path, "*.rb")].each do |lib|
    require lib.gsub(/\.rb$/, '')
  end
end
