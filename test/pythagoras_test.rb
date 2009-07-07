require 'test_helper'
require 'test_helper'

class PythagorasTest < Test::Unit::TestCase
  context "running pythagoras" do
    before_should "load data from integrity" do
      @config = {:integrity_config => "config path"}
      mock(YAML).load_file("config.yml") { @config }
      mock(Integrity).new(@config[:integrity_config])

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
      @config = {:integrity_config => "config path"}
      mock(YAML).load_file("config.yml") { @config }
      mock(Integrity).new(@config[:integrity_config])

      mock(Integrity::Project).all { raise Sqlite3Error }
      mock(STDERR).puts(anything)
      mock(Pythagoras).new(anything).never
    end

    before_should "ignore projects based on ignore in config" do
      @config = {:integrity_config => "config path", :ignore => "1\.9"}
      mock(YAML).load_file("config.yml") { @config }
      mock(Integrity).new(@config[:integrity_config])

      @project = Integrity::Project.new
      stub(@project).name { "awesome 1.9" }
      mock(Integrity::Project).all { [@project] }
      mock(Pythagoras).new(anything).never
    end

    setup do
      Pythagoras.run
    end
  end

  context "with a pythagoras object" do
    setup do
      @project = Integrity::Project.new(:name => "awesome")
      @config = {}
      @py = Pythagoras.new(@project, @config)
    end

    should "store project and config" do
      assert_equal @py.project, @project
      assert_equal @py.config, @config
    end

    should "change directory to the export directory if it exists" do
      directory = "dir"
      mock(Integrity::ProjectBuilder).new(@project).mock!.send(:export_directory) { directory }
      mock(File).exist?(directory) { true }
      mock(Dir).chdir(directory) { 0 }
      assert @py.ready?
    end

    should "not change directory to the export directory if it does not exists" do
      directory = "dir"
      mock(Integrity::ProjectBuilder).new(@project).mock!.send(:export_directory) { directory }
      mock(File).exist?(directory) { false }
      mock(Dir).chdir(anything).never
      mock(STDERR).puts(anything)
      assert ! @py.ready?
    end

    should "use _site/:project for generating metrics" do
      assert @project.public
      assert_equal File.expand_path(File.join(__FILE__, "..", "..", "_site", @project.name)), @py.output_path
    end

    should "use _site/private/:project for generating metrics on a private project" do
      @project.public = false
      assert_equal File.expand_path(File.join(__FILE__, "..", "..", "_site", "private", @project.name)), @py.output_path
    end

    should "set build artifacts to private" do
      #@py.configure
    end
  end
end
