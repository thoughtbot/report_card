require 'test_helper'

class RunnerTest < Test::Unit::TestCase
  context "with a runner" do
    setup do
      @project = Integrity::Project.new(:name => "awesome")
      @config = {'url'  => 'http://metrics.thoughtbot.com',
                 'site' => '/path/to/site'}
      @runner = Pythagoras::Runner.new(@project, @config)
    end

    should "not even run if not ready" do
      mock(@runner).ready? { false }
      mock(@runner).configure.never
      mock(@runner).generate.never
      mock(@runner).wrapup.never
      @runner.run
    end

    should "run and wrapup if successful" do
      mock(@runner).ready? { true }
      mock(@runner).configure
      mock(@runner).generate
      mock(@runner).success? { true }
      mock(@runner).wrapup
      @runner.run
    end

    should "run and not wrapup if unsuccessful" do
      mock(@runner).ready? { true }
      mock(@runner).configure
      mock(@runner).generate
      mock(@runner).success? { false }
      mock(@runner).wrapup.never
      @runner.run
    end

    should "score, record, and notify when wrapping up" do
      mock(@runner).score
      mock(@runner).record
      mock(@runner).score_changed? { true }
      mock(@runner).notify
      @runner.wrapup
    end

    should "score, record, and not notify when wrapping up and the score hasn't changed" do
      mock(@runner).score
      mock(@runner).record
      mock(@runner).score_changed? { false }
      mock(@runner).notify.never
      @runner.wrapup
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

    context "with a public project" do
      setup do
        assert @project.public
      end

      should "have an announcement message for notification" do
        message = @runner.message
        assert_match "New metrics", message
        assert_match "#{@config['url']}/#{@project.name}/output", message
      end

      should "use _site/:project for output_path" do
        assert_equal File.expand_path(File.join(@config['site'], @project.name)), @runner.output_path
      end
    end

    context "with a private project" do
      setup do
        @project.public = false
      end

      should "have an announcement message for notification" do
        message = @runner.message
        assert_match "New metrics", message
        assert_match "#{@config['url']}/private/#{@project.name}/output", message
      end

      should "use _site/private/:project for output_path" do
        assert_equal File.expand_path(File.join(@config['site'], "private", @project.name)), @runner.output_path
      end
    end

    should "use _site/scores/:project for scores_path" do
      assert_equal File.expand_path(File.join(@config['site'], "scores", @project.name)), @runner.scores_path
    end

    should "use _site/archive/:project for archive_path" do
      assert_equal File.expand_path(File.join(@config['site'], "archive", @project.name)), @runner.archive_path
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
        stub(File).exist?(anything) { false }
        stub(FileUtils).mkdir(anything)
        stub(File).open(@runner.scores_path, "w")
      end

      should "load old scores if they exist" do
        old_scores = "old scores"
        mock(File).exist?(@runner.scores_path) { true }
        mock(YAML).load_file(@runner.scores_path) { old_scores }

        @runner.score
        assert_equal old_scores, @runner.old_scores
      end

      should "set old score if it's not there" do
        mock(File).exist?(@runner.scores_path) { false }
        mock(FileUtils).mkdir(File.dirname(@runner.scores_path))

        @runner.score
        assert_equal Hash.new, @runner.old_scores
      end

      should "load and write scores from report yml" do
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
          stub(@runner).message { "message" }
          stub(@runner).scoreboard { "scoreboard" }
        end

        context "with different old score" do
          setup do
            stub(@runner).old_scores { "old scores" }
          end

          should "return true for score_changed?" do
            assert @runner.score_changed?
          end
        end

        context "with similar old score" do
          setup do
            stub(@runner).old_scores { @runner.scores }
          end

          should "return false for score_changed?" do
            assert ! @runner.score_changed?
          end
        end

        should "add to archive" do
          archive = "archive"
          mock(archive)[DateTime.now.to_s] = @runner.scores

          mock(File).exist?(@runner.archive_path) { true }
          mock(YAML).load_file(@runner.archive_path) { archive }
          mock(File).open(@runner.archive_path, "w")

          @runner.archive
        end

        should "set and create archive if it does not exist" do
          #archive = "archive"
          #mock(archive)[DateTime.now.to_s] = @runner.scores

          mock(File).exist?(@runner.archive_path) { false }
          mock(YAML).load_file(anything).never
          mock(FileUtils).mkdir(File.dirname(@runner.archive_path))
          mock(File).open(@runner.archive_path, "w")

          @runner.archive
        end

        should "skip notification if config value is there" do
          @config['skip_notification'] = true
          @runner.notify
          mock(Tinder::Campfire).new.never
        end

        should "report problem if notification fails" do
          mock(@project).notifiers { raise "problem" }
          mock(STDERR).puts(anything)
          mock(Tinder::Campfire).new.never

          @runner.notify
        end

        should "not skip notification if config value isn't there" do
          project_config = { "user"    => "nobody",
                             "pass"    => "secret",
                             "room"    => "awesome",
                             "account" => "comp" }
          mock(@project).notifiers.mock!.first.mock!.config { project_config }

          room = "room"
          mock(room).speak(@runner.message)
          mock(room).paste(@runner.scoreboard)
          mock(room).leave

          campfire = "campfire"
          mock(campfire).login(project_config["user"], project_config["pass"])
          mock(campfire).find_room_by_name(project_config["room"]) { room }
          mock(Tinder::Campfire).new(project_config["account"], :ssl => true) { campfire }

          @runner.notify
        end
      end
    end
  end
end
