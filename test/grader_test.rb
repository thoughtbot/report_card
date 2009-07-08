require 'test_helper'

class GraderTest < Test::Unit::TestCase
  context "with a grader" do
    setup do
      @project = Integrity::Project.new(:name => "awesome")
      @config = {'url'  => 'http://metrics.thoughtbot.com',
                 'site' => '/path/to/site'}
      @grader = ReportCard::Grader.new(@project, @config)
      stub(STDERR).puts(anything)
    end

    should "not even grade if not ready" do
      mock(@grader).ready? { false }
      mock(@grader).configure.never
      mock(@grader).generate.never
      mock(@grader).wrapup.never
      @grader.grade
    end

    should "grade and wrapup if successful" do
      mock(@grader).ready? { true }
      mock(@grader).configure
      mock(@grader).generate
      mock(@grader).success? { true }
      mock(@grader).wrapup
      @grader.grade
    end

    should "grade and not wrapup if unsuccessful" do
      mock(@grader).ready? { true }
      mock(@grader).configure
      mock(@grader).generate
      mock(@grader).success? { false }
      mock(@grader).wrapup.never
      @grader.grade
    end

    should "score and notify when wrapping up" do
      mock(@grader).score
      mock(@grader).score_changed? { true }
      mock(@grader).notify
      @grader.wrapup
    end

    should "score and not notify when wrapping up and the score hasn't changed" do
      mock(@grader).score
      mock(@grader).score_changed? { false }
      mock(@grader).notify.never
      @grader.wrapup
    end

    should "store project and config" do
      assert_equal @grader.project, @project
      assert_equal @grader.config, @config
    end

    should "change directory to the export directory if it exists" do
      directory = "dir"
      mock(Integrity::ProjectBuilder).new(@project).mock!.send(:export_directory) { directory }
      mock(File).exist?(directory) { true }
      mock(Dir).chdir(directory) { 0 }
      assert @grader.ready?
    end

    should "not change directory to the export directory if it does not exists" do
      directory = "dir"
      mock(Integrity::ProjectBuilder).new(@project).mock!.send(:export_directory) { directory }
      mock(File).exist?(directory) { false }
      mock(Dir).chdir(anything).never
      mock(STDERR).puts(anything)
      assert ! @grader.ready?
    end

    context "with a public project" do
      setup do
        assert @project.public
      end

      should "have an announcement message for notification" do
        message = @grader.message
        assert_match "New metrics", message
        assert_match "#{@config['url']}/#{@project.name}/output", message
      end

      should "use _site/:project for output_path" do
        assert_equal File.expand_path(File.join(@config['site'], @project.name)), @grader.output_path
      end
    end

    context "with a private project" do
      setup do
        @project.public = false
      end

      should "have an announcement message for notification" do
        message = @grader.message
        assert_match "New metrics", message
        assert_match "#{@config['url']}/private/#{@project.name}/output", message
      end

      should "use _site/private/:project for output_path" do
        assert_equal File.expand_path(File.join(@config['site'], "private", @project.name)), @grader.output_path
      end
    end

    should "use _site/scores/:project for scores_path" do
      assert_equal File.expand_path(File.join(@config['site'], "scores", @project.name)), @grader.scores_path
    end

    should "use _site/archive/:project for archive_path" do
      assert_equal File.expand_path(File.join(@config['site'], "archive", @project.name)), @grader.archive_path
    end

    should "set build artifacts and prepare metric_fu for configure" do
      mock(ENV)['CC_BUILD_ARTIFACTS'] = @grader.output_path

      config = "config"
      mock(config).reset
      mock(config).template_class = AwesomeTemplate
      mock(config).metrics = mock(config).graphs = [:flog, :flay, :rcov, :reek, :roodi]
      mock(config).rcov = anything
      mock(config).data_directory = @grader.archive_path

      mock.proxy(MetricFu::Configuration).run.yields(config)
      @grader.configure
      assert_equal Hash.new, MetricFu.report.instance_variable_get(:@report_hash)
    end

    context "given already configured" do
      setup do
        @grader.configure
      end

      should "successfully generate output" do
        Timecop.freeze(Date.today) do
          metric = "metric"
          report = "report"
          graph  = "graph"
          one_graph = "one_graph"

          mock(report).add(metric)
          mock(report).save_templatized_report
          mock(report).to_yaml { "yaml" }.twice
          mock(report).save_output("yaml", MetricFu.base_directory, "report.yml")
          mock(report).save_output("yaml", MetricFu.data_directory, "#{Time.now.strftime("%Y%m%d")}.yml")

          stub(MetricFu).report { report }
          mock(MetricFu).metrics.stub!.each.yields(metric)

          mock(graph).add(one_graph)
          mock(graph).generate
          stub(MetricFu).graph  { graph }
          mock(MetricFu).graphs.stub!.each.yields(one_graph)

          @grader.generate
          assert @grader.success?
        end
      end

      should "be unsuccessful if some problem arises" do
        stub(MetricFu).metrics { raise "some problem" }
        mock(STDERR).puts(anything)
        @grader.generate
        assert ! @grader.success?
      end
    end

    context "wrapping up" do
      setup do
        @report = YAML.load_file(File.expand_path(File.join(__FILE__, "..", "fixtures", "report.yml")))
        stub(YAML).load_file(File.join(MetricFu.base_directory, "report.yml")) { @report }
        stub(File).exist?(anything) { false }
        stub(FileUtils).mkdir_p(anything)
        stub(File).open(@grader.scores_path, "w")
      end

      should "load old scores if they exist" do
        old_scores = "old scores"
        mock(File).exist?(@grader.scores_path) { true }
        mock(YAML).load_file(@grader.scores_path) { old_scores }

        @grader.score
        assert_equal old_scores, @grader.old_scores
      end

      should "set old score if it's not there" do
        mock(File).exist?(@grader.scores_path) { false }
        mock(FileUtils).mkdir_p(File.dirname(@grader.scores_path))

        @grader.score
        assert_equal Hash.new, @grader.old_scores
      end

      should "load and write scores from report yml" do
        mock(File).open(@grader.scores_path, "w")

        @grader.score

        assert_equal @report[:flay][:total_score].to_s,        @grader.scores[:flay]
        assert_equal @report[:flog][:total].to_s,              @grader.scores[:flog_total]
        assert_equal @report[:flog][:average].to_s,            @grader.scores[:flog_average]
        assert_equal @report[:roodi][:problems].size.to_s,     @grader.scores[:roodi]
        assert_equal @report[:rcov][:global_percent_run].to_s, @grader.scores[:rcov]
        assert_equal "9",                                      @grader.scores[:reek]
      end

      context "with scores" do
        setup do
          stub(@grader).scores { "scores" }
          stub(@grader).message { "message" }
          stub(@grader).scoreboard { "scoreboard" }
        end

        context "with different old score" do
          setup do
            stub(@grader).old_scores { "old scores" }
          end

          should "return true for score_changed?" do
            assert @grader.score_changed?
          end
        end

        context "with similar old score" do
          setup do
            stub(@grader).old_scores { @grader.scores }
          end

          should "return false for score_changed?" do
            assert ! @grader.score_changed?
          end
        end

        should "skip notification if config value is there" do
          @config['skip_notification'] = true
          @grader.notify
          mock(Tinder::Campfire).new.never
        end

        should "report problem if notification fails" do
          mock(@project).notifiers { raise "problem" }
          mock(STDERR).puts(anything)
          mock(Tinder::Campfire).new.never

          @grader.notify
        end

        should "not skip notification if config value isn't there" do
          project_config = { "user"    => "nobody",
                             "pass"    => "secret",
                             "room"    => "awesome",
                             "account" => "comp" }
          mock(@project).notifiers.mock!.first.mock!.config { project_config }

          room = "room"
          mock(room).speak(@grader.message)
          mock(room).paste(@grader.scoreboard)
          mock(room).leave

          campfire = "campfire"
          mock(campfire).login(project_config["user"], project_config["pass"])
          mock(campfire).find_room_by_name(project_config["room"]) { room }
          mock(Tinder::Campfire).new(project_config["account"], :ssl => true) { campfire }

          @grader.notify
        end
      end
    end
  end
end
