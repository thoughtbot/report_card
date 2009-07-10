module ReportCard
  class Index
    attr_reader :projects, :footer

    TEMPLATE_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "template", "index.html.erb"))

    def self.create(projects, site)
      new(projects.select { |p| p.public }, site, "<a href='/private'>TOP SECRET PROJECTS</a>")
      new(projects.select { |p| ! p.public }, File.join(site, 'private'), "<a href='/'>NORMAL BORING PROJECTS</a>")
    end

    def initialize(projects, path, footer)
      return if projects.empty?

      @projects = projects
      @footer = footer

      erb = File.read(TEMPLATE_PATH)
      html = ERB.new(erb).result(binding)

      File.open(File.join(path, "index.html"), "w") do |f|
        f.write html
      end
    end
  end
end
