Feature: Grading projects
  As a programmer who is concerned about quality
  I want to be able to find out details metrics about my application
  In order to improve it and make it awesome

  Scenario: Grading public and private projects
    Given I have integrity setup
    And I have a public integrity project named "factory_girl"
    And I have a public integrity project named "clearance"
    And I have a private integrity project named "paperclip"
    And I have a basic site configuration

    When I run "rake grade"

    Then the "_site/index.html" file should exist
    And I should see "factory_girl" in "_site/index.html"
    And I should see "clearance" in "_site/index.html"
    And the "_site/clearance/output" directory should exist
    And the "_site/factory_girl/output" directory should exist

    And the "_site/private/index.html" file should exist
    And I should see "paperclip" in "_site/private/index.html"
    And the "_site/private/paperclip/output" directory should exist
    And the template files should exist in "_site"
