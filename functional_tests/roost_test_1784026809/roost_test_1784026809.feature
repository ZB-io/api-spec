Feature: Inward SWIFT MX processing, validation, repair/authorization, and cross-channel visibility

  # The requirements are predominantly UI-driven across Back-Office (TCS BANCS), Branch, and Mobile applications.
  # Limited API scenarios are inferred to add meaningful coverage for file creation, upload, and message ingestion status.
  # DATA-INCONSISTENCY NOTE: Source mixes MX pacs.008 flow with MT103 terminology and ABA (USA) in a GBP context; preserved as-is where referenced.

  @ui @readiness @high @P1
  Scenario: Environment readiness - MX messages enabled and core BO navigation accessible
    Given I acknowledge the precondition "MX messages should be enabled for Inward SWIFT transfer"
    And I launch the TCS BANCS application
    When I log in as a valid BO user
    And I navigate to "Service Indicator > Messages"
    Then I should see the "Messages" screen without error
    And I should see at least one historical MX message for incoming SWIFT
    When I navigate to "Credit transfer > Payments List"
    Then I should see the "Payments List" screen without error
    And I conclude that MX messages are enabled and core navigation is operational

  # API Tests
  @api @creation @upload @P1
  Scenario Outline: API - Create and upload inward SWIFT file, then verify message ingestion presence
    Given the API base URL is "<base_url>"
    And the authorization token is set
    When I send a <method> request to "<endpoint>" with payload "<payload>"
    Then the response status should be <status>
    And the response should contain "<field>"
    And the response JSON at path "<json_path>" should equal "<expected_value>"

    Examples:
      | base_url               | method | endpoint                                         | payload                                                                                                                                                   | status | field  | json_path           | expected_value |
      | https://api.test.local | POST   | /api/inward-swift/files                          | {"currency":"GBP","amount":1250.75,"beneficiaryAccount":"GB29NWBK60161331926819","abaCode":"999999999","correspondentBic":"TESTGB2LXXX"}                 | 201    | id     | currency            | GBP           |
      | https://api.test.local | POST   | /api/inward-swift/files/FILE123/upload           | {}                                                                                                                                                        | 202    | status | status              | ACCEPTED      |
      | https://api.test.local | GET    | /api/inward-swift/messages?fileRef=FILE123       | {}                                                                                                                                                        | 200    | items  | items[0].direction  | INWARD        |

  @api @validation @P0
  Scenario Outline: API - Workitem validations list includes required parameters
    Given the API base URL is "<base_url>"
    And the authorization token is set
    When I send a GET request to "/api/inward-swift/workitems/<workitemId>/validations" with payload "{}"
    Then the response status should be 200
    And the response should contain "validations"
    And the response JSON at path "validations[*].name" should contain "<validation_text>"

    Examples:
      | base_url               | workitemId | validation_text                                |
      | https://api.test.local | WI-10001   | Correspondent BIC as sender of MT103           |
      | https://api.test.local | WI-10001   | Correspondent account for Transfer currency    |
      | https://api.test.local | WI-10001   | Valid Beneficiary Account in IBAN format       |
      | https://api.test.local | WI-10001   | Valid Beneficiary Account                      |
      | https://api.test.local | WI-10001   | Valid Beneficiary Account Status               |
      | https://api.test.local | WI-10001   | AML scanning                                   |

  # BO UI - Authentication and Navigation
  @ui @login @navigation @P1
  Scenario: BO user login and core navigation across Payments List, Messages, and Workitem summary
    Given I launch the TCS BANCS application
    When I log in as a valid BO user
    And I navigate to "Credit transfer > Payments List"
    Then I should see the "Payments List" screen
    When I navigate to "Service Indicator > Messages"
    Then I should see the "Messages" screen
    When I navigate to "Workitem summary list"
    Then I should see the "Workitem summary" list

  # BO UI - File creation and upload (preconditions for validations)
  @ui @file @upload @P1
  Scenario: Create inward SWIFT file with ABA and upload successfully
    Given I have access to the inward SWIFT file creation interface
    When I enter correct file details including currency "GBP", amount "1250.75", beneficiary account "GB29NWBK60161331926819"
    And I enter the ABA code of USA "999999999"
    And I save the file for creation
    Then the file should be created successfully
    When I upload the created file
    Then the upload should complete successfully without errors

  # BO UI - Message receipt after upload
  @ui @receipt @P0
  Scenario: Verify inward SWIFT message is received post-upload
    Given I am logged in to TCS BANCS as a valid BO user
    And I navigate to "Credit transfer > Payments List"
    When I check if inward SWIFT messages are received
    Then I should see an inward SWIFT message received from SWIFT
    And I optionally record the message reference for traceability

  # BO UI - Workitem selection
  @ui @workitem @P1
  Scenario: Navigate to Workitem summary and select incoming SWIFT transfer
    Given I am logged in to TCS BANCS as a valid BO user
    And an inward SWIFT message exists to act upon
    When I navigate to "Workitem summary list"
    And I locate the incoming SWIFT transfer
    And I select the incoming SWIFT transfer
    Then the selected workitem should open and be in focus

  # BO UI - Validation presence checks (positive visibility)
  @ui @validation @P0
  Scenario Outline: Verify required validations are present in Workitem
    Given I am viewing the selected incoming SWIFT transfer in Workitem summary
    When I review the validations applied to the message
    Then I should see the validation "<validation_text>" listed

    Examples:
      | validation_text                             |
      | Correspondent BIC as sender of MT103        |
      | Correspondent account for Transfer currency |
      | Valid Beneficiary Account in IBAN format    |
      | Valid Beneficiary Account                   |
      | Valid Beneficiary Account Status            |
      | AML scanning                                |

  # BO UI - Negative validations leading to Repair awaited
  @ui @validation @negative @P0
  Scenario Outline: Validation failure routes the item to Repair awaited and allows repair
    Given I am viewing the selected incoming SWIFT transfer in Workitem summary
    When I introduce a "<failure_trigger>" on the item
    And I re-validate the item
    Then I should see the item status as "Repair awaited"
    And the Modify action should be available to initiate repair

    Examples:
      | failure_trigger                                 |
      | Mismatched Correspondent BIC (sender of MT103)  |
      | Invalid Correspondent account for currency      |
      | Invalid IBAN format                             |
      | Invalid Beneficiary Account                     |
      | Invalid Beneficiary Account Status              |
      | AML scanning flagged findings                   |

  # BO UI - Repair (Modify) enablement
  @ui @repair @P0
  Scenario: Initiate repair via Modify when in Repair awaited
    Given the selected inward SWIFT message status is "Repair awaited"
    When I click "Modify" on the workitem
    Then the item should enter repair mode
    And fields required for correction should be enabled

  # BO UI - Repair to Authorization and Approval to Success
  @ui @authorization @P0
  Scenario Outline: Repair, authorize, and confirm successful incoming SWIFT transaction
    Given I have opened the item in repair mode
    When I apply the necessary corrections for "<correction_context>" and save
    And I initiate the authorization action
    Then the transfer should be approved
    And the incoming SWIFT transaction should be successful

    Examples:
      | correction_context                               |
      | Correspondent BIC alignment                       |
      | Correspondent account for currency correction     |
      | IBAN format correction                            |
      | Beneficiary account correction                    |
      | Beneficiary account status correction             |
      | AML scanning remediation                          |

  # BO UI - Messages screen (post-authorization observability)
  @ui @messages @P0
  Scenario: Verify MX message presence under Service Indicator > Messages
    Given the incoming SWIFT transaction is successful
    And I am logged in to TCS BANCS as a valid BO user
    When I navigate to "Service Indicator > Messages"
    Then I should see the MX message corresponding to the processed incoming SWIFT
    And I capture message evidence for audit

  # Branch UI - Login and customer selection
  @ui @branch @login @P1
  Scenario Outline: Branch user login and customer selection
    Given I launch the Branch application
    When I log in as "<username>" with password "<password>"
    Then I should land on the branch dashboard
    When I search for Customer ID "<customerId>"
    And I select the customer from results
    Then I should be in the customer context view with demand accounts visible
    When I sign out from branch
    Then I should see the login screen

    Examples:
      | username       | password  | customerId    |
      | branch.user01  | ********  | CUST-GB-0001  |

  # Branch UI - Demand account visibility of SWIFT posting
  @ui @branch @recon @P0
  Scenario: Verify SWIFT transaction entry is available in the customer demand account
    Given the incoming SWIFT transaction is successful
    And I am logged in to the Branch application as "branch.user01"
    And I have selected customer "CUST-GB-0001"
    When I navigate to the customer's demand account transactions
    Then I should see the SWIFT transaction entry in the list
    And I capture audit evidence of the entry

  # Mobile UI - Login
  @ui @mobile @login @P2
  Scenario Outline: Mobile user login
    Given I launch the Mobile application
    When I log in as "<username>" with password "<password>"
    Then I should see the mobile home/dashboard
    And I should be able to access the account overview
    When I log out from mobile
    Then I should see the mobile login screen

    Examples:
      | username    | password |
      | mb.user01   | ******** |

  # Mobile UI - Transaction visibility
  @ui @mobile @recon @P0
  Scenario: Verify SWIFT transaction entry is available in the mobile application
    Given the incoming SWIFT transaction is successful
    And I am logged in to the Mobile application as "mb.user01"
    When I open the relevant demand account transactions
    Then I should see the SWIFT transaction entry in mobile
    And I capture audit evidence of the entry

  # E2E consolidation - up to Repair awaited
  @ui @e2e @P0
  Scenario: End-to-end flow to Repair awaited in Workitem
    Given I create an inward SWIFT file with correct details including ABA code "999999999"
    And I upload the file successfully
    And I log in to TCS BANCS as a valid BO user
    And I navigate to "Credit transfer > Payments List" and confirm inward SWIFT receipt
    When I open the Workitem summary and select the incoming transfer
    And I review the listed validations
    Then the item status should be "Repair awaited"

  # E2E consolidation - repair and authorization to success
  @ui @e2e @P0
  Scenario: End-to-end repair via Modify and authorization to successful incoming SWIFT
    Given an inward SWIFT workitem is in "Repair awaited" status
    When I click "Modify", perform the required corrections, and save
    And I authorize the transfer
    Then the transfer should be approved
    And the incoming SWIFT transaction should be successful

  # E2E consolidation - observability in Messages
  @ui @e2e @messages @P0
  Scenario: End-to-end confirmation of MX message presence under Messages
    Given the incoming SWIFT transaction is successful
    When I navigate to "Service Indicator > Messages" in TCS BANCS
    Then I should see the MX message received for the incoming SWIFT
    And I record the message evidence for reconciliation

  # Cross-channel reconciliation - BO to Branch
  @ui @reconciliation @branch @P0
  Scenario: Reconcile BO successful transaction with Branch demand account entry
    Given the incoming SWIFT transaction is successful in BO
    And I have logged in to the Branch application and selected customer "CUST-GB-0001"
    When I open the customer's demand account transactions
    Then the SWIFT transaction entry should be available in the Branch demand account

  # Cross-channel reconciliation - BO to Mobile
  @ui @reconciliation @mobile @P0
  Scenario: Reconcile BO successful transaction with Mobile transaction entry
    Given the incoming SWIFT transaction is successful in BO
    And I have logged in to the Mobile application as "mb.user01"
    When I open the relevant demand account transactions in mobile
    Then the SWIFT transaction entry should be available in the mobile app
