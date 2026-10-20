import 'package:flutter/material.dart';

import '../../../core/widgets/app_image.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../offers/presentation/widgets/offer_widgets.dart';
import '../data/my_requests_provider.dart';

enum _Kind { live, waiting, chosen, expired, done }

enum _Filter { all, open, chosen, ended }

class _Item {
  const _Item(this.kind, this.title, this.sub, this.image, this.r);
  final _Kind kind;
  final String title;
  final String sub;
  final String image;
  final RequestSummary r;

  factory _Item.of(RequestSummary r) {
    final kind = switch (r.status) {
      _ when r.isOpen => r.offers > 0 ? _Kind.live : _Kind.waiting,
      'selected' => _Kind.chosen,
      'closed' => _Kind.done,
      _ => _Kind.expired,
    };
    final sub = switch (kind) {
      _Kind.live => '${r.offers}/${r.maxOffers} عروض',
      _Kind.waiting => 'بانتظار العروض · 0 عروض',
      _Kind.chosen => 'اخترت عرض · بانتظار الاستلام',
      _Kind.done => 'خلص الطلب',
      _Kind.expired =>
        r.status == 'cancelled' ? 'ألغيته · ما انخصم شي' : 'انتهى الوقت · ما انخصم شي',
    };
    return _Item(kind, r.title, sub, r.image, r);
  }
}

/// 25 · «طلباتي»: all of the customer's requests with a status pill.
class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  _Filter filter = _Filter.all;

  void _retry() => ref.invalidate(myRequestsProvider);

  bool _in(_Item i) => switch (filter) {
    _Filter.all => true,
    _Filter.open => i.kind == _Kind.live || i.kind == _Kind.waiting,
    _Filter.chosen => i.kind == _Kind.chosen,
    _Filter.ended => i.kind == _Kind.expired || i.kind == _Kind.done,
  };

  void _open(_Item i) => context.push(switch (i.kind) {
    _Kind.live || _Kind.waiting => Routes.liveRequest(i.r.id),
    _Kind.expired => Routes.noOffers(i.r.id),
    _Kind.chosen || _Kind.done =>
      i.r.orderId == null ? Routes.offers(i.r.id) : Routes.orderStatus(i.r.orderId!),
  });

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myRequestsProvider);
    final loading = async.isLoading && !async.hasValue;
    final failed = async.hasError && !async.hasValue;
    final items = [for (final r in async.value ?? const <RequestSummary>[]) _Item.of(r)];
    final open = items
        .where((i) => i.kind == _Kind.live || i.kind == _Kind.waiting)
        .length;
    const labels = {
      _Filter.all: 'الكل',
      _Filter.open: 'مفتوحة',
      _Filter.chosen: 'اخترت',
      _Filter.ended: 'منتهية',
    };
    final shown = items.where(_in).toList();
    final noItems = !loading && !failed && items.isEmpty;
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
                  trailing: noItems || failed
                      ? null
                      : Pill(
                          '$open من 3 مفتوحة',
                          bg: AppColors.white.withValues(alpha: .18),
                          fg: AppColors.white,
                        ),
                ),
                if (!noItems && !failed)
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
                if (failed)
                  _Message(
                    icon: AppIcon.wifiOff,
                    color: AppColors.grey,
                    title: 'ما كدرنا نجيب طلباتك',
                    text: 'تأكد من النت وجرّب مرة ثانية',
                    action: AppButton(
                      'جرّب مرة ثانية',
                      variant: AppButtonVariant.ghost,
                      onPressed: _retry,
                    ),
                  )
                else if (loading)
                  for (var k = 0; k < 3; k++) const _SkeletonCard()
                else if (noItems)
                  _Message(
                    icon: AppIcon.clipboard,
                    color: AppColors.ink,
                    opacity: .3,
                    title: 'ما عندك طلبات بعد',
                    text: 'اكتب شتريد وخلي الصفحات تتسابق عليك',
                    action: AppButton(
                      'انشر طلب جديد',
                      onPressed: () => context.push(Routes.post),
                    ),
                  )
                else if (shown.isEmpty)
                  _Message(
                    icon: AppIcon.filter,
                    color: AppColors.grey,
                    title: 'ماكو طلبات ${labels[filter]}',
                    action: GestureDetector(
                      onTap: () => setState(() => filter = _Filter.all),
                      child: Text(
                        'شوف الكل',
                        textAlign: TextAlign.center,
                        style: AppText.strong.copyWith(color: AppColors.blue),
                      ),
                    ),
                  ),
                if (!loading && !failed)
                  for (final i in shown)
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
                NavTab.notifications => context.go(Routes.notifications),
                NavTab.account => context.go(Routes.account),
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
      _Kind.waiting => Pill(
        'بانتظار عروض',
        bg: AppColors.blueTint,
        fg: AppColors.blue,
      ),
      _Kind.chosen => const Pill(
        'اخترت',
        bg: AppColors.warnBg,
        fg: AppColors.warn,
      ),
      _Kind.expired => Pill(
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
          child: AppImage(item.image, width: 52, height: 52, fit: BoxFit.cover),
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

/// Centered icon + title + text + action (25b, 25d, 25e).
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.title,
    this.text,
    required this.action,
    this.opacity = 1,
  });
  final double opacity;
  final AppIcon icon;
  final Color color;
  final String title;
  final String? text;
  final Widget action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 96, 32, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Opacity(
            opacity: opacity,
            child: AppSvgIcon(icon, color: color, size: 56),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: AppText.big),
        if (text != null) ...[
          const SizedBox(height: 6),
          Text(text!, textAlign: TextAlign.center, style: AppText.muted),
        ],
        const SizedBox(height: 20),
        action,
      ],
    ),
  );
}

/// 25c · request-card-sized placeholder with a shimmer sweep.
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: AnimatedBuilder(
      animation: c,
      builder: (_, _) => Container(
        // Card padding 16 + 52 thumb.
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment(-1 + 4 * c.value - 1, 0),
            end: Alignment(1 + 4 * c.value - 1, 0),
            colors: const [
              Color(0xFFEFEAE0),
              Color(0xFFF6F2E8),
              Color(0xFFEFEAE0),
            ],
          ),
        ),
      ),
    ),
  );
}
