import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/settings_row.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';
import 'topup_sheet.dart';
import 'widgets/seller_nav.dart';

/// 22 · «رصيدي»: balance, selection cost, manual top-up, ledger.
class SellerWalletScreen extends ConsumerWidget {
  const SellerWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    final c = s.config;
    return AppPage(
      title: 'رصيدي',
      showBack: false,
      nav: const SellerNav(SellerTab.wallet),
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الرصيد المتاح',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.headerSub,
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${thousands(s.balance)} '),
                const TextSpan(text: 'د.ع', style: TextStyle(fontSize: 15)),
              ],
            ),
            style: AppText.number.copyWith(
              fontSize: 34,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
          Pill(
            s.freeLeft
                ? 'باقيلك ${c.freeSelections - s.freeUsed} من ${c.freeSelections} اختيارات مجانية'
                : 'خلصت الـ ${c.freeSelections} اختيارات المجانية',
            bg: AppColors.goldSoft.withValues(alpha: .2),
            fg: AppColors.goldSoft,
            icon: AppIcon.gift,
          ),
        ],
      ),
      children: [
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('تكلفة كل اختيار', style: AppText.strong),
                    const Spacer(),
                    Text(
                      '${thousands(c.selectionFee)} د.ع',
                      style: AppText.number.copyWith(color: AppColors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'تندفع بس إذا الزبون اختار عرضك. ينحجز وقت الإرسال ويرجع إذا ما انختار.',
                  style: AppText.muted,
                ),
              ],
            ),
          ),
        ),
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('عبّي رصيدك', style: AppText.strong),
                const SizedBox(height: 10),
                TopupForm(
                  onDone: () => showAppToast(context, 'انرسل الوصل للمراجعة'),
                ),
              ],
            ),
          ),
        ),
        const SectionLabel('الحركات'),
        SettingsGroup([
          for (final e in s.ledger)
            SettingsRow(
              null,
              e.title,
              sub: e.sub,
              trailing: Text(
                e.amount > 0
                    ? '+${thousands(e.amount)}'
                    : (e.amount == 0 ? '0' : '-${thousands(-e.amount)}'),
                textDirection: TextDirection.ltr,
                style: AppText.number.copyWith(
                  color: switch (e.kind) {
                    LedgerKind.debit => AppColors.danger,
                    LedgerKind.free => AppColors.grey,
                    LedgerKind.held => AppColors.warn,
                    LedgerKind.credit => PillTone.teal.fg,
                  },
                ),
              ),
            ),
        ]),
      ],
    );
  }
}
