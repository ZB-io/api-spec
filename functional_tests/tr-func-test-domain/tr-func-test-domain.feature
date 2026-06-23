Feature: EvolvePay - User Onboarding, KYC, Cards, Top-up, Remittance

  # UI Tests

  @ui @registration @tier1
  Scenario Outline: Register new user attains Tier 1 and can view it in Profile
    Given I am on the EvolvePay registration page
    And I see the registration form with email and password fields
    When I enter email "<email>" and password "<password>"
    And I click the "Register" button
    Then I should land on an authenticated page (e.g., dashboard)
    And I navigate to "Profile" from the main menu
    And I should see the verification status "Tier 1"
    And I log out and am redirected to the login page

    Examples:
      | email                      | password       |
      | test+reg01@example.com     | P@ssw0rd123!   |
      | test+reg02@example.com     | P@ssw0rd123!   |

  @ui @registration @login
  Scenario Outline: Register, then log out and log back in securely
    Given I am on the EvolvePay registration page
    When I register with email "<email>" and password "<password>"
    And I confirm I am on an authenticated page
    And I log out to the login screen
    When I enter email "<email>" and password "<password>" on the login form
    And I click the "Log In" button
    Then I should be authenticated and see the dashboard
    And I navigate to "Profile" and see the verification status "Tier 1"

    Examples:
      | email                      | password       |
      | test+reg03@example.com     | P@ssw0rd123!   |

  @ui @login @negative
  Scenario Outline: Invalid credentials are rejected during secure login
    Given I am on the EvolvePay login page
    When I attempt to log in with email "<email>" and password "<password>"
    Then I should <outcome>
    And no authenticated UI elements should be visible when the outcome is "remain on the login page"
    When I navigate directly to a protected URL
    Then I should be redirected back to the login page

    Examples:
      | email                          | password        | outcome                        |
      | test+login02@example.com       | WrongPass!234   | remain on the login page       |
      | test+doesnotexist@example.com  | AnyPass!234     | remain on the login page       |
      | test+login02@example.com       |                 | remain on the login page       |

  @ui @login @positive
  Scenario Outline: Successful secure login for an already registered user
    Given I am on the EvolvePay login page
    When I enter email "<email>" and password "<password>" and click "Log In"
    Then I should land on an authenticated page and see the user menu
    And I navigate to "Profile" and the account is accessible
    And I log out and return to the login screen

    Examples:
      | email                        | password       |
      | test+login01@example.com     | P@ssw0rd123!   |

  @ui @profile @status
  Scenario Outline: Profile clearly shows the user’s verification status
    Given I am on the EvolvePay login page
    And I log in with email "<email>" and password "<password>"
    When I navigate to "Profile"
    Then I should see the verification status "<expected_status>" clearly
    And I refresh the page and the status "<expected_status>" persists
    And I log out

    Examples:
      | email                         | password       | expected_status |
      | test+login03@example.com      | P@ssw0rd123!   | Tier 1          |
      | test+status02@example.com     | ****Login#123  | Pending         |
      | test+status03@example.com     | ****Login#123  | Tier 2          |

  @ui @kyc @positive
  Scenario Outline: Submit KYC with ID and selfie (supported ID types)
    Given I am logged in as "<email>" with password "<password>"
    And I navigate to the "KYC/Verification" page
    When I select ID type "<id_type>"
    And I upload the ID image "<id_file>"
    And I upload the selfie image "<selfie_file>"
    Then the "Submit" button becomes enabled
    When I click "Submit"
    Then I see submission processing and no error is displayed
    And I navigate to "Profile" and the verification status is visible (may be "Pending")

    Examples:
      | email                      | password       | id_type          | id_file                     | selfie_file              |
      | test+kyc01@example.com     | P@ssw0rd123!   | Passport         | passport_placeholder.jpg    | selfie_placeholder.jpg   |
      | test+kyc02@example.com     | P@ssw0rd123!   | Driver's license | dl_placeholder.jpg          | selfie_placeholder.jpg   |

  @ui @kyc @negative
  Scenario Outline: KYC submission requires both ID and selfie
    Given I am logged in as "test+kyc03@example.com" with password "P@ssw0rd123!"
    And I navigate to the "KYC/Verification" page
    When I select ID type "Passport"
    And I upload the ID image "<id_file>"
    And I upload the selfie image "<selfie_file>"
    Then the "Submit" button should be <submit_state>
    When I provide both required files if needed
    And I click "Submit"
    Then I see successful submission and no error

    Examples:
      | id_file                   | selfie_file             | submit_state          |
      | passport_placeholder.jpg  |                         | disabled or rejected  |
      |                          | selfie_placeholder.jpg  | disabled or rejected  |
      | passport_placeholder.jpg  | selfie_placeholder.jpg  | enabled               |

  @ui @kyc @state-transition
  Scenario: KYC drives transition from Tier 1 to Tier 2 after completion
    Given I am logged in as "test+kyc04@example.com" with password "P@ssw0rd123!"
    And I navigate to "Profile" and confirm the status is "Tier 1"
    When I go to "KYC/Verification" and submit required passport and selfie files
    Then the submission is accepted without error
    When KYC is completed in the test environment
    And I refresh "Profile"
    Then I should see the verification status "Tier 2"

  @ui @virtual-card @availability
  Scenario Outline: Apply for a virtual prepaid card (Tier 1 and Tier 2) and see immediate availability
    Given I am logged in as "<email>" with password "<password>"
    And I navigate to "Prepaid Card Management"
    When I select "Apply for Virtual Prepaid Card" and submit
    Then I should see a new virtual card in my card list immediately
    And I can open the virtual card details without delay
    And I log out

    Examples:
      | email                        | password       |
      | test+vcard01@example.com     | ****Login#123  |
      | test+vcard04@example.com     | ****Login#123  |

  @ui @virtual-card @security
  Scenario: Unauthenticated users cannot apply for virtual card
    Given I am not logged in
    When I attempt to navigate to the Virtual Card application screen
    Then I am prompted to log in and cannot use the application form
    When I try to submit an application without logging in
    Then no card is created and I remain unauthenticated

  @ui @physical-card @gating
  Scenario Outline: Physical card ordering is restricted to Tier 2
    Given I am logged in as "<email>" with password "<password>"
    And I navigate to "Prepaid Card Management"
    When I look for the "Order Physical Card" option
    Then the option should be "<visibility>"
    When I attempt to place an order if visible
    Then the result should be "<result>"
    And I log out

    Examples:
      | email                         | password       | visibility            | result                          |
      | test+pcard02@example.com      | ****Login#123  | not visible/disabled  | blocked/not allowed              |
      | test+pcard01@example.com      | ****Login#123  | visible/enabled       | order accepted with confirmation |

  @ui @physical-card @confirmation
  Scenario: Physical card order indicates delivery to the user’s address
    Given I am logged in as "test+pcard05@example.com" with password "Test!23456"
    And I navigate to "Prepaid Card Management"
    When I select "Order Physical Card" and confirm
    Then I should see a confirmation indicating the card will be mailed to my address
    And I can see an order confirmation or reference
    And I log out

  @ui @topup @balance @transactions
  Scenario Outline: Top-up funds from linked bank account updates balance and records a 'load'
    Given I am logged in as "<email>" with password "<password>"
    And I open "Card Details" and record the current balance as B0
    When I navigate to "Top-up" and enter amount "<amount>" from a linked bank account
    And I submit the top-up
    Then I see a successful confirmation
    When I return to "Card Details"
    Then the displayed balance should equal B0 + "<amount>"
    And I open "Recent Transactions" and should see a 'load' entry for "<amount>"
    And I log out

    Examples:
      | email                          | password     | amount   |
      | test+topup01@example.com       | Test!23456   | 100.00   |
      | test+baltxn02@example.com      | Test!23456   | 60.00    |
      | test+topup04@example.com       | Test!23456   | 75.00    |

  @ui @topup @security
  Scenario: Top-up requires an authenticated user session
    Given I am not logged in
    When I try to open the "Top-up" URL directly
    Then I should be redirected to the login page
    When I log in as "test+topup02@example.com" with password "Test!23456"
    Then I can access the "Top-up" screen
    And I log out
    When I try the "Top-up" URL again while logged out
    Then I am still blocked or redirected to login

  @ui @transactions @pagination
  Scenario Outline: Transaction history pagination shows 25 items per page
    Given I am logged in as "<email>" with password "<password>"
    When I open "Transaction History"
    Then I should see exactly 25 items on page 1
    When I navigate to page 2
    Then I should see exactly "<expected_page2_count>" items on page 2
    And navigating back to page 1 shows exactly 25 items again

    Examples:
      | email                         | password     | expected_page2_count |
      | test+txnhist01@example.com    | Test!23456   | 5                    |
      | test+t25@example.com          | *****        | 0                    |
      | test+t26@example.com          | *****        | 1                    |

  @ui @transactions @filters @date-range
  Scenario Outline: Date range filter returns matching transactions only
    Given I am logged in as "<email>" with password "<password>"
    And I open "Transaction History"
    When I apply the date range filter from "<start_date>" to "<end_date>"
    Then I should see exactly "<expected_count>" transactions listed
    And transactions outside the range should not appear
    When I clear the date filter
    Then the broader history becomes visible again

    Examples:
      | email                          | password     | start_date  | end_date    | expected_count |
      | test+daterange@example.com     | *****        | 2025-09-01  | 2025-09-30  | 3              |
      | test+t1@example.com            | *****        | 2025-11-01  | 2025-11-30  | 0              |
      | test+t1@example.com            | *****        | 2025-10-15  | 2025-10-15  | 2              |

  @ui @transactions @filters @type
  Scenario Outline: Filter by transaction type shows only the selected type
    Given I am logged in as "<email>" with password "<password>"
    And I open "Transaction History"
    When I filter by transaction type "<type>"
    Then only "<type>" entries should be visible
    And no other transaction types should appear

    Examples:
      | email                           | password     | type     |
      | test+topup04@example.com        | Test!23456   | load     |
      | test+purchasefilter@example.com | *****        | purchase |
      | test+txnhist10@example.com      | *****        | refund   |

  @ui @card-block @state-transition
  Scenario: Block card immediately from the app and see persistent blocked status
    Given I am logged in as "test+blocknow@example.com" with password "*****"
    And I open "Card Details" and confirm status is "Active"
    When I initiate the "Block Card" action and confirm
    Then the status updates immediately to "Blocked" on "Card Details"
    When I navigate away and return to "Card Details"
    Then the status remains "Blocked"

  @ui @card-block @security
  Scenario: Only authenticated users can access the block action
    Given I am not logged in
    When I try to navigate to "Card Details"
    Then I cannot see the block control
    When I log in as "test+secureblock@example.com" with password "*****"
    Then I open "Card Details" and the block control is visible
    When I log out
    Then the block control is not visible while logged out

  @ui @limits @formatting
  Scenario Outline: Card details show balance and daily limit string with correct formatting
    Given I am logged in as "<email>" with password "<password>"
    And I navigate to "Card Details"
    When I locate the daily load limit usage string
    Then it should display "<used> / <limit> daily limit used" with proper currency and two decimals
    And the current balance is visible

    Examples:
      | email                        | password     | used      | limit       |
      | test+limit02@example.com     | ******       | $0.00     | $2000.00    |
      | test+limit01@example.com     | ******       | $300.00   | $2000.00    |
      | test+limit04@example.com     | ******       | $500.00   | $2000.00    |

  @ui @remittance @gating
  Scenario Outline: Remittance send flow is gated to Tier 2 (review shows rate and fees)
    Given I log in as "<email>" with password "<password>"
    When I attempt to access "International Remittance > Send Money"
    Then I should see "<expected_access>"
    When I proceed (if allowed) to select a saved beneficiary and enter amount "<amount>"
    And I reach the review step
    Then I should see the exchange rate and any transaction fees before confirming

    Examples:
      | email                          | password | expected_access                 | amount |
      | test+tier1remit02@example.com  | ******   | access blocked for Tier 1       | 100    |
      | test+tier2control@example.com  | ******   | access allowed and review shown | 100    |

  @ui @beneficiaries @add
  Scenario: Add and save a beneficiary with required fields
    Given I am logged in as "test+benef01@example.com" with password "******"
    When I navigate to "International Remittance > Beneficiaries"
    And I add a beneficiary with Full Name "Sara Mensah", Country "Ghana", Mobile Money "GH-MM-***5566"
    Then I should see "Sara Mensah" listed with masked account summary
    And the entry persists after refresh

  @ui @beneficiaries @delete
  Scenario: Delete a beneficiary removes it from the saved list and from send flow
    Given I am logged in as "test+benef02@example.com" with password "******"
    And I have a saved beneficiary "Luis Pereira" with account "BR-BANK-***2211"
    When I delete the beneficiary "Luis Pereira" and confirm
    Then it no longer appears in the Beneficiaries list
    And it is not present in the Send Money beneficiary selector

  @ui @beneficiaries @selection
  Scenario: Saved beneficiary is selectable and auto-populates the send flow
    Given I am logged in as "test.user+benef03@example.com" with password "******"
    And I have saved beneficiary "Amina K Test" (Kenya, ACCT-****4321)
    When I start the Send Money flow and choose "Amina K Test" from saved beneficiaries
    Then recipient fields auto-populate and persist to the review step
    And cancelling returns me without deleting the saved beneficiary

  @ui @remittance @send @history
  Scenario: Tier 2 user can send money internationally and see it in remittance history
    Given I am logged in as "test+tier2remit01@example.com" with password "******"
    And I have at least one saved beneficiary
    When I start a new Send Money, select the beneficiary, and enter amount "$100.00"
    And I verify the review shows exchange rate and any fees
    And I confirm the transfer
    Then I navigate to "Remittance History" and see the new transfer with a status (e.g., Pending/Completed/Failed)

  @ui @remittance @history @pagination @statuses
  Scenario: Remittance history is paginated and shows statuses
    Given I am logged in as "test.user+remhist02@example.com" with password "******"
    When I open "Remittance History"
    Then I can see pagination controls and navigate to the next page and back
    And I see entries labeled with statuses "Pending", "Completed", and "Failed"
    And statuses persist after refresh

  @ui @e2e @tier-gating @cards @limits
  Scenario: E2E - Register → KYC → Virtual card → Order physical → Verify daily limit string
    Given I register with email "test+pcard04@example.com" and password "Test!23456"
    And I confirm on "Profile" the status is "Tier 1"
    When I submit KYC with passport and selfie and wait for verification in the test environment
    Then "Profile" should show "Tier 2"
    When I apply for a Virtual Prepaid Card
    Then a new virtual card appears immediately in my card list
    When I order a Physical Card
    Then the order is accepted and confirmation is shown
    When I open the issued card’s details
    Then I see the balance and a daily load limit string like "$X / $Y daily limit used"

  # API Tests

  @api @auth @registration
  Scenario Outline: API - Register new user and verify Tier 1 in profile
    Given the API base URL is "<base_url>"
    When I send a POST request to "/api/auth/register" with JSON payload:
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    Then the response status should be 201
    And the response JSON should contain "id"
    And I store the access token from the response as "reg_token"
    When I send a GET request to "/api/users/me" with Authorization "Bearer reg_token"
    Then the response status should be 200
    And the response JSON path "$.tier" should equal "Tier 1"

    Examples:
      | base_url                 | email                      | password       |
      | https://api.evolvepay.test | test+api.reg01@example.com | P@ssw0rd123!   |

  @api @auth @login
  Scenario Outline: API - Login valid and invalid attempts
    Given the API base URL is "<base_url>"
    When I send a POST request to "/api/auth/login" with JSON payload:
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    Then the response status should be <expected_status>
    And the response JSON should <token_expectation>

    Examples:
      | base_url                   | email                        | password       | expected_status | token_expectation                   |
      | https://api.evolvepay.test | test+login01@example.com     | P@ssw0rd123!   | 200             | contain "accessToken"               |
      | https://api.evolvepay.test | test+login02@example.com     | WrongPass!234  | 401             | not contain "accessToken"           |
      | https://api.evolvepay.test | test+doesnotexist@example.com| AnyPass!234    | 401             | not contain "accessToken"           |

  @api @kyc @submission
  Scenario Outline: API - Submit KYC and verify Pending status
    Given the API base URL is "<base_url>"
    And I am authenticated as "<email>" with password "<password>" and store token "u_token"
    When I send a POST request to "/api/kyc/submissions" with JSON payload:
      """
      {
        "idType": "<id_type>",
        "idFileId": "<id_file_id>",
        "selfieFileId": "<selfie_file_id>"
      }
      """
    Then the response status should be 201
    And the response JSON path "$.status" should equal "Submitted"
    When I send a GET request to "/api/users/me" with Authorization "Bearer u_token"
    Then the response status should be 200
    And the response JSON path "$.tier" should be one of "Tier 1","Pending"

    Examples:
      | base_url                   | email                      | password       | id_type          | id_file_id | selfie_file_id |
      | https://api.evolvepay.test | test+kyc01@example.com     | P@ssw0rd123!   | Passport         | file-pp-1  | file-sf-1      |
      | https://api.evolvepay.test | test+kyc02@example.com     | P@ssw0rd123!   | DriverLicense    | file-dl-2  | file-sf-2      |

  @api @cards @virtual
  Scenario Outline: API - Apply for virtual card and verify presence in list
    Given the API base URL is "<base_url>"
    And I am authenticated as "<email>" with password "<password>" and store token "c_token"
    When I send a POST request to "/api/cards/virtual" with JSON payload:
      """
      {
        "label": "Virtual Prepaid Card"
      }
      """
    Then the response status should be 201
    And the response JSON path "$.type" should equal "VIRTUAL"
    And I store the response JSON path "$.id" as "card_id"
    When I send a GET request to "/api/cards?type=VIRTUAL" with Authorization "Bearer c_token"
    Then the response status should be 200
    And the response JSON array should contain an object where "id" equals "card_id"

    Examples:
      | base_url                   | email                        | password     |
      | https://api.evolvepay.test | test+vcard01@example.com     | ****Login#123|
      | https://api.evolvepay.test | test+vcard04@example.com     | ****Login#123|

  @api @cards @physical @gating
  Scenario Outline: API - Physical card ordering requires Tier 2
    Given the API base URL is "<base_url>"
    And I am authenticated as "<email>" with password "<password>" and store token "p_token"
    When I send a POST request to "/api/cards/physical-orders" with JSON payload:
      """
      {
        "shippingAddressOnFile": true
      }
      """
    Then the response status should be <expected_status>

    Examples:
      | base_url                   | email                         | password      | expected_status |
      | https://api.evolvepay.test | test+pcard02@example.com      | ****Login#123 | 403             |
      | https://api.evolvepay.test | test+pcard01@example.com      | ****Login#123 | 201             |

  @api @topup @transactions
  Scenario Outline: API - Top-up increases balance and creates 'load' transaction
    Given the API base URL is "<base_url>"
    And I am authenticated as "<email>" with password "<password>" and store token "t_token"
    And I have a virtual card and store its id as "card_id"
    When I send a GET request to "/api/cards/<card_id>" with Authorization "Bearer t_token"
    Then the response status should be 200
    And I store the response JSON path "$.balance" as "B0"
    When I send a POST request to "/api/cards/<card_id>/topups" with JSON payload:
      """
      {
        "amount": <amount>,
        "fundingSource": "LINKED_BANK"
      }
      """
    Then the response status should be 201
    When I send a GET request to "/api/cards/<card_id>" with Authorization "Bearer t_token"
    Then the response status should be 200
    And the response JSON path "$.balance" should equal "B0 + <amount>"
    When I send a GET request to "/api/cards/<card_id>/transactions?type=load&limit=25&page=1" with Authorization "Bearer t_token"
    Then the response status should be 200
    And the response JSON array should contain an object where "amount" equals <amount> and "type" equals "load"

    Examples:
      | base_url                   | email                       | password     | amount |
      | https://api.evolvepay.test | test+topup01@example.com    | Test!23456   | 100    |

  @api @transactions @pagination
  Scenario Outline: API - Transaction history paginated at 25 per page
    Given the API base URL is "<base_url>"
    And I am authenticated as "<email>" with password "<password>" and store token "h_token"
    When I send a GET request to "/api/cards/<card_id>/transactions?limit=25&page=1" with Authorization "Bearer h_token"
    Then the response status should be 200
    And the response JSON array length should equal 25
    When I send a GET request to "/api/cards/<card_id>/transactions?limit=25&page=2" with Authorization "Bearer h_token"
    Then the response status should be 200
    And the response JSON array length should equal <expected_page2_count>

    Examples:
      | base_url                   | email                      | password     | card_id       | expected_page2_count |
      | https://api.evolvepay.test | test+txnhist01@example.com | Test!23456   | CARD-SEED-30  | 5                    |
      | https://api.evolvepay.test | test+t25@example.com       | *****        | CARD-SEED-25  | 0                    |
      | https://api.evolvepay.test | test+t26@example.com       | *****        | CARD-SEED-26  | 1                    |

  @api @card-block
  Scenario Outline: API - Block card and verify status immediately
    Given the API base URL is "<base_url>"
    And I am authenticated as "<email>" with password "<password>" and store token "b_token"
    When I send a POST request to "/api/cards/<card_id>/block" with JSON payload:
      """
      {
        "reason": "USER_REQUEST"
      }
      """
    Then the response status should be 200
    When I send a GET request to "/api/cards/<card_id>" with Authorization "Bearer b_token"
    Then the response status should be 200
    And the response JSON path "$.status" should equal "Blocked"

    Examples:
      | base_url                   | email                         | password | card_id         |
      | https://api.evolvepay.test | test+blocknow@example.com     | *****    | CARD-****-A1    |

  @api @remittance @gating
  Scenario Outline: API - Remittance send flow gated to Tier 2
    Given the API base URL is "<base_url>"
    And I am authenticated as "<email>" with password "<password>" and store token "r_token"
    When I send a POST request to "/api/remittance/transfers" with JSON payload:
      """
      {
        "beneficiaryId": "<beneficiary_id>",
        "amount": <amount>,
        "currency": "USD"
      }
      """
    Then the response status should be <expected_status>
    And the response JSON should <result_expectation>

    Examples:
      | base_url                   | email                           | password | beneficiary_id | amount | expected_status | result_expectation                  |
      | https://api.evolvepay.test | test+tier1gate04@example.com    | ******   | ben-123        | 75     | 403             | not contain "id"                    |
      | https://api.evolvepay.test | test+tier2gate04@example.com    | ******   | ben-456        | 75     | 201             | contain "id"                        |
