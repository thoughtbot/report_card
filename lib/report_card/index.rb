module ReportCard
  class Index
    TEMPLATE_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "template", "index.html.erb"))

    def self.create(projects, site)
      new(projects.select { |p| p.public }, site)
      new(projects.select { |p| ! p.public }, File.join(site, 'private'))
    end

    def initialize(projects, path)
      return if projects.empty?

      @projects = projects

      erb = File.read(TEMPLATE_PATH)
      html = ERB.new(erb).result(binding)

      File.open(File.join(path, "index.html"), "w") do |f|
        f.write html
      end
    end
  end
end
