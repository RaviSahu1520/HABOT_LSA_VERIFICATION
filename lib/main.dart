import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'controllers/verification_controller.dart';
import 'screens/lsa_verification_screen.dart';
import 'services/assignment_mock_client.dart';
import 'services/compliance_service.dart';

const _useAssignmentMock = bool.fromEnvironment(
  'USE_ASSIGNMENT_MOCK',
  defaultValue: true,
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final http.Client _httpClient;
  late final ComplianceService _complianceService;
  late final VerificationController _verificationController;

  @override
  void initState() {
    super.initState();
    _httpClient = _useAssignmentMock
        ? AssignmentMockClient.create()
        : http.Client();
    _complianceService = ComplianceService(client: _httpClient);
    _verificationController = VerificationController(
      service: _complianceService,
    );
  }

  @override
  void dispose() {
    _verificationController.dispose();
    _complianceService.close();
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B5C68),
    );

    return MaterialApp(
      title: 'LSA Onboarding Gate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: LsaVerificationScreen(controller: _verificationController),
    );
  }
}
