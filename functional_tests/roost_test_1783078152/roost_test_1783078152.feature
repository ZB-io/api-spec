Feature: Inward SWIFT MX (pacs.008) processing, validation, repair, authorization, and cross-channel visibility via UI
  # Scope:
  # - UI-only tests across Back Office (TCS BaNCS), Branch, and Mobile applications
  # - Covers file creation, ABA code validation, upload, receipt, workitem selection, validation parameters (incl. AML scanning),
  #   status "Repair awaited", Modify/repair, authorization to success, Service Indicator >> Messages audit,
  #   and demand account/mobile transaction entry visibility (pre- and post-success)
  # Test IDs covered (non-exhaustive mapping by group):
  #   File/ABA/Upload: TC-FILE-01, TC-FILE-02, TC-FILE-03, TC-ABA-01, TC-ABA-02, TC-ABA-03, TC-ABA-04, TC-FCV-01, TC-FCV-02, TC-UPL-01, TC-UPL-02
  #   Auth/Nav/Receipt/Workitem: TC-AUTH-01, TC-AUTH-02, TC-NAV-01, TC-NAV-02, TC-RCPT-01, TC-RCPT-02, TC-RCPT-03, TC-RCPT-04, TC-WKIT-01, TC-WKIT-02, TC-WKIT-03
  #   Validation/Status/Modify/AuthZ/Success: TC-VAL-01..TC-VAL-05, TC-VAL-08..TC-VAL-13, TC-STATUS-01..TC-STATUS-04, TC-REPAIR-01..TC-REPAIR-04, TC-AUTHZ-01..TC-AUTHZ-04, TC-STATE-01..TC-STATE-03, TC-SUCCESS-01..TC-SUCCESS-03
  #   Messages audit: TC-MSG-01..TC-MSG-03, TC-MSG-05
  #   Branch/Mobile visibility: TC-BRANCH-01..TC-BRANCH-03, TC-LEDGER-01..TC-LEDGER-04, TC-XREC-01..TC-XREC-02, TC-MOBL-01..TC-MOBL-02, TC-MOBV-01..TC-MOBV-04

  Background:
    Given MX messages are enabled for Inward SWIFT transfer
    And the test environment is reachable

  # UI Tests — Authentication and Navigation
  @ui
  Scenario Outline: BO user logs in and navigates to Payments List
    Given I launch the TCS BaNCS application
    When I login with username "<username>" and password "<password>"
    Then I should see "Login should be successful"
    When I open the "Credit transfer" menu
    And I select "Payments List"
    Then I should land on "Payments list"

    Examples:
      | username     | password    |
      | bo_user_001  | P@ssw0rd01! |
      | bo_user_qa02 | P@ssw0rd02! |

  # UI Tests — File Creation, ABA Code, and Upload
  @ui
  Scenario Outline: Create inward SWIFT file with correct details, capture ABA, and upload successfully
    Given I am logged in to TCS BaNCS as "<username>"
    When I open the Inward SWIFT file creation workflow
    And I provide all required correct details for a "<currency>" pacs.008 message
    And I enter the ABA code of USA "<aba_code>"
    And I save to create the file
    Then I should see "File should be created successfully" with a created file reference
    When I open the created file details view
    Then I should see the ABA code field shows "<aba_code>"
    When I proceed to the upload action for the created file
    And I start the upload
    Then I should see "File should be uploaded successfully"

    Examples:
      | username     | currency | aba_code  |
      | bo_user_001  | GBP      | 123123123 |
      | bo_user_qa02 | GBP      | 321321321 |
      | bo_user_001  | GBP      | 741852963 |
      | bo_user_qa02 | GBP      | 852741963 |

  @ui
  Scenario Outline: File creation is blocked with incorrect/incomplete details until corrected
    Given I am logged in to TCS BaNCS as "<username>"
    When I open the Inward SWIFT file creation workflow
    And I attempt to provide details with issue "<issue_type>" using value "<invalid_value>"
    And I try to save to create the file
    Then I should see creation is blocked and does not proceed
    When I correct the details by setting "<correction_field>" to "<corrected_value>"
    And I enter a correct ABA code "<correct_aba>"
    And I save to create the file
    Then I should see "File should be created successfully" with all details populated

    Examples:
      | username     | issue_type               | invalid_value    | correction_field             | corrected_value  | correct_aba |
      | bo_user_001  | missing_required_detail  | amount_missing   | amount                       | 1000.00         | 246801357   |
      | bo_user_001  | aba_blank                | (blank)          | aba_code                     | 246801357       | 246801357   |
      | bo_user_qa02 | aba_non_numeric          | ABC123XYZ        | aba_code                     | 654987321       | 654987321   |
      | bo_user_qa02 | iban_malformed           | GB12TEST123      | beneficiary_account_iban     | GB12TEST12345612345678 | 159753486   |

  # UI Tests — Receipt Ordering and Payments List Visibility
  @ui
  Scenario Outline: Receipt is confirmed only after upload and is visible on Payments List
    Given I am logged in to TCS BaNCS as "<username>"
    And I have created and uploaded an inward SWIFT file with ABA "<aba_code>" successfully
    When I open the "Credit transfer" menu
    And I select "Payments List"
    Then I should land on "Payments list"
    And I should see "Inward SWIFT message should be received successfully from SWIFT" for reference "<reference>"

    Examples:
      | username     | aba_code  | reference             |
      | bo_user_001  | 852741963 | INW-P008-REF-001      |
      | bo_user_qa02 | 741852963 | INW-P008-REF-002      |

  # UI Tests — Workitem Summary and Selection
  @ui
  Scenario Outline: Navigate to Workitem summary list and select the incoming SWIFT transfer
    Given I am logged in to TCS BaNCS as "<username>"
    And I am on "Payments list" with received message "<reference>"
    When I navigate to "Workitem summary list"
    Then I should land on "workitem summary list"
    When I select the incoming SWIFT transfer "<reference>"
    Then I should see "incoming SWIFT transfer selected"
    And the workitem details view should be displayed

    Examples:
      | username     | reference        |
      | bo_user_001  | INW-P008-REF-001 |
      | bo_user_qa02 | INW-P008-REF-002 |

  # UI Tests — Validation Parameters (incl. AML scanning) and Status = Repair awaited
  @ui
  Scenario Outline: Validation parameters are shown and status is 'Repair awaited' immediately after validation
    Given I am logged in to TCS BaNCS as "<username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    When I open the validation parameters section
    Then I should see the following validations listed: "<validation_expectations>"
    And I should immediately see the status displays "Repair awaited status"

    Examples:
      | username     | reference        | validation_expectations                                                                                                          |
      | bo_user_001  | INW-P008-REF-001 | Correspondent account for Transfer currency; Valid Beneficiary Account in IBAN format; Valid Beneficiary Account; AML scanning  |
      | bo_user_qa02 | INW-P008-REF-002 | Correspondent BIC as sender of MT103; Correspondent BIC as sender of MT103; AML scanning                                        |

  # UI Tests — Negative validations leading to Repair awaited, then Modify → Authorize → Success
  @ui
  Scenario Outline: Specific validation failures enforce 'Repair awaited' until repaired, then authorization approves and transaction succeeds
    Given I am logged in to TCS BaNCS as "<username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    When I open the validation parameters section
    Then I should see validation failure(s): "<failures>"
    And I should see the status displays "Repair awaited status"
    When I click "Modify" to repair
    And I apply the repair "<repair_action>"
    And I save the modifications
    Then I should see the save is successful
    When I authorize the transfer
    Then I should see "Transfer should be approved"
    And I should see "Incoming SWIFT transaction should be successful"

    Examples:
      | username     | reference        | failures                                                                      | repair_action                                              |
      | bo_user_001  | INW-P008-REF-003 | Correspondent BIC as sender of MT103                                          | Change Sender BIC to a non-correspondent value             |
      | bo_user_qa02 | INW-P008-REF-004 | Correspondent BIC as sender of MT103 (duplicate line enforcement)             | Update Sender BIC to valid non-correspondent value         |
      | bo_user_001  | INW-P008-REF-005 | Correspondent account for Transfer currency                                   | Add valid correspondent account for GBP (e.g., CORR-GBP-1) |
      | bo_user_qa02 | INW-P008-REF-006 | Valid Beneficiary Account in IBAN format                                      | Replace IBAN with plausible value GB12TEST12345612345678   |
      | bo_user_001  | INW-P008-REF-007 | AML scanning                                                                  | Resolve AML flag per protocol and rescreen                 |
      | bo_user_qa02 | INW-P008-REF-008 | Correspondent BIC as sender of MT103; Correspondent account for Transfer currency | Change Sender BIC; Add correspondent account            |
      | bo_user_001  | INW-P008-REF-009 | Valid Beneficiary Account in IBAN format; Valid Beneficiary Account Status    | Enter valid IBAN; Select valid beneficiary account         |
      | bo_user_qa02 | INW-P008-REF-010 | Valid Beneficiary Account; AML scanning                                       | Select valid beneficiary account; Resolve AML flag         |

  # UI Tests — Status behavior and authorization gating
  @ui
  Scenario Outline: Item remains in 'Repair awaited status' across refresh until Modify is performed
    Given I am logged in to TCS BaNCS as "<username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    When I check the status
    Then I should see the status displays "Repair awaited status"
    When I refresh the details view
    Then I should still see the status displays "Repair awaited status"
    When I open "Modify"
    Then I should be able to edit fields for repair

    Examples:
      | username     | reference        |
      | bo_user_001  | INW-P008-REF-011 |
      | bo_user_qa02 | INW-P008-REF-012 |

  @ui
  Scenario Outline: Authorization is not performed while status is 'Repair awaited status'
    Given I am logged in to TCS BaNCS as "<username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    And the status displays "Repair awaited status"
    When I attempt to authorize without modifying
    Then the authorization should not be performed
    And the status should remain "Repair awaited status"

    Examples:
      | username     | reference        |
      | bo_user_001  | INW-P008-REF-013 |
      | bo_user_qa02 | INW-P008-REF-014 |

  @ui
  Scenario Outline: Modify enables addressing specific fields to clear validations (pre-authorization)
    Given I am logged in to TCS BaNCS as "<username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    And the status displays "Repair awaited status"
    When I click "Modify"
    And I update "<repair_field>" to "<new_value>"
    And I save the modifications
    Then I should see the save is successful
    And the updated value "<new_value>" should be visible in details

    Examples:
      | username     | reference        | repair_field                                 | new_value               |
      | bo_user_001  | INW-P008-REF-015 | correspondent_account_for_transfer_currency  | CORR-GBP-TEST          |
      | bo_user_qa02 | INW-P008-REF-016 | beneficiary_account_iban                     | GB12TEST12345612345678 |
      | bo_user_001  | INW-P008-REF-017 | sender_bic                                   | BOFAUS3NXXX            |
      | bo_user_qa02 | INW-P008-REF-018 | beneficiary_account                          | BENEF-ACC-VALID-001    |

  @ui
  Scenario Outline: Attempt authorization, then repair via Modify, then authorize to approval (sequence integrity)
    Given I am logged in to TCS BaNCS as "<username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    And the status displays "Repair awaited status"
    When I attempt to authorize without modifying
    Then the authorization should not be performed
    And the status should remain "Repair awaited status"
    When I click "Modify"
    And I apply the repair "<repair_action>"
    And I save the modifications
    Then I should see the save is successful
    When I authorize the transfer
    Then I should see "Transfer should be approved"
    And I should see "Incoming SWIFT transaction should be successful"

    Examples:
      | username     | reference        | repair_action                                   |
      | bo_user_001  | INW-P008-REF-019 | Set correspondent account to CORR-GBP-OK        |
      | bo_user_qa02 | INW-P008-REF-020 | Set beneficiary account to BENEF-ACC-VALID-001  |

  # UI Tests — End-to-End lifecycle ordering
  @ui
  Scenario: Lifecycle order is enforced: Received → Repair awaited → Modify → Authorize → Successful
    Given I am logged in to TCS BaNCS as "bo_user_001"
    And I have created and uploaded an inward SWIFT file with ABA "111000111" successfully
    When I open the "Credit transfer" menu
    And I select "Payments List"
    Then I should land on "Payments list"
    And I should see "Inward SWIFT message should be received successfully from SWIFT" for reference "INW-P008-REF-E2E"
    When I navigate to "Workitem summary list"
    And I select the incoming SWIFT transfer "INW-P008-REF-E2E"
    Then I should see the validation parameters section
    And I should see the status displays "Repair awaited status"
    When I click "Modify" to repair
    And I update "correspondent_account_for_transfer_currency" to "CORR-GBP-E2E"
    And I save the modifications
    Then I should see the save is successful
    When I authorize the transfer
    Then I should see "Transfer should be approved"
    And I should see "Incoming SWIFT transaction should be successful"

  # UI Tests — Service Indicator >> Messages audit after success
  @ui
  Scenario Outline: MX message is present on Messages screen after successful transaction
    Given I am logged in to TCS BaNCS as "<username>"
    And the incoming SWIFT transfer "<reference>" shows "Incoming SWIFT transaction should be successful"
    When I navigate to "Service Indicator >> Messages"
    Then I should land on "messages screen"
    And I should see "MX message should be received" for reference "<reference>"

    Examples:
      | username     | reference        |
      | bo_user_001  | INW-P008-REF-021 |
      | bo_user_qa02 | INW-P008-REF-022 |

  # UI Tests — Branch channel: demand account visibility (pre-/post-success)
  @ui
  Scenario Outline: Branch login and customer selection is successful
    Given I launch the Branch application
    When I login as branch user "<branch_username>" with password "<branch_password>"
    Then I should see "Login successful"
    When I search and select customer "<customer_id>"
    Then I should see the selected customer context "<customer_id>"

    Examples:
      | branch_username | branch_password | customer_id  |
      | br_user_001     | Br@ncH01!       | CUST-GB-001  |
      | br_user_002     | Br@ncH02!       | CUST-GB-002  |

  @ui
  Scenario Outline: Demand account entry is absent before success and present after approval
    Given I am logged in to TCS BaNCS as "<bo_username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    And the status displays "Repair awaited status"
    When I login to Branch as "<branch_username>" with password "<branch_password>" and select customer "<customer_id>"
    And I open the customer's demand account transactions
    Then I should not see a SWIFT transaction entry for "<reference>" before success
    When I return to TCS BaNCS and repair via "Modify" and authorize to approval
    Then I should see "Incoming SWIFT transaction should be successful"
    When I refresh the Branch demand account transactions
    Then I should see the SWIFT transaction entry for "<reference>"

    Examples:
      | bo_username  | reference        | branch_username | branch_password | customer_id |
      | bo_user_001  | INW-P008-REF-023 | br_user_001     | Br@ncH01!       | CUST-GB-001 |

  # UI Tests — Mobile channel: login and transaction visibility (pre-/post-success)
  @ui
  Scenario Outline: Mobile user login is successful
    Given I launch the Mobile application
    When I login to Mobile with username "<mobile_username>" and password "<mobile_password>"
    Then I should land on the Mobile home screen with an active session

    Examples:
      | mobile_username | mobile_password |
      | mob_user_001    | M0b!Login01     |
      | mob_user_002    | M0b!Login02     |

  @ui
  Scenario Outline: Mobile transaction entry becomes visible only after success
    Given I am logged in to TCS BaNCS as "<bo_username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    And the status displays "Repair awaited status"
    When I login to Mobile as "<mobile_username>" with password "<mobile_password>"
    And I navigate to the account transactions for customer "<customer_id>"
    Then I should not see a SWIFT transaction entry for "<reference>" before success
    When I return to TCS BaNCS, repair via "Modify", and authorize to approval
    Then I should see "Incoming SWIFT transaction should be successful"
    When I refresh the Mobile transactions view
    Then I should see the SWIFT transaction entry for "<reference>"

    Examples:
      | bo_username  | reference        | mobile_username | mobile_password | customer_id |
      | bo_user_qa02 | INW-P008-REF-024 | mob_user_001    | M0b!Login01     | CUST-GB-001 |

  @ui
  Scenario Outline: After success, refreshing Mobile transactions shows the SWIFT entry
    Given the incoming SWIFT transfer "<reference>" shows "Incoming SWIFT transaction should be successful"
    And I am logged in to Mobile as "<mobile_username>" with password "<mobile_password>"
    When I open the account transactions for customer "<customer_id>"
    And I manually refresh the transactions view
    Then I should see the SWIFT transaction entry for "<reference>"

    Examples:
      | reference        | mobile_username | mobile_password | customer_id |
      | INW-P008-REF-025 | mob_user_002    | M0b!Login02     | CUST-GB-002 |

  # UI Tests — Payments List receipt visibility (observability)
  @ui
  Scenario Outline: Payments List reflects received inward SWIFT messages post-upload
    Given I am logged in to TCS BaNCS as "<username>"
    And I have created and uploaded an inward SWIFT file with ABA "<aba_code>" successfully
    When I open the "Credit transfer" menu
    And I select "Payments List"
    Then I should land on "Payments list"
    And I should see "Inward SWIFT message should be received successfully from SWIFT" for reference "<reference>"
    When I refresh the Payments List
    Then I should still see the received message "<reference>"

    Examples:
      | username     | aba_code  | reference        |
      | bo_user_001  | 111000111 | INW-P008-REF-026 |

  # UI Tests — Validation text presence checks (reference completeness)
  @ui
  Scenario Outline: Validation references include both 'Valid Beneficiary Account in IBAN format' and 'Valid Beneficiary Account'
    Given I am logged in to TCS BaNCS as "<username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    When I open the validation parameters section
    Then I should see "Valid Beneficiary Account in IBAN format"
    And I should see "Valid Beneficiary Account"

    Examples:
      | username     | reference        |
      | bo_user_001  | INW-P008-REF-027 |

  # UI Tests — Success must be confirmed after authorization and before audit check
  @ui
  Scenario Outline: Success is confirmed after authorization and before navigating to Messages for MX audit
    Given I am logged in to TCS BaNCS as "<username>"
    And I have selected the incoming SWIFT transfer "<reference>" in "Workitem summary list"
    And I have reviewed validation parameters (including AML scanning)
    And the status displays "Repair awaited status"
    When I repair via "Modify" and save
    And I authorize the transfer
    Then I should see "Transfer should be approved"
    And I should see "Incoming SWIFT transaction should be successful"
    When I navigate to "Service Indicator >> Messages"
    Then I should land on "messages screen"
    And I should see "MX message should be received" for reference "<reference>"

    Examples:
      | username     | reference        |
      | bo_user_qa02 | INW-P008-REF-028 |
