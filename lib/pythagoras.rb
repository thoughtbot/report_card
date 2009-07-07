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

    Integrity.new(config[:integrity_config])

    begin
      projects = Integrity::Project.all
    rescue Exception => e
      STDERR.puts "No projects were found at #{config[:integrity_config]}: #{e}"
      return
    end

    projects.each do |project|
      Pythagoras.new(project, config)
    end
  end

  def initialize(project, config)
  end
end
