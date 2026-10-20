import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_header.dart';
import 'app_icons.dart';
import 'ishtar_pattern.dart';

/// Full-screen state (31, 34–38): header, 120px Ishtar tile, big title with an
/// optional inline icon, body, optional extra, primary button.
class FullStateScreen extends StatelessWidget {
  const FullStateScreen({
    super.key,
    required this.header,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    this.onAction,
    this.titleIcon,
    this.extra,
    this.onBack,
  });

  final String header;
  final AppIcon icon;
  final AppIcon? titleIcon;
  final String title;
  final String body;
  final Widget? extra;
  final String action;
  final VoidCallback? onAction;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(title: header, onBack: onBack),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: IshtarBackground(
                      borderRadius: BorderRadius.circular(40),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.blue, AppColors.navy],
                      ),
                      child: Center(
                        child: AppSvgIcon(
                          icon,
                          size: 52,
                          color: AppColors.goldSoft,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    text: title,
                    children: [
                      if (titleIcon != null) ...[
                        const TextSpan(text: ' '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: AppSvgIcon(
                            titleIcon!,
                            size: 23,
                            color: AppColors.navy,
                            strokeWidth: 2.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppText.big,
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.7,
                    color: AppColors.grey,
                  ),
                ),
                ?extra,
                const SizedBox(height: 26),
                AppButton(action, onPressed: onAction),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
