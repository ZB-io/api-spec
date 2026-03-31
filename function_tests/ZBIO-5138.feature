Feature: Credit Card Due Reminder Notifications

  Scenario: Send credit card due notification one day before the due date
    Given the credit card due date is '10/05/2023'
    When the system checks the date '09/05/2023' for upcoming due reminders
    Then a reminder notification should be sent
    And the notification should include the due date '10/05/2023'

  Scenario: Send credit card due notification one day before the due date on weekends
    Given the credit card due date is '10/05/2023' and it falls on a weekend
    When the system checks the date '09/05/2023' for upcoming due reminders
    Then a reminder notification should be sent
    And the notification should include the due date '10/05/2023'
