import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_inputs.dart';
import '../data/auth_providers.dart';
import '../domain/phone_number.dart';

class LoginPhoneScreen extends ConsumerStatefulWidget {
  const LoginPhoneScreen({super.key, this.initialPhone = '', this.initialErrors = const {}});

  /// Used by design previews / deep links.
  final String initialPhone;
  final Set<PhoneError> initialErrors;

  @override
  ConsumerState<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends ConsumerState<LoginPhoneScreen> {
  late final _ctrl = TextEditingController(text: widget.initialPhone);
  final _focus = FocusNode();
  late Set<PhoneError> _errors = {...widget.initialErrors};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final r = PhoneNumber.parse(_ctrl.text);
    if (r.error != null) {
      setState(() => _errors = {r.error!});
      return;
    }
    setState(() {
      _errors = {};
      _busy = true;
    });
    ref.read(pendingPhoneProvider.notifier).set(r.phone!);
    await ref.read(authRepositoryProvider).requestOtp(r.phone!);
    if (!mounted) return;
    setState(() => _busy = false);
    context.go(Routes.otp);
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus || widget.initialPhone.isNotEmpty;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: AppStrings.loginTitle,
                subtitle: const Text(AppStrings.loginSub),
                onBack: () => context.go(Routes.onboarding),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel(AppStrings.loginPhoneLabel),
                    InputShell(
                      focused: focused,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            Text(AppStrings.countryCode, style: AppText.number.copyWith(fontSize: 18, height: AppText.lh(18), color: AppColors.navy)),
                            const SizedBox(width: 9),
                            Expanded(
                              child: BareTextField(
                                controller: _ctrl,
                                focusNode: _focus,
                                keyboardType: TextInputType.phone,
                                textDirection: TextDirection.ltr,
                                style: AppText.number.copyWith(fontSize: 18, height: AppText.lh(18), color: AppColors.navy),
                                onChanged: (_) => _errors.isEmpty ? null : setState(() => _errors = {}),
                              ),
                            ),
                            const Text('🇮🇶', style: TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(AppStrings.loginHint, style: AppText.muted),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 34,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errors.contains(PhoneError.incomplete))
                  const AlertCard(title: AppStrings.errIncompleteTitle, body: AppStrings.errIncompleteBody),
                if (_errors.length > 1) const SizedBox(height: 10),
                if (_errors.contains(PhoneError.notIraqi))
                  const AlertCard(title: AppStrings.errNotIraqiTitle, body: AppStrings.errNotIraqiBody),
                if (_errors.isNotEmpty) const SizedBox(height: 24),
                AppButton(AppStrings.loginSend, onPressed: _busy ? null : _submit),
                const SizedBox(height: 16),
                Text.rich(
                  const TextSpan(children: [
                    TextSpan(text: AppStrings.termsPrefix),
                    TextSpan(text: AppStrings.privacy, style: _link),
                    TextSpan(text: AppStrings.and),
                    TextSpan(text: AppStrings.terms, style: _link),
                  ]),
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _link = TextStyle(fontWeight: FontWeight.w700, color: AppColors.blue);
}
