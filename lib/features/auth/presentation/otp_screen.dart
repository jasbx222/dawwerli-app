import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/role/app_role.dart';
import '../../seller/data/seller_controller.dart';

import '../../guest/guest.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../data/auth_providers.dart';
import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';
import 'otp_issue_cards.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    this.initialCode = '',
    this.expiresIn = const Duration(minutes: 5),
    this.resendIn = const Duration(seconds: 60),
    this.lockedFor,
    this.frozenClock = false,
  });

  final String initialCode;
  final Duration expiresIn;
  final Duration resendIn;
  final Duration? lockedFor;

  /// Design previews freeze the countdowns.
  final bool frozenClock;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static final _len = 6;
  late final _ctrl = TextEditingController(text: widget.initialCode);
  final _focus = FocusNode();
  Timer? _tick;
  late Duration _expires = widget.expiresIn;
  late Duration _resend = widget.resendIn;
  late Duration? _locked = widget.lockedFor;
  int? _attemptsLeft;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    if (!widget.frozenClock) {
      _tick = Timer.periodic(Duration(seconds: 1), (_) => _onTick());
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus(),
      );
    }
  }

  void _onTick() {
    final s = Duration(seconds: 1);
    setState(() {
      if (_expires > Duration.zero) _expires -= s;
      if (_expires <= Duration.zero) _expired = true;
      if (_resend > Duration.zero) _resend -= s;
      if (_locked != null) {
        _locked = _locked! - s;
        if (_locked! <= Duration.zero) _locked = null;
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  PhoneNumber? get _phone =>
      ref.read(pendingPhoneProvider) ?? PhoneNumber.parse('7701234567').phone;

  Future<void> _onChanged(String v) async {
    setState(() {});
    if (v.length < _len || _locked != null) return;
    final r = await ref.read(authRepositoryProvider).verifyOtp(_phone!, v);
    if (!mounted) return;
    switch (r) {
      case OtpOk(:final needsProfile):
        ref.read(guestProvider.notifier).set(false);
        if (ref.read(appRoleProvider) == AppRole.seller) {
          context.go(sellerEntryRoute(ref.read(sellerProvider).status));
        } else {
          context.go(needsProfile ? Routes.profileSetup : Routes.home);
        }
      case OtpWrong(:final attemptsLeft):
        setState(() => _attemptsLeft = attemptsLeft);
      case OtpExpired():
        setState(() => _expired = true);
      case OtpVerifyLocked(:final retryIn):
        setState(() {
          _locked = retryIn;
          _attemptsLeft = null;
          _ctrl.clear();
        });
    }
  }

  Future<void> _resendCode() async {
    final r = await ref
        .read(authRepositoryProvider)
        .requestOtp(_phone!, smsNotReceived: true);
    if (!mounted) return;
    setState(() {
      switch (r) {
        case OtpSent(:final expiresIn, :final resendIn):
          _expires = expiresIn;
          _resend = resendIn;
          _expired = false;
          _ctrl.clear();
        case OtpRateLimited(:final retryIn):
          _resend = retryIn;
        case OtpLocked(:final retryIn):
          _locked = retryIn;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(pendingPhoneProvider) ?? _phone!;
    final code = _ctrl.text;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: AppStrings.otpTitle,
                subtitle: Text(
                  '${AppStrings.otpSentTo}${phone.pretty} \u202A${AppStrings.countryCode}\u202C',
                ),
                onBack: () => context.go(Routes.login),
              ),
              SizedBox(height: 28),
              GestureDetector(
                onTap: () => _focus.requestFocus(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Invisible real input that drives the boxes.
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        width: 1,
                        height: 1,
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          enabled: _locked == null,
                          keyboardType: TextInputType.number,
                          autofillHints: [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_len),
                          ],
                          onChanged: _onChanged,
                        ),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _len; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            _Box(
                              char: i < code.length ? code[i] : '',
                              active: i == code.length,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: AppStrings.otpExpiresIn),
                    TextSpan(
                      text: mmss(_expires),
                      style: AppText.number.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: AppText.muted,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _resend > Duration.zero
                    ? AppButton(
                        '${AppStrings.otpResendIn}${mmss(_resend)}',
                        variant: AppButtonVariant.disabled,
                      )
                    : AppButton(AppStrings.otpResend, onPressed: _resendCode),
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
                if (_expired)
                  OtpExpiredCard(onResend: _resendCode)
                else if (_attemptsLeft != null)
                  OtpWrongCard(
                    attemptsLeft: _attemptsLeft!,
                    onClear: () => setState(() {
                      _ctrl.clear();
                      _attemptsLeft = null;
                      _focus.requestFocus();
                    }),
                  )
                else
                  AppCard(
                    child: Row(
                      children: [
                        AppSvgIcon(AppIcon.whatsapp, color: AppColors.whatsapp),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.otpNoSmsTitle,
                                style: AppText.strong,
                              ),
                              Text(
                                AppStrings.otpNoSmsBody,
                                style: AppText.muted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_locked != null) ...[
                  const SizedBox(height: 12),
                  const AlertCard(
                    leading: AppSvgIcon(
                      AppIcon.lock,
                      color: AppColors.danger,
                      size: 22,
                    ),
                    title: AppStrings.otpLockedTitle,
                    body: AppStrings.otpLockedBody,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.char, required this.active});

  final String char;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: active ? AppColors.blue : AppColors.border,
            spreadRadius: active ? 2 : 1.5,
          ),
        ],
      ),
      child: Text(
        char,
        style: AppText.number.copyWith(
          fontSize: 24,
          height: AppText.lh(24),
          color: AppColors.ink,
        ),
      ),
    );
  }
}
