require 'integrity'
require 'metric_fu'
require 'tinder'

$:.unshift(File.dirname(__FILE__))
require 'report_card/runner'

module ReportCard
  CONFIG_FILE = "config.yml"

  def self.run
    Integrity.new(config['integrity_config'])

    ignore = config['ignore'] ? Regexp.new(config['ignore']) : /[^\w\d\s]+/

    Integrity::Project.all.each do |project|
      ReportCard::Runner.new(project, config).run if project.name !~ ignore
    end
  end

  def self.config
    if File.exist?(CONFIG_FILE)
      @config ||= YAML.load_file(CONFIG_FILE)
    else
      Kernel.abort("You need a config file. Check the readme please!")
    end
  end

  def self.setup
    FileUtils.mkdir_p(config['site'])
    FileUtils.cp(Dir[File.join(File.dirname(__FILE__), '..', 'template', '*.{css,ico}')], config['site'])
  end
end
