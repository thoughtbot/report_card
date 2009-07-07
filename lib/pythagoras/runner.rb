module Pythagoras
  class Runner
    attr_reader :project, :config, :scores

    def initialize(project, config)
      @project = project
      @config = config
    end

=begin
    def run
      if ready?
        configure
        generate
        wrapup if success?
      end
    end

    def wrapup
      score
      record
      notify
    end
=end

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

      File.open(self.scores_path, "w") do |f|
        f.write @scores.to_yaml
      end
    end

    def archive
      if File.exist?(self.archive_path)
        archive = YAML.load_file(archive_path)
      else
        archive = {}
      end

      archive[DateTime.now.to_s] = self.scores
      File.open(self.archive_path, 'w') do |f|
        f.write archive.to_yaml
      end
    end

    def success?
      @success
    end

    def site_path(*dirs)
      File.expand_path(File.join(__FILE__, "..", "..", "..", "_site", *dirs))
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
