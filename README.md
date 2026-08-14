# LSA Verification & Data Lineage Integration

## Project Overview

This Flutter application demonstrates the HabotConnect LSA onboarding compliance
gate. It collects a parent consent code, combines it with system-controlled LSA
and lineage metadata, and verifies the record through the compliance API.

## Features

- LSA identification with a prefilled, read-only LSA ID
- Parent consent code input and validation
- System-controlled predecessor lineage validation
- Compliance API integration with required metadata headers
- Fail-closed handling for missing lineage and invalid API outcomes
- Idle, processing, quarantined, and success status feedback
- Five-second parent consent field hesitation logging
- Volatile in-memory verification data only

## Architecture

The application uses a small Flutter-native state flow:

```text
LsaVerificationScreen -> VerificationController -> ComplianceService -> HTTP API
```

`LsaVerificationScreen` is a stateless view. `VerificationController` owns the
text controllers, focus node, timer, verification status, validation, and state
transitions. `ComplianceService` is responsible for constructing and sending
the HTTP request and defensively parsing the response. `ComplianceVerifier` is a
small injectable abstraction used by tests to avoid real network calls.

## API

The assignment API is treated as a supplied mock/compliance endpoint.

Debug builds use `AssignmentMockClient` as the HTTP transport because the
supplied host is not reachable in the local assignment environment. It still
passes through `ComplianceService`, including the exact endpoint, headers, and
request body. It returns a verified status only for the supplied fixture values;
other response data remains fail-closed. Release builds use a regular HTTP
client for the supplied endpoint.

- Method: `POST`
- Endpoint: `https://api.habotconnect.com/v1/compliance/verify`
- `Content-Type`: `application/json`
- `x-trace-id`: `8f3d1b2a-4c9e-4a11-b8d2-9901ef23a011`
- `x-logic-hash`: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`

The request body is shaped as follows. `timestamp_utc` is generated at
submission time using the current UTC time.

```json
{
  "predecessor_id": "PRED-9982-XYZ",
  "lsa_id": "LSA-7049",
  "parent_consent_code": "PCC-2026-9901",
  "timestamp_utc": "2026-08-07T11:30:00.000Z"
}
```

## Fail-Closed Behavior

- Missing or blank predecessor lineage uses `LineageException`, skips the
  network call, and immediately moves the UI to quarantine.
- HTTP failures, timeouts, malformed responses, and JSON `null` responses are
  treated as compliance failures.
- A response with a missing or blank `status` is invalid and is quarantined.

On a compliance failure, the controller clears the temporary request and
response, clears the parent consent input, restores system fields to their
initial values, locks the submit button, and displays:

`Data Quarantined – Compliance Failure`

## UI Friction Logging

When the parent consent field gains focus, a one-shot five-second timer starts.
Typing, submitting, or losing focus cancels the timer. If the user remains
idle, the controller emits one `debugPrint` line containing the UTC timestamp,
the `parent_consent_code` field name, and the hesitation duration. The log is
not persisted.

## Testing

Tests cover:

- Successful submission and request construction
- Missing lineage with no service call
- HTTP 500, timeout, malformed response, JSON `null`, and null status handling
- Temporary data clearing and terminal quarantine state
- Duplicate submission prevention
- Required API headers and JSON body
- Initial form rendering and friction logging

Run the test suite with:

```bash
flutter test
```

Tests use injected fake verifiers and mocked HTTP clients; they do not contact
the supplied endpoint.

## Running the Project

```bash
flutter pub get
flutter run
```

Static analysis and formatting can be run with:

```bash
dart format .
flutter analyze
```

## Assumptions

- The predecessor ID is system-controlled and is never editable in the UI.
- Verification data is intentionally volatile and is not stored in a database
  or preferences store.
- The supplied endpoint and header values are assignment/mock integration
  inputs, not production credentials or service configuration.
- Any non-empty string `status` is treated as an interpretable successful
  compliance response; a missing, null, or blank status fails closed.
