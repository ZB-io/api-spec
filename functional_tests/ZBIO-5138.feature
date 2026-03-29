Feature: Credit Card Notification System Testing
  Background:
    Given the base URL 'http://localhost:8080/api'

  Scenario: Credit Card Due Reminder
    Given the saved credit card due date is '01/12/2022'
    When I send a GET request to '/dueReminder'
    Then the response status code should be 200
    And the response should contain a scheduled reminder for '30/11/2022'

  Scenario: Overdue Balance Alert
    Given the system shows the card payment as not done and today's date is '02/12/2022'
    When I send a GET request to '/overdueAlert'
    Then the response status code should be 200
    And the response should contain an alert for the date '02/12/2022'

  Scenario: Collection Notification
    Given the system identifies an account with more than 60 days past due
    When I send a GET request to '/collectionNotification'
    Then the response status code should be 200
    And the response should contain overdue balance, late fine and necessary actions details

  Scenario: Payment Plan Proposal
    Given the cardholder contacts the bank unable to pay full overdue balance
    When I send a POST request to '/paymentPlan' with the payment proposal
    Then the response status code should be 201
    And the response should contain a section 'payment plan proposal'

  Scenario: Collection Agency Involvement
    Given the system detects cardholder's three failed attempts to respond to notifications and reminders of overdue balance
    When I send a GET request to '/agencyInvolvement'
    Then the response status code should be 200
    And the response should contain 'Involve a collection agency'

  Scenario: Legal Action Initiation
    Given the system detects chronic non-payment behavior from the cardholder
    When I send a GET request to '/legalActionInitiation'
    Then the response status code should be 200
    And the response should contain 'Initiate stringent legal actions'

  Scenario: Performance Testing
    Given the application is under test
    When I bombard the API endpoint with multiple simultaneous requests
    Then the application should respond within acceptable time limits

  Scenario: Usability Testing
    Given the application interface is rendered
    When a user navigates the application
    Then the application should be navigable and intuitive

  Scenario: Security Testing
    Given the sensitive user data
    When the data is transmitted over the network
    Then the data should be encrypted and secure

  Scenario: Compatibility Testing
    Given the application
    When accessed from different devices
    Then the application should be compatible and responsive

  Scenario: Reliability Testing
    Given the running application
    When operating for a certain period of time
    Then the application should demonstrate reliability and stability

  Scenario: Recovery Testing
    Given the application
    When a crash or hardware failure occurs
    Then the application should recover and retain data integrity

  Scenario: API Testing
    Given the APIs provided by the application
    When I send requests to the APIs
    Then the API responses should be fast, reliable, secure, and accurate
