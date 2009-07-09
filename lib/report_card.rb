$:.unshift(File.dirname(__FILE__))

require 'integrity'
require 'metric_fu'
require 'tinder'

require 'report_card/index'
require 'report_card/grader'

module ReportCard
  CONFIG_FILE = "config.yml"

  def self.grade
    Integrity.new(config['integrity_config'])

    ignore = config['ignore'] ? Regexp.new(config['ignore']) : /[^\w\d\s]+/
    projects = []

    Integrity::Project.all.each do |project|
      if project.name !~ ignore
        grader = Grader.new(project, config)
        grader.grade
        projects << project if grader.success?
      end
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