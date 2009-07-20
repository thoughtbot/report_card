$:.unshift(File.join(File.dirname(__FILE__)), '..', 'lib')

require 'test/unit'
require 'report_card'

TEST_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
INTEGRITY_DIR = File.join(TEST_DIR, 'integrity')
INTEGRITY_CONFIG = File.join(INTEGRITY_DIR, 'config.yml')

World do
  include Test::Unit::Assertions
end
