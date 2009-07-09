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

    should "create index" do
      ReportCard::Index.create(@projects, @site)
    end
  end
end
