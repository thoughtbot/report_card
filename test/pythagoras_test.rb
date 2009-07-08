require 'test_helper'

class PythagorasTest < Test::Unit::TestCase
  context "running pythagoras" do
    setup do
      @config = {'integrity_config' => '/path/to/integrity/config.yml'}
      stub(Pythagoras).config { @config }

      @project = Integrity::Project.new
    end

    should "run if project name is valid" do
      stub(@project).name { "awesome" }

      mock(Integrity).new(@config['integrity_config'])
      mock(Integrity::Project).all.mock!.each.yields(@project)
      mock(Pythagoras::Runner).new(@project, @config).mock!.run
      Pythagoras.run
    end

    should "not run if project name is ignored" do
      @config['ignore'] = "1\.9"
      stub(@project).name { "awesome 1.9" }

      mock(Integrity).new(@config['integrity_config'])
      mock(Integrity::Project).all.mock!.each.yields(@project)
      mock(Pythagoras::Runner).new(@project, @config).never
      Pythagoras.run
    end
  end

  context "loading the config" do
    setup do
      @config = {'integrity_config' => '/path/to/integrity/config.yml'}
    end

    should "load if file exists" do
      mock(File).exist?(Pythagoras::CONFIG_FILE) { true }
      mock(YAML).load_file(Pythagoras::CONFIG_FILE) { @config }
      assert_equal @config, Pythagoras.config
    end

    should "not load if file does not exist" do
      mock(File).exist?(Pythagoras::CONFIG_FILE) { false }
      mock(YAML).load_file(Pythagoras::CONFIG_FILE).never
      mock(Kernel).abort(anything)
      Pythagoras.config
    end
  end

  context "setting up" do
    setup do
      @config = {'site' => '/path/to/site'}
      stub(Pythagoras).config { @config }
    end

    should "move files from the template over" do
      mock(FileUtils).mkdir_p(@config['site'])
      mock(FileUtils).cp(is_a(Array), @config['site'])
      Pythagoras.setup
    end
  end
end
