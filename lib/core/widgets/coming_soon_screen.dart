import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../router/routes.dart';
import '../theme/app_typography.dart';
import 'app_header.dart';

/// Temporary target for links into groups not built yet.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: AppStrings.appName,
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            const Expanded(child: Center(child: Text(AppStrings.comingSoon, style: AppText.big))),
          ],
        ),
      );
}
