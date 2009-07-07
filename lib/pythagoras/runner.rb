module Pythagoras
  class Runner
    attr_reader :project, :config, :scores, :old_scores

    def initialize(project, config)
      @project = project
      @config = config
    end

    def run
      return unless ready?
      configure
      generate
      wrapup if success?
    end

    def wrapup
      score
      archive
      notify if score_changed?
    end

    def ready?
      dir = Integrity::ProjectBuilder.new(project).send(:export_directory)
      if File.exist?(dir)
        Dir.chdir dir
      else
        STDERR.puts ">> Skipping, directory does not exist: #{dir}"
      end
    end

    def configure
      ENV['CC_BUILD_ARTIFACTS'] = self.output_path
      MetricFu::Configuration.run do |config|
        config.reset
        config.template_class = AwesomeTemplate
        config.metrics  = [:flog, :flay, :rcov, :reek, :roodi]
        config.rcov     = { :test_files => ['test/functional/*_test.rb', 'test/unit/*_test.rb'],
                            :rcov_opts  => ["--sort coverage",
                            "--no-html",
                            "--text-coverage",
                            "--no-color",
                            "--profile",
                            "--rails",
                            "--include test",
                            "--exclude /gems/,/usr/local/lib/site_ruby/1.8/,spec"]}
      end
      MetricFu.report.instance_variable_set(:@report_hash, {})
    end

    def generate
      begin
        MetricFu.metrics.each { |metric| MetricFu.report.add(metric) }
        MetricFu.report.save_output(MetricFu.report.to_yaml, MetricFu.base_directory, 'report.yml')
        MetricFu.report.save_templatized_report
        @success = true
      rescue Exception => e
        STDERR.puts "Problem generating the reports: #{e}"
        @success = false
      end
    end

    def score
      report = YAML.load_file(File.join(MetricFu.base_directory, 'report.yml'))

      @scores = {
        :flay         => report[:flay][:total_score].to_s,
        :flog_total   => report[:flog][:total].to_s,
        :flog_average => report[:flog][:average].to_s,
        :reek         => report[:reek][:matches].inject(0) { |sum, match| sum + match[:code_smells].size }.to_s,
        :roodi        => report[:roodi][:problems].size.to_s
      }

      @scores[:rcov] = report[:rcov][:global_percent_run].to_s if report.has_key?(:rcov)

      if File.exist?(self.scores_path)
        @old_scores = YAML.load_file(self.scores_path)
      else
        FileUtils.mkdir(File.dirname(self.scores_path))
        @old_scores = {}
      end

      File.open(self.scores_path, "w") do |f|
        f.write @scores.to_yaml
      end
    end

    def archive
      if File.exist?(self.archive_path)
        archive = YAML.load_file(archive_path)
      else
        FileUtils.mkdir(File.dirname(self.archive_path))
        archive = {}
      end

      archive[DateTime.now.to_s] = self.scores
      File.open(self.archive_path, 'w') do |f|
        f.write archive.to_yaml
      end
    end

    def notify
      return if @config['skip_notification']

      begin
        config = @project.notifiers.first.config
        room ||= begin
          options = {}
          options[:ssl] = true
          campfire = Tinder::Campfire.new(config["account"], options)
          campfire.login(config["user"], config["pass"])
          campfire.find_room_by_name(config["room"])
        end
        room.speak self.message
        room.paste self.scoreboard
        room.leave
      rescue Exception => e
        STDERR.puts ">> Problem connecting to Campfire: #{e}"
      end
    end

    def message
      path = @project.public ? "" : "private"
      "New metrics generated for #{@project.name}: #{File.join(@config['url'], path, @project.name, 'output')}"
    end

    def scoreboard
      scores = ""
      columns = "%15s%20s%20s\n"
      scores << sprintf(columns, "", "This Run", "Last Run")
      scores << sprintf(columns, "Flay Score", @scores[:flay], @old_scores[:flay])
      scores << sprintf(columns, "Flog Total/Avg", "#{@scores[:flog_total]}/#{@scores[:flog_average]}", "#{@old_scores[:flog_total]}/#{@old_scores[:flog_average]}")
      scores << sprintf(columns, "Reek Smells", @scores[:reek], @old_scores[:reek])
      scores << sprintf(columns, "Roodi Problems", @scores[:roodi], @old_scores[:roodi])
    end

    def score_changed?
      self.scores != self.old_scores
    end

    def success?
      @success
    end

    def site_path(*dirs)
      site_dir = @config['site'] || File.join(File.dirname(__FILE__), "..", "..")
      File.expand_path(File.join(site_dir, *dirs))
    end

    def output_path
      path = [@project.name]
      path.unshift("private") unless @project.public
      site_path(*path)
    end

    def scores_path
      site_path("scores", @project.name)
    end

    def archive_path
      site_path("archive", @project.name)
    end
  end
end
