import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/ishtar_pattern.dart';
import '../../../../core/widgets/stripe.dart';
import '../../domain/home_models.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.data,
    this.onLocation,
    this.onBell,
    this.onStory,
  });

  final HomeData data;
  final VoidCallback? onLocation;
  final VoidCallback? onBell;
  final ValueChanged<StoryPage>? onStory;

  @override
  Widget build(BuildContext context) {
    final glass = AppColors.white.withValues(alpha: .14);
    return IshtarBackground(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      gradient: cssRadial(
        rx: 1.2,
        ry: .9,
        at: const Offset(1, 0),
        colors: const [AppColors.blueLight, AppColors.blue, AppColors.navy],
        stops: const [0, .45, 1],
      ),
      child: Stack(
        children: [
          // Gold glow, top-left.
          Positioned(
            left: -90,
            top: -60,
            width: 260,
            height: 260,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0x59E8B33A),
                    const Color(0x59E8B33A).withValues(alpha: 0),
                  ],
                  stops: const [0, .65],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 14,
            child: GoldStripe(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 52, 0, 104),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Wordmark(size: 30),
                        const Spacer(),
                        GestureDetector(
                          onTap: onLocation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: glass,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppSvgIcon(
                                  AppIcon.pin,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppStrings.locationLabel(
                                    data.area,
                                    data.governorate,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.500000,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onBell,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: glass,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const AppSvgIcon(
                                  AppIcon.bell,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                                if (data.hasUnreadNotifications)
                                  Positioned(
                                    top: 9,
                                    right: 10,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: AppColors.gold,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.blue,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: .85,
                          child: Text(
                            AppStrings.hello(data.firstName),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: '${AppStrings.homeQ1}\n'),
                              TextSpan(
                                text: AppStrings.homeQ2(data.governorate),
                                style: const TextStyle(
                                  color: AppColors.goldSoft,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 31,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 58 + 5 + 17,
                      child: ListView.separated(
                        // Clipped to the 20px content box like the design (`.stos{overflow:hidden}`).
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.hardEdge,
                        itemCount: data.stories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => _Story(
                          story: data.stories[i],
                          onTap: () => onStory?.call(data.stories[i]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.story, this.onTap});
  final StoryPage story;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  startAngle: -1.5708,
                  endAngle: 4.7124,
                  colors: [
                    AppColors.goldSoft,
                    AppColors.sticker,
                    AppColors.goldSoft,
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.navy, width: 2.5),
                  image: DecorationImage(
                    image: AssetImage(story.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Names may run a little wider than the 58px ring, as in the design.
            SizedBox(
              height: 17,
              child: OverflowBox(
                maxWidth: 70,
                child: Text(
                  story.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 17 / 11,
                  ),
                ),
              ),
            ),
            if (story.isAd)
              const Text(
                AppStrings.ad,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.484568,
                  color: AppColors.goldSoft,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
