Feature: EvolvePay onboarding, KYC, cards, top-up, transactions, and remittance - UI functional and security tests

  # UI Tests

  Background:
    Given the application is reachable

  # Registration & Login
  # Covers: TC-REG-01, TC-STATUS-01
  @ui
  Scenario Outline: New user registration results in Tier 1 access and virtual card entry is accessible
    Given I am on the registration screen
    When I enter email "<email>" and a masked password and submit registration
    And I navigate to the login screen
    And I log in with email "<email>" and the same masked password
    And I open the Profile screen
    Then I should see the verification status as "Tier 1"
    And I navigate to the Cards area
    And I should see an entry point to apply for a virtual card

    Examples:
      | email                       |
      | test+reg01@example.com      |
      | test+status01@example.com   |

  # Covers: TC-REG-02
  @ui
  Scenario Outline: Registration enforces both email and password as required inputs
    Given I am on the registration screen
    When I enter email "<email_input>" and password "<password_input>" and submit registration
    Then I should see "<expected_outcome>"

    Examples:
      | email_input                | password_input | expected_outcome                                                     |
      | test+reg02a@example.com    |                | Registration is blocked and the form does not proceed               |
      |                            | ********       | Registration is blocked and the form does not proceed               |
      | test+reg02b@example.com    | ********       | Registration proceeds to success state without error                |

  # Covers: TC-LOGIN-01
  @ui
  Scenario: Tier 1 user can log in and see profile Tier 1 status
    Given I am on the login screen
    When I enter email "test+login01@example.com" and a masked password and click Login
    Then I should land on the dashboard
    And I navigate to the Profile screen
    And I should see the verification status as "Tier 1"
    And I navigate to Home and back to confirm the session persists without re-login

  # Tier-based Card Access (Virtual vs Physical)
  # Covers: TC-REG-03, TC-PCARD-02, TC-PCARD-03, TC-ACCESS-01
  @ui
  Scenario: Tier 1 user is blocked from physical card order and can access virtual card application
    Given I am logged in as a Tier 1 user with email "test+pcard02_t1@example.com"
    When I navigate to the Cards management area
    Then I should not see any "Order Physical Card" option
    And I attempt to access the physical card order screen via a direct link
    Then access should be denied or redirected and no order form is presented
    And I should see an entry to apply for a virtual card
    When I click "Apply for Virtual Card"
    Then I should see a confirmation and a new virtual card entry in my cards list

  # Covers: TC-PCARD-01, TC-ACCESS-02
  @ui
  Scenario: Tier 2 user can order a physical prepaid card
    Given I am logged in as a Tier 2 user with email "test+pcard01_t2@example.com"
    When I navigate to the Cards → Physical Card ordering section
    Then I should see "Order Physical Card" enabled
    When I click "Order Physical Card"
    Then I should see an order placement confirmation
    And I should see a physical card order or entry in the Cards overview

  # KYC Submission & Visibility
  # Covers: TC-KYC-01, TC-KYC-03, TC-KYC-05, TC-KYC-07
  @ui
  Scenario Outline: KYC submission validation enforces eligible ID types and requires selfie
    Given I am logged in as a Tier 1 user with email "<email>"
    And I navigate to the KYC submission screen
    When I select ID type "<id_type>"
    And I upload ID document "<id_file>"
    And I upload selfie "<selfie_file>"
    And I click Submit on KYC
    Then I should see "<expected_result>"
    And I navigate to the Profile screen
    Then the verification status should be "<expected_status>"

    Examples:
      | email                      | id_type           | id_file                    | selfie_file            | expected_result                 | expected_status |
      | test+kyc01@example.com     | Passport          | passport_test_user.pdf     | selfie_test_user.jpg   | KYC submission accepted         | Pending         |
      | test+kyc07_t1@example.com  | Driver's license  | drivers_license_test.jpg   | selfie_test.jpg        | KYC submission accepted         | Pending         |
      | test+kyc03@example.com     | Passport          | passport_test_user.pdf     |                        | Submission blocked (selfie req) | Tier 1          |
      | test+kyc05@example.com     | National ID       | national_id_test_user.pdf  | selfie_test_user.jpg   | Submission blocked (ID invalid) | Tier 1          |

  # Covers: TC-KYC-06, TC-KYC-08
  @ui
  Scenario Outline: KYC submission entry point visibility by user tier
    Given I am on the login screen
    When I log in as "<tier>" user with email "<email>"
    And I navigate to Profile → Verification/Compliance
    Then the KYC submission action should be "<visibility>"
    And if visible, when I open it I should see options for Passport and Driver's License and a Selfie upload field

    Examples:
      | tier  | email                         | visibility         |
      | Tier1 | test+kyc06_t1@example.com     | visible            |
      | Tier2 | test+kyc06_t2@example.com     | not visible        |

  # Verification Status Display
  # Covers: TC-STATUS-02
  @ui
  Scenario: Profile displays Pending status after successful KYC submission
    Given I am logged in as a Tier 1 user with email "test+status02@example.com"
    And I navigate to the Profile screen
    Then I should see the verification status as "Tier 1"
    When I navigate to KYC submission
    And I select Passport and upload "passport_status02.jpg" and "selfie_status02.jpg"
    And I submit KYC and return to Profile
    Then I should see the verification status as "Pending"
    When I log out and log back in with the same account
    Then the Profile should still show "Pending"

  # Virtual Card Application
  # Covers: TC-VCARD-01
  @ui
  Scenario: Tier 1 user can apply for a new virtual prepaid card
    Given I am logged in as a Tier 1 user with email "test+vcard01_t1@example.com"
    When I navigate to Cards → Virtual Card
    And I click "Apply for Virtual Card"
    Then I should see confirmation and a new virtual card entry in my card list
    When I open the virtual card details
    Then the details load without error
    And after refresh, the new virtual card remains visible

  # Top-up and Balance/Transactions
  # Covers: TC-TOPUP-01
  @ui
  Scenario: Tier 1 user can load funds from a linked bank account
    Given I am logged in as a Tier 1 user with email "test+t1@example.com"
    When I navigate to Top-up (Load Funds)
    And I select a linked bank account "Test Checking"
    And I enter amount "75.00" USD and confirm
    Then I should see a success confirmation
    And the Balance should reflect an increase by $75.00 compared to pre-top-up

  # Covers: TC-TOPUP-03, TC-BAL-03
  @ui
  Scenario: Successful top-up increases balance by $50 and creates a 'load' transaction
    Given I am logged in as a user with a starting balance of $200.00
    When I perform a top-up of $50.00 from a linked bank account
    Then my balance should read $250.00
    And the most recent transaction should be a 'load' of $50.00 dated now

  # Covers: TC-BAL-01
  @ui
  Scenario: Card balance is displayed to the user
    Given I am logged in as a user with email "test+bal@example.com"
    When I navigate to Balance and Recent Transactions
    Then I should see a Current Balance element with a non-empty numeric value
    And after refresh and navigation away/back, the Current Balance remains visible

  # Covers: TC-BAL-02
  @ui
  Scenario: Recent transactions list is displayed with recognizable types
    Given I am logged in as a user with email "test+txlist@example.com"
    When I navigate to Balance and Recent Transactions
    Then I should see a non-empty list of transactions
    And I should see at least one 'load', one 'purchase', and one 'refund' entry if present
    And transaction rows show typical details like amount and date

  # Transaction History - Pagination & Filters
  # Covers: TC-TXHIST-01, TC-TXHIST-02, TC-TXHIST-03, TC-TXHIST-06
  @ui
  Scenario Outline: Transaction History pagination boundary behavior
    Given I am logged in as a user with email "<email>"
    And I navigate to Transaction History with no filters applied
    Then I should see exactly <page1_count> items on page 1
    And if total is greater than <page1_count>, I should see a 'Next' control
    When I navigate to page 2
    Then I should see exactly <page2_count> items on page 2
    And attempting to navigate beyond the last page should show no additional items or a disabled Next

    Examples:
      | email                       | page1_count | page2_count |
      | test+hist26@example.com     | 25          | 1           |
      | test+hist50@example.com     | 25          | 25          |
      | test+hist24@example.com     | 24          | 0           |
      | test+txhist06@example.com   | 24          | 0           |

  # Covers: TC-TXHIST-07, TC-TXHIST-10
  @ui
  Scenario Outline: Transaction type filter behavior for valid and invalid values
    Given I am logged in as a user with email "<email>"
    And I navigate to Transaction History with no filters applied
    And I record the baseline total count as <baseline_count>
    When I apply the transaction type filter value "<filter_value>"
    Then I should see "<expected_condition>"
    And the displayed row count should be <expected_count>
    And no rows of other types should appear when a valid type is applied

    Examples:
      | email                      | baseline_count | filter_value | expected_condition                                     | expected_count |
      | test+txhist07@example.com  | 25             | load         | only 'load' transactions are listed                    | 12             |
      | test+txhist10@example.com  | 20             | transfer     | invalid filter yields no change to baseline result set | 20             |

  # Covers: TC-TXHIST-11
  @ui
  Scenario: Date range filtering narrows results to the selected period
    Given I am logged in as a user with email "test+txhist11@example.com"
    And I navigate to Transaction History
    When I set From date "2025-10-01" and To date "2025-10-07" and apply
    Then I should see exactly 10 transactions
    And each transaction date should be within 2025-10-01 to 2025-10-07 inclusive
    When I clear the date filter
    Then I should see the full unfiltered set (e.g., 22 items)

  # Covers: TC-TXHIST-12
  @ui
  Scenario: Combined filter of date range and type 'load' returns only in-range loads
    Given I am logged in as a user with email "test+txhist12@example.com"
    And I navigate to Transaction History
    When I apply date range From "2025-10-01" To "2025-10-07"
    And I apply type filter "load"
    Then I should see exactly 4 transactions
    And every transaction listed is type "load" with a date within the range

  # Covers: TC-TXHIST-13
  @ui
  Scenario: Filtered results paginate at 25-per-page when more than 25 matches exist
    Given I am logged in as a user with email "test+txhist13@example.com"
    And I navigate to Transaction History
    When I apply type filter "load"
    Then I should see 25 items on page 1
    When I navigate to page 2
    Then I should see 8 items on page 2
    And all items visible under the filter are type "load"

  # Covers: TC-TXHIST-14
  @ui
  Scenario: Transaction type filter UI exposes exactly load, purchase, refund
    Given I am logged in as a user with email "test+txhist14@example.com"
    And I navigate to Transaction History
    When I open the Transaction Type filter control
    Then I should see exactly three options: load, purchase, refund
    And no other option should be present
    And each option can be selected

  # Covers: TC-TXHIST-15
  @ui
  Scenario: Clearing transaction type filter restores full paginated list at 25 per page
    Given I am logged in as a user with email "hist.user@example.com"
    And I navigate to Transaction History
    Then I should see 25 items on page 1
    When I apply type filter "load"
    Then only 'load' entries are displayed
    When I clear the filters
    Then page 1 should again show exactly 25 items
    And I should see multiple types among the rows

  # Covers: TC-TXHIST-16
  @ui
  Scenario: Date range-only filtering still enforces 25-per-page pagination
    Given I am logged in as a user with email "range.user@example.com"
    And I navigate to Transaction History
    When I set a date range from 30 days ago to today and apply
    Then I should see exactly 25 items on page 1
    When I navigate to page 2
    Then I should see exactly 25 items on page 2 if total > 25
    When I navigate to the last page
    Then I should see at most 25 items and no further pages beyond the last
    When I attempt to navigate beyond the last page
    Then I should see no additional items or a disabled Next control

  # Card Blocking & Daily Limit Display
  # Covers: TC-BLOCK-01
  @ui
  Scenario: Blocking the card reflects immediately and persists across navigation and re-login
    Given I am logged in as a Tier 1 user with email "tier1_user+block01@example.com"
    And I navigate to Card Details/Management
    When I click "Block Card"
    Then the card state should immediately show "Blocked"
    When I navigate away and return to Card Details/Management
    Then the card should still display as "Blocked"
    When I log out and log back in and open Card Details/Management
    Then the card should remain "Blocked"

  # Covers: TC-BLOCK-03
  @ui
  Scenario: Blocking the card prevents further top-up in the same session
    Given I am logged in as a user with email "test+block03@example.com"
    And my card status is "Active" on Card Details
    When I perform a top-up of $10.00 and confirm success
    Then my balance increases and a 'load' entry appears in Recent Transactions
    When I block the card from Card Settings
    Then the card status immediately shows "Blocked"
    When I attempt another top-up of $5.00 in the same session
    Then the top-up should be prevented and no new 'load' appears and the balance is unchanged

  # Covers: TC-CARDDET-01
  @ui
  Scenario: Card Details displays current balance, daily load limit, and remaining allowance together
    Given I am logged in as a user with email "tier1_user+carddet01@example.com"
    When I open the Card Details screen
    Then I should see a current balance value
    And I should see the daily load limit value
    And I should see the remaining daily allowance value
    And the used/limit context is presented together in one view

  # Covers: TC-CARDDET-02
  @ui
  Scenario: Daily load limit display shows $0 used with full remaining allowance
    Given I am logged in as a user with email "tier1_user+carddet02@example.com" and no loads today
    When I open the Card Details screen
    Then I should see used "$0.00" in the used/limit display (e.g., "$0.00 / $2000.00 daily limit used")
    And the remaining allowance equals "$2000.00"

  # Covers: TC-CARDDET-03
  @ui
  Scenario: After a $500 same-day load, used/limit shows "$500.00 / $2000.00 daily limit used"
    Given I am logged in as a user with email "tier1_user+carddet03@example.com" and no loads today
    When I perform a top-up of $500.00
    And I open the Card Details screen
    Then I should see used "$500.00" and limit "$2000.00" in the used/limit display
    And the format resembles "$500.00 / $2000.00 daily limit used"

  # Covers: TC-CARDDET-04
  @ui
  Scenario: After a $2000 same-day load, used equals limit and remaining is $0.00
    Given I am logged in as a user with email "tier1_user+carddet04@example.com" and no loads today
    When I perform a top-up of $2000.00
    And I open the Card Details screen
    Then I should see "$2000.00 / $2000.00 daily limit used"
    And the remaining allowance shows "$0.00"

  # Covers: TC-CARDDET-05
  @ui
  Scenario: Remaining allowance equals limit minus used after a $750 same-day load
    Given I am logged in as a user with email "tier1_user+carddet05@example.com" and no loads today
    When I perform a top-up of $750.00
    And I open the Card Details screen
    Then I should see "$750.00 / $2000.00 daily limit used"
    And I should see remaining allowance "$1250.00"

  # Covers: TC-CARDDET-06
  @ui
  Scenario: Used amount increases and remaining decreases accordingly after an additional top-up
    Given I am logged in as a user with email "limits.user@example.com" and Card Details shows "$500.00 / $2000.00 daily limit used"
    When I perform a top-up of $200.00
    And I return to the Card Details screen
    Then I should see "$700.00 / $2000.00 daily limit used"
    And the remaining allowance reflects "$1300.00"

  # Send Money (Remittance) Access & Flow
  # Covers: TC-REMIT-01, TC-REMIT-03
  @ui
  Scenario Outline: Tier 2 user can initiate send money and reach review step
    Given I am logged in as a Tier 2 user with email "<email>"
    When I navigate to the Send Money screen
    And I select a saved beneficiary "<beneficiary>"
    And I enter a transfer amount of "<amount>"
    And I proceed to the review step
    Then I should see the review screen with beneficiary and amount displayed
    And I cancel/back out without confirming

    Examples:
      | email                          | beneficiary         | amount  |
      | tier2_user+remit01@example.com | Test Beneficiary    | 100.00  |
      | tier2_user+remit03@example.com | Test Beneficiary    | 150.00  |

  # Covers: TC-REMIT-02, TC-REMIT-04
  @ui
  Scenario: Tier 1 user cannot access Send Money; Tier 2 can
    Given I am logged in as a Tier 1 user with email "tier1_user+remit02@example.com"
    When I view the main navigation/dashboard
    Then I should not see a "Send Money" option
    When I attempt to access a Send Money route directly
    Then access should be blocked or redirected and no send form opens
    When I log out
    And I log in as a Tier 2 user with email "test.tier2.user@example.com"
    Then I should see a "Send Money" option in the navigation
    When I click "Send Money"
    Then the send form should open for Tier 2

  # Rate & Fees Preview
  # Covers: TC-PREVIEW-01, TC-PREVIEW-02, TC-PREVIEW-03
  @ui
  Scenario: Exchange rate and fees are shown before confirm and persist to confirmation step
    Given I am logged in as a Tier 2 user with email "test.user+preview01@example.com"
    When I navigate to Send Money
    And I select beneficiary "Amina Diallo"
    And I enter transfer amount "100"
    And I proceed to the review screen
    Then I should see an Exchange Rate value and a Fees value
    When I note the Exchange Rate and Fees values
    And I proceed to the next step where confirmation is presented
    Then the Exchange Rate matches the noted value
    And the Fees match the noted value
    And the Confirm action is presented only on/after the review step

  # Remittance History
  # Covers: TC-REMHIST-01, TC-REMHIST-05, TC-REMHIST-06, TC-REMHIST-09
  @ui
  Scenario: Remittance history is paginated and Next/Previous controls work across pages
    Given I am logged in as a Tier 2 user with email "test.user+remhist01@example.com"
    When I navigate to Remittance History
    Then I should see pagination controls
    And I should see a Status column or label for each listed transfer on page 1
    When I click "Next"
    Then the list updates to a different set of transfers and statuses are visible
    When I click "Previous"
    Then I return to page 1 and see the original set of entries
    When I click "Next" twice (if available)
    Then each page transition shows a different set of records

  # Covers: TC-REMHIST-02
  @ui
  Scenario: Remittance history displays Pending status for applicable transfers
    Given I am logged in as a Tier 2 user with email "test.user+remhist02@example.com"
    When I navigate to Remittance History
    Then I should find at least one transfer row with status "Pending"
    And if I open its details (if available), the status remains "Pending"

  # Covers: TC-REMHIST-07
  @ui
  Scenario: Only allowed statuses (Pending, Completed, Failed) appear in remittance history
    Given I am logged in as a Tier 2 user with email "test+remhist07@example.com"
    When I navigate to Remittance History
    Then every visible status label should be one of "Pending", "Completed", or "Failed"
    When I click "Next" while enabled and review additional pages
    Then all statuses on subsequent pages also belong to the allowed set

  # Covers: TC-REMHIST-08
  @ui
  Scenario: Exact status labels are rendered as 'Pending', 'Completed', 'Failed'
    Given I am logged in as a Tier 2 user with email "test+remhist08@example.com"
    When I navigate to Remittance History
    Then I should locate an entry labeled exactly "Pending"
    And I should locate an entry labeled exactly "Completed"
    And I should locate an entry labeled exactly "Failed"

  # Covers: TC-REMHIST-10
  @ui
  Scenario: Remittance history shows 25 items on page 1 and remaining on page 2 when total is 26
    Given I am logged in as a Tier 2 user with email "test+remhist10@example.com"
    When I navigate to Remittance History
    Then I should see exactly 25 transfers on page 1
    When I navigate to page 2
    Then I should see exactly 1 transfer on page 2
    And there should be no page 3 available
    And all statuses are within {Pending, Completed, Failed}

  # Beneficiary Management
  # Covers: TC-BENE-01, TC-BENE-04
  @ui
  Scenario Outline: Adding a beneficiary validates required Full Name and saves valid entries
    Given I am logged in as a Tier 2 user with email "<email>"
    And I navigate to the Beneficiaries screen
    When I click "Add Beneficiary"
    And I enter Full Name "<full_name>"
    And I select Country "<country>"
    And I choose "<method>" and enter details "<details>"
    And I click "Save"
    Then I should see "<expected_result>"
    And when applicable, the new beneficiary "<full_name>" appears in the list

    Examples:
      | email                         | full_name       | country     | method        | details          | expected_result                                 |
      | test.user+bene01@example.com  | Amina Diallo    | Ghana       | Bank Account  | GH-BA-****1234   | Beneficiary saved successfully                  |
      | test.user+bene04@example.com  |                 | Philippines | Bank Account  | PH-BA-****2222   | Validation error for missing Full Name displayed |

  # Covers: TC-BENE-03, TC-BENE-06
  @ui
  Scenario: Deleting a previously saved beneficiary removes it from the list
    Given I am logged in as a Tier 2 user with email "test.user+bene03@example.com"
    And I navigate to the Beneficiaries screen
    And I see an existing beneficiary "Test Beneficiary"
    When I delete "Test Beneficiary" and confirm
    Then I should see a success confirmation
    And after refresh, "Test Beneficiary" no longer appears in the list

  # Covers: TC-BENE-05
  @ui
  Scenario: A saved beneficiary appears in the list and is selectable in the send flow
    Given I am logged in as a Tier 2 user with email "test.user+bene05@example.com"
    And I navigate to the Beneficiaries screen
    When I add a beneficiary "Nguyen Thi Lan" with Country "Vietnam" via "Mobile Money" details "VN-MM-****3344"
    Then I should see "Nguyen Thi Lan" in the Beneficiaries list
    When I navigate to the Send Money start screen
    Then I should be able to select "Nguyen Thi Lan" as a beneficiary
    When I return to Beneficiaries and delete "Nguyen Thi Lan"
    Then it should no longer appear after refresh

  # End-to-End Journeys
  # Covers: TC-E2E-01
  @ui
  Scenario: End-to-end onboarding from registration through KYC submission to Pending status
    Given I am on the registration screen
    When I register with email "test+e2e01@example.com" and a masked password
    And I log in with the same credentials
    And I open the KYC submission screen
    And I upload an allowed ID "id_passport_mock.png" and a selfie "selfie_mock.png"
    And I submit KYC
    And I open the Profile screen
    Then I should see my verification status as "Pending"

  # Covers: TC-E2E-02
  @ui
  Scenario: End-to-end: Apply virtual card, top-up, verify balance update, filter and paginate transactions
    Given I am logged in as a user with email "test+e2e02@example.com"
    When I navigate to Cards and apply for a Virtual Card
    Then I should see a virtual card in my wallet
    When I navigate to Top-up and load $50 from a linked bank account
    Then my balance should increase accordingly
    When I open Transaction History
    And I apply a date range covering seeded transactions
    And I apply transaction type "load"
    Then I should see exactly 25 items on page 1
    When I navigate to page 2
    Then I should see the remaining 'load' items

  # Covers: TC-E2E-03
  @ui
  Scenario: End-to-end: Add beneficiary, send money with rate/fees preview, history shows allowed status
    Given I am logged in as a Tier 2 user with email "test+e2e03@example.com"
    When I add a beneficiary "Alex Test" with Country "NG" via "Mobile Money" details "MM-00012345"
    And I navigate to Send Money and select "Alex Test" and enter an amount
    And I proceed to the review step
    Then I should see Exchange Rate and Fees before confirming
    When I confirm the transfer
    And I navigate to Remittance History
    Then I should see the new transfer with a status in {Pending, Completed, Failed}
    When I delete the beneficiary "Alex Test"
    Then it should no longer appear in the list

  # Additional RBAC and Direct Navigation Hardening
  # Covers: TC-PCARD-04
  @ui
  Scenario: Tier 1 direct navigation attempt to physical card order is denied
    Given I am logged in as a Tier 1 user with email "test.tier1.user@example.com"
    And I do not see "Order Physical Card" in the Cards area
    When I navigate directly to the Physical Card Order route
    Then I should be denied access or redirected
    And no physical card order is created in my account

  # Top-up -> Transaction History Discovery
  # Covers: TC-TOPUP-04
  @ui
  Scenario: A top-up creates a 'load' entry discoverable by type filter
    Given I am logged in as a user with email "topup.user@example.com"
    When I perform a top-up of $100.00 and see success
    And I open Transaction History
    And I apply type filter "load"
    Then the most recent entry should be a 'load' for $100.00 corresponding to the top-up
