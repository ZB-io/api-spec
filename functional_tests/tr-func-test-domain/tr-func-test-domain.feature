Feature: EvolvePay App - UI acceptance for onboarding, verification, cards, transactions, and remittance

  @ui
  Background:
    Given the EvolvePay test environment is reachable
    And I start a clean browser session

  # Registration and Login

  @ui @registration @authentication @tier-assignment @TC-REG-01 @TC-LOGIN-01
  Scenario Outline: Register and login successfully; new account shows Tier 1 and KYC entry points
    Given I am on the Registration screen
    When I register with email "<email>" and password "<password>"
    And I navigate to the Login screen
    And I sign in with email "<email>" and password "<password>"
    Then I should land on the user dashboard
    And I navigate to Profile
    And I should see the verification status "Tier 1"
    And I should see the KYC submission entry point with options to submit ID and selfie
    And my session should persist when I navigate between Home and Profile

    Examples:
      | email                      | password        |
      | test+reg01@example.com     | SynthetiC!234   |
      | test+login01@example.com   | SynthetiC!234   |

  @ui @registration @tier-access @virtual-card @TC-REG-02
  Scenario Outline: Newly registered Tier 1 user sees virtual card application and remains Tier 1
    Given I am on the Registration screen
    When I register with email "<email>" and password "<password>"
    And I navigate to the Login screen
    And I sign in with email "<email>" and password "<password>"
    And I navigate to Card Management
    Then I should see an action labelled "Apply for Virtual Prepaid Card"
    And I navigate to Profile
    And I should see the verification status "Tier 1"

    Examples:
      | email                      | password        |
      | test+reg02@example.com     | SynthetiC!234   |

  @ui @authentication @tier2 @TC-LOGIN-02
  Scenario Outline: Tier 2 verified user can log in securely and see Tier 2 status
    Given I am on the Login screen
    When I sign in with email "<email>" and password "<password>"
    Then I should land on the user dashboard
    And I navigate to Profile
    And I should see the verification status "Tier 2"
    And I navigate to Card Management and then back to Profile without access errors
    And I log out successfully

    Examples:
      | email                             | password        |
      | test+tier2login@example.com       | SynthetiC!234   |

  # KYC Submission (Positive and Negative)

  @ui @kyc @uploads @state-transition @TC-REG-03 @TC-KYC-01
  Scenario Outline: Tier 1 user submits supported ID and selfie; status moves to Pending
    Given I am on the Registration screen
    And I register with email "<email>" and password "<password>"
    And I sign in with email "<email>" and password "<password>"
    And I navigate to Profile
    And I should see the verification status "Tier 1"
    When I open the KYC submission screen
    And I select ID type "<id_type>"
    And I upload the ID image file "<id_image>"
    And I upload the selfie image file "<selfie_image>"
    And I click Submit for KYC
    Then I should see a confirmation or indicator that verification has started
    And I navigate to Profile
    And I should see the verification status "Pending"

    Examples:
      | email                      | password        | id_type  | id_image                 | selfie_image             |
      | test+reg03@example.com     | SynthetiC!234   | Passport | passport_test_reg03.jpg  | selfie_test_reg03.jpg    |
      | test+kyc01@example.com     | SynthetiC!234   | Passport | passport_kyc01.jpg       | selfie_kyc01.jpg         |

  @ui @kyc @negative @validation @TC-KYC-03
  Scenario: Unsupported ID types are not accepted for KYC submission
    Given I am on the Registration screen
    And I register with email "test+kyc03@example.com" and password "SynthetiC!234"
    And I sign in with email "test+kyc03@example.com" and password "SynthetiC!234"
    And I navigate to Profile
    And I should see the verification status "Tier 1"
    When I open the KYC submission screen
    Then I should see only "Passport" and "Driver's license" available in the ID Type selector
    When I attempt to enter or select an unsupported ID type "National ID"
    Then the UI should prevent selection or ignore the unsupported type
    When I attempt to submit KYC without a valid ID type and no selfie
    Then the submission should be blocked and no KYC is recorded
    And I navigate to Profile
    And I should see the verification status "Tier 1"

  @ui @kyc @negative @mandatory-fields @TC-KYC-04
  Scenario: KYC submission requires a selfie in addition to the ID
    Given I am on the Registration screen
    And I register with email "test+kyc04@example.com" and password "SynthetiC!234"
    And I sign in with email "test+kyc04@example.com" and password "SynthetiC!234"
    And I navigate to Profile
    And I should see the verification status "Tier 1"
    When I open the KYC submission screen
    And I select ID type "Passport"
    And I upload the ID image file "passport_kyc04.jpg"
    And I skip uploading a selfie
    And I click Submit for KYC
    Then the submission should be blocked due to missing selfie
    And I navigate to Profile
    And I should see the verification status "Tier 1"

  # Profile Status Visibility and Transitions

  @ui @status @visibility @TC-STATUS-01 @TC-STATUS-02 @TC-STATUS-03
  Scenario Outline: Profile displays verification status correctly for seeded accounts
    Given I am on the Login screen
    When I sign in with email "<email>" and password "<password>"
    And I navigate to Profile
    Then I should see the verification status "<expected_status>"
    And after refresh and navigating away and back, the status remains "<expected_status>"

    Examples:
      | email                        | password | expected_status |
      | test+status01@example.com    | ******** | Tier 1          |
      | test+pending@example.com     | ****     | Pending         |
      | test+tier2@example.com       | ****     | Tier 2          |

  @ui @status @state-transition @polling @TC-STATUS-04
  Scenario: Profile reflects status transitions Tier 1 -> Pending -> Tier 2 after KYC
    Given I sign in with email "test+tier1_kyc@example.com" and password "****"
    And I navigate to Profile
    Then I should see the verification status "Tier 1"
    When I open the KYC submission screen
    And I select ID type "Passport" and upload a passport image and a selfie
    And I click Submit for KYC
    Then I navigate to Profile and I should see the verification status "Pending"
    When I wait and refresh the Profile at permitted intervals
    Then I should see the verification status "Tier 2"

  # Card Management: Virtual/Physical and Gating

  @ui @virtual-card @issuance @TC-VCARD-01
  Scenario: Tier 1 user can apply for a new virtual prepaid card
    Given I sign in with email "test+tier1_vcard@example.com" and password "****"
    When I navigate to Cards
    And I click "Apply for Virtual Card"
    Then I should see a success confirmation
    And a new Virtual card entry should appear in the Cards list
    And the Virtual card details should be viewable

  @ui @physical-card @tier2 @order @TC-PCARD-01
  Scenario: Tier 2 verified user can order a physical prepaid card
    Given I sign in with email "test+tier2_pcard@example.com" and password "****"
    When I navigate to Cards
    And I select "Order Physical Card"
    And I confirm the order
    Then I should see a success confirmation
    And an indicator of a physical card order or reference should be visible

  @ui @physical-card @tier1 @negative @TC-PCARD-02
  Scenario: Tier 1 user is not allowed to order a physical prepaid card
    Given I sign in with email "test+tier1_pcard@example.com" and password "****"
    When I navigate to Cards
    Then I should not be able to proceed with "Order Physical Card" (absent or disabled)
    And no physical card order should be created

  # Top-up and Card Balance/Transactions

  @ui @top-up @transactions @dual-tier @TC-TOPUP-01 @TC-GATE-03
  Scenario Outline: Top-up from a linked bank updates balance and appears as 'load' for both tiers
    Given I sign in with email "<email>" and password "****"
    And I navigate to Cards and open the virtual card details
    And I note the current balance
    When I navigate to Top-Up
    And I enter amount "<amount>" from the linked bank account
    And I submit the top-up
    Then I should see a top-up success confirmation
    And the card balance should increase by "<amount>"
    When I open Transactions and filter by type "load"
    Then I should see a recent 'load' entry for "<amount>"

    Examples:
      | email                         | amount  |
      | test+tier1_topup@example.com  | 50.00   |
      | test+t2_topup@example.com     | 75.00   |

  @ui @balance @display @TC-BAL-01
  Scenario: Card details displays current balance with a known starting amount
    Given I sign in with email "test+balance@example.com" and password "****"
    When I navigate to Cards and open the prepaid card
    Then I should see a Current Balance field
    And the displayed balance should equal "$200.00"
    And the value should persist across navigation within the session

  @ui @transactions @recent @TC-BAL-02
  Scenario: Card screen displays a populated Recent Transactions list
    Given I sign in with email "test+bal02@example.com" and password "********"
    When I navigate to the Card screen
    Then I should see the current balance
    And I should see a Recent Transactions section
    And the Recent Transactions list should contain one or more items
    And scrolling the list should load items without duplication or gaps

  @ui @transactions @recent @top-up @TC-BAL-03
  Scenario: Completed top-up appears in Recent Transactions
    Given I sign in with email "test+bal03@example.com" and password "********"
    And I navigate to the Card screen
    When I initiate a top-up of "75.00" and confirm
    And I return to the Card screen
    Then the most recent Recent Transactions entry should be a 'load' of "75.00"

  # Transactions History: Pagination and Filters

  @ui @transactions @pagination @boundary @TC-TXN-01 @TC-TXN-03 @TC-TXN-04
  Scenario Outline: Transaction history page count boundaries with seeded totals
    Given I sign in with email "<email>" and password "********"
    And I navigate to the Transactions History view
    When I navigate to page "<page_request>"
    Then I should see exactly "<expected_count>" transactions on the page
    And if a last page is expected, no additional items should load beyond it

    Examples:
      | email                     | page_request | expected_count |
      | test+txn01@example.com    | 1            | 25             |
      | test+txn03@example.com    | 3            | 10             |
      | test+txn04@example.com    | 4            | 0              |

  @ui @transactions @filtering @date-range @TC-TXN-05
  Scenario: Filtering transaction history by a date range limits results to that range
    Given I sign in with email "test+txn05@example.com" and password "********"
    And I navigate to the Transactions History view
    When I open the filter panel
    And I set Start Date to "2025-06-01" and End Date to "2025-06-30"
    And I apply the filter
    Then all displayed transactions should have dates within "2025-06-01" to "2025-06-30" inclusive
    When I clear the filter
    Then the full unfiltered history should return

  @ui @transactions @filtering @type @TC-TXN-06
  Scenario: Filtering by transaction type 'load' returns only load transactions
    Given I sign in with email "test+txn06@example.com" and password "********"
    And I navigate to the Transactions History view
    When I open the filter panel
    And I set Transaction Type to "Load"
    And I apply the filter
    Then every visible transaction should have type "Load"
    When I clear the filter
    Then I should see a mixed set of transaction types

  @ui @transactions @filtering @combined @TC-TXN-09
  Scenario: Combined date range and transaction type filter returns only matching records
    Given I sign in with email "test+2009@example.com" and password "********"
    And I navigate to the Transactions History view
    When I open the filter panel
    And I set Start Date to "2025-10-01" and End Date to "2025-10-31"
    And I set Transaction Type to "Purchase"
    And I apply the filter
    Then all rows on page 1 should be type "Purchase" with dates within "2025-10-01" to "2025-10-31"
    When I navigate to page 2 (if available)
    Then all rows on page 2 should be type "Purchase" with dates within "2025-10-01" to "2025-10-31"
    When I clear all filters
    Then the mixed unfiltered list should return

  @ui @transactions @filtering @empty-state @TC-TXN-10
  Scenario: Filters that match no transactions display an empty result set
    Given I sign in with email "test+2010@example.com" and password "********"
    And I navigate to the Transactions History view
    When I open the filter panel
    And I set Start Date to "2024-09-01" and End Date to "2024-09-30"
    And I set Transaction Type to "Refund"
    And I apply the filter
    Then I should see zero transactions
    And pagination to next pages should be unavailable
    When I clear the filters
    Then transactions should reappear

  @ui @transactions @enumeration @filtering @TC-TXN-11
  Scenario: Transaction type filter options are limited to Load, Purchase, Refund
    Given I sign in with email "test+2011@example.com" and password "********"
    And I navigate to the Transactions History view
    When I open the filter panel
    And I open the Transaction Type selector
    Then I should see exactly these options: "Load", "Purchase", "Refund"
    And no other options like "Transfer", "Fee", or "Cashback" should appear
    When I select each valid option in turn
    Then each valid option should be selectable

  @ui @transactions @filtering @pagination @boundary @TC-TXN-12
  Scenario: Pagination remains at 25 per page when filters are applied
    Given I sign in with email "test+2012@example.com" and password "********"
    And I navigate to the Transactions History view
    When I open the filter panel
    And I set Start Date to "2025-07-01" and End Date to "2025-07-31"
    And I set Transaction Type to "Purchase"
    And I apply the filter
    Then I should see exactly 25 rows on page 1
    When I navigate to page 2
    Then I should see exactly 25 rows on page 2
    When I navigate to the last page
    Then the last page should have 25 or fewer rows

  # Card Security

  @ui @card-block @security @TC-BLOCK-01
  Scenario: User can block their card immediately from the app
    Given I sign in with email "test+block01@example.com" and password "********"
    And I navigate to Card Details
    When I tap "Block Card" and confirm
    Then the card should be shown as blocked immediately
    And active card-use controls should no longer be presented
    When I refresh Card Details
    Then the card should remain in a blocked state

  # Card Details: Limits and Allowance

  @ui @card-details @display @TC-DETAILS-01
  Scenario: Card details display current balance, daily load limit, and remaining allowance
    Given I sign in with email "test+details01@example.com" and password "********"
    When I navigate to Card Details
    Then I should see a populated "Current Balance" field
    And I should see a populated "Daily Load Limit" field
    And I should see a populated "Remaining Allowance for the Day" field
    And none of these should be empty or placeholder values

  @ui @card-details @formatting @TC-DETAILS-02
  Scenario: Card details show usage string like "$X.XX / $Y.XX daily limit used"
    Given I sign in with email "test+details02@example.com" and password "********"
    When I navigate to Card Details
    Then I should see a usage string that contains a currency amount, "/", another currency amount, and the phrase "daily limit used"

  @ui @card-details @allowance-update @top-up @TC-DETAILS-03
  Scenario: Remaining daily allowance updates after a same-day top-up
    Given I sign in with email "test+details03@example.com" and password "********"
    And I navigate to Card Details
    And I record the Remaining Allowance value as R1 and the used amount as U1
    When I navigate to Load Funds and submit a top-up of "100.00" from "Test Bank **** 6789"
    And I return to Card Details
    Then the Remaining Allowance value R2 should be R1 minus "100.00" and/or the used amount U2 should be U1 plus "100.00"
    And the Transactions list should contain a 'load' entry of "100.00"

  # Remittance: Send, Gating, Beneficiaries, Quotes, History

  @ui @remittance @send @tier2 @TC-REMIT-01
  Scenario: Tier 2 user can send money to an international recipient
    Given I sign in with email "test+remit01@example.com" and password "********"
    When I navigate to Remittance > Send Money
    And I select the saved beneficiary "Alex Kim (PH)"
    And I enter the send amount "50.00"
    And I proceed to confirm the transfer
    Then I should see a submission acknowledgment
    When I navigate to Remittance > History
    Then I should see a new remittance entry to "Alex Kim" for "50.00" with a valid status

  @ui @remittance @gating @tier1 @negative @TC-REMIT-02
  Scenario: Tier 1 user is blocked from sending international remittance
    Given I sign in with email "test+remit02@example.com" and password "********"
    When I navigate to Remittance > Send Money
    Then I should be blocked from proceeding to a payable state
    And submission controls should remain unavailable
    When I navigate to Remittance > History
    Then no new remittance entries from this session should appear

  @ui @beneficiaries @add @save @cleanup @TC-BEN-01 @TC-BEN-02
  Scenario Outline: Add a beneficiary with Full Name, Country, and payment details, then delete
    Given I sign in with email "<email>" and password "Passw0rd!"
    And I navigate to Beneficiaries
    When I click "Add Beneficiary"
    And I enter Full Name "<full_name>"
    And I select Country "<country>"
    And I enter "<payment_label>" details "<payment_value>" with identifier "<id_tag>"
    And I save the beneficiary
    Then I should see the beneficiary "<full_name>" with Country "<country>" and type "<payment_label>" in the list
    When I open the beneficiary details for "<full_name>"
    Then the stored values should match my entries (with masking as applicable)
    When I delete the beneficiary "<full_name>"
    Then the beneficiary "<full_name>" should no longer appear in the list

    Examples:
      | email                      | full_name        | country    | payment_label | payment_value   | id_tag        |
      | test+ben01@example.com     | Ben Bank Test    | Kenya      | Bank Account  | ACCT-****1234   | BEN-BANK-01   |
      | test+ben02@example.com     | Ben Mobile Test  | Ghana      | Mobile Money  | MM-****-7890    | BEN-MM-01     |

  @ui @beneficiaries @persistence @reuse @TC-BEN-03
  Scenario: Saving a beneficiary persists across sessions and is selectable in send flow
    Given I sign in with email "test+ben03@example.com" and password "Passw0rd!"
    And I navigate to Beneficiaries
    When I add a beneficiary "Future Use Ben" with Country "Philippines" and Bank Account "ACCT-****7788" identified as "BEN-FUTURE-01"
    Then I should see "Future Use Ben" in the list
    When I log out and log back in with the same credentials
    And I navigate to Beneficiaries
    Then I should still see "Future Use Ben" in the list
    When I start a Send Money flow
    Then "Future Use Ben" should be available for selection as recipient
    When I cancel Send Money
    And I delete the beneficiary "Future Use Ben"
    Then it should be removed from the list

  @ui @beneficiaries @delete @TC-BEN-04
  Scenario: Deleting a saved beneficiary removes it from the list
    Given I sign in with email "test+ben04@example.com" and password "Passw0rd!"
    And I navigate to Beneficiaries
    When I add a beneficiary "Deletable Ben" with Country "India" and Mobile Money "MM-****-1122"
    Then I should see "Deletable Ben" in the list
    When I delete the beneficiary "Deletable Ben"
    Then "Deletable Ben" should no longer appear, including after navigating away and back

  @ui @remittance @quote @pre-confirmation @TC-QUOTE-01 @TC-QUOTE-02
  Scenario Outline: Pre-confirmation shows required quote information before confirming
    Given I sign in with email "<email>" and password "Passw0rd!"
    And I navigate to Beneficiaries
    When I add a beneficiary "<ben_name>" with Country "<country>" and "<pay_type>" "<pay_value>"
    And I start a Send Money flow
    And I select recipient "<ben_name>"
    And I enter transfer amount "<amount>"
    And I proceed to the review/pre-confirmation screen
    Then I should see a visible non-empty "<info_field>" on the review screen
    When I cancel the flow
    Then no transfer should be executed
    And I delete the beneficiary "<ben_name>"

    Examples:
      | email                        | ben_name   | country  | pay_type     | pay_value       | amount | info_field     |
      | test+quote01@example.com     | Quote Ben  | Nigeria  | Bank Account | ACCT-****5566   | 100    | Exchange Rate  |
      | test+quote02@example.com     | Fee Ben    | Mexico   | Mobile Money | MM-****-3344    | 150    | Fees           |

  @ui @remittance @history @pagination @TC-RHIST-01 @TC-RHIST-02 @TC-RHIST-03 @TC-RHIST-04
  Scenario Outline: Remittance history pagination supports next/previous and last-page boundary
    Given I sign in with email "<email>" and password "Passw0rd!"
    And I navigate to Remittance History
    Then page 1 should display "<page1_assertion>"
    When I navigate to page 2 (if available)
    Then page 2 should display "<page2_assertion>"
    When I navigate to the last page
    Then the last page should contain 25 or fewer items and prevent navigation beyond it
    When I navigate back to page 1
    Then page 1 should display "<page1_assertion>"

    Examples:
      | email                       | page1_assertion                 | page2_assertion          |
      | test+hist01@example.com     | exactly 25 items                | up to 25 items           |
      | test+hist02@example.com     | exactly 25 items                | up to 25 items           |
      | test+hist03@example.com     | at least 1 and at most 25 items | up to 25 items           |

  @ui @remittance @history @status @TC-RHIST-05
  Scenario: Remittance history displays status Pending for pending transfers
    Given I sign in with email "test+rh_pend@example.com" and password "****"
    And I navigate to Remittance History
    Then I should find the seeded in-progress transfer on page 1
    And its Status column should display exactly "Pending"

  @ui @remittance @history @empty-state @TC-RHIST-08
  Scenario: Remittance history displays an empty state when no transfers exist
    Given I sign in with email "test+rh_empty@example.com" and password "****"
    When I navigate to Remittance History
    Then I should see zero rows on page 1
    And pagination should remain at page 1 with no results

  # Tier Gating Consolidation

  @ui @gating @tier1 @virtual-card @physical-card @remittance @TC-GATE-01
  Scenario: Tier 1 can apply virtual card, cannot order physical card, and cannot send remittance
    Given I sign in with email "test+t1_gating@example.com" and password "****"
    And I navigate to Cards
    When I select "Apply for Virtual Card"
    Then a Virtual card should be issued and visible in the list
    When I look for "Order Physical Card"
    Then I should not be able to proceed with ordering a physical card
    When I navigate to Remittance and attempt to start Send Money
    Then the send action should be unavailable for Tier 1

  @ui @transactions @pagination @filtering @dual-tier @TC-GATE-04
  Scenario Outline: Transactions pagination (25/page) and filters are available to both tiers
    Given I sign in with email "<email>" and password "****"
    And I navigate to the Transactions History view
    Then page 1 should display exactly 25 items
    When I navigate to page 2
    Then page 2 should display exactly 25 items
    When I navigate to page 3
    Then page 3 should display 25 or fewer items
    When I open the filter panel and set a date range for the last 7 days
    And I set Transaction Type to "Purchase"
    And I apply the filter
    Then only "Purchase" transactions within the last 7 days should be visible
    When I change Transaction Type to "Refund"
    Then only "Refund" transactions within the last 7 days should be visible

    Examples:
      | email                         |
      | test+t1_hist@example.com      |
      | test+t2_hist@example.com      |

  # End-to-End Journeys

  @ui @e2e @tier2 @kyc @virtual-card @top-up @transactions @limits @remittance @TC-E2E-01
  Scenario: E2E Tier 2 journey from registration to remittance with required UI confirmations
    Given I am on the Registration screen
    When I register with email "test+e2e01@example.com" and password "****"
    And I sign in with email "test+e2e01@example.com" and password "****"
    And I navigate to Profile
    Then I should see the verification status "Tier 1"
    When I open KYC and submit "passport" and a selfie
    Then Profile should show "Pending"
    When I wait for auto-approval and refresh Profile
    Then I should see the verification status "Tier 2"
    When I navigate to Cards and apply for a Virtual Card
    And I perform a Top-up of "50.00" from the linked bank
    And I open Transactions
    Then page 1 should display exactly 25 items
    When I set the date range to last 7 days and type to "load"
    Then I should see the recent 'load' of "50.00" in results
    When I open Card Details
    Then I should see Current Balance and a daily limit usage string like "$X / $Y daily limit used"
    When I add beneficiary "Sam Demo" (PH, ****5678) and start Send Money for "25.00"
    Then the review screen should display an exchange rate and fees
    When I confirm the transfer and open Remittance History
    Then I should see the new transfer with status in {Pending, Completed, Failed}

  @ui @e2e @tier2 @physical-card @block-card @transactions @TC-E2E-02
  Scenario: E2E Tier 2 - order physical card, block card immediately, histories remain intact
    Given I sign in with email "test+t2_block@example.com" and password "****"
    And I navigate to Cards
    When I apply for a Virtual Card if none exists
    And I order a Physical Card
    Then I should see an order success indication
    When I top-up "25.00" from the linked bank
    And I open Transactions
    Then I should see a recent 'load' of "25.00"
    When I return to Cards and block the card
    Then the card should be blocked immediately
    When I re-open Transactions
    Then the previous 'load' entry should still be visible
    And Remittance History should still be viewable

  @ui @e2e @tier1 @virtual-card @top-up @pagination @filters @gating @TC-E2E-03
  Scenario: E2E Tier 1 - register, virtual card, top-up, 25/page history, gated on physical and remittance
    Given I am on the Registration screen
    When I register with email "test+e2e03@example.com" and password "****Test123!"
    And I sign in with email "test+e2e03@example.com" and password "****Test123!"
    And I navigate to Cards and apply for a Virtual Card
    And I perform a Top-up of "100.00" from the linked bank
    Then Recent Transactions should show a 'load' of "100.00"
    When I open Transactions History
    Then page 1 should display exactly 25 items
    When I navigate to the next (last) page
    Then the last page should display exactly 1 item (with 26 total)
    When I attempt to navigate beyond the last page
    Then no additional transactions should be shown
    When I filter by type "load" and a date range including all seeded records
    Then only 'load' transactions should appear and each page should have at most 25 items
    When I look for "Order Physical Card"
    Then I should be blocked from ordering a physical card
    When I navigate to Remittance > Send Money
    Then I should be blocked from sending remittance as Tier 1

  @ui @e2e @tier1 @balance @recent-transactions @card-details @gating @TC-E2E-04
  Scenario: E2E Tier 1 - view balance and recent transactions, card details usage string, remittance send unavailable
    Given I am on the Registration screen
    When I register with email "test+e2e04@example.com" and password "****Test123!"
    And I sign in with email "test+e2e04@example.com" and password "****Test123!"
    And I navigate to Cards and apply for a Virtual Card
    And I perform a Top-up of "50.00" from the linked bank
    Then the Card screen should show the current balance and a recent 'load' of "50.00"
    When I open Card Details
    Then I should see Current Balance and a daily limit usage string like "$X / $Y daily limit used"
    When I navigate to Remittance > Send Money
    Then the send action should be unavailable for Tier 1
    And Profile should continue to show "Tier 1"
