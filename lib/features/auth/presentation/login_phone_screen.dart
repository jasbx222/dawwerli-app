import 'package:flutter/material.dart';

import 'package:dawwerli/core/widgets/emoji_text.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../account/presentation/server_url_sheet.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_inputs.dart';
import '../data/auth_providers.dart';
import '../domain/phone_number.dart';
import 'phone_field.dart';

class LoginPhoneScreen extends ConsumerStatefulWidget {
  const LoginPhoneScreen({
    super.key,
    this.initialPhone = '',
    this.initialErrors = const {},
  });

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
    try {
      await ref.read(authRepositoryProvider).requestOtp(r.phone!);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) context.go(Routes.otp);
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus || widget.initialPhone.isNotEmpty;
    final reset = ref.watch(authFlowProvider) == AuthFlow.reset;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: reset ? AppStrings.resetTitle : AppStrings.loginTitle,
                subtitle: EmojiText(
                  reset ? AppStrings.resetSub : AppStrings.loginSub,
                ),
                onBack: () => context.go(Routes.login),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel(AppStrings.loginPhoneLabel),
                    PhoneField(
                      controller: _ctrl,
                      focusNode: _focus,
                      focused: focused,
                      onChanged: (_) =>
                          _errors.isEmpty ? null : setState(() => _errors = {}),
                    ),
                    const SizedBox(height: 8),
                    Text(AppStrings.loginHint, style: AppText.muted),
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
                PhoneErrorCards(_errors),
                if (_errors.isNotEmpty) const SizedBox(height: 24),
                AppButton(
                  AppStrings.loginSend,
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: 16),
                // Long-press: point the app at another API server (testing on a real phone).
                GestureDetector(
                  onLongPress: () => ServerUrlSheet.show(context),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: AppStrings.termsPrefix),
                        TextSpan(text: AppStrings.privacy, style: _link),
                        TextSpan(text: AppStrings.and),
                        TextSpan(text: AppStrings.terms, style: _link),
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
    );
  }

  static final _link = TextStyle(
    fontWeight: FontWeight.w700,
    color: AppColors.blue,
  );
}
