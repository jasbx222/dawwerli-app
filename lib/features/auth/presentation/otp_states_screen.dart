import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/app_header.dart';
import 'otp_issue_cards.dart';

/// 04b — catalogue of every sign-in state card (also reachable at /login/otp/states).
class OtpStatesScreen extends StatelessWidget {
  const OtpStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: AppStrings.otpTitle,
              subtitle: const Text(AppStrings.otpStatesSub),
              onBack: () => context.go(Routes.otp),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OtpExpiredCard(),
                  gap,
                  OtpWhatsappCard(),
                  gap,
                  OtpWrongCard(attemptsLeft: 2),
                  gap,
                  OtpLockedCard(retryIn: Duration(minutes: 14, seconds: 32)),
                  gap,
                  OtpRateLimitedCard(retryIn: Duration(seconds: 42)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
