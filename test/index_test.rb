require 'test_helper'

class IndexTest < Test::Unit::TestCase
  context "with a few projects" do
    setup do
      @public_project1  = Integrity::Project.new(:name => "awesome")
      @public_project2  = Integrity::Project.new(:name => "wicked")
      @private_project  = Integrity::Project.new(:name => "secret", :public => false)

      @site = "/path/to/file"
      @projects = [@public_project1, @public_project2, @private_project]
    end

    should "split up public and private projects" do
      mock(ReportCard::Index).new([@public_project1, @public_project2], @site)
      mock(ReportCard::Index).new([@private_project], File.join(@site, "private"))

      ReportCard::Index.create(@projects, @site)
    end

    should "write out projects for each template" do
      erb = "erb"
      html = "html"
      io = "io"
      mock(io).write(html)

      mock(File).read(ReportCard::Index::TEMPLATE_PATH) { erb }
      mock(ERB).new(erb).mock!.result(anything) { html }
      mock(File).open(File.join(@site, "index.html"), "w").yields(io)

      ReportCard::Index.new([@private_project], @site)
    end

    should "not write out anything if there's no projects" do
      mock(File).read(anything).never
      mock(ERB).new(anything).never
      mock(File).open(anything, "w").never
      ReportCard::Index.new([], @site)
    end
  end
end
