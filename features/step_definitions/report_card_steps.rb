Given /^I have integrity setup in the "([^\"]*)" directory$/ do |dir|
  `integrity install #{File.join(TEST_DIR, dir)}`
  `integrity migrate_db #{File.join(TEST_DIR, dir, "config.yml")}`
end

Given /^I have a (private|public) integrity project called "([^\"]*)"$/ do |access, name|
  pending
end

Given /^I have a configuration file with "([^\"]*)" set to "([^\"]*)"$/ do |key, value|
  pending
end

When /^I run "([^\"]*)"$/ do |command|
  pending
end

Then /^the "([^\"]*)" file should exist$/ do |name|
  pending
end

Then /^I should see "([^\"]*)" in "([^\"]*)"$/ do |text, file|
  pending
end

Then /^the "([^\"]*)" directory should exist$/ do |name|
  pending
end

Then /^the template files should exist in "([^\"]*)"$/ do |dir|
  pending
end
