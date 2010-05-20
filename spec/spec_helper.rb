$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'chicago'
require 'spec'
require 'spec/autorun'
require 'yaml'

include Chicago

TEST_DB = Sequel.connect(YAML.load(File.read(File.dirname(__FILE__) + "/db_connections.yml")))

Spec::Runner.configure do |config|
end
