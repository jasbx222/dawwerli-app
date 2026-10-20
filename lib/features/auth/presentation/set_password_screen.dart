import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_inputs.dart';
import '../data/auth_providers.dart';
import '../data/session.dart';
import '../domain/auth_repository.dart';
import 'phone_field.dart';

/// After OTP: sign-up sets the first password; «نسيت الرمز» sets a new one with the code.
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

enum _Problem { tooShort, mismatch, codeInvalid, generic }

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  /// Client-side check only; the server enforces its configured minimum.
  static const _minLength = 8;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();
  _Problem? _problem;
  bool _busy = false;

  bool get _reset => ref.read(authFlowProvider) == AuthFlow.reset;

  @override
  void initState() {
    super.initState();
    _f1.addListener(() => setState(() {}));
    _f2.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _f1.dispose();
    _f2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _password.text;
    if (pw.length < _minLength) {
      setState(() => _problem = _Problem.tooShort);
      return;
    }
    if (pw != _confirm.text) {
      setState(() => _problem = _Problem.mismatch);
      return;
    }
    setState(() {
      _problem = null;
      _busy = true;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      bool needsProfile;
      if (_reset) {
        final r = await repo.resetPassword(
          ref.read(pendingPhoneProvider)!,
          ref.read(resetCodeProvider) ?? '',
          pw,
        );
        if (r is! LoginOk) {
          if (mounted) setState(() => _problem = _Problem.codeInvalid);
          return;
        }
        needsProfile = r.needsProfile;
        ref.read(resetCodeProvider.notifier).set(null);
        ref.read(authFlowProvider.notifier).set(AuthFlow.signUp);
      } else {
        if (await repo.setPassword(pw) == PasswordError.tooShort) {
          if (mounted) setState(() => _problem = _Problem.tooShort);
          return;
        }
        needsProfile = ref.read(postSignUpProvider);
      }
      final to = await afterSignIn(ref, needsProfile: needsProfile);
      if (mounted) context.go(to);
    } on ApiException {
      if (mounted) setState(() => _problem = _Problem.generic);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clear() => _problem == null ? null : setState(() => _problem = null);

  @override
  Widget build(BuildContext context) {
    final reset = ref.watch(authFlowProvider) == AuthFlow.reset;
    final (title, body) = switch (_problem) {
      _Problem.tooShort => (
        AppStrings.passwordShortTitle,
        AppStrings.passwordShortBody,
      ),
      _Problem.mismatch => (
        AppStrings.passwordMismatchTitle,
        AppStrings.passwordMismatchBody,
      ),
      _Problem.codeInvalid => (
        AppStrings.codeInvalidTitle,
        AppStrings.codeInvalidBody,
      ),
      _Problem.generic => (
        AppStrings.genericErrorTitle,
        AppStrings.genericErrorBody,
      ),
      null => ('', ''),
    };
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeader(
            title: reset
                ? AppStrings.newPasswordTitle
                : AppStrings.setPasswordTitle,
            subtitle: const Text(AppStrings.setPasswordSub),
            // Sign-up is already signed in; only the reset flow can go back to the code.
            onBack: reset ? () => context.go(Routes.otp) : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel(AppStrings.passwordLabel),
                PasswordField(
                  controller: _password,
                  focusNode: _f1,
                  focused: _f1.hasFocus,
                  onChanged: (_) => _clear(),
                ),
                const SizedBox(height: 8),
                Text(AppStrings.passwordHint, style: AppText.muted),
                const SizedBox(height: 16),
                const FieldLabel(AppStrings.confirmPasswordLabel),
                PasswordField(
                  controller: _confirm,
                  focusNode: _f2,
                  focused: _f2.hasFocus,
                  onChanged: (_) => _clear(),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                if (_problem != null) ...[
                  AlertCard(title: title, body: body),
                  const SizedBox(height: 16),
                ],
                AppButton(
                  AppStrings.savePassword,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
