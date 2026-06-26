Feature: EvolvePay onboarding, verification, cards, funding, transactions, remittance, and visibility

  Background:
    Given the application base URL is set from environment variable 'BASE_URL'
    And the API base URL is set from environment variable 'API_BASE_URL'
    And I have a clean browser session and cache

  # UI Tests — Onboarding & Authentication

  @ui
  Scenario Outline: Register via UI and verify Tier 1 baseline access
    Given I am on the EvolvePay landing page
    When I navigate to Register
    And I enter email "<email>" and password "<password>" on the registration form
    And I submit the registration form
    And I navigate to Login
    And I enter email "<email>" and password "<password>" on the login form
    And I click "Sign In"
    Then I should land in an authenticated area
    And I open the Profile page
    And I should see the verification status value "Tier 1"

    Examples:
      | email                           | password     |
      | test+tc-reg-01@example.com      | T3st@Reg01!  |
      | test+tc-reg-03@example.com      | T3st@Reg03!  |

  @ui
  Scenario: Registration blocked without password
    Given I am on the EvolvePay landing page
    When I navigate to Register
    And I enter email "test+tc-reg-02@example.com" and leave password empty
    And I submit the registration form
    Then I should see a validation error indicating the password is required
    And I cannot access any authenticated page
    When I navigate to Login
    And I try to sign in with email "test+tc-reg-02@example.com" and password "Dummy!234"
    Then I should see an authentication error and remain logged out

  @ui
  Scenario: Registered user can log in
    Given I am on the EvolvePay landing page
    When I navigate to Login
    And I enter email "test+tc-login-01@example.com" and password "T3st@Login01!"
    And I click "Sign In"
    Then I should land in an authenticated area
    When I open the Profile page
    Then I should see the verification status field
    When I navigate to another authenticated page
    Then I should remain signed in

  @ui
  Scenario: Unregistered user cannot log in
    Given I am on the EvolvePay landing page
    When I navigate to Login
    And I enter email "test+tc-login-02@example.com" and password "BadPass!234"
    And I click "Sign In"
    Then I should see an authentication error and remain logged out
    When I try to open Profile via direct URL
    Then I should be blocked or redirected to Login

  # UI Tests — KYC and Verification Status

  @ui
  Scenario Outline: Submit KYC with allowed document types results in Pending
    Given I am on the Login page
    When I sign in as "<email>" with password "<password>"
    And I navigate to KYC submission
    And I select document type "<doc_type>"
    And I upload ID image "<id_image>" and selfie "<selfie_image>"
    And I submit the KYC form
    Then I should see the submission succeed without validation errors
    When I open the Profile page
    Then I should see the verification status value "Pending"
    When I refresh the Profile page
    Then I should still see the verification status value "Pending"

    Examples:
      | email                         | password     | doc_type         | id_image            | selfie_image        |
      | test+tc-kyc-01@example.com    | T3st@Kyc01!  | passport         | passport_tc01.jpg   | selfie_tc01.jpg     |
      | test+tc-kyc-02@example.com    | T3st@Kyc02!  | driver's license | dl_tc02.jpg         | selfie_tc02.jpg     |

  @ui
  Scenario: KYC submission blocked without selfie
    Given I am on the Login page
    When I sign in as "test+tc-kyc-03@example.com" with password "T3st@Kyc03!"
    And I navigate to KYC submission
    And I select document type "passport"
    And I upload only the ID image "passport_tc03.jpg" and no selfie
    And I submit the KYC form
    Then I should see a validation error that selfie is required
    When I open the Profile page
    Then I should see the verification status value "Tier 1"

  @ui
  Scenario: KYC document types limited to passport or driver's license
    Given I am on the Login page
    When I sign in as "test+tc-kyc-04@example.com" with password "T3st@Kyc04!"
    And I navigate to KYC submission
    And I open the document type selector
    Then I should see exactly the options "passport" and "driver's license" and no others

  @ui
  Scenario: Status displays Tier 2 after verification
    Given I am on the Login page
    When I sign in as "test+verstat03@example.com" with password "P@ssw0rd!123"
    And I open the Profile page
    Then I should see the verification status value "Tier 2"
    When I navigate away and return to Profile
    Then I should still see the verification status value "Tier 2"
    When I log out and log back in as "test+verstat03@example.com" with password "P@ssw0rd!123"
    And I open the Profile page
    Then I should still see the verification status value "Tier 2"

  @ui
  Scenario: Only Tier 1, Pending, or Tier 2 statuses appear across users
    Given I am on the Login page
    When I sign in as "test+verstat04a@example.com" with password "P@ssw0rd!123"
    And I open the Profile page
    Then I should see the verification status value "Tier 1"
    And I should not see any unsupported status labels such as "In Review", "Rejected", or "Suspended"
    When I log out
    And I sign in as "test+verstat04c@example.com" with password "P@ssw0rd!123"
    And I open the Profile page
    Then I should see the verification status value "Tier 2"
    And I should not see any unsupported status labels such as "In Review", "Rejected", or "Suspended"

  # UI Tests — Cards: Virtual and Physical

  @ui
  Scenario Outline: Virtual card available immediately for online purchases (Tier 1 and Tier 2)
    Given I am on the Login page
    When I sign in as "<email>" with password "<password>"
    And I navigate to Prepaid Card Management
    And I select "Apply for Virtual Card"
    And I confirm the application
    Then I should see the flow complete without additional approval
    When I open the Card Dashboard
    Then I should see a new virtual prepaid card listed immediately
    And the virtual card details are visible in the same session

    Examples:
      | email                        | password      |
      | test+virt01@example.com      | P@ssw0rd!123  |
      | test+virt03@example.com      | P@ssw0rd!123  |

  @ui
  Scenario: Tier 2 can order physical prepaid card
    Given I am on the Login page
    When I sign in as "test+phys01-tier2@example.com" with password "P@ssw0rd!123"
    And I navigate to Prepaid Card Management
    And I select "Order Physical Card"
    And I review the order summary
    And I confirm the physical card order
    Then I should see an order success confirmation
    And I should see an active physical card order in my account

  @ui
  Scenario: Tier 1 blocked from ordering physical card
    Given I am on the Login page
    When I sign in as "test+phys02-tier1@example.com" with password "P@ssw0rd!123"
    And I navigate to Prepaid Card Management
    Then I should not see an enabled "Order Physical Card" option
    When I attempt any direct path to order a physical card
    Then I should be prevented from initiating an order
    And no physical card order should be created

  @ui
  Scenario: Physical card order indicates mailed to my address
    Given I am on the Login page
    When I sign in as "test+phys03-tier2@example.com" with password "P@ssw0rd!123"
    And I navigate to Prepaid Card Management
    And I select "Order Physical Card"
    And I review the order details
    Then I should see a clear indication the card will be mailed to my address
    When I confirm the order
    Then the confirmation should indicate mailing to my address

  @ui
  Scenario: Order Physical Card option appears after verification (Tier 2)
    Given I am on the Login page
    When I sign in as "test+phys04-tier1@example.com" with password "P@ssw0rd!123"
    And I open the Profile page
    Then I should see the verification status value "Tier 1"
    When I navigate to Prepaid Card Management
    Then I should not see an enabled "Order Physical Card" option
    When I navigate to KYC submission
    And I select document type "passport"
    And I upload ID image "id_passport_test.jpg" and selfie "selfie_test.jpg"
    And I submit the KYC form
    Then I should see KYC submission accepted
    When I open the Profile page until the status shows "Tier 2"
    And I navigate to Prepaid Card Management
    Then I should see the "Order Physical Card" option visible and enabled

  # UI Tests — Top-up, Balance, Transactions

  @ui
  Scenario Outline: Top-up is available and creates a 'load' transaction entry
    Given I am on the Login page
    When I sign in as "<email>" with password "<password>"
    And I open the Top-up screen
    And I select a linked bank account
    And I enter the top-up amount "<amount>" and submit
    Then I should see a successful completion message
    When I open the Card Dashboard
    Then my card balance should reflect the added funds
    When I open Transactions History
    And I filter by transaction type "load"
    Then I should see a new 'load' transaction matching amount "<amount>"

    Examples:
      | email                          | password      | amount |
      | test+topup03-t1@example.com    | P@ssw0rd!123  | 10.00  |
      | test+topup03-t2@example.com    | P@ssw0rd!123  | 15.00  |

  @ui
  Scenario: Top-up reduces remaining daily load allowance display
    Given I am on the Login page
    When I sign in as "test+topup04@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    Then I should see the usage string "$500.00 / $2000.00 daily limit used"
    When I open the Top-up screen
    And I enter the top-up amount "100.00" and submit
    And I return to Card Details and refresh
    Then I should see the usage string "$600.00 / $2000.00 daily limit used"

  @ui
  Scenario: View current card balance
    Given I am on the Login page
    When I sign in as "test+baltx01@example.com" with password "P@ssw0rd!123"
    And I open Card Dashboard/Details
    Then I should see a current balance field
    When I navigate away and return to Card Dashboard/Details
    Then I should still see the current balance field

  @ui
  Scenario: View recent transactions list
    Given I am on the Login page
    When I sign in as "test+bal02@example.com" with password "Test#12345"
    And I open Card Details
    Then I should see a Recent Transactions list with at least one entry

  @ui
  Scenario: Balance reflects top-up
    Given I am on the Login page
    When I sign in as "test+bal03@example.com" with password "Test#12345"
    And I open Card Details and record the current balance as B0
    And I open the Top-up screen
    And I enter the top-up amount "100.00" and submit
    And I return to Card Details
    Then the balance should equal B0 plus 100.00
    When I open Recent Transactions
    And I filter by transaction type "load"
    Then I should see a 'load' entry for "100.00" today

  @ui
  Scenario Outline: Transactions pagination at 25-per-page boundary cases
    Given I am on the Login page
    When I sign in as "<email>" with password "<password>"
    And I open Transactions History
    Then page 1 should display exactly "<page1_count>" items
    When I navigate to page 2 if available
    Then page 2 should display exactly "<page2_count>" items
    And there should be no page 3 if "<total>" equals 50 or 26 or 25

    Examples:
      | email                      | password    | total | page1_count | page2_count |
      | test+txn01@example.com     | Test#12345  | 50    | 25          | 25          |
      | test+txn02@example.com     | Test#12345  | 26    | 25          | 1           |
      | test+txn03@example.com     | Test#12345  | 25    | 25          | 0           |

  @ui
  Scenario: Filter transactions by date range
    Given I am on the Login page
    When I sign in as "test+txn04@example.com" with password "Test#12345"
    And I open Transactions History
    And I set Start Date to "2025-10-01" and End Date to "2025-10-31"
    And I apply filters
    Then only transactions dated 2025-10-01, 2025-10-10, and 2025-10-20 should be visible
    And out-of-range transactions should not appear

  @ui
  Scenario Outline: Filter transactions by single type
    Given I am on the Login page
    When I sign in as "<email>" with password "Test#12345"
    And I open Transactions History
    And I clear all filters
    And I filter by transaction type "<type>"
    Then only "<type>" transactions should be visible

    Examples:
      | email                     | type     |
      | test+txn05@example.com    | load     |
      | test+txn06@example.com    | purchase |
      | test+txn07@example.com    | refund   |

  @ui
  Scenario: Apply date range and type filter together
    Given I am on the Login page
    When I sign in as "test+txn08@example.com" with password "Test#12345"
    And I open Transactions History
    And I set Start Date to "2025-10-01" and End Date to "2025-10-31"
    And I filter by transaction type "purchase"
    And I apply filters
    Then I should see only purchases dated 2025-10-05 and 2025-10-15
    And I should not see loads or refunds from 2025-10-10 or out-of-range purchases

  @ui
  Scenario: Pagination remains 25 per page when filtered
    Given I am on the Login page
    When I sign in as "test+txn09@example.com" with password "Test#12345"
    And I open Transactions History
    Then page 1 should display exactly 25 items
    When I set Start Date to "2025-10-01" and End Date to "2025-10-30"
    And I filter by transaction type "purchase"
    And I apply filters
    Then filtered page 1 should display exactly 25 items
    When I navigate to page 2 of filtered results
    Then filtered page 2 should display exactly 25 items
    When I navigate to the last page of filtered results
    Then the last filtered page should display no more than 25 items
    When I clear all filters
    Then unfiltered page 1 should display exactly 25 items

  # UI Tests — Card Block and Limits display

  @ui
  Scenario: Block card immediately from the app
    Given I am on the Login page
    When I sign in as "test+block01@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    And I trigger "Block card"
    Then I should immediately see the card state marked as "Blocked"
    When I navigate to Transactions and back to Card Details
    Then the "Blocked" state should persist

  @ui
  Scenario: 'Block card' action visible to Tier 1 and Tier 2
    Given I am on the Login page
    When I sign in as "test+block02t1@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    Then I should see the "Block card" action available
    When I log out
    And I sign in as "test+block02t2@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    Then I should see the "Block card" action available

  @ui
  Scenario: Card details show balance, daily load limit, and remaining allowance
    Given I am on the Login page
    When I sign in as "test+limit01@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    Then I should see the current balance
    And I should see the daily load limit
    And I should see the remaining allowance for the day

  @ui
  Scenario: Display includes exact example string format
    Given I am on the Login page
    When I sign in as "test+limit02@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    Then I should see the usage string "$500.00 / $2000.00 daily limit used"

  @ui
  Scenario: After one top-up, used vs limit display updates
    Given I am on the Login page
    When I sign in as "test+limit03@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    Then I should see the usage string "$350.00 / $2000.00 daily limit used"
    When I open the Top-up screen
    And I enter the top-up amount "150.00" and submit
    And I return to Card Details
    Then I should see the usage string "$500.00 / $2000.00 daily limit used"
    When I open Transactions History and filter by transaction type "load"
    Then I should see a new 'load' entry for "150.00"

  @ui
  Scenario: Just-below-limit usage shows remaining allowance
    Given I am on the Login page
    When I sign in as "test+limit04@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    Then I should see the daily limit "$2,000.00" and remaining allowance "$0.01"

  @ui
  Scenario: At-limit usage shows used equals daily limit
    Given I am on the Login page
    When I sign in as "test+limit05@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    Then I should see the usage string "$2000.00 / $2000.00 daily limit used"

  @ui
  Scenario: Card details include current balance field with expected value
    Given I am on the Login page
    When I sign in as "test+limit06@example.com" with password "P@ssw0rd!123"
    And I open Card Details
    Then I should see the current balance "$750.50"

  # UI Tests — Remittance and Beneficiaries

  @ui
  Scenario: Tier 2 user can send money internationally
    Given I am on the Login page
    When I sign in as "test+t2-send01@example.com" with password "Test#12345!"
    And I navigate to Remittance > Send
    And I choose beneficiary "Amina Yusuf"
    And I enter amount "100.00" and continue to review
    And I confirm and send
    Then I should see a submission success confirmation
    When I navigate to Remittance > History
    Then I should see a new transfer entry for "Amina Yusuf" amount "100.00"

  @ui
  Scenario: Tier 1 cannot initiate international remittance
    Given I am on the Login page
    When I sign in as "test+t1-remit02@example.com" with password "Test#12345!"
    And I attempt to navigate to Remittance > Send
    Then I should be blocked from initiating a send
    When I open Remittance > History
    Then I should not see any new remittance entries

  @ui
  Scenario: Send money using a newly added beneficiary
    Given I am on the Login page
    When I sign in as "test+t2-send03@example.com" with password "Test#12345!"
    And I navigate to Remittance > Beneficiaries
    And I add a beneficiary "Carlos Mendez" country "Mexico" bank account "MX-00123456789"
    Then I should see "Carlos Mendez" in my beneficiaries list
    When I navigate to Remittance > Send
    And I select beneficiary "Carlos Mendez" and enter amount "75.00"
    And I continue to review and confirm the send
    Then I should see a submission success confirmation
    When I open Remittance > History
    Then I should see a new transfer entry for "Carlos Mendez" amount "75.00"

  @ui
  Scenario: After send, transfer appears with Pending status
    Given I am on the Login page
    When I sign in as "test+t2-remit04@example.com" with password "Test#12345!"
    And I navigate to Remittance > Beneficiaries
    And I add a beneficiary "Minh Nguyen" country "Vietnam" bank account "VN-0099887766"
    And I navigate to Remittance > Send
    And I select beneficiary "Minh Nguyen" and enter amount "50.00"
    And I continue to review and confirm the send
    Then I should see a submission success confirmation
    When I open Remittance > History
    Then I should see the latest entry for "Minh Nguyen" amount "50.00" with status "Pending"
    When I refresh the history view
    Then the entry should still show status "Pending"

  @ui
  Scenario: Remittance option enabled when user becomes Tier 2
    Given I am on the Login page
    When I sign in as "test+state05@example.com" with password "Test#12345!"
    And I open the Profile page
    Then I should see the verification status value "Tier 1"
    When I attempt to navigate to Remittance > Send
    Then I should be blocked from initiating a send
    When I navigate to KYC submission
    And I upload passport "id_passport.jpg" and selfie "selfie.jpg" and submit
    Then I should see KYC submission accepted
    When I open the Profile page until the status shows "Tier 2"
    And I navigate to Remittance > Send
    Then I should see the send screen accessible

  @ui
  Scenario: Add beneficiary with required fields
    Given I am on the Login page
    When I sign in as "test+bene01@example.com" with password "Test#12345!"
    And I navigate to Remittance > Beneficiaries
    And I add a beneficiary "Amina Yusuf" country "Kenya" bank account "KE-001234567890"
    Then I should see "Amina Yusuf" in my beneficiaries list
    When I navigate away and back to Beneficiaries
    Then I should still see "Amina Yusuf" in my beneficiaries list

  @ui
  Scenario: Save beneficiary appears for reuse in send flow
    Given I am on the Login page
    When I sign in as "test+bene02@example.com" with password "Test#12345!"
    And I navigate to Remittance > Beneficiaries
    And I add a beneficiary "David Okoro" country "Nigeria" mobile money "MM-NG-778899"
    Then I should see "David Okoro" in my beneficiaries list
    When I navigate to Remittance > Send
    Then I should be able to select "David Okoro" as a beneficiary
    When I cancel the send flow
    Then no remittance should be created and the beneficiary remains saved

  @ui
  Scenario: Delete saved beneficiary
    Given I am on the Login page
    When I sign in as "test+bene03@example.com" with password "Test#12345!"
    And I navigate to Remittance > Beneficiaries
    And I delete the beneficiary "Temp Ben"
    Then "Temp Ben" should be removed from the list
    When I navigate to Remittance > Send
    Then "Temp Ben" should not be available for selection

  @ui
  Scenario Outline: Beneficiary validation errors
    Given I am on the Login page
    When I sign in as "<email>" with password "Test#12345!"
    And I navigate to Remittance > Beneficiaries
    And I attempt to add a beneficiary with Full Name "<full_name>", Country "<country>", Bank Account "<bank_account>", Mobile Money "<mobile_money>"
    And I try to save the beneficiary
    Then I should see a validation error "<error_message>"
    And no new beneficiary should be created

    Examples:
      | email                      | full_name | country | bank_account   | mobile_money | error_message                                     |
      | test+bene04@example.com    |           | Ghana   | GH-000111222   |              | Full Name is required                             |
      | test+bene05@example.com    | Sara Ali  | Pakistan|                |              | Either Bank Account or Mobile Money is required   |

  @ui
  Scenario: Remittance history is paginated
    Given I am on the Login page
    When I sign in as "test+t2.hist01@example.com" with password "P@ssw0rd!123"
    And I navigate to Remittance > History
    Then I should see pagination controls
    When I navigate to the next page
    Then the entries should differ from page 1
    When I navigate back to page 1
    Then the original entries should reappear

  @ui
  Scenario Outline: Remittance history shows status values
    Given I am on the Login page
    When I sign in as "<email>" with password "P@ssw0rd!123"
    And I navigate to Remittance > History
    Then I should see at least one entry with status "<status>"

    Examples:
      | email                      | status    |
      | test+t2.hist02@example.com | Pending   |
      | test+t2.hist03@example.com | Completed |
      | test+t2.hist04@example.com | Failed    |

  @ui
  Scenario: Navigate across multiple pages of remittance history
    Given I am on the Login page
    When I sign in as "test+t2.hist05@example.com" with password "P@ssw0rd!123"
    And I navigate to Remittance > History
    Then I should see pagination controls
    When I move to page 2 and then to page 3
    Then I should see different entries on each page
    When I return to page 1
    Then I should see the original page 1 entries

  @ui
  Scenario: New transfer appears in history with a status
    Given I am on the Login page
    When I sign in as "test+t2.hist06@example.com" with password "P@ssw0rd!123"
    And I navigate to Remittance > Send
    And I select a saved beneficiary and enter amount "120"
    And I continue to review and verify exchange rate and fees are shown
    And I confirm and send
    Then I should see a submission success confirmation
    When I navigate to Remittance > History
    Then I should see the new transfer with a status of "Pending" or "Completed" or "Failed"

  # API Tests — Critical Backend Coverage

  @api
  Scenario Outline: Auth register/login and validation
    Given the API base URL is set
    And the authorization token is cleared
    When I send a <method> request to "<endpoint>" with JSON payload
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    Then the response status should be <status>
    And the response JSON should contain field "<expected_field>"

    Examples:
      | method | endpoint              | email                          | password      | status | expected_field |
      | POST   | /api/auth/register    | test+tc-reg-01@example.com     | T3st@Reg01!   | 201    | id             |
      | POST   | /api/auth/login       | test+tc-login-01@example.com   | T3st@Login01! | 200    | token          |
      | POST   | /api/auth/login       | test+tc-login-02@example.com   | BadPass!234   | 401    | error          |
      | POST   | /api/auth/register    | test+tc-reg-02@example.com     |               | 400    | error          |

  @api
  Scenario Outline: KYC submissions API and document-type enumeration
    Given the API base URL is set
    And the authorization token is set for user "<user>"
    When I send a <method> request to "<endpoint>" with JSON payload
      """
      <payload>
      """
    Then the response status should be <status>
    And the response JSON should contain field "<expected_field>"

    Examples:
      | user                        | method | endpoint                  | payload                                                                                          | status | expected_field |
      | test+tc-kyc-01@example.com  | GET    | /api/kyc/document-types   | {}                                                                                               | 200    | documentTypes  |
      | test+tc-kyc-01@example.com  | POST   | /api/kyc/submissions      | {"doc_type":"passport","id_image":"passport_tc01.jpg","selfie_image":"selfie_tc01.jpg"}          | 201    | status         |
      | test+tc-kyc-03@example.com  | POST   | /api/kyc/submissions      | {"doc_type":"passport","id_image":"passport_tc03.jpg"}                                           | 400    | error          |

  @api
  Scenario Outline: Card issuance and ordering via API with tier gating
    Given the API base URL is set
    And the authorization token is set for user "<user>"
    When I send a <method> request to "<endpoint>" with JSON payload
      """
      <payload>
      """
    Then the response status should be <status>
    And the response JSON should contain field "<expected_field>"

    Examples:
      | user                           | method | endpoint                        | payload                         | status | expected_field |
      | test+virt03@example.com        | POST   | /api/cards/virtual              | {"label":"New Virtual Card"}    | 201    | cardType       |
      | test+phys01-tier2@example.com  | POST   | /api/cards/physical/orders      | {"shippingAddressId":"addr1"}   | 201    | orderId        |
      | test+phys02-tier1@example.com  | POST   | /api/cards/physical/orders      | {"shippingAddressId":"addr1"}   | 403    | error          |

  @api
  Scenario Outline: Top-up API creates 'load' transaction and transactions list supports pagination and filtering
    Given the API base URL is set
    And the authorization token is set for user "<user>"
    When I send a POST request to "/api/topups" with JSON payload
      """
      {"amount": <amount>, "source": "linked_bank"}
      """
    Then the response status should be 201
    And the response JSON should contain field "id"
    When I send a GET request to "/api/transactions?type=load&page=1&page_size=25"
    Then the response status should be 200
    And the response JSON list should contain an item with field "type" equals "load" and "amount" equals <amount>

    Examples:
      | user                        | amount |
      | test+topup03-t1@example.com | 10.00  |
      | test+topup03-t2@example.com | 15.00  |

  @api
  Scenario: Block card via API sets blocked status immediately
    Given the API base URL is set
    And the authorization token is set for user "test+block03@example.com"
    And I have a card id "card_123"
    When I send a POST request to "/api/cards/card_123/block" with JSON payload
      """
      {"reason": "user_requested"}
      """
    Then the response status should be 200
    And the response JSON should contain field "status" equals "Blocked"

  @api
  Scenario Outline: Remittance create and history pagination via API
    Given the API base URL is set
    And the authorization token is set for user "<user>"
    When I send a POST request to "/api/remittances" with JSON payload
      """
      {"beneficiaryId":"<beneficiary_id>", "amount": <amount>, "currency":"USD"}
      """
    Then the response status should be 201
    And the response JSON should contain field "status" equals "Pending"
    When I send a GET request to "/api/remittances/history?page=1&page_size=20"
    Then the response status should be 200
    And the response JSON list should contain an item with field "beneficiaryId" equals "<beneficiary_id>"

    Examples:
      | user                          | beneficiary_id | amount |
      | test+t2-send01@example.com    | bene_amina     | 100.00 |
      | test+t2-send03@example.com    | bene_carlos    | 75.00  |

  @api
  Scenario Outline: Beneficiaries CRUD and validation via API
    Given the API base URL is set
    And the authorization token is set for user "<user>"
    When I send a <method> request to "<endpoint>" with JSON payload
      """
      <payload>
      """
    Then the response status should be <status>
    And the response JSON should contain field "<expected_field>"

    Examples:
      | user                       | method | endpoint                 | payload                                                        | status | expected_field |
      | test+bene01@example.com    | POST   | /api/beneficiaries       | {"fullName":"Amina Yusuf","country":"Kenya","bankAccount":"KE-001234567890"} | 201    | id             |
      | test+bene04@example.com    | POST   | /api/beneficiaries       | {"country":"Ghana","bankAccount":"GH-000111222"}              | 400    | error          |
      | test+bene05@example.com    | POST   | /api/beneficiaries       | {"fullName":"Sara Ali","country":"Pakistan"}                  | 400    | error          |
      | test+bene03@example.com    | DELETE | /api/beneficiaries/b1    | {}                                                             | 204    | null           |
