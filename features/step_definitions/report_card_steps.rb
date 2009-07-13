Given /^I have integrity setup/ do
  `integrity install #{INTEGRITY_DIR}`
  `integrity migrate_db #{INTEGRITY_CONFIG}`
end

Given /^I have a (private|public) integrity project named "([^\"]*)"$/ do |access, name|
  Integrity.new(INTEGRITY_CONFIG)
  project = Integrity::Project.create(:name => name,
                                      :uri => "git://github.com/thoughtbot/#{name}",
                                      :public => (access == "public"))
  print project.build
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
  And   %{I have a configuration file with "site" set to "_site"}
end


When /^I run "([^\"]*)"$/ do |command|
  print `#{command} --trace`
end

Then /^the "([^\"]*)" file should exist$/ do |name|
  assert File.file?(file)
end

Then /^I should see "([^\"]*)" in "([^\"]*)"$/ do |text, file|
  assert_match Regexp.new(text), File.read(file)
end

Then /^the "([^\"]*)" directory should exist$/ do |name|
  assert File.directory?(dir)
end

Then /^the template files should exist in "([^\"]*)"$/ do |dir|
  Then %{the "_site/buttons.css" file should exist"}
  And  %{the "_site/reset.css" file should exist"}
  And  %{the "_site/integrity.css" file should exist"}
  And  %{the "_site/favicon.ico" file should exist"}
end
