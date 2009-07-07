require 'test_helper'
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

    should "set build artifacts and prepare metric_fu for configure" do
      mock(ENV)['CC_BUILD_ARTIFACTS'] = @py.output_path

      config = "config"
      mock(config).reset
      mock(config).template_class = AwesomeTemplate
      mock(config).metrics = [:flog, :flay, :rcov, :reek, :roodi]
      mock(config).rcov = anything

      mock.proxy(MetricFu::Configuration).run.yields(config)
      @py.configure
      assert_equal Hash.new, MetricFu.report.instance_variable_get(:@report_hash)
    end

    context "given already configured" do
      setup do
        @py.configure
      end

      should "successfully generate output" do
        metric = "metric"
        report = "report"

        mock(report).add(metric)
        mock(report).save_templatized_report
        mock(report).to_yaml { "yaml" }
        mock(report).save_output("yaml", MetricFu.base_directory, "report.yml")

        stub(MetricFu).report { report }
        mock(MetricFu).metrics.stub!.each.yields(metric)

        @py.generate
        assert @py.success?
      end

      should "be unsuccessful if some problem arises" do
        stub(MetricFu).metrics { raise "some problem" }
        mock(STDERR).puts(anything)
        @py.generate
        assert ! @py.success?
      end
    end
  end
end
