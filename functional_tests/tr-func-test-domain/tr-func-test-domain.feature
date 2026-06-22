Feature: EvolvePay onboarding, compliance, cards, funding, transactions, and remittance

  # UI Tests

  @ui @registration @authentication @tier
  Scenario Outline: Registration creates account and defaults to Tier 1
    Given I am on the Registration page with a clean session
    When I enter email "<email>" and password "<password>" and submit the registration form
    Then I should see a success indication or be redirected to Sign In
    When I navigate to Sign In and authenticate with "<email>" and "<password>"
    Then I should land on the dashboard
    When I navigate to the Profile page
    Then I should see the verification status displayed as "Tier 1"
    And I should not see any Tier 2 indicators
    When I refresh the Profile page
    Then the verification status should persist as "Tier 1"
    And I log out and should return to the login screen

    Examples:
      | email                     | password        |
      | test+reg01@example.com    | S3cure!Pass01   |
      | test+reg02@example.com    | S3cure!Pass02   |

  @ui @authentication @tier
  Scenario Outline: Secure login displays correct verification status by tier
    Given I am on the Login page
    When I sign in with "<email>" and "<password>"
    Then I should land on the dashboard
    When I open Profile
    Then I should see verification status "<expectedStatus>"
    And I navigate away and back to Profile
    Then the verification status should remain "<expectedStatus>"
    And I log out successfully

    Examples:
      | email                      | password        | expectedStatus |
      | test+auth01@example.com    | S3cure!Pass01   | Tier 1         |
      | test+auth02@example.com    | S3cure!Pass02   | Tier 2         |

  @ui @kyc @uploads @state-transition
  Scenario Outline: KYC submission with supported ID and selfie sets status to Pending
    Given I am logged in as "<email>" with password "<password>" and current profile status is Tier 1
    When I navigate to the KYC submission screen
    And I select ID type "<idType>"
    And I upload the ID image file "<idImage>"
    And I upload the selfie image file "<selfieImage>"
    And I click Submit on the KYC form
    Then I should see a submission confirmation
    When I navigate to Profile
    Then the verification status should be "Pending"
    And I log out successfully

    Examples:
      | email                      | password        | idType           | idImage                 | selfieImage         |
      | test+kyc01@example.com     | S3cure!Pass01   | passport         | passport_kyc01.jpg      | selfie_kyc01.jpg    |
      | test+kyc02@example.com     | S3cure!Pass02   | driver's license | drivers_license_kyc02.png | selfie_kyc02.png  |

  @ui @kyc @negative @validation
  Scenario: Only supported ID types are accepted (passport, driver's license)
    Given I am logged in as "test+kyc03@example.com" with password "S3cure!Pass03"
    When I open the KYC submission screen
    And I open the ID type selector
    Then I should see only the options "passport" and "driver's license"
    When I upload "id_doc_tmp.jpg" without selecting an ID type
    And I upload "selfie_tmp.jpg"
    And I click Submit
    Then I should see an error that a supported ID type is required and submission is blocked
    When I select ID type "passport"
    And I click Submit
    Then the submission should succeed
    When I open Profile
    Then the verification status should be "Pending"

  @ui @kyc @negative @required
  Scenario: Selfie is mandatory for KYC submission
    Given I am logged in as "test+kyc04@example.com" with password "S3cure!Pass04"
    When I open the KYC submission screen
    And I select ID type "passport"
    And I upload the ID image file "passport_only.jpg"
    And I leave the selfie field empty
    And I click Submit
    Then I should see an error indicating selfie is required and no status change occurs
    When I upload the selfie image file "selfie_required.jpg"
    And I click Submit
    Then I should see a successful submission
    When I open Profile
    Then the verification status should be "Pending"

  @ui @kyc @state-transition
  Scenario: KYC lifecycle transitions Tier 1 -> Pending -> Tier 2
    Given I am logged in as "test+kyc05@example.com" with password "S3cure!Pass05"
    When I open Profile
    Then I should see verification status "Tier 1"
    When I navigate to KYC submission and select "driver's license" and upload "dl_kyc05.jpg" and "selfie_kyc05.jpg" and submit
    Then I should see KYC submission success
    When I open Profile
    Then I should see verification status "Pending"
    When I periodically refresh Profile after external verification completes
    Then the verification status should update to "Tier 2"

  @ui @cards @virtual @authorization
  Scenario Outline: Apply for a virtual prepaid card by tier
    Given I am logged in as "<email>" with password "<password>"
    When I navigate to Card Management
    And I click "Apply for Virtual Card"
    Then a virtual card should be created and visible in my card list
    When I open the new virtual card details
    Then the card type should be "virtual"
    And I log out

    Examples:
      | email                          | password       |
      | tier1_user+vcard01@example.com | P@ssw0rd!123   |

  @ui @cards @physical @authorization
  Scenario Outline: Physical card ordering authorization by tier
    Given I am logged in as "<email>" with password "<password>"
    When I navigate to Card Management
    And I attempt to "Order Physical Card"
    Then the physical card order should be "<expectedOutcome>"
    And if "<expectedOutcome>" is "accepted" I should see an order confirmation and a physical card/order entry
    And if "<expectedOutcome>" is "blocked" I should see an authorization denial and no physical card/order entry exists even after refresh
    And I log out

    Examples:
      | email                           | password      | expectedOutcome |
      | tier1_user+pcard02@example.com  | P@ssw0rd!123  | blocked         |
      | tier2_user+pcard01@example.com  | P@ssw0rd!123  | accepted        |

  @ui @topup @balance @transactions
  Scenario Outline: User top-up from linked bank account updates balance and recent transactions
    Given I am logged in as "<email>" with password "<password>"
    And I have an active virtual card (create one if none exists)
    When I start the Load/Top-up flow
    And I enter amount "<amount>" and select the linked bank account and confirm
    Then the top-up should succeed without error
    When I view the card balance
    Then the balance should increase by "<amount>" relative to the baseline
    When I open recent transactions
    Then I should see a "load" transaction for "<amount>" visible
    And I log out

    Examples:
      | email                              | password      | amount  |
      | tier2_user+topup01@example.com     | P@ssw0rd!123  | 50.00   |
      | tier1_user+topup02@example.com     | P@ssw0rd!123  | 25.00   |

  @ui @history @pagination @boundary
  Scenario Outline: Transaction history shows fixed page size with boundary totals
    Given I am logged in as "<email>" with password "<password>"
    And I navigate to Transaction History
    And I ensure all filters are cleared
    When I count the number of visible rows on page 1
    Then I should see exactly <expectedPage1Count> rows on page 1
    When I navigate to page 2 if available
    Then I should see exactly <expectedPage2Count> rows on page 2 (or 0 if no page 2)
    And I log out

    Examples:
      | email                    | password     | expectedPage1Count | expectedPage2Count |
      | test.hist03@example.com | any-pass     | 0                   | 0                  |
      | test.hist01@example.com | any-pass     | 25                  | 0                  |
      | test.hist02@example.com | any-pass     | 25                  | 1                  |
      | test.hist04@example.com | any-pass     | 25                  | 25                 |

  @ui @history @filtering @type
  Scenario Outline: Filter transaction history by type
    Given I am logged in as "<email>" with password "<password>"
    And I navigate to Transaction History
    And I clear any existing filters
    When I open the Type filter and select "<type>"
    And I apply the filter
    Then every visible transaction row should have Type "<type>"
    When I clear the filter
    Then the full mixed list should be visible
    And I log out

    Examples:
      | email                    | password  | type     |
      | test.hist05@example.com  | any-pass  | load     |
      | test.hist06@example.com  | any-pass  | purchase |
      | test.hist07@example.com  | any-pass  | refund   |

  @ui @history @filtering @date
  Scenario: Filter transaction history by a date range
    Given I am logged in as "test.hist08@example.com" with password "any-pass"
    And I navigate to Transaction History
    When I open Date Range filter and set Start "2025-10-10" and End "2025-10-20"
    And I apply the filter
    Then every visible row should have a transaction date between "2025-10-10" and "2025-10-20" inclusive
    When I clear the date filter
    Then the full list should return
    And I log out

  @ui @history @filtering @combined @pagination
  Scenario: Combine date range and type filters with fixed pagination size
    Given I am logged in as "test.tier2@example.com" with password "any-pass"
    And I navigate to Transaction History
    When I set Date Range Start "2025-10-01" and End "2025-10-31"
    And I set Type filter to "purchase" and apply
    Then every visible transaction should have Type "purchase" and date within "2025-10-01" to "2025-10-31"
    When I count items on page 1
    Then I should see exactly 25 items on page 1
    When I go to page 2
    Then I should see exactly 1 item on page 2
    And I clear filters

  @ui @cards @block @state-transition
  Scenario Outline: Card state changes to blocked immediately after block action
    Given I am logged in as "<email>" with password "<password>"
    And I have an active virtual card visible in Card Management
    When I open the card details and confirm its status is "active"
    And I select "Block card" and confirm
    Then the card status in details should immediately show "blocked"
    When I return to Card Management
    Then the same card should be labeled "blocked" in the list
    And I refresh the details view
    Then the status should persist as "blocked"
    And I log out

    Examples:
      | email                 | password     |
      | test.tier1@example.com| any-pass     |
      | test.tier2@example.com| any-pass     |

  @ui @limits @display @boundary
  Scenario Outline: Daily load limit used/remaining display across boundaries and cumulative updates
    Given I am logged in as "test.tier2@example.com" with password "any-pass"
    And I have an active virtual card
    When I navigate to Card Details
    Then I should see the daily limit indicator in the format "$X.XX / $2000.00 daily limit used"
    When I perform a top-up of "<firstAmount>" from a linked bank account (or $0.00 if "<firstAmount>" is 0.00)
    And I return to Card Details
    Then the "used" value should be "$<expectedAfterFirst> / $2000.00 daily limit used"
    And if "<secondAmount>" is not empty I perform a second top-up of "<secondAmount>"
    And if "<secondAmount>" is not empty I return to Card Details
    Then if "<secondAmount>" is not empty the "used" value should be "$<expectedAfterSecond> / $2000.00 daily limit used"
    And I log out

    Examples:
      | firstAmount | expectedAfterFirst | secondAmount | expectedAfterSecond |
      | 0.00        | 0.00               |              |                     |
      | 300.00      | 300.00             |              |                     |
      | 999.00      | 999.00             | 1000.00      | 1999.00             |
      | 1500.00     | 1500.00            | 500.00       | 2000.00             |
      | 300.00      | 300.00             | 150.00       | 450.00              |

  @ui @remittance @tier-gating @fees @rate
  Scenario: Tier 2 user can send remittance with pre-confirmation rate and fees visible
    Given I am logged in as "tier2.sender+001@example.com" with password "any-pass"
    And my Profile shows verification status "Tier 2"
    When I navigate to International Remittance (Send Money)
    And I choose existing beneficiary "Aisha Khan"
    And I enter transfer amount "100.00" USD and proceed to review
    Then I should see both exchange rate and transaction fees visible before confirmation
    When I confirm/send the transfer
    Then I should see an on-screen confirmation
    When I open Remittance History
    Then I should see a new entry for this transfer with status in {"Pending","Completed","Failed"}
    And I record the transfer reference if displayed

  @ui @remittance @negative @authorization
  Scenario: Tier 1 user cannot initiate international remittance
    Given I am logged in as "tier1.user+002@example.com" with password "any-pass"
    And my Profile shows verification status "Tier 1"
    When I navigate to International Remittance (Send Money)
    Then I should not be able to start a new transfer (no initiation control or access denied)
    And I should not see exchange rate or fee previews
    When I open Remittance History
    Then no new entries should exist from this attempt
    And I refresh and re-check access
    Then the restriction should persist

  @ui @beneficiaries @crud
  Scenario Outline: Add beneficiary for Bank Account or Mobile Money and verify persistence
    Given I am logged in as "<email>" with password "any-pass"
    When I navigate to Beneficiary Management
    And I click "Add Beneficiary"
    And I enter Full Name "<fullName>" and Country "<country>"
    And I enter "<payoutField>" value "<payoutValue>" and leave the other payout method blank
    And I save the beneficiary
    Then I should see a success indication
    When I return to the list
    Then I should see "<fullName>" with Country "<country>" and masked "<payoutField>" visible
    When I open the beneficiary details
    Then the saved values should match input
    And I refresh the page
    Then the beneficiary should persist in the list
    And I log out

    Examples:
      | email                         | fullName        | country     | payoutField   | payoutValue   |
      | bene.tester+001@example.com   | Maria Gomez     | Philippines | Bank Account  | ****1289      |
      | bene.tester+002@example.com   | Abena Mensah    | Ghana       | Mobile Money  | MM****5577    |

  @ui @beneficiaries @delete @state-cleanup
  Scenario: Delete beneficiary and verify removal and unavailability for send
    Given I am logged in as "bene.tester+004@example.com" with password "any-pass"
    And I have a beneficiary "Omar Faruk" with Country "Bangladesh" and Mobile Money "MM****2244" saved
    When I delete beneficiary "Omar Faruk" and confirm
    Then I should see a deletion success indication
    And "Omar Faruk" should no longer appear in the Beneficiary list
    When I navigate to International Remittance and open the beneficiary selector
    Then "Omar Faruk" should not be listed
    And I refresh Beneficiaries
    Then the deletion should persist

  # UI End-to-End Tests

  @ui @e2e @kyc @physical-card
  Scenario: Register -> Login -> KYC -> Tier 2 -> Order physical card
    Given I am on the Registration page with a clean session
    When I register a new account "test+e2e01@example.com" with password "Any!Pass123"
    Then I should be signed in and Profile shows "Tier 1"
    When I log out and sign back in with "test+e2e01@example.com" and "Any!Pass123"
    And I navigate to KYC, select "passport", upload masked ID "P<TEST>****" and selfie, and submit
    Then Profile should show "Pending"
    When I periodically refresh Profile until status updates
    Then Profile should show "Tier 2"
    When I navigate to Card Management and choose "Order physical prepaid card" and confirm
    Then I should see an order success confirmation
    And Card Management should show a physical card/order entry as placed

  @ui @e2e @virtual-card @topup @limits @history @block
  Scenario: Apply virtual card -> Top-up -> Validate limit -> History -> Block card
    Given I am logged in as "test+e2e02@example.com" with password "any-pass"
    When I apply for a new virtual card
    Then I should see the virtual card in my list
    When I top up $150.00 from my linked bank account
    Then the top-up should succeed and balance should increase by $150.00
    When I open Card Details
    Then I should see current balance and a daily limit indicator like "$X / $2000.00 daily limit used"
    When I open Transaction History and set filters type "load" and date range = today..today
    Then page 1 should show exactly 25 items and a Next Page control
    When I go to page 2
    Then I should see remaining "load" items for today
    When I return to Card Management and block the card
    Then the card should immediately show status "blocked"
    When I attempt another top-up
    Then the top-up action should not be permitted while blocked

  @ui @e2e @remittance @beneficiaries @fees @rate @history
  Scenario: Add beneficiary -> Send remittance -> View rate/fees -> Confirm -> History status
    Given I am logged in as "test+e2e03@example.com" with password "any-pass" and Profile shows "Tier 2"
    When I add beneficiary "Juan Perez" Country "Mexico" Bank "MX88****4321"
    Then I should see "Juan Perez" in my beneficiary list
    When I start a new remittance to "Juan Perez" for $100.00
    Then I should see exchange rate and transaction fees before confirmation
    When I confirm the transfer
    Then I should see a submission confirmation with a transfer reference
    When I open Remittance History
    Then the new transfer should appear with status "Pending"
    When I refresh/wait for processing
    Then the status should update to "Completed"
    When I delete beneficiary "Juan Perez"
    Then "Juan Perez" should no longer appear in the beneficiary list

  # API Tests

  @api @registration @authentication @tier
  Scenario Outline: API - Register and login yields Tier 1 profile
    Given the API base URL is "https://api.evolvepay.test"
    When I send a POST request to "/api/auth/register" with payload
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    Then the response status should be 201
    And the response should contain "id"
    When I send a POST request to "/api/auth/login" with payload
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    Then the response status should be 200
    And I store "token" from the response as "authToken"
    When I send a GET request to "/api/users/me" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 200
    And the response field "verificationStatus" should equal "Tier 1"

    Examples:
      | email                   | password      |
      | test+reg01@example.com  | S3cure!Pass01 |
      | test+reg02@example.com  | S3cure!Pass02 |

  @api @kyc @state-transition
  Scenario Outline: API - KYC submission sets status to Pending for supported ID types
    Given the API base URL is "https://api.evolvepay.test"
    And I have a Tier 1 user token "authToken" obtained by logging in as "<email>" with "<password>"
    When I send a POST request to "/api/kyc/submissions" with header "Authorization: Bearer {{authToken}}" and payload
      """
      {
        "idType": "<idType>",
        "idImage": "base64:<idImageB64>",
        "selfieImage": "base64:<selfieB64>"
      }
      """
    Then the response status should be 202
    When I send a GET request to "/api/users/me" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 200
    And the response field "verificationStatus" should equal "Pending"

    Examples:
      | email                  | password      | idType           | idImageB64   | selfieB64   |
      | test+kyc01@example.com | S3cure!Pass01 | passport         | aGVsbG8x     | c2VsZmllMQ==|
      | test+kyc02@example.com | S3cure!Pass02 | driver's license | aGVsbG8y     | c2VsZmllMg==|

  @api @kyc @negative @validation
  Scenario Outline: API - KYC validation errors for missing selfie or unsupported idType
    Given the API base URL is "https://api.evolvepay.test"
    And I have a Tier 1 user token "authToken" obtained by logging in as "<email>" with "<password>"
    When I send a POST request to "/api/kyc/submissions" with header "Authorization: Bearer {{authToken}}" and payload
      """
      {
        "idType": "<idType>",
        "idImage": "base64:SUQ=",
        "selfieImage": <selfieField>
      }
      """
    Then the response status should be <status>
    And the response should contain "<errorField>"

    Examples:
      | email                  | password      | idType           | selfieField | status | errorField          |
      | test+kyc04@example.com | S3cure!Pass04 | passport         | null        | 400    | selfieImage         |
      | test+kyc03@example.com | S3cure!Pass03 | national_id      | "base64:QQ==" | 400  | idType              |

  @api @cards @authorization
  Scenario Outline: API - Card creation/ordering authorization by tier
    Given the API base URL is "https://api.evolvepay.test"
    And I have a user token "authToken" obtained by logging in as "<email>" with "<password>"
    When I send a POST request to "<endpoint>" with header "Authorization: Bearer {{authToken}}" and payload
      """
      <payload>
      """
    Then the response status should be <expectedStatus>
    And if <expectedStatus> = 201 the response should contain "<successField>"

    Examples:
      | email                           | password      | endpoint                 | payload                                         | expectedStatus | successField |
      | tier1_user+vcard01@example.com  | P@ssw0rd!123  | /api/cards               | {"type":"virtual"}                              | 201            | cardId       |
      | tier2_user+pcard01@example.com  | P@ssw0rd!123  | /api/cards/physical-orders | {"shippingAddress":"on-file"}                 | 201            | orderId      |
      | tier1_user+pcard02@example.com  | P@ssw0rd!123  | /api/cards/physical-orders | {"shippingAddress":"on-file"}                 | 403            | null         |

  @api @topup @transactions
  Scenario Outline: API - Top-up succeeds and transaction recorded
    Given the API base URL is "https://api.evolvepay.test"
    And I have a user token "authToken" obtained by logging in as "<email>" with "<password>"
    And I have a virtual card "cardId" by creating one if none exists via POST "/api/cards"
    When I send a POST request to "/api/cards/{{cardId}}/topups" with header "Authorization: Bearer {{authToken}}" and payload
      """
      {
        "amount": <amount>,
        "source": "linked_bank"
      }
      """
    Then the response status should be 201
    And I store "topupId" from the response as "topupId"
    When I send a GET request to "/api/cards/{{cardId}}/transactions?type=load&sort=desc" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 200
    And the response list should contain an item where "type"="load" and "amount"=<amount>

    Examples:
      | email                          | password      | amount |
      | tier2_user+topup01@example.com | P@ssw0rd!123  | 50.00  |
      | tier1_user+topup02@example.com | P@ssw0rd!123  | 25.00  |

  @api @transactions @pagination @filtering
  Scenario Outline: API - Transaction history pagination and type filtering returns <= 25 per page
    Given the API base URL is "https://api.evolvepay.test"
    And I have a user token "authToken" obtained by logging in as "<email>" with "<password>"
    And I have a virtual card "cardId"
    When I send a GET request to "/api/cards/{{cardId}}/transactions?type=<type>&page=<page>&pageSize=25" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 200
    And the number of items in the response should be <= 25
    And every item should have "type"="<type>"

    Examples:
      | email                    | password | type     | page |
      | test.hist05@example.com | any-pass | load     | 1    |
      | test.hist06@example.com | any-pass | purchase | 1    |
      | test.hist07@example.com | any-pass | refund   | 1    |

  @api @transactions @filtering @date
  Scenario: API - Date range filter returns only in-range transactions
    Given the API base URL is "https://api.evolvepay.test"
    And I have a user token "authToken" obtained by logging in as "test.hist08@example.com" with "any-pass"
    And I have a virtual card "cardId"
    When I send a GET request to "/api/cards/{{cardId}}/transactions?startDate=2025-10-10&endDate=2025-10-20&page=1&pageSize=25" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 200
    And every item should have "date" between "2025-10-10" and "2025-10-20"

  @api @cards @block @state-transition
  Scenario: API - Block card updates status immediately
    Given the API base URL is "https://api.evolvepay.test"
    And I have a user token "authToken" obtained by logging in as "test.tier2@example.com" with "any-pass"
    And I have an active virtual card "cardId"
    When I send a POST request to "/api/cards/{{cardId}}/block" with header "Authorization: Bearer {{authToken}}" and payload
      """
      { "reason": "user_request" }
      """
    Then the response status should be 200
    When I send a GET request to "/api/cards/{{cardId}}" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 200
    And the response field "status" should equal "blocked"

  @api @remittance @quote @fees @rate
  Scenario: API - Remittance quote shows exchange rate and fee before sending
    Given the API base URL is "https://api.evolvepay.test"
    And I have a Tier 2 user token "authToken" obtained by logging in as "tier2.sender+001@example.com" with "any-pass"
    And I have an existing beneficiary "beneficiaryId" for this user
    When I send a GET request to "/api/remittances/quote?beneficiaryId={{beneficiaryId}}&amount=100.00&currency=USD" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 200
    And the response should contain "exchangeRate"
    And the response should contain "fee"

  @api @remittance @authorization
  Scenario Outline: API - Remittance initiation allowed only for Tier 2
    Given the API base URL is "https://api.evolvepay.test"
    And I have a user token "authToken" obtained by logging in as "<email>" with "<password>"
    And I have an existing beneficiary "beneficiaryId" for this user (or none for Tier 1 if blocked)
    When I send a POST request to "/api/remittances" with header "Authorization: Bearer {{authToken}}" and payload
      """
      {
        "beneficiaryId": "{{beneficiaryId}}",
        "amount": 100.00,
        "currency": "USD"
      }
      """
    Then the response status should be <expectedStatus>
    And if <expectedStatus> = 201 the response should contain "transferId" and "status" in ["Pending","Completed","Failed"]

    Examples:
      | email                         | password     | expectedStatus |
      | tier1.user+002@example.com    | any-pass     | 403            |
      | tier2.sender+001@example.com  | any-pass     | 201            |

  @api @beneficiaries @crud
  Scenario: API - Add, list, and delete beneficiary
    Given the API base URL is "https://api.evolvepay.test"
    And I have a Tier 2 user token "authToken" obtained by logging in as "bene.tester+001@example.com" with "any-pass"
    When I send a POST request to "/api/beneficiaries" with header "Authorization: Bearer {{authToken}}" and payload
      """
      {
        "fullName": "Maria Gomez",
        "country": "PH",
        "bankAccount": "****1289"
      }
      """
    Then the response status should be 201
    And I store "id" from the response as "beneficiaryId"
    When I send a GET request to "/api/beneficiaries" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 200
    And the response list should contain an item where "id"="{{beneficiaryId}}" and "fullName"="Maria Gomez"
    When I send a DELETE request to "/api/beneficiaries/{{beneficiaryId}}" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 204
    When I send a GET request to "/api/beneficiaries" with header "Authorization: Bearer {{authToken}}"
    Then the response status should be 200
    And the response list should not contain an item where "id"="{{beneficiaryId}}"
