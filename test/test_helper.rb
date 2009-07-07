require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'rr'
require 'timecop'

begin
  require 'redgreen'
rescue LoadError
end

Timecop.freeze(Date.today)

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'pythagoras'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end
