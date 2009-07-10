require 'test_helper'

class ReportCardTest < Test::Unit::TestCase
  context "grading report_card" do
    setup do
      @config = {'integrity_config' => '/path/to/integrity/config.yml',
                 'site'             => '/path/to/site'}
      stub(ReportCard).config { @config }

      @project = Integrity::Project.new
    end

    should "grade if project name is valid" do
      stub(@project).name { "awesome" }

      mock(Integrity).new(@config['integrity_config'])
      mock(ReportCard).setup
      mock(Integrity::Project).all.mock!.each.yields(@project)

      grader = "grader"
      mock(grader).grade
      mock(grader).success? { true }
      mock(ReportCard::Grader).new(@project, @config) { grader }
      mock(ReportCard::Index).create([@project], @config['site'])
      ReportCard.grade
    end

    should "not grade if project name is ignored" do
      @config['ignore'] = "1\.9"
      stub(@project).name { "awesome 1.9" }

      mock(Integrity).new(@config['integrity_config'])
      mock(ReportCard).setup
      mock(Integrity::Project).all.mock!.each.yields(@project)
      mock(ReportCard::Grader).new(@project, @config).never
      mock(ReportCard::Index).create(anything, anything).never
      ReportCard.grade
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
