import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'compliance_service.dart';

class AssignmentMockClient {
  static http.Client create() {
    return MockClient((request) async {
      if (request.method != 'POST' ||
          request.url != ComplianceService.endpoint ||
          !_hasRequiredHeaders(request)) {
        return http.Response('{"status":null}', 500);
      }

      final body = _decodeBody(request.body);
      final isAssignmentFixture =
          body != null &&
          body['predecessor_id'] == 'PRED-9982-XYZ' &&
          body['lsa_id'] == 'LSA-7049' &&
          body['parent_consent_code'] == 'PCC-2026-9901';

      return http.Response(
        jsonEncode({'status': isAssignmentFixture ? 'verified' : null}),
        200,
      );
    });
  }

  static Map<String, dynamic>? _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static bool _hasRequiredHeaders(http.Request request) {
    return ComplianceService.requiredHeaders.entries.every(
      (entry) => request.headers[entry.key] == entry.value,
    );
  }
}
