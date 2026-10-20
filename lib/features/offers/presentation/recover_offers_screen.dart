import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../data/offers_providers.dart';

/// 47b · the other offers stay available 48h after choosing.
class RecoverOffersScreen extends ConsumerWidget {
  const RecoverOffersScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(offersProvider(requestId)).value;
    final chosen = ref.watch(selectionProvider(requestId)).value;
    final others = [
      for (final o in board?.offers ?? const [])
        if (o.id != (chosen?.offer.id ?? 'o1')) o,
    ];
    Widget gap(Widget w) =>
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: w);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: 'العروض الثانية',
              subtitle: const Text('تبقى متاحة 48 ساعة بعد اختيارك'),
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            gap(
              const AppCard(
                flat: true,
                color: AppColors.warnBg,
                child: Row(
                  children: [
                    AppSvgIcon(AppIcon.clock, color: AppColors.warn, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'الصفحة اللي اخترتها ما زبطت؟ تكدر ترجع لعرض ثاني لحد ',
                          children: [
                            TextSpan(
                              // Mock deadline = selection + 48h.
                              text: '21/10 · 9:42 م',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.502222,
                          color: AppColors.warnText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final o in others)
              gap(
                AppCard(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          o.image,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.pageName, style: AppText.strong),
                            Text.rich(
                              TextSpan(
                                text: '${thousands(o.price)} د.ع · ',
                                children: [
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: AppSvgIcon(
                                      AppIcon.star,
                                      color: AppColors.gold,
                                      size: 13,
                                    ),
                                  ),
                                  TextSpan(text: ' ${o.rating}'),
                                ],
                              ),
                              style: AppText.muted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 68,
                        child: AppButton(
                          'رجّعه',
                          compact: true,
                          variant: AppButtonVariant.ghost,
                          onPressed: () => context.push(
                            Routes.offerDetails(requestId, o.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              'بعد 48 ساعة تختفي هالعروض نهائياً',
              textAlign: TextAlign.center,
              style: AppText.muted,
            ),
          ],
        ),
      ),
    );
  }
}
