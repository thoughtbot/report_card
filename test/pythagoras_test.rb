require 'test_helper'

class PythagorasTest < Test::Unit::TestCase
  context "running pythagoras" do
    before_should "load data from integrity" do
      @config = {'integrity_config' => 'config path'}
      mock(YAML).load_file("config.yml") { @config }
      mock(Integrity).new(@config['integrity_config'])

      @project = Integrity::Project.new
      stub(@project).name { "awesome" }
      mock(Integrity::Project).all { [@project] }
      mock(Pythagoras).new(@project, @config)
    end

    before_should "dump out if no config file" do
      mock(YAML).load_file("config.yml") { raise "no way" }
      mock(STDERR).puts(anything)

      mock(Integrity).new(anything).never
      mock(Pythagoras).new(anything).never
    end

    before_should "dump out if blank config file" do
      mock(YAML).load_file("config.yml") { false }
      mock(STDERR).puts(anything)

      mock(Integrity).new(anything).never
      mock(Pythagoras).new(anything).never
    end

    before_should "dump out if no projects" do
      @config = {'integrity_config' => 'config path'}
      mock(YAML).load_file("config.yml") { @config }
      mock(Integrity).new(@config['integrity_config'])

      mock(Integrity::Project).all { raise Sqlite3Error }
      mock(STDERR).puts(anything)
      mock(Pythagoras).new(anything).never
    end

    before_should "ignore projects based on ignore in config" do
      @config = {'integrity_config' => 'config path', 'ignore' => '1\.9'}
      mock(YAML).load_file("config.yml") { @config }
      mock(Integrity).new(@config['integrity_config'])

      @project = Integrity::Project.new
      stub(@project).name { "awesome 1.9" }
      mock(Integrity::Project).all { [@project] }
      mock(Pythagoras).new(anything).never
    end

    setup do
      Pythagoras.run
    end
  end
end
