$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'chicago'
require 'rspec'
require 'yaml'
require 'rspec/autorun'

include Chicago

unless defined? TEST_DB
  TEST_DB = Sequel.connect(YAML.load(File.read(File.dirname(__FILE__) + "/db_connections.yml")))
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
end
