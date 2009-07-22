Given /^I have integrity setup/ do
  FileUtils.rm_rf(INTEGRITY_DIR)
  FileUtils.rm_rf(File.join(TEST_DIR, '_site'))
  FileUtils.rm_rf(File.join(TEST_DIR, 'config.yml'))
  `integrity install #{INTEGRITY_DIR}`
  `integrity migrate_db #{INTEGRITY_CONFIG}`
end

Given /^I have a (private|public) integrity project named "([^\"]*)"$/ do |access, name|
  Integrity.new(INTEGRITY_CONFIG)
  project = Integrity::Project.create(:name   => name,
                                      :uri    => "git://github.com/thoughtbot/#{name}",
                                      :public => (access == "public"))
  project.build
end

Given /^I have a configuration file with "([^\"]*)" set to "([^\"]*)"$/ do |key, value|
  File.open(File.join(TEST_DIR, 'config.yml'), 'a') do |f|
    f.write("#{key}: #{value}\n")
    f.close
  end
end

Given /^I have a basic site configuration$/ do
  Given %{I have a configuration file with "url" set to "http://metrics.thoughtbot.com"}
  And   %{I have a configuration file with "integrity_config" set to "integrity/config.yml"}
  And   %{I have a configuration file with "site" set to "#{File.expand_path('_site')}"}
end


When /^I run "([^\"]*)"$/ do |command|
  `cd #{TEST_DIR}; #{command} --trace`
end

Then /^the "([^\"]*)" file should exist$/ do |name|
  assert File.file?(name)
end

Then /^I should see "([^\"]*)" in "([^\"]*)"$/ do |text, file|
  assert_match Regexp.new(text), File.read(file)
end

Then /^the "([^\"]*)" directory should exist$/ do |name|
  assert File.directory?(name)
end

Then /^the template files should exist in "([^\"]*)"$/ do |dir|
  Then %{the "#{dir}/buttons.css" file should exist}
  And  %{the "#{dir}/reset.css" file should exist}
  And  %{the "#{dir}/integrity.css" file should exist}
  And  %{the "#{dir}/favicon.ico" file should exist}
end
