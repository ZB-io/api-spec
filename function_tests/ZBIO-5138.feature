Feature: Credit Card Due Reminder Notification

  Scenario: Send reminder notification one day before the due date
    Given the API base URL 'http://api.financeservice.com'
    And a credit card due date is set to '2023-04-10'
    When I send a GET request to '/reminders/check' on '2023-04-09'
    Then the response status should be 200
    And the response body should contain 'Reminder notification sent'

  Scenario: Send reminder notification on a weekend due date
    Given the API base URL 'http://api.financeservice.com'
    And a credit card due date is set to a weekend '2023-04-10'
    When I send a GET request to '/reminders/check' on '2023-04-09'
    Then the response status should be 200
    And the response body should contain 'Reminder notification sent'
