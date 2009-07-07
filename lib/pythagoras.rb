require 'integrity'

class Pythagoras
  CONFIG_FILE = "config.yml"

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
        Pythagoras.new(project.name, config) if project.name !~ ignore
      end
    rescue Exception => e
      STDERR.puts "There was a problem loading your projects from integrity: #{e}"
      return
    end
  end

  def initialize(project, config)
    p project
  end
end
