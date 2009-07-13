Feature: Grading projects
  As a programmer who is concerned about quality
  I want to be able to find out details metrics about my application
  In order to improve it and make it awesome

  Scenario: Grading public projects
    Given I have integrity setup in the "integrity" directory
    And I have a public integrity project called "factory_girl"
    And I have a public integrity project called "clearance"
    And I have a configuration file with "url" set to "http://metrics.thoughtbot.com"
    And I have a configuration file with "integrity_config" set to "integrity/config.yml"
    And I have a configuration file with "site" set to "_site"

    When I run "rake grade"

    Then the "_site/index.html" file should exist
    And I should see "factory_girl" in "_site/index.html"
    And I should see "clearance" in "_site/index.html"
    And I should see "http://metrics.thoughtbot.com" in "_site/index.html"
    And the "_site/clearance/output" directory should exist
    And the "_site/factory_girl/output" directory should exist
    And the template files should exist in "_site"

  Scenario: Grading public and private projects
    Given I have integrity setup in the "integrity" directory
    And I have a public integrity project called "factory_girl"
    And I have a public integrity project called "clearance"
    And I have a private integrity project called "paperclip"
    And I have a configuration file with "url" set to "http://metrics.thoughtbot.com"
    And I have a configuration file with "integrity_config" set to "integrity/config.yml"
    And I have a configuration file with "site" set to "_site"

    When I run "rake grade"

    Then the "_site/index.html" file should exist
    And I should see "factory_girl" in "_site/index.html"
    And I should see "clearance" in "_site/index.html"
    And I should see "http://metrics.thoughtbot.com" in "_site/index.html"
    And the "_site/clearance/output" directory should exist
    And the "_site/factory_girl/output" directory should exist
    And the "_site/private/index.html" file should exist
    And I should see "paperclip" in "_site/private/index.html"
    And I should see "http://metrics.thoughtbot.com" in "_site/private/index.html"
    And the "_site/private/paperclip/output" directory should exist
    And the template files should exist in "_site"
