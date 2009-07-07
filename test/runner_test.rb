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

    context "output_path" do
      should "use _site/:project for a public project" do
        assert @project.public
        assert_equal File.expand_path(File.join(__FILE__, "..", "..", "_site", @project.name)), @runner.output_path
      end

      should "use _site/private/:project for a private project" do
        @project.public = false
        assert_equal File.expand_path(File.join(__FILE__, "..", "..", "_site", "private", @project.name)), @runner.output_path
      end
    end

    should "use _site/scores/:project for score_path" do
      assert_equal File.expand_path(File.join(__FILE__, "..", "..", "_site", "scores", @project.name)), @runner.scores_path
    end

    should "use _site/archive/:project for score_path" do
      assert_equal File.expand_path(File.join(__FILE__, "..", "..", "_site", "archive", @project.name)), @runner.archive_path
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

    context "wrapping up" do
      setup do
        @report = YAML.load_file(File.expand_path(File.join(__FILE__, "..", "fixtures", "report.yml")))
        stub(YAML).load_file(File.join(MetricFu.base_directory, "report.yml")) { @report }
      end

      should "load scores from report yml" do
        mock(File).open(@runner.scores_path, "w")

        @runner.score

        assert_equal @report[:flay][:total_score].to_s,        @runner.scores[:flay]
        assert_equal @report[:flog][:total].to_s,              @runner.scores[:flog_total]
        assert_equal @report[:flog][:average].to_s,            @runner.scores[:flog_average]
        assert_equal @report[:roodi][:problems].size.to_s,     @runner.scores[:roodi]
        assert_equal @report[:rcov][:global_percent_run].to_s, @runner.scores[:rcov]
        assert_equal "9",                                      @runner.scores[:reek]
      end

      context "with scores" do
        setup do
          stub(@runner).scores { "scores" }
        end

        should "add to archive" do
          archive = "archive"
          mock(archive)[DateTime.now.to_s] = @runner.scores
          mock(YAML).load_file(@runner.archive_path) { archive }

          mock(File).exist?(@runner.archive_path) { true }
          mock(File).open(@runner.archive_path, "w")

          @runner.archive
        end
      end

    end
  end
end
