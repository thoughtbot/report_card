require 'test_helper'

class RunnerTest < Test::Unit::TestCase
  context "with a pythagoras object" do
    setup do
      @project = Integrity::Project.new(:name => "awesome")
      @config = {}
      @runner = Pythagoras::Runner.new(@project, @config)
    end

    should "store project and config" do
      assert_equal @runner.project, @project
      assert_equal @runner.config, @config
    end

    should "change directory to the export directory if it exists" do
      directory = "dir"
      mock(Integrity::ProjectBuilder).new(@project).mock!.send(:export_directory) { directory }
      mock(File).exist?(directory) { true }
      mock(Dir).chdir(directory) { 0 }
      assert @runner.ready?
    end

    should "not change directory to the export directory if it does not exists" do
      directory = "dir"
      mock(Integrity::ProjectBuilder).new(@project).mock!.send(:export_directory) { directory }
      mock(File).exist?(directory) { false }
      mock(Dir).chdir(anything).never
      mock(STDERR).puts(anything)
      assert ! @runner.ready?
    end

    should "use _site/:project for generating metrics" do
      assert @project.public
      assert_equal File.expand_path(File.join(__FILE__, "..", "..", "_site", @project.name)), @runner.output_path
    end

    should "use _site/private/:project for generating metrics on a private project" do
      @project.public = false
      assert_equal File.expand_path(File.join(__FILE__, "..", "..", "_site", "private", @project.name)), @runner.output_path
    end

    should "set build artifacts and prepare metric_fu for configure" do
      mock(ENV)['CC_BUILD_ARTIFACTS'] = @runner.output_path

      config = "config"
      mock(config).reset
      mock(config).template_class = AwesomeTemplate
      mock(config).metrics = [:flog, :flay, :rcov, :reek, :roodi]
      mock(config).rcov = anything

      mock.proxy(MetricFu::Configuration).run.yields(config)
      @runner.configure
      assert_equal Hash.new, MetricFu.report.instance_variable_get(:@report_hash)
    end

    context "given already configured" do
      setup do
        @runner.configure
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

        @runner.generate
        assert @runner.success?
      end

      should "be unsuccessful if some problem arises" do
        stub(MetricFu).metrics { raise "some problem" }
        mock(STDERR).puts(anything)
        @runner.generate
        assert ! @runner.success?
      end
    end

    context "notification" do
    end
  end
end
