import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/verification_request.dart';

abstract interface class ComplianceVerifier {
  Future<ComplianceResponse?> verify(VerificationRequest request);
}

class ComplianceResponse {
  const ComplianceResponse({required this.status, required this.payload});

  factory ComplianceResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    return ComplianceResponse(
      status: status is String ? status : null,
      payload: Map.unmodifiable(json),
    );
  }

  final String? status;
  final Map<String, dynamic> payload;

  bool get isValid => status?.trim().isNotEmpty ?? false;
}

class ComplianceServiceException implements Exception {
  const ComplianceServiceException(this.message);

  final String message;

  @override
  String toString() => 'ComplianceServiceException: $message';
}

class ComplianceService implements ComplianceVerifier {
  ComplianceService({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static final Uri endpoint = Uri.parse(
    'https://api.habotconnect.com/v1/compliance/verify',
  );

  static const Map<String, String> requiredHeaders = {
    'Content-Type': 'application/json',
    'x-trace-id': '8f3d1b2a-4c9e-4a11-b8d2-9901ef23a011',
    'x-logic-hash':
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
  };

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  bool _isClosed = false;

  @override
  Future<ComplianceResponse?> verify(VerificationRequest request) async {
    final response = await _client
        .post(
          endpoint,
          headers: requiredHeaders,
          body: jsonEncode(request.toJson()),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ComplianceServiceException(
        'Compliance API returned HTTP ${response.statusCode}.',
      );
    }

    if (response.body.trim().isEmpty) {
      throw const ComplianceServiceException(
        'Compliance API returned an empty response.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ComplianceServiceException(
        'Compliance API returned malformed JSON.',
      );
    }

    if (decoded == null) {
      return null;
    }

    if (decoded is! Map) {
      throw const ComplianceServiceException(
        'Compliance API returned an unexpected response shape.',
      );
    }

    return ComplianceResponse.fromJson(Map<String, dynamic>.from(decoded));
  }

  void close() {
    if (_ownsClient && !_isClosed) {
      _isClosed = true;
      _client.close();
    }
  }
}
