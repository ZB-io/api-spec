Feature: Credit card due reminder API
  Scenario: Testing HTTP POST method for Credit Card Due Reminder
    Given a credit card API
    When I send a POST request to '/dueReminder' with due date '01/12/2022' 
    Then the response status should be 200
    And I should receive a response scheduled for '30/11/2022'
    
  Scenario: Testing weekend/holiday reminder logic
    Given a credit card API
    When I send a POST request to '/dueReminder' with a due date on weekend or holiday
    Then I should receive a response scheduled for the previous working day

Feature: Overdue balance alert API
  Scenario: Testing HTTP POST method for Overdue Balance Alert
    Given a credit card API
    When I send a POST request to '/overdueAlert' with a due date '01/12/2022' and current date '02/12/2022'
    Then the response status should be 200
    And I should receive an overdue balance alert for '02/12/2022'
    
  Scenario: Testing the overdue alert publication time
    Given a credit card API
    When I send a POST request to '/overdueAlert' before the due date 
    Then I should not receive an overdue balance alert

Feature: Collection notification API
  Scenario: Testing HTTP POST method for Collection Notification
    Given a credit card API
    When I send a POST request to '/collectionNotification' with the account overdue by 60 days
    Then the response status is 200
    And I should receive a collection notice outlining the overdue amount

  Scenario: Testing collection notice sending rules
    Given a credit card API
    When I send a POST request to '/collectionNotification' with the account overdue by less than 60 days
    Then I should not receive a collection notice
    
Feature: Payment plan proposal API
  Scenario: Testing HTTP POST method for Payment Plan Proposal
    Given a credit card API
    When I send a POST request to '/paymentPlan' indicating inability to pay full overdue balance
    Then the response status is 200
    And I should receive a payment plan with a structured repayment schedule and potentially reduced rates or fees

  Scenario: Testing payment plan proposal conditions
    Given a credit card API
    When I send a POST request to '/paymentPlan' with the account only slightly delinquent
    Then I should not receive a payment plan proposal

Feature: Collection Agency Involvement API
  Scenario: Testing HTTP POST method for Collection Agency Involvement
    Given a credit card API
    When I send a POST request to '/agencyInvolvement' with non-response after 3 consecutive notifications
    Then the response status is 200
    And a collection agency is involved in the response

  Scenario: Testing collection agency involvement conditions
    Given a credit card API
    When I send a POST request to '/agencyInvolvement' before 3 consecutive notifications were sent
    Then a collection agency should not be involved in the response

Feature: Legal Action Initiation API
  Scenario: Testing HTTP POST method for Legal Action Initiation
    Given a credit card API
    When I send a POST request to '/legalAction' with an overdue period crossing 180 days
    Then the response status is 200
    And the legal action initiation process should be indicated in the response 

  Scenario: Testing legal action initiation conditions
    Given a credit card API
    When I send a POST request to '/legalAction' before all other collection efforts
    Then the legal action initiation process should not be indicated in the response
