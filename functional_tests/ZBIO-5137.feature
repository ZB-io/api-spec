Feature: Credit Card Management System

Scenario: Validate Credit Card Due Date and Balance
Given a valid credit card number
When the user requests the credit card due date and balance
Then the system should display the correct due date and balance

Scenario: Retrieve Unpaid and Overdue Balance
Given a valid credit card number
When the user requests the unpaid and overdue balance
Then the system should display the correct unpaid and overdue balance
And handle edge cases like card reported lost/stolen, zero balance, and pending transactions

Scenario: Initiate a Call to User for Unpaid and Overdue Balance
Given a user's phone number and credit card details
When the system detects an unpaid and overdue balance
Then the system should initiate a call to the user
And handle edge cases like unavailable/incorrect contact number and non-working hours

Scenario: Collect Payment for Balance
Given the payment amount
When the user makes a payment
Then the system should credit the payment and update the balance correctly
And handle edge cases like insufficient funds, partial payments, and multiple payments on the same day

Scenario: Update The Credit Card Balance Post Payment
Given the payment amount and credit card details
When the payment is processed
Then the system should update the credit card balance correctly
And handle edge cases like multiple payments on the same day and payments in different currencies

Scenario: Performance Test - Fetch Credit Card Due Date and Balance
Given a valid credit card number
When the user requests the due date and balance
Then the system should respond within an acceptable time limit

Scenario: Security Test - Protect Sensitive Customer Information
Given the user's payment details
When the payment is processed
Then the system should protect the sensitive customer information from unauthorized access

Scenario: Usability Test - Ease of Navigation and Accurate Inputs
Given the user interacts with the application
When the user retrieves the overdue balance and makes a payment
Then the system should provide an easy-to-use interface and accurate error messages for invalid inputs

Scenario: Compatibility Test - Cross-browser and Cross-platform Functionality
Given the user accesses the application on different devices and browsers
When the user makes a payment
Then the system should function correctly across various platforms and browsers

Scenario: Recovery Test - System Resilience During Payment Procedures
Given the system experiences a crash during a payment
When the system recovers
Then the payment process should resume without any data loss

Scenario: Localization Test - Accurate Display of Card Details and Balance
Given the user's locale
When the user views the credit card details and balance
Then the system should display the information accurately based on the user's locale
