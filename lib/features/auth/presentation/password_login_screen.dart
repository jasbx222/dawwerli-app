import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../account/presentation/server_url_sheet.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_inputs.dart';
import '../data/auth_providers.dart';
import '../data/session.dart';
import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';
import 'phone_field.dart';

/// Phone + password sign-in for buyers and pages (role from the «أشتري/أبيع» choice).
class PasswordLoginScreen extends ConsumerStatefulWidget {
  const PasswordLoginScreen({super.key});

  @override
  ConsumerState<PasswordLoginScreen> createState() =>
      _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends ConsumerState<PasswordLoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  Set<PhoneError> _phoneErrors = {};
  PasswordLoginResult? _failure;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_phoneErrors.isEmpty && _failure == null) return;
    setState(() {
      _phoneErrors = {};
      _failure = null;
    });
  }

  Future<void> _submit() async {
    final p = PhoneNumber.parse(_phone.text);
    if (p.error != null) {
      setState(() => _phoneErrors = {p.error!});
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _failure = const LoginWrong());
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ref
          .read(authRepositoryProvider)
          .login(p.phone!, _password.text);
      if (!mounted) return;
      if (r case LoginOk(:final needsProfile)) {
        final to = await afterSignIn(ref, needsProfile: needsProfile);
        if (mounted) context.go(to);
      } else {
        setState(() => _failure = r);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Phone → OTP for a new account or for «نسيت الرمز».
  void _startOtp(AuthFlow flow) {
    ref.read(authFlowProvider.notifier).set(flow);
    context.go(Routes.loginPhone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AppHeader(
              title: AppStrings.signInTitle,
              subtitle: const Text(AppStrings.signInSub),
              onBack: () => context.go(Routes.onboarding),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel(AppStrings.loginPhoneLabel),
                  PhoneField(
                    controller: _phone,
                    focusNode: _phoneFocus,
                    focused: _phoneFocus.hasFocus,
                    onChanged: (_) => _clearErrors(),
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel(AppStrings.passwordLabel),
                  PasswordField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    focused: _passwordFocus.hasFocus,
                    onChanged: (_) => _clearErrors(),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GestureDetector(
                      onTap: () => _startOtp(AuthFlow.reset),
                      child: const Text(
                        AppStrings.forgotPassword,
                        style: _link,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PhoneErrorCards(_phoneErrors),
                  if (_failure case LoginWrong())
                    const AlertCard(
                      title: AppStrings.wrongCredsTitle,
                      body: AppStrings.wrongCredsBody,
                    ),
                  if (_failure case LoginLocked(:final retryIn))
                    AlertCard(
                      title: AppStrings.loginLockedTitle,
                      body:
                          '${AppStrings.loginLockedBody}${(retryIn.inSeconds / 60).ceil()}${AppStrings.minutes}',
                    ),
                  if (_phoneErrors.isNotEmpty || _failure != null)
                    const SizedBox(height: 16),
                  AppButton(
                    AppStrings.signIn,
                    onPressed: _busy ? null : _submit,
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => _startOtp(AuthFlow.signUp),
                    // Long-press: point the app at another API server (testing on a real phone).
                    onLongPress: () => ServerUrlSheet.show(context),
                    child: Text.rich(
                      const TextSpan(
                        children: [
                          TextSpan(text: AppStrings.noAccount),
                          TextSpan(
                            text: AppStrings.createAccount,
                            style: _link,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: AppText.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _link = TextStyle(
    fontWeight: FontWeight.w700,
    color: AppColors.blue,
  );
}
