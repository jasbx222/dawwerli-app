import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../offers/presentation/widgets/offer_widgets.dart';

enum _Kind { live, waiting, chosen, expired, done }

enum _Filter { all, open, chosen, ended }

class _Item {
  const _Item(this.kind, this.title, this.sub, this.image);
  final _Kind kind;
  final String title;
  final String sub;
  final String image;
}

const _img = 'assets/images/mock';

// Mock list until the requests API lands.
const _items = [
  _Item(
    _Kind.live,
    'حذاء رياضي أسود',
    '3/5 عروض · يتسكر بعد 23:41',
    '$_img/cat_shoes_1.webp',
  ),
  _Item(
    _Kind.waiting,
    'ساعة كاسيو',
    'وصل لـ 8 صفحات · 0 عروض',
    '$_img/cat_watches_1.webp',
  ),
  _Item(
    _Kind.chosen,
    'عطر عود هدية',
    'عطور الشرق · 40,000 د.ع · بالطريق',
    '$_img/cat_perfumes_2.webp',
  ),
  _Item(
    _Kind.expired,
    'آيفون 13 مستعمل',
    '24 ساعة بدون عروض · ما انخصم شي',
    '$_img/cat_phones_2.webp',
  ),
  _Item(_Kind.done, 'بوكس هدية', 'قيّمت', '$_img/cat_gifts_1.webp'),
];

/// 25 · «طلباتي»: all of the customer's requests with a status pill.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  _Filter filter = _Filter.all;

  bool _in(_Item i) => switch (filter) {
    _Filter.all => true,
    _Filter.open => i.kind == _Kind.live || i.kind == _Kind.waiting,
    _Filter.chosen => i.kind == _Kind.chosen,
    _Filter.ended => i.kind == _Kind.expired || i.kind == _Kind.done,
  };

  void _open(_Item i) => context.push(switch (i.kind) {
    _Kind.live || _Kind.waiting => Routes.liveRequest('r1'),
    _Kind.expired => '${Routes.liveRequest('r1')}?preview=expired',
    _Kind.chosen || _Kind.done => Routes.orderStatus('o1'),
  });

  @override
  Widget build(BuildContext context) {
    final open = _items
        .where((i) => i.kind == _Kind.live || i.kind == _Kind.waiting)
        .length;
    const labels = {
      _Filter.all: 'الكل',
      _Filter.open: 'مفتوحة',
      _Filter.chosen: 'اخترت',
      _Filter.ended: 'منتهية',
    };
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 18 + 70 + 24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: 'طلباتي',
                  showBack: false,
                  trailing: Pill(
                    '$open من 3 مفتوحة',
                    bg: AppColors.white.withValues(alpha: .18),
                    fg: AppColors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in _Filter.values)
                        AppChip(
                          labels[f]!,
                          selected: f == filter,
                          onTap: () => setState(() => filter = f),
                        ),
                    ],
                  ),
                ),
                for (final i in _items.where(_in))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: GestureDetector(
                      onTap: () => _open(i),
                      child: AppCard(child: _Row(item: i)),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18 + MediaQuery.viewPaddingOf(context).bottom,
            child: AppBottomNav(
              current: NavTab.requests,
              onTab: (t) => switch (t) {
                NavTab.home => context.go(Routes.home),
                NavTab.requests => null,
                _ => context.push(Routes.comingSoon),
              },
              onPost: () => context.push(Routes.post),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    final pill = switch (item.kind) {
      _Kind.live => const _LiveDotPill(),
      _Kind.waiting => const Pill(
        'بانتظار عروض',
        bg: AppColors.blueTint,
        fg: AppColors.blue,
      ),
      _Kind.chosen => const Pill(
        'اخترت',
        bg: AppColors.warnBg,
        fg: AppColors.warn,
      ),
      _Kind.expired => const Pill(
        'انتهى · ما لكينا',
        bg: AppColors.tabTrack,
        fg: AppColors.tabText,
      ),
      _Kind.done => const Pill(
        'تم ',
        bg: Color(0xFFCCFBF1),
        fg: Color(0xFF0B6E66),
        check: true,
      ),
    };
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            item.image,
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
              Text(
                item.title,
                style: AppText.strong.copyWith(
                  fontSize: 14.5,
                  height: AppText.lh(14.5),
                ),
              ),
              item.kind == _Kind.done
                  ? Text.rich(
                      TextSpan(
                        text: '${item.sub} ',
                        children: [
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: AppSvgIcon(
                              AppIcon.star,
                              color: AppColors.gold,
                              size: 13,
                            ),
                          ),
                          const TextSpan(text: ' 5'),
                        ],
                      ),
                      style: AppText.muted,
                    )
                  : Text(item.sub, style: AppText.muted),
            ],
          ),
        ),
        const SizedBox(width: 12),
        pill,
      ],
    );
  }
}

/// `.pill.pl-t` with the «●» drawn as a dot.
class _LiveDotPill extends StatelessWidget {
  const _LiveDotPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFCCFBF1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF0B6E66),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'مباشر',
          style: TextStyle(
            fontSize: 12,
            height: AppText.lh(12),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0B6E66),
          ),
        ),
      ],
    ),
  );
}
