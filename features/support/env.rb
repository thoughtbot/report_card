require 'test/unit'

TEST_DIR = File.join('/', 'tmp', 'report_card')

World do
  include Test::Unit::Assertions
end

Before do
  FileUtils.mkdir(TEST_DIR)
  Dir.chdir(TEST_DIR)
end

After do
  Dir.chdir(TEST_DIR)
  FileUtils.rm_rf(TEST_DIR)
end
