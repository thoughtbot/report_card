require 'test_helper'

class ReportCardTest < Test::Unit::TestCase
  context "running report_card" do
    setup do
      @config = {'integrity_config' => '/path/to/integrity/config.yml'}
      stub(ReportCard).config { @config }

      @project = Integrity::Project.new
    end

    should "run if project name is valid" do
      stub(@project).name { "awesome" }

      mock(Integrity).new(@config['integrity_config'])
      mock(Integrity::Project).all.mock!.each.yields(@project)
      mock(ReportCard::Runner).new(@project, @config).mock!.run
      ReportCard.run
    end

    should "not run if project name is ignored" do
      @config['ignore'] = "1\.9"
      stub(@project).name { "awesome 1.9" }

      mock(Integrity).new(@config['integrity_config'])
      mock(Integrity::Project).all.mock!.each.yields(@project)
      mock(ReportCard::Runner).new(@project, @config).never
      ReportCard.run
    end
  end

  context "loading the config" do
    setup do
      @config = {'integrity_config' => '/path/to/integrity/config.yml'}
    end

    should "load if file exists" do
      mock(File).exist?(ReportCard::CONFIG_FILE) { true }
      mock(YAML).load_file(ReportCard::CONFIG_FILE) { @config }
      assert_equal @config, ReportCard.config
    end

    should "not load if file does not exist" do
      mock(File).exist?(ReportCard::CONFIG_FILE) { false }
      mock(YAML).load_file(ReportCard::CONFIG_FILE).never
      mock(Kernel).abort(anything)
      ReportCard.config
    end
  end

  context "setting up" do
    setup do
      @config = {'site' => '/path/to/site'}
      stub(ReportCard).config { @config }
    end

    should "move files from the template over" do
      mock(FileUtils).mkdir_p(@config['site'])
      mock(FileUtils).cp(is_a(Array), @config['site'])
      ReportCard.setup
    end
  end
end
