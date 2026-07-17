Feature: Collections communications masking and state rules
  Ensures notifications, agency handoffs, and legal documents follow state guards and strict PAN masking (only last 4 digits), with no full PAN exposure.

  Background:
    Given the API base URL is set from environment variable 'BASE_URL'
    And the authorization token is set from environment variable 'AUTH_TOKEN'
    And the default headers include 'Content-Type' as 'application/json' and 'Authorization: Bearer <AUTH_TOKEN>'

  # API Tests — Due Reminder masking and security
  @api @dueReminder @masking @security
  Scenario Outline: Due Reminder generation and masking compliance for upcoming due accounts
    Given account '<account_id>' exists with state 'upcoming_due' and stored last4 '<last4>'
    When I send a POST request to '/api/notifications/jobs/due-reminders/run' with JSON payload
      """
      {
        "window": "current"
      }
      """
    Then the response status should be 202
    When I send a GET request to '/api/outbox?accountId=<account_id>&type=DueReminder'
    Then the response status should be 200
    And I select the latest artifact from the response list
    When I send a GET request to '/api/outbox/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should contain exactly one 4-digit card identifier
    And the response body should not contain any 3-digit-only identifier variants in the card identifier position
    And the response body should not contain any 5+ digit contiguous numeric sequences related to the card identifier
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN in plain text)

    Examples:
      | account_id  | last4 |
      | CUST-DR01   | 1234  |
      | CUST-DR02   | 5678  |
      | CUST-DR03   | 9012  |
      | CUST-DR04   | 3456  |
      | CUST-DR05   | 7788  |

  # API Tests — Overdue Alert state guard
  @api @overdueAlert @state
  Scenario Outline: Overdue Balance Alert is sent only after the due date is missed
    Given account '<account_id>' exists with state '<state>' and stored last4 '<last4>'
    When I send a POST request to '/api/notifications/jobs/overdue-alerts/run' with JSON payload
      """
      {
        "window": "current"
      }
      """
    Then the response status should be 202
    When I send a GET request to '/api/outbox?accountId=<account_id>&type=OverdueAlert'
    Then the response status should be 200
    And the number of artifacts returned should be <expected_count>

    Examples:
      | account_id  | state        | last4 | expected_count |
      | CUST-OA01A  | upcoming_due | 0000  | 0              |
      | CUST-OA01B  | missed_due   | 9999  | 1              |

  # API Tests — Overdue Alert masking and character-class validation
  @api @overdueAlert @masking @security
  Scenario Outline: Overdue Balance Alert masking compliance (digits only, exact four, no PAN)
    Given account '<account_id>' exists with state 'missed_due' and stored last4 '<last4>'
    When I send a POST request to '/api/notifications/jobs/overdue-alerts/run' with JSON payload
      """
      {
        "window": "current"
      }
      """
    Then the response status should be 202
    When I send a GET request to '/api/outbox?accountId=<account_id>&type=OverdueAlert'
    Then the response status should be 200
    And I select the latest artifact from the response list
    When I send a GET request to '/api/outbox/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the identifier should comprise only numeric digits (no letters or symbols)
    And the response body should contain exactly one 4-digit card identifier
    And the response body should not contain any 5+ digit contiguous numeric sequences related to the card identifier
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN in plain text)

    Examples:
      | account_id  | last4 |
      | CUST-OA02   | 1122  |
      | CUST-OA04   | 3344  |
      | CUST-OA05   | 8899  |

  # API Tests — Overdue Alert identifier length boundary validation (BVA)
  @api @overdueAlert @boundary
  Scenario Outline: Overdue Balance Alert rejects invalid identifier lengths and accepts exactly four digits
    Given account '<account_id>' exists with state 'missed_due'
    When I send a POST request to '/api/test/overrides/overdue-alerts' with JSON payload
      """
      {
        "accountId": "<account_id>",
        "identifierOverride": "<identifier>"
      }
      """
    Then the response status should be <status>
    And the response outcome should indicate 'accepted' equals <accepted>
    When I send a GET request to '/api/outbox?accountId=<account_id>&type=OverdueAlert'
    Then the response status should be 200
    And the number of approved artifacts should be <artifact_count>

    Examples:
      | account_id | identifier | status | accepted | artifact_count |
      | ACC-3101   | 123        | 400    | false    | 0              |
      | ACC-3101   | 9876       | 201    | true     | 1              |
      | ACC-3101   | 98765      | 400    | false    | 1              |

  # API Tests — Agency involvement gating and masking
  @api @agency @state @masking
  Scenario Outline: Collection agency involvement occurs only after no response to prior notifications and uses last four only
    Given account '<account_id>' exists and is eligible for collections processing with last4 '<last4>'
    And the engagement status for '<account_id>' is set to 'Responded'
    When I send a POST request to '/api/collections/agency/handoffs/evaluate' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 200
    And no agency handoff record should exist for '<account_id>'
    And the engagement status for '<account_id>' is updated to 'NoResponse'
    When I send a POST request to '/api/collections/agency/handoffs/evaluate' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 201
    And an agency handoff record should exist for '<account_id>'
    When I send a GET request to '/api/collections/agency/handoffs?accountId=<account_id>&limit=1'
    Then the response status should be 200
    And I select the latest handoff artifact id
    When I send a GET request to '/api/collections/agency/handoffs/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should not contain any 5+ digit contiguous numeric sequences related to the card identifier
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN in plain text)

    Examples:
      | account_id | last4 |
      | ACC-1001   | 1234  |

  @api @agency @masking
  Scenario Outline: Agency handoff artifact includes only the last four digits and no extended masked patterns
    Given account '<account_id>' exists with engagement 'NoResponse' and last4 '<last4>'
    When I send a POST request to '/api/collections/agency/handoffs' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/collections/agency/handoffs?accountId=<account_id>&limit=1'
    Then the response status should be 200
    And I select the latest handoff artifact id
    When I send a GET request to '/api/collections/agency/handoffs/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should not contain any masked-but-extended pattern implying more than last four (e.g., '**** **** **<last4>')
    And the response body should not contain any 5+ digit contiguous numeric sequences
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN)

    Examples:
      | account_id | last4 |
      | ACC-2002   | 5678  |

  @api @agency @boundary
  Scenario Outline: Agency handoff identifier length validation (BVA)
    Given account '<account_id>' exists with engagement 'NoResponse'
    When I send a POST request to '/api/test/overrides/agency-handoffs' with JSON payload
      """
      {
        "accountId": "<account_id>",
        "identifierOverride": "<identifier>"
      }
      """
    Then the response status should be <status>
    And the response outcome should indicate 'accepted' equals <accepted>
    When I send a GET request to '/api/collections/agency/handoffs?accountId=<account_id>'
    Then the response status should be 200
    And the number of accepted handoff artifacts should be <artifact_count>

    Examples:
      | account_id | identifier   | status | accepted | artifact_count |
      | ACC-3003   | 123          | 400    | false    | 0              |
      | ACC-3003   | 0123         | 201    | true     | 1              |
      | ACC-3003   | 01234        | 400    | false    | 1              |
      | ACC-3003   | 0123456789   | 400    | false    | 1              |

  @api @agency @security
  Scenario Outline: Agency handoff never includes full PAN and sanitizes injected long numeric sequences
    Given account '<account_id>' exists with engagement 'NoResponse' and last4 '<last4>'
    When I send a POST request to '/api/collections/agency/handoffs' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/collections/agency/handoffs?accountId=<account_id>&limit=1'
    Then the response status should be 200
    And I select the latest handoff artifact id
    When I send a GET request to '/api/collections/agency/handoffs/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN)
    When I send a POST request to '/api/test/overrides/agency-handoffs' with JSON payload
      """
      {
        "accountId": "<account_id>",
        "extraField": "99999999999999999999"
      }
      """
    Then the response status should be 400
    And no new handoff artifact should be created for '<account_id>'

    Examples:
      | account_id | last4 |
      | ACC-4004   | 9012  |

  # API Tests — Legal action gating and masking
  @api @legal @state @masking
  Scenario Outline: Legal action is initiated only for extreme non-payment/default and documents include only last four
    Given account '<account_id>' exists with state 'significantly_delinquent' (not extreme) and last4 '<last4>'
    When I send a POST request to '/api/legal/actions/initiate' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 403
    And no legal case should exist for '<account_id>'
    And I update account '<account_id>' state to 'extreme_default'
    When I send a POST request to '/api/legal/actions/initiate' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 201
    And a legal case should exist for '<account_id>'
    When I send a GET request to '/api/legal/documents?accountId=<account_id>&limit=1'
    Then the response status should be 200
    And I select the latest legal document id
    When I send a GET request to '/api/legal/documents/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should not contain any 5+ digit contiguous numeric sequences
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN)

    Examples:
      | account_id | last4 |
      | ACC-5005   | 3456  |

  @api @legal @masking
  Scenario Outline: Legal documentation includes only the last four digits and no extended masked patterns
    Given account '<account_id>' exists with state 'extreme_default' and last4 '<last4>'
    When I send a POST request to '/api/legal/documents/generate' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/legal/documents?accountId=<account_id>&limit=1'
    Then the response status should be 200
    And I select the latest legal document id
    When I send a GET request to '/api/legal/documents/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should not contain any masked-but-extended pattern implying more than last four (e.g., '**** **** **<last4>')
    And the response body should not contain any 5+ digit contiguous numeric sequences
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN)

    Examples:
      | account_id | last4 |
      | ACC-6006   | 7890  |

  @api @legal @boundary
  Scenario Outline: Legal documentation identifier length validation (BVA)
    Given account '<account_id>' exists with state 'extreme_default'
    When I send a POST request to '/api/test/overrides/legal-documents' with JSON payload
      """
      {
        "accountId": "<account_id>",
        "identifierOverride": "<identifier>"
      }
      """
    Then the response status should be <status>
    And the response outcome should indicate 'accepted' equals <accepted>
    When I send a GET request to '/api/legal/documents?accountId=<account_id>'
    Then the response status should be 200
    And the number of accepted legal document artifacts should be <artifact_count>

    Examples:
      | account_id | identifier | status | accepted | artifact_count |
      | ACC-7007   | 567        | 400    | false    | 0              |
      | ACC-7007   | 4567       | 201    | true     | 1              |
      | ACC-7007   | 34567      | 400    | false    | 1              |

  @api @legal @security
  Scenario Outline: Legal documentation never displays full PAN and sanitizes injected long numeric sequences
    Given account '<account_id>' exists with state 'extreme_default' and last4 '<last4>'
    When I send a POST request to '/api/legal/documents/generate' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/legal/documents?accountId=<account_id>&limit=1'
    Then the response status should be 200
    And I select the latest legal document id
    When I send a GET request to '/api/legal/documents/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN)
    When I send a POST request to '/api/test/overrides/legal-documents' with JSON payload
      """
      {
        "accountId": "<account_id>",
        "extraField": "11111111111111111"
      }
      """
    Then the response status should be 400
    And no new legal document artifact should be created for '<account_id>'

    Examples:
      | account_id | last4 |
      | ACC-8008   | 2345  |

  # API Tests — Global masking compliance across lifecycle artifacts
  @api @masking @allStages
  Scenario Outline: All communications include only the last four digits — per artifact type
    Given account '<account_id>' exists with last4 '<last4>' and is eligible for '<type>' generation
    When I send a POST request to '<trigger_endpoint>' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 201
    When I send a GET request to '<fetch_endpoint>?accountId=<account_id>&limit=1&type=<type_query>'
    Then the response status should be 200
    And I select the latest artifact id
    When I send a GET request to '<content_endpoint>/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should not contain any 5+ digit contiguous numeric sequences
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN)

    Examples:
      | account_id | last4 | type                    | trigger_endpoint                                  | fetch_endpoint                 | content_endpoint                        | type_query            |
      | ACC-9009   | 6789  | DueReminder             | /api/notifications/jobs/due-reminders/run         | /api/outbox                    | /api/outbox                              | DueReminder           |
      | ACC-9009   | 6789  | OverdueAlert            | /api/notifications/jobs/overdue-alerts/run        | /api/outbox                    | /api/outbox                              | OverdueAlert          |
      | ACC-9009   | 6789  | CollectionNotification  | /api/notifications/jobs/collection-notices/run    | /api/outbox                    | /api/outbox                              | CollectionNotification |
      | ACC-9009   | 6789  | PaymentPlanProposal     | /api/notifications/jobs/payment-plans/run         | /api/outbox                    | /api/outbox                              | PaymentPlanProposal   |
      | ACC-9009   | 6789  | AgencyHandoff           | /api/collections/agency/handoffs                  | /api/collections/agency/handoffs | /api/collections/agency/handoffs        | AgencyHandoff         |
      | ACC-9009   | 6789  | LegalDocument           | /api/legal/documents/generate                     | /api/legal/documents           | /api/legal/documents                     | LegalDocument         |

  @api @security @allStages
  Scenario Outline: No communication or documentation displays the full PAN — per artifact type
    Given account '<account_id>' exists with last4 '<last4>' and is eligible for '<type>' generation
    When I send a POST request to '<trigger_endpoint>' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 201
    When I send a GET request to '<fetch_endpoint>?accountId=<account_id>&limit=1&type=<type_query>'
    Then the response status should be 200
    And I select the latest artifact id
    When I send a GET request to '<content_endpoint>/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN)

    Examples:
      | account_id | last4 | type                    | trigger_endpoint                                  | fetch_endpoint                 | content_endpoint                        | type_query            |
      | ACC-1010   | 1122  | DueReminder             | /api/notifications/jobs/due-reminders/run         | /api/outbox                    | /api/outbox                              | DueReminder           |
      | ACC-1010   | 1122  | OverdueAlert            | /api/notifications/jobs/overdue-alerts/run        | /api/outbox                    | /api/outbox                              | OverdueAlert          |
      | ACC-1010   | 1122  | CollectionNotification  | /api/notifications/jobs/collection-notices/run    | /api/outbox                    | /api/outbox                              | CollectionNotification |
      | ACC-1010   | 1122  | PaymentPlanProposal     | /api/notifications/jobs/payment-plans/run         | /api/outbox                    | /api/outbox                              | PaymentPlanProposal   |
      | ACC-1010   | 1122  | AgencyHandoff           | /api/collections/agency/handoffs                  | /api/collections/agency/handoffs | /api/collections/agency/handoffs        | AgencyHandoff         |
      | ACC-1010   | 1122  | LegalDocument           | /api/legal/documents/generate                     | /api/legal/documents           | /api/legal/documents                     | LegalDocument         |

  @api @masking @boundary
  Scenario Outline: Exactly four numeric digits are present where the last-4 identifier is required (multi-artifact check)
    Given account '<account_id>' exists with appropriate state for '<type>' and last4 '<last4>'
    When I send a POST request to '<trigger_endpoint>' with JSON payload
      """
      {
        "accountId": "<account_id>"
      }
      """
    Then the response status should be 201
    When I send a GET request to '<fetch_endpoint>?accountId=<account_id>&limit=1&type=<type_query>'
    Then the response status should be 200
    And I select the latest artifact id
    When I send a GET request to '<content_endpoint>/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<last4>'
    And the response body should contain exactly one 4-digit card identifier
    And the response body should not contain any 5+ digit contiguous numeric sequences

    Examples:
      | account_id | last4 | type                   | trigger_endpoint                                 | fetch_endpoint       | content_endpoint       | type_query             |
      | ACC-1001   | 1234  | DueReminder            | /api/notifications/jobs/due-reminders/run        | /api/outbox          | /api/outbox            | DueReminder            |
      | ACC-1002   | 9876  | CollectionNotification | /api/notifications/jobs/collection-notices/run   | /api/outbox          | /api/outbox            | CollectionNotification |
      | ACC-1003   | 4321  | LegalDocument          | /api/legal/documents/generate                    | /api/legal/documents | /api/legal/documents   | LegalDocument          |

  @api @validation @boundary
  Scenario Outline: Inclusion of fewer than or more than four digits is invalid and rejected; exactly four is accepted
    Given account '<account_id>' exists with appropriate state for '<type>'
    When I send a POST request to '<invalid_endpoint>' with JSON payload
      """
      {
        "accountId": "<account_id>",
        "identifierOverride": "<invalid_identifier>"
      }
      """
    Then the response status should be 400
    And no approved '<type>' artifact should exist for '<account_id>'
    When I send a POST request to '<valid_endpoint>' with JSON payload
      """
      {
        "accountId": "<account_id>",
        "identifierOverride": "<valid_identifier>"
      }
      """
    Then the response status should be 201
    When I send a GET request to '<fetch_endpoint>?accountId=<account_id>&limit=1&type=<type_query>'
    Then the response status should be 200
    And I select the latest artifact id
    When I send a GET request to '<content_endpoint>/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '<valid_identifier>'
    And the response body should not contain any 5+ digit contiguous numeric sequences

    Examples:
      | account_id | type                   | invalid_identifier | valid_identifier | invalid_endpoint                               | valid_endpoint                                   | fetch_endpoint | content_endpoint | type_query             |
      | ACC-1101   | DueReminder            | 123                | 6789             | /api/test/overrides/due-reminders              | /api/test/overrides/due-reminders                | /api/outbox    | /api/outbox      | DueReminder            |
      | ACC-1102   | CollectionNotification | 12345              | 1234             | /api/test/overrides/collection-notifications   | /api/test/overrides/collection-notifications     | /api/outbox    | /api/outbox      | CollectionNotification |

  # API Tests — State transition validations for reminders and notifications
  @api @dueReminder @state
  Scenario Outline: Due Reminder is sent only for accounts with an upcoming due date
    Given account '<account_id>' exists with state '<state>'
    When I send a POST request to '/api/notifications/jobs/due-reminders/run' with JSON payload
      """
      {
        "window": "current"
      }
      """
    Then the response status should be 202
    When I send a GET request to '/api/outbox?accountId=<account_id>&type=DueReminder'
    Then the response status should be 200
    And the number of artifacts returned should be <expected_count>
    And if <expected_count> equals 1, I select the artifact and fetch its content from '/api/outbox/<selectedArtifactId>/content'
    And if <expected_count> equals 1, the content should not contain any 5+ digit sequences or 13–19 digit sequences

    Examples:
      | account_id | state          | expected_count |
      | ACC-2001   | upcoming_due   | 1              |
      | ACC-2002   | not_upcoming   | 0              |

  @api @collectionNotification @state @masking
  Scenario: Collection notification is not issued before significant delinquency; issued after with last four only
    Given account 'ACC-2101' exists with state 'missed_due' (not significantly delinquent)
    When I send a POST request to '/api/notifications/jobs/collection-notices/run' with JSON payload
      """
      {
        "accountId": "ACC-2101"
      }
      """
    Then the response status should be 200
    And no CollectionNotification artifact should exist for 'ACC-2101'
    And I update account 'ACC-2101' state to 'significantly_delinquent'
    When I send a POST request to '/api/notifications/jobs/collection-notices/run' with JSON payload
      """
      {
        "accountId": "ACC-2101"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/outbox?accountId=ACC-2101&type=CollectionNotification&limit=1'
    Then the response status should be 200
    And I select the latest artifact id
    When I send a GET request to '/api/outbox/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '2468'
    And the response body should not contain any 5+ digit contiguous numeric sequences or 13–19 digit sequences

  @api @agency @state @masking
  Scenario: Collection agency involvement is blocked without prior notifications and proceeds after recording no response
    Given account 'ACC-2201' exists with delinquent status and last4 '3141'
    And no prior notifications/reminders are recorded for 'ACC-2201'
    When I send a POST request to '/api/collections/agency/handoffs/evaluate' with JSON payload
      """
      {
        "accountId": "ACC-2201"
      }
      """
    Then the response status should be 403
    And no agency handoff record should exist for 'ACC-2201'
    And I record that prior notifications and reminders were sent with no response for 'ACC-2201'
    When I send a POST request to '/api/collections/agency/handoffs/evaluate' with JSON payload
      """
      {
        "accountId": "ACC-2201"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/collections/agency/handoffs?accountId=ACC-2201&limit=1'
    Then the response status should be 200
    And I select the latest handoff artifact id
    When I send a GET request to '/api/collections/agency/handoffs/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '3141'
    And the response body should not contain any 5+ digit contiguous numeric sequences or 13–19 digit sequences

  @api @paymentPlan @state @masking
  Scenario: Transition from significant delinquency to collection notification then to payment plan when unable to pay in full
    Given account 'ACC-2401' exists with state 'significantly_delinquent' and last4 '8642'
    When I send a POST request to '/api/notifications/jobs/collection-notices/run' with JSON payload
      """
      {
        "accountId": "ACC-2401"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/outbox?accountId=ACC-2401&type=CollectionNotification&limit=1'
    Then the response status should be 200
    And I select the latest artifact id
    When I send a GET request to '/api/outbox/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '8642'
    And the response body should contain the required elements 'amount owed' and 'additional charges'
    And the response body should not contain any 5+ digit contiguous numeric sequences or 13–19 digit sequences
    And I record that the cardholder is unable to pay the full overdue balance at once for 'ACC-2401'
    When I send a POST request to '/api/notifications/jobs/payment-plans/run' with JSON payload
      """
      {
        "accountId": "ACC-2401"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/outbox?accountId=ACC-2401&type=PaymentPlanProposal&limit=1'
    Then the response status should be 200
    And I select the latest artifact id
    When I send a GET request to '/api/outbox/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should include a structured repayment schedule and reduced interest rates or fees
    And the response body should contain the identifier '8642'
    And the response body should not contain any 5+ digit contiguous numeric sequences or 13–19 digit sequences

  # API Tests — Collection Notification masking security (explicit negative)
  @api @collectionNotification @boundary
  Scenario: Collection notification is rejected if it includes more than the last 4 digits
    Given account 'ACC-3001' exists with state 'significantly_delinquent'
    When I send a POST request to '/api/test/overrides/collection-notifications' with JSON payload
      """
      {
        "accountId": "ACC-3001",
        "identifierOverride": "12345"
      }
      """
    Then the response status should be 400
    And no approved 'CollectionNotification' artifact should exist for 'ACC-3001'
    When I send a POST request to '/api/test/overrides/collection-notifications' with JSON payload
      """
      {
        "accountId": "ACC-3001",
        "identifierOverride": "1234"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/outbox?accountId=ACC-3001&type=CollectionNotification&limit=1'
    Then the response status should be 200
    And I select the latest artifact id
    When I send a GET request to '/api/outbox/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '1234'
    And the response body should not contain any 5+ digit contiguous numeric sequences

  @api @collectionNotification @security
  Scenario: Collection notification never displays the full PAN in plain text
    Given account 'ACC-3002' exists with state 'significantly_delinquent'
    When I send a POST request to '/api/test/overrides/collection-notifications' with JSON payload
      """
      {
        "accountId": "ACC-3002",
        "contentInjection": "This is a test 5555444433332222 sequence"
      }
      """
    Then the response status should be 400
    And no approved 'CollectionNotification' artifact should exist for 'ACC-3002'
    When I send a POST request to '/api/test/overrides/collection-notifications' with JSON payload
      """
      {
        "accountId": "ACC-3002",
        "identifierOverride": "5555"
      }
      """
    Then the response status should be 201
    When I send a GET request to '/api/outbox?accountId=ACC-3002&type=CollectionNotification&limit=1'
    Then the response status should be 200
    And I select the latest artifact id
    When I send a GET request to '/api/outbox/<selectedArtifactId>/content'
    Then the response status should be 200
    And the response body should contain the identifier '5555'
    And the response body should not contain any 13–19 digit contiguous numeric sequences (no full PAN)
