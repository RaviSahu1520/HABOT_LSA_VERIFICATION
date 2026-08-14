import 'package:flutter/material.dart';

import '../controllers/verification_controller.dart';

class VerificationForm extends StatelessWidget {
  const VerificationForm({required this.controller, super.key});

  final VerificationController controller;

  @override
  Widget build(BuildContext context) {
    final isProcessing = controller.status == VerificationStatus.processing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SystemField(
          key: const Key('lsa-id-field'),
          label: 'LSA ID',
          controller: controller.lsaIdController,
          helperText: 'System-provided identifier',
          errorText: controller.lsaIdError,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 20),
        TextField(
          key: const Key('parent-consent-code-field'),
          controller: controller.parentConsentCodeController,
          focusNode: controller.parentConsentFocusNode,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) => controller.verifyAndSubmit(),
          decoration: _inputDecoration(
            label: 'Parent Consent Code',
            hintText: 'e.g. PCC-2026-9901',
            errorText: controller.parentConsentError,
            icon: Icons.key_outlined,
          ),
        ),
        const SizedBox(height: 20),
        _SystemField(
          key: const Key('predecessor-id-field'),
          label: 'Predecessor ID',
          controller: controller.predecessorIdController,
          helperText: 'System-controlled lineage record',
          icon: Icons.account_tree_outlined,
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            key: const Key('verify-submit-button'),
            onPressed: controller.canSubmit
                ? () => controller.verifyAndSubmit()
                : null,
            icon: isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: const Text('Verify & Submit'),
          ),
        ),
        if (controller.status == VerificationStatus.quarantined) ...[
          const SizedBox(height: 12),
          Text(
            'This verification session is locked. Contact compliance support '
            'if the source record needs review.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _SystemField extends StatelessWidget {
  const _SystemField({
    required this.label,
    required this.controller,
    required this.helperText,
    required this.icon,
    this.errorText,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String helperText;
  final String? errorText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      showCursor: false,
      enableInteractiveSelection: false,
      decoration: _inputDecoration(
        label: label,
        helperText: helperText,
        errorText: errorText,
        icon: icon,
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  String? hintText,
  String? helperText,
  String? errorText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    prefixIcon: Icon(icon),
  );
}
