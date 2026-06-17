Feature: EvolvePay onboarding, KYC, cards, transactions, and remittance

  # UI Tests

  @ui @registration
  Scenario Outline: Registration form validation and Tier 1 onboarding
    Given I am on the Registration screen with a fresh browser session
    And no account exists for '<email>'
    When I enter email '<email>' and password '<password>' on the registration form
    And I click the 'Register' button
    Then I should <outcome_ui>
    And if authenticated I navigate to 'Profile' and I should see verification status 'Tier 1'
    And if authenticated I log out and should return to the login screen

    Examples:
      | email                      | password     | outcome_ui                                                                                  |
      | test+reg01@example.com     | TestPwd!234  | land on an authenticated page (e.g., dashboard or home)                                     |
      |                            | TestPwd!234  | remain on the Registration screen (blocked submission due to missing email)                 |
      | test+reg02a@example.com    |              | remain on the Registration screen (blocked submission due to missing password)              |

  @ui @profile
  Scenario: Post-registration profile shows Tier 1 and persists across refresh and re-login
    Given I have just registered with email 'test+reg03@example.com' and password 'TestPwd!234'
    When I navigate to 'Profile'
    Then I should see verification status 'Tier 1'
    When I refresh the page
    Then I should still see verification status 'Tier 1'
    When I log out and log back in with 'test+reg03@example.com' and 'TestPwd!234'
    And I navigate to 'Profile'
    Then I should still see verification status 'Tier 1'

  @ui @auth
  Scenario Outline: Secure login for registered user and rejection for unregistered user
    Given I am on the Login screen
    When I enter email '<email>' and password '<password>'
    And I click the 'Log In' button
    Then I should <login_outcome>
    And when authenticated I navigate to 'Profile' and should see a verification status present
    And when authenticated I log out and protected pages require login again

    Examples:
      | email                   | password     | login_outcome                                                                     |
      | test+auth01@example.com | TestPwd!234  | land on the authenticated dashboard                                               |
      | test+auth02@example.com | WrongPwd!000 | remain on the Login screen (authentication fails; no authenticated area is shown) |

  @ui @kyc
  Scenario Outline: KYC submission accepts allowed ID types with selfie
    Given I am logged in as Tier 1 user '<email>' with password 'TestPwd!234'
    And I navigate to the 'KYC submission' screen
    When I select ID type '<id_type>'
    And I upload ID image file '<id_file>'
    And I upload selfie image file 'selfie_sample.jpg'
    And I submit the KYC form
    Then I should see a submission success indication (no validation errors)
    When I navigate to 'Profile'
    Then I should see a verification status element present

    Examples:
      | email                    | id_type          | id_file                     |
      | test+kyc01@example.com   | Passport         | passport_sample.jpg         |
      | test+kyc02@example.com   | Driver's license | drivers_license_sample.jpg  |

  @ui @kyc @negative
  Scenario: KYC requires selfie with ID (blocked until selfie is added)
    Given I am logged in as Tier 1 user 'test+kyc03@example.com' with password 'TestPwd!234'
    And I navigate to the 'KYC submission' screen
    When I select ID type 'Passport'
    And I upload ID image file 'passport_sample.jpg'
    And I do not upload a selfie image
    And I attempt to submit the KYC form
    Then the submission should be blocked on the same screen (missing selfie)
    When I upload selfie image file 'selfie_sample.jpg'
    And I submit the KYC form
    Then I should see a submission success indication

  @ui @kyc @allowed-values
  Scenario: Only Passport and Driver's license appear as KYC ID types
    Given I am logged in as Tier 1 user 'test+kyc04@example.com' with password 'TestPwd!234'
    And I navigate to the 'KYC submission' screen
    When I open the ID type selector
    Then I should see 'Passport' and 'Driver's license' as the only selectable options
    When I select 'Passport' and then switch to 'Driver's license'
    Then the selection should update accordingly
    And I close the form without submitting

  @ui @kyc @status
  Scenario: Status shows Pending immediately after KYC submission and persists across re-login
    Given I am logged in as Tier 1 user 'test+kyc05@example.com' with password 'TestPwd!234'
    And I navigate to 'Profile' and verify current status shows 'Tier 1'
    When I go to 'KYC submission' and submit Passport + selfie
    And I navigate back to 'Profile'
    Then I should see verification status 'Pending'
    When I log out and log back in as 'test+kyc05@example.com' with 'TestPwd!234'
    And I navigate to 'Profile'
    Then I should still see verification status 'Pending'

  @ui @kyc @state-transition
  Scenario: Verification status progression Tier 1 -> Pending -> Tier 2 is visible in Profile
    Given I register a new account 'test+kyc06@example.com' with password 'Test@12345' and land on the dashboard
    And I navigate to 'Profile' and should see verification status 'Tier 1'
    When I navigate to 'KYC submission' and submit 'sample_id_passport.jpg' and 'selfie_front.jpg'
    And I navigate to 'Profile'
    Then I should see verification status 'Pending'
    When I wait for KYC to complete in the test environment and then refresh 'Profile'
    Then I should see verification status 'Tier 2'
    When I log out and log back in as 'test+kyc06@example.com' with 'Test@12345'
    And I navigate to 'Profile'
    Then I should still see verification status 'Tier 2'

  @ui @profile @enumeration
  Scenario Outline: Profile shows only enumerated statuses and is clearly visible
    Given I am logged in as '<email>' with password '<password>'
    When I navigate to 'Profile'
    Then I should see a visible verification status element
    And the displayed status should be one of 'Tier 1', 'Pending', or 'Tier 2'
    And the displayed status should equal '<expected_status>'

    Examples:
      | email                        | password     | expected_status |
      | test+vstat01@example.com     | Test@12345   | Tier 1         |
      | test+vstat02@example.com     | Test@12345   | Pending        |
      | test+vstat03@example.com     | Test@12345   | Tier 2         |

  @ui @virtual-card
  Scenario Outline: Tier 1 user applies for a virtual prepaid card and it is available immediately
    Given I am logged in as Tier 1 user '<email>' with password 'Test@12345'
    And I navigate to 'Cards > Virtual'
    When I click 'Apply' for a new virtual card
    Then I should see a success confirmation
    And I should be able to view the new virtual card in the card list immediately
    When I open the new card’s details
    Then the card should be labeled as 'Virtual'
    When I log out and log back in as '<email>' with 'Test@12345'
    And I navigate to the card list
    Then the same virtual card should be visible

    Examples:
      | email                       |
      | test+vcard01@example.com    |
      | test+vcard03@example.com    |

  @ui @physical-card @tier-gating
  Scenario Outline: Physical card order visibility and ordering behavior by user tier
    Given I am logged in as '<user_email>' with password '<password>'
    And I navigate to 'Profile'
    Then I should see verification status '<tier_status>'
    When I navigate to 'Prepaid Card Management'
    Then the 'Order physical prepaid card' action should be <visible_state>
    When the action is visible I click 'Order physical prepaid card' and confirm the order
    Then I should <order_outcome>

    Examples:
      | user_email               | password  | tier_status | visible_state     | order_outcome                                     |
      | test.tier1@example.com   | ****      | Tier 1      | not visible       | see no order flow and no success confirmation     |
      | test.tier2@example.com   | ****      | Tier 2      | visible           | see a success confirmation for the physical order |

  @ui @physical-card @state-transition
  Scenario: Physical card order becomes available after Tier 2 verification
    Given I am logged in as Tier 1 user 'test.kyc1@example.com' with password '****'
    And on 'Prepaid Card Management' I confirm 'Order physical prepaid card' is not present
    When I navigate to 'Profile > KYC' and submit passport + selfie
    Then I should see status 'Pending' in Profile
    When I wait until the status updates to 'Tier 2'
    And I return to 'Prepaid Card Management'
    Then I should see the 'Order physical prepaid card' action visible and enabled
    When I place the physical card order and confirm
    Then I should see a success confirmation

  @ui @physical-card @virtual-card
  Scenario: Tier 2 can order a physical card when a virtual card already exists
    Given I am logged in as Tier 2 user 'test.vp2@example.com' with password '****'
    When I navigate to 'Prepaid Card Management' and apply for a virtual prepaid card
    Then I should see the virtual card in my card list
    When I click 'Order physical prepaid card' and confirm
    Then I should see a success confirmation for the physical card order

  @ui @topup @transactions
  Scenario: Top-up from linked bank account updates balance and appears in recent transactions and filtered history
    Given I am logged in as 'test.load1@example.com' with password '****'
    And I have a prepaid card with a linked bank account
    And I navigate to 'Card Details' and record the current balance as B_before
    When I navigate to 'Load Funds' and enter amount '$100.00' and select the linked bank account
    And I submit the top-up
    Then I should see a success confirmation
    When I return to 'Card Details'
    Then the balance should equal B_before + $100.00
    When I navigate to 'Recent Transactions'
    Then I should see a new transaction for '$100.00' load
    When I navigate to 'Transaction History'
    And I filter by type 'load' and a date range including today
    Then I should see the $100.00 load in the filtered results

  @ui @topup @negative
  Scenario: Top-up requires a linked bank account
    Given I am logged in as 'test.nobank@example.com' with password '****'
    And I have a prepaid card with no linked bank accounts
    When I navigate to 'Load Funds' and enter amount '$50.00'
    And I attempt to submit the top-up without selecting a bank account
    Then the submission should be blocked or fail validation
    When I navigate to 'Card Details' and 'Recent Transactions'
    Then the balance should be unchanged and no new load transaction should appear

  @ui @card-details
  Scenario: Post top-up, Card Details shows updated balance and the daily limit/allowance display format
    Given I am logged in as 'test.allow1@example.com' with password '****'
    And I navigate to 'Card Details' and record the balance B0 and verify a daily limit/allowance string is visible
    When I navigate to 'Load Funds' and top up '$150.00'
    And I return to 'Card Details'
    Then the balance should equal B0 + $150.00
    And I should see a daily limit/allowance string that includes two currency amounts and the phrase 'daily limit used'

  @ui @balance
  Scenario: View current card balance equals seeded value
    Given I am logged in as 'test+bal01@example.com' with password 'TestPwd#2025!'
    When I navigate to 'Card Details'
    Then I should see current balance '$250.00'
    When I refresh 'Card Details'
    Then I should still see current balance '$250.00'

  @ui @recent-transactions
  Scenario Outline: Recent transactions list visibility and empty state handling
    Given I am logged in as '<email>' with password 'TestPwd#2025!'
    When I navigate to 'Card Details'
    And I view the 'Recent Transactions' section
    Then I should <expectation>

    Examples:
      | email                          | expectation                                                                                       |
      | test+rtx01@example.com         | see entries including amounts '10.00', '23.45', and '5.00' without errors                         |
      | test+rtxempty@example.com      | see an empty list (zero rows) without errors and no phantom items after refresh                   |

  @ui @txhistory @pagination
  Scenario Outline: Transaction history pagination boundaries and navigation to last page
    Given I am logged in as '<email>' with password '********'
    And I navigate to 'Transaction History'
    When I observe the first page
    Then I should see exactly '<page1_count>' items on page 1
    When I navigate to the last page
    Then I should see exactly '<last_page_count>' items on the last page
    And there should be '<expected_pages>' total pages
    When I attempt to navigate beyond the last page
    Then I should remain on the last page
    When I return to page 1
    Then I should again see exactly '<page1_count>' items

    Examples:
      | email                         | expected_pages | page1_count | last_page_count |
      | test+hist25@example.com       | 1              | 25          | 25              |
      | test+hist26@example.com       | 2              | 25          | 1               |
      | test+hist12@example.com       | 1              | 12          | 12              |
      | test.txhist08@example.com     | 3              | 25          | 13              |

  @ui @txhistory @navigation
  Scenario Outline: Transaction history pagination control navigation
    Given I am logged in as '<email>' with password '********'
    And I navigate to 'Transaction History'
    And I am on page 1 with 25 items
    When I use the '<control>' pagination control
    Then I should land on '<expected_page>' and see '<expected_count>' items
    And using 'Previous' on page 1 should not navigate to an earlier page

    Examples:
      | email                              | control  | expected_page | expected_count |
      | test+histnavfirst@example.com      | go to 3  | page 3        | 25             |
      | test+histnext@example.com          | Next     | page 2        | 25             |
      | test+histprev@example.com          | Previous | page 1        | 25             |

  @ui @txhistory @filters
  Scenario: Date range filter narrows transaction history
    Given I am logged in as 'test.txhist09@example.com' with password '********'
    And I navigate to 'Transaction History'
    When I set the date range filter Start '2025-09-02' and End '2025-09-03' and apply
    Then I should see only transactions dated '2025-09-02' or '2025-09-03'
    And I should see total 5 results on a single page
    When I clear filters
    Then I should see the default unfiltered first page (up to 25 items)
    When I reapply the same date range
    Then I should see the same 5 results again

  @ui @txhistory @type-filters
  Scenario Outline: Transaction type filter supports load, purchase, refund
    Given I am logged in as 'test.txhist10@example.com' with password '********'
    And I navigate to 'Transaction History'
    When I set transaction type filter to '<type>' and apply
    Then every listed item should indicate type '<type>'
    And the first page should show at most 25 items
    When I clear filters
    Then the unfiltered list (up to 25 items) should return

    Examples:
      | type     |
      | load     |
      | purchase |
      | refund   |

  @ui @txhistory @combined-filters
  Scenario: Combined date range and type filters narrow results conjunctively
    Given I am logged in as 'test.txhist11@example.com' with password '********'
    And I navigate to 'Transaction History'
    When I set Start '2025-10-02' End '2025-10-03' and set transaction type 'purchase' and apply
    Then I should see only purchase transactions dated '2025-10-02' or '2025-10-03'
    And I should see total 7 results on a single page
    When I change type to 'load' keeping the same dates and apply
    Then I should see only load transactions within '2025-10-02'..'2025-10-03'
    When I clear all filters
    Then the default first page (25 items) should return

  @ui @card-block
  Scenario Outline: Block card action is immediate and tier-agnostic
    Given I am logged in as '<user_email>' with password '********'
    And I navigate to 'Card Details' and see status 'Active'
    When I click 'Block Card' on the same screen
    Then the card status should update immediately to 'Blocked' on the same screen
    When I navigate away and return to 'Card Details'
    Then the card status should persist as 'Blocked'

    Examples:
      | user_email                         |
      | test.cblock01@example.com          |
      | test.cblock02@example.com          |
      | test.cblock03.t1@example.com       |
      | test.cblock03.t2@example.com       |

  @ui @card-details @display
  Scenario: Card details displays daily load limit and remaining allowance including example format
    Given I am logged in as 'test.cdetail02@example.com' with password '********'
    When I navigate to 'Card Details'
    Then I should see a daily load limit value (e.g., $2000.00) and a remaining allowance value
    When I log out and back in as 'test.cdetail03@example.com' with '********'
    And I navigate to 'Card Details'
    Then I should see the exact text "$500.00 / $2000.00 daily limit used"

  @ui @card-details @consistency
  Scenario: Balance displayed on Card Details matches balance on balance/transactions view
    Given I am logged in as 'test+tier2@example.com' with password 'ValidTestPwd!23'
    When I navigate to the balance/transactions view and read 'Current Balance' as BAL_A
    And I navigate to 'Card Details' and read 'Current Balance' as BAL_B
    Then BAL_A should equal BAL_B
    And I should see the daily limit/remaining allowance display on Card Details

  @ui @remittance @gating
  Scenario Outline: Send Money entry point is accessible only to Tier 2
    Given I am logged in as '<email>' with password '********'
    When I inspect dashboard/menus for 'Send Money' entry
    Then the 'Send Money' entry should be <visibility>
    When visible I open 'Send Money'
    Then the send screen should <access_outcome>
    When I log out
    Then I return to the login screen

    Examples:
      | email                    | visibility | access_outcome                             |
      | test+tier1@example.com   | hidden     | not load for Tier 1                        |
      | test+tier2@example.com   | visible    | load successfully for Tier 2               |

  @ui @remittance @send
  Scenario: Tier 2 user can send money with rate and fees disclosed; transfer appears in history with a status
    Given I am logged in as 'test+tier2@example.com' with password '********'
    When I open 'Send Money' and enter recipient "Amara Singh" (India, IN-AC-11**77**22) and amount '90.00'
    And I proceed to the review step
    Then I should see a clear exchange rate and a transaction fee before confirmation
    When I confirm the transfer
    Then the transfer should complete successfully
    When I navigate to 'Remittance History'
    Then I should see the new remittance listed with a status among 'Pending', 'Completed', or 'Failed'

  @ui @beneficiaries
  Scenario: Add beneficiary with required fields and reuse in send flow
    Given I am logged in as 'test+tier2@example.com' with password '********'
    When I navigate to 'Beneficiary Management' and add "Lina Haddad" (Morocco, MA-AC-22**11**33)
    Then I should see "Lina Haddad" in the saved beneficiaries list
    When I open 'Send Money' and select saved beneficiary "Lina Haddad" and enter amount '60.00'
    And I proceed to review
    Then I should see exchange rate and fees disclosed before confirmation
    And I cancel to avoid sending

  @ui @beneficiaries @delete
  Scenario: Delete beneficiary removes it from selection
    Given I am logged in as 'test+tier2@example.com' with password '********'
    And I have a saved beneficiary "Marco Liu" (China, CN-AC-88**22**44)
    When I delete the beneficiary "Marco Liu" from 'Beneficiary Management'
    Then "Marco Liu" should no longer appear in the saved list
    When I open 'Send Money' and open the beneficiary selector
    Then "Marco Liu" should not be available to select

  @ui @beneficiaries @negative
  Scenario Outline: Cannot save beneficiary when a required field is missing
    Given I am logged in as '<user>' with password '********'
    And I navigate to 'Beneficiary Management' and click 'Add Beneficiary'
    When I enter Full Name '<full_name>', Country '<country>', and Bank/Mobile '<account>'
    And I click 'Save'
    Then the save should be blocked and I should remain on the form
    When I return to the beneficiary list
    Then I should not see a new entry matching the attempted details

    Examples:
      | user                         | full_name | country     | account         |
      | test+t2_ben04@example.com    |           | Philippines | ****123456789   |
      | test+t2_ben05@example.com    | Asha Rao  | India       |                 |

  @ui @remittance @history
  Scenario Outline: Remittance history pagination and status visibility
    Given I am logged in as '<email>' with password '********'
    When I navigate to 'Remittance History'
    Then I should see pagination controls when more than one page exists
    And I should see entries with statuses including '<status_check>' when seeded
    When I navigate Next and Previous between pages
    Then I should see different sets of remittances without errors
    And when no remittances exist the view should show an empty state without pagination

    Examples:
      | email                          | status_check                       |
      | test+t2_hist01@example.com     | Pending or Completed or Failed     |
      | test+t2_hist02@example.com     | Pending, Completed, and Failed     |
      | test+t2_hist03@example.com     | none (empty history)               |

  # API Tests

  @api @auth @registration
  Scenario Outline: API registration and login establish Tier 1 session or reject unknown user
    Given the API base URL is '<base_url>'
    And the 'Content-Type' header is 'application/json'
    When I send a POST request to '/api/users/register' with payload:
      """
      {
        "email": "<reg_email>",
        "password": "<reg_password>"
      }
      """
    Then the response status should be <reg_status>
    And if <reg_status> is 201 the response body should contain field 'verificationStatus' with value 'Tier 1'
    When I send a POST request to '/api/auth/login' with payload:
      """
      {
        "email": "<login_email>",
        "password": "<login_password>"
      }
      """
    Then the response status should be <login_status>
    And if <login_status> is 200 the response body should contain field 'token'

    Examples:
      | base_url                 | reg_email                 | reg_password  | reg_status | login_email              | login_password | login_status |
      | https://staging.api.ep   | test+reg01@example.com    | TestPwd!234   | 201        | test+reg01@example.com   | TestPwd!234    | 200          |
      | https://staging.api.ep   |                           |               | 400        | test+auth02@example.com  | WrongPwd!000   | 401          |

  @api @profile
  Scenario Outline: API profile returns allowed verification statuses only
    Given the API base URL is '<base_url>'
    And I have a valid bearer token for '<role>'
    When I send a GET request to '/api/users/me'
    Then the response status should be 200
    And the response body should contain field 'verificationStatus' with a value in ['Tier 1','Pending','Tier 2']

    Examples:
      | base_url               | role   |
      | https://staging.api.ep | tier1  |
      | https://staging.api.ep | tier2  |

  @api @kyc
  Scenario Outline: API KYC allowed ID types and submission transitions to Pending
    Given the API base URL is '<base_url>'
    And I have a valid bearer token for 'tier1'
    When I send a GET request to '/api/kyc/id-types'
    Then the response status should be 200
    And the response body should equal the set ['passport','drivers_license']
    When I send a POST request to '/api/kyc/submissions' with payload:
      """
      {
        "idType": "<id_type>",
        "idImage": "base64:id_image_data",
        "selfieImage": "base64:selfie_image_data"
      }
      """
    Then the response status should be 202
    And the response body should contain field 'status' with value 'Pending'

    Examples:
      | base_url               | id_type          |
      | https://staging.api.ep | passport         |
      | https://staging.api.ep | drivers_license  |

  @api @cards @physical @authorization
  Scenario Outline: API physical card order is allowed for Tier 2 and forbidden for Tier 1
    Given the API base URL is '<base_url>'
    And I have a valid bearer token for '<role>'
    When I send a POST request to '/api/cards/physical/orders' with payload:
      """
      {
        "shippingAddressId": "addr_123"
      }
      """
    Then the response status should be <status>
    And if <status> is 201 the response body should contain field 'orderId'

    Examples:
      | base_url               | role  | status |
      | https://staging.api.ep | tier1 | 403    |
      | https://staging.api.ep | tier2 | 201    |

  @api @cards @virtual
  Scenario: API virtual card creation returns 201 with cardId
    Given the API base URL is 'https://staging.api.ep'
    And I have a valid bearer token for 'tier1'
    When I send a POST request to '/api/cards/virtual' with payload:
      """
      {
        "label": "My Virtual Card"
      }
      """
    Then the response status should be 201
    And the response body should contain field 'cardId'

  @api @topup
  Scenario Outline: API top-up requires a linked bank account and creates a transaction when valid
    Given the API base URL is '<base_url>'
    And I have a valid bearer token for '<role>'
    When I send a POST request to '/api/cards/<card_id>/topups' with payload:
      """
      {
        "amount": 10000,
        "currency": "USD",
        "bankLinkId": <bank_link_id>
      }
      """
    Then the response status should be <expected_status>

    Examples:
      | base_url               | role  | card_id  | bank_link_id | expected_status |
      | https://staging.api.ep | user  | card_001 | 12345        | 201             |
      | https://staging.api.ep | user  | card_001 | null         | 400             |

  @api @transactions @pagination @filters
  Scenario Outline: API transactions list supports 25-per-page pagination and filters
    Given the API base URL is '<base_url>'
    And I have a valid bearer token for 'user'
    When I send a GET request to '/api/cards/<card_id>/transactions?type=<type>&startDate=<start>&endDate=<end>&page=<page>&pageSize=25'
    Then the response status should be 200
    And the response body should contain exactly <expected_count> items
    And each item type should equal '<type>' when type is not 'all'

    Examples:
      | base_url               | card_id  | type     | start       | end         | page | expected_count |
      | https://staging.api.ep | card_001 | all      |             |             | 1    | 25             |
      | https://staging.api.ep | card_001 | all      |             |             | 3    | 13             |
      | https://staging.api.ep | card_001 | load     | 2025-09-02  | 2025-09-03  | 1    | 5              |
      | https://staging.api.ep | card_001 | purchase | 2025-10-02  | 2025-10-03  | 1    | 7              |

  @api @cards @block
  Scenario: API block card sets status to blocked immediately
    Given the API base URL is 'https://staging.api.ep'
    And I have a valid bearer token for 'user'
    When I send a POST request to '/api/cards/card_001/block' with payload:
      """
      {
        "reason": "user_requested"
      }
      """
    Then the response status should be 200
    And the response body should contain field 'status' with value 'blocked'

  @api @remittance @authorization @history
  Scenario Outline: API remittance create authorization and history pagination with statuses
    Given the API base URL is '<base_url>'
    And I have a valid bearer token for '<role>'
    When I send a POST request to '/api/remittances' with payload:
      """
      {
        "beneficiaryId": "ben_123",
        "sourceAmount": 10000,
        "sourceCurrency": "USD"
      }
      """
    Then the response status should be <create_status>
    When I send a GET request to '/api/remittances?status=<hist_status>&page=1&pageSize=25'
    Then the response status should be 200

    Examples:
      | base_url               | role  | create_status | hist_status  |
      | https://staging.api.ep | tier1 | 403           |              |
      | https://staging.api.ep | tier2 | 201           | Pending      |
      | https://staging.api.ep | tier2 | 201           | Completed    |
      | https://staging.api.ep | tier2 | 201           | Failed       |
