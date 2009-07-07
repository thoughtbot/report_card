require 'integrity'
require 'metric_fu'

class Pythagoras
  CONFIG_FILE = "config.yml"
  attr_reader :project, :config

  def initialize(project, config)
    @project = project
    @config = config
  end

=begin
  def run
    if ready?
      configure
      generate
      report if success?
    end
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

  def success?
    @success
  end

  def output_path
    path = [@project.name]
    path.unshift("private") unless @project.public
    File.expand_path(File.join(__FILE__, "..", "..", "_site", *path))
  end

  def self.run
    begin
      config = YAML.load_file(CONFIG_FILE)
    rescue Exception => e
      STDERR.puts "There was a problem reading your #{CONFIG_FILE} file: #{e}"
      return
    end

    if config
      Integrity.new(config[:integrity_config])
    else
      STDERR.puts "Your config file is blank."
      return
    end

    ignore = config[:ignore] ? Regexp.new(config[:ignore]) : /[^\w\d\s]+/

    begin
      Integrity::Project.all.each do |project|
        Pythagoras.new(project, config) if project.name !~ ignore
      end
    rescue Exception => e
      STDERR.puts "There was a problem loading your projects from integrity: #{e}"
      return
    end
  end
end
