import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_icons.dart';

/// Status card with tinted icon tile, title, body and an action (04b states).
class StateCard extends StatelessWidget {
  const StateCard({
    super.key,
    required this.icon,
    required this.tint,
    required this.tone,
    required this.title,
    required this.body,
    required this.action,
    this.actionVariant = AppButtonVariant.primary,
    this.onAction,
  });

  final AppIcon icon;
  final Color tint;
  final Color tone;
  final String title;
  final InlineSpan body;
  final String action;
  final AppButtonVariant actionVariant;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: 14,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: AppSvgIcon(icon, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.4839,
                        fontWeight: FontWeight.w700,
                        color: tone,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      body,
                      style: AppText.muted.copyWith(height: 19 / 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            action,
            variant: actionVariant,
            compact: true,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
