import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../guest/guest.dart';
import '../../../core/role/app_role.dart';
import '../../../core/widgets/seg_tabs.dart';

import 'package:dawwerli/core/widgets/emoji_text.dart';

import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/ishtar_pattern.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seller = ref.watch(appRoleProvider) == AppRole.seller;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 470, width: double.infinity, child: _Hero()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${AppStrings.onbTitle1}\n'),
                        TextSpan(
                          text: AppStrings.onbTitle2,
                          style: TextStyle(color: AppColors.blue),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: AppText.big.copyWith(
                      fontSize: 27,
                      height: AppText.lh(27),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.onbBody,
                    textAlign: TextAlign.center,
                    style: AppText.muted.copyWith(fontSize: 14.5, height: 1.7),
                  ),
                  const SizedBox(height: 22),
                  const _PageDots(count: 3, active: 0),
                  const SizedBox(height: 18),
                  const _RoleChoice(),
                  const SizedBox(height: 14),
                  AppButton(
                    AppStrings.onbStart,
                    onPressed: () => context.go(Routes.login),
                  ),
                  const SizedBox(height: 14),
                  if (!seller)
                    GestureDetector(
                      onTap: () {
                        ProviderScope.containerOf(context)
                            .read(guestProvider.notifier)
                            .set(true);
                        context.go(Routes.home);
                      },
                      child: Text(
                        AppStrings.onbBrowse,
                        style: AppText.strong.copyWith(color: AppColors.blue),
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
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return IshtarBackground(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      gradient: LinearGradient(
        // CSS 160deg
        begin: Alignment(-0.342, -0.94),
        end: Alignment(0.342, 0.94),
        colors: [AppColors.blue, AppColors.navy],
      ),
      child: Stack(
        children: [
          Positioned.directional(
            textDirection: TextDirection.ltr,
            top: 90,
            end: 40,
            child: Transform.rotate(
              angle: 6 * 3.14159265 / 180,
              child: Container(
                width: 170,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/cat_phones_1.webp'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      offset: Offset(0, 20),
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.directional(
            textDirection: TextDirection.ltr,
            top: 150,
            start: 24,
            child: Transform.rotate(
              angle: -5 * 3.14159265 / 180,
              child: const _OffersCard(),
            ),
          ),
          Positioned.directional(
            textDirection: TextDirection.ltr,
            top: 330,
            start: 120,
            child: Transform.rotate(
              angle: -7 * 3.14159265 / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sticker,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xB3FF7A59),
                      offset: Offset(0, 4),
                      blurRadius: 10,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: EmojiText(
                  AppStrings.onbSticker,
                  style: AppText.body.copyWith(
                    fontSize: 12,
                    height: AppText.lh(12),
                    fontWeight: FontWeight.w700,
                    color: AppColors.stickerText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersCard extends StatelessWidget {
  const _OffersCard();

  static const _prices = ['35,000', '39,000', '42,000'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 20),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.onbOffersArrived, style: AppText.muted),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _prices.length; i++) ...[
                if (i > 0) const SizedBox(width: 7),
                Expanded(
                  child: _Slot(price: _prices[i], chosen: i == 0),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.price, required this.chosen});

  final String price;
  final bool chosen;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: chosen ? AppColors.blue : AppColors.slotBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: chosen ? AppColors.blue : AppColors.blueRing,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            price,
            style: AppText.body.copyWith(
              fontSize: 13.5,
              height: AppText.lh(13.5),
              fontWeight: FontWeight.w700,
              color: chosen ? AppColors.white : AppColors.ink,
            ),
          ),
          Text(
            AppStrings.currency,
            style: AppText.body.copyWith(
              fontSize: 10,
              height: AppText.lh(10),
              color: chosen ? AppColors.blueRing : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: i == active ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? AppColors.blue : AppColors.dotOff,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ],
      ],
    );
  }
}

/// «أشتري» opens the customer app, «أبيع» the page app; remembered on the device.
class _RoleChoice extends ConsumerWidget {
  const _RoleChoice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRoleProvider);
    return SegTabs(
      labels: const ['أشتري', 'أبيع'],
      selected: role.index,
      onSelect: (i) =>
          ref.read(appRoleProvider.notifier).set(AppRole.values[i]),
    );
  }
}
