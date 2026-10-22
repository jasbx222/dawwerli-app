import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/catalog.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/countdown.dart';
import '../../../core/widgets/notes.dart';
import '../../../core/widgets/pill.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';
import 'widgets/page_side_widgets.dart';
import 'widgets/seller_nav.dart';
import 'widgets/seller_widgets.dart';

const _pageSize = 20;

/// «الهوم» — every open customer request, filtered by category, publish date
/// and price. Cards lead to the submit-offer flow; the customer phone stays hidden.
class SellerHomeScreen extends ConsumerStatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  ConsumerState<SellerHomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<SellerHomeScreen>
    with WidgetsBindingObserver, PagePolling {
  FeedFilter _filter = const FeedFilter();
  List<SellerRequest> _items = const [];
  int _total = 0;
  int _page = 0;
  bool _loading = false;
  bool _more = false;
  Object? _error;

  bool get _canLoad {
    final s = ref.read(sellerProvider);
    return s.status == VerifyStatus.verified && !s.suspended;
  }

  @override
  void initState() {
    super.initState();
    startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    if (!_canLoad) return;
    final f = _filter;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await ref.read(sellerProvider.notifier).loadFeed(f);
      if (!mounted || f != _filter) return;
      setState(() {
        _items = p.items;
        _total = p.total;
        _page = 1;
      });
    } catch (e) {
      if (mounted && f == _filter) setState(() => _error = e);
    } finally {
      if (mounted && f == _filter) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_more) return;
    final f = _filter;
    setState(() => _more = true);
    try {
      final p = await ref
          .read(sellerProvider.notifier)
          .loadFeed(f, page: _page + 1, pageSize: _pageSize);
      if (!mounted || f != _filter) return;
      final have = {for (final r in _items) r.id};
      setState(() {
        _items = [..._items, ...p.items.where((r) => !have.contains(r.id))];
        _total = p.total;
        _page++;
      });
    } catch (_) {
      if (mounted) showAppToast(context, 'ما كدرنا نجيب أكثر، جرّب مرة ثانية');
    } finally {
      if (mounted) setState(() => _more = false);
    }
  }

  /// Quietly refreshes what is on screen (first pages, up to 50 cards).
  @override
  Future<void> poll() async {
    if (!_canLoad || _loading || _more || _error != null) return;
    final f = _filter;
    final n = _items.length.clamp(_pageSize, 50);
    try {
      final p = await ref
          .read(sellerProvider.notifier)
          .loadFeed(f, pageSize: n);
      if (!mounted || f != _filter) return;
      final fresh = {for (final r in p.items) r.id};
      setState(() {
        _items = [
          ...p.items,
          ..._items.skip(n).where((r) => !fresh.contains(r.id)),
        ];
        _total = p.total;
        _page = (_items.length / _pageSize).ceil().clamp(1, 1 << 20);
      });
    } catch (_) {
      // Keep the last good list; the next tick retries.
    }
  }

  void _apply(FeedFilter f) {
    if (f == _filter) return;
    setState(() {
      _filter = f;
      _items = const [];
      _total = 0;
    });
    _reload();
  }

  Future<void> _openSheet(List<CatalogCategoryRef> cats) async {
    final f = await showModalBottomSheet<FeedFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C070E1F),
      builder: (_) => FeedFilterSheet(initial: _filter, categories: cats),
    );
    if (f != null) _apply(f);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sellerProvider);
    ref.listen(sellerProvider.select((s) => (s.status, s.suspended)), (a, b) {
      if (a != b && _canLoad && _items.isEmpty) _reload();
    });
    final cats = ref.watch(catalogProvider).value?.categories ?? const [];
    final set = s.settings;
    return AppPage(
      title: 'الهوم',
      showBack: false,
      trailing: _total > 0
          ? Pill(
              '$_total طلب مفتوح',
              bg: AppColors.white.withValues(alpha: .18),
              fg: AppColors.white,
            )
          : null,
      nav: const SellerNav(SellerTab.home),
      onRefresh: _reload,
      children: [
        if (s.status != VerifyStatus.verified)
          Gap(
            StateCardLink(
              title: 'صفحتك بعدها مو موثّقة',
              body: 'الطلبات تطلع بس للصفحات الموثقة. كمّل التوثيق.',
              action: 'كمّل التوثيق',
              onTap: () => context.push(sellerEntryRoute(s.status)),
            ),
          ),
        if (s.suspended)
          Gap(
            StateCardLink(
              title: 'صفحتك موقوفة',
              body: 'ما تكدر تقدّم عروض لحد ما يخلص الإيقاف.',
              action: 'شوف حالة صفحتك',
              onTap: () => context.push(Routes.sellerStanding),
            ),
          ),
        if (!set.receiving)
          Gap(
            StateCardLink(
              title: 'إشعارات الطلبات متوقفة',
              body: 'طفّيتها من الإعدادات، تكدر تشوف الطلبات هنا بس ما يوصلك إشعار.',
              action: 'شغّلها',
              onTap: () => context.push(Routes.sellerSettings),
            ),
          ),
        if (_canLoad) ...[
          if (s.earlyAccess) const Gap(_EarlyBanner()),
          ChipRow(
            children: [
              FilterChipButton(
                count: _filter.active,
                onTap: () => _openSheet(cats),
              ),
              choiceChip(
                'كل الأقسام',
                _filter.categoryId == null,
                () => _apply(_filter.copyWith(categoryId: () => null)),
              ),
              for (final c in cats)
                choiceChip(
                  '${c.emoji ?? ''} ${c.name}'.trim(),
                  _filter.categoryId == c.id,
                  () => _apply(_filter.copyWith(categoryId: () => c.id)),
                ),
            ],
          ),
          Gap(
            _Summary(filter: _filter, total: _total, loading: _loading),
            top: 10,
          ),
          ..._body(),
        ],
      ],
    );
  }

  List<Widget> _body() {
    if (_loading && _items.isEmpty) return const [ListSkeleton()];
    if (_error != null && _items.isEmpty) {
      return [Gap(RetryCard(error: _error!, onRetry: _reload))];
    }
    if (_items.isEmpty) {
      return [
        Gap(
          EmptyStateCard(
            icon: AppIcon.clipboardList,
            title: _filter.active > 0
                ? 'ماكو طلبات بهالفلتر'
                : 'ماكو طلبات هسه',
            body: _filter.active > 0
                ? 'جرّب تغيّر القسم أو التاريخ أو السعر.'
                : 'أول ما زبون ينشر طلب يطلع هنا وتكدر تقدّم عرضك.',
            action: _filter.active > 0
                ? AppButton(
                    'صفّر الفلاتر',
                    compact: true,
                    variant: AppButtonVariant.ghost,
                    onPressed: () => _apply(const FeedFilter()),
                  )
                : null,
          ),
        ),
      ];
    }
    return [
      ResponsiveCards(children: [for (final r in _items) _RequestCard(r)]),
      if (_items.length < _total)
        Gap(
          AppButton(
            _more ? 'دنجيب...' : 'حمّل أكثر',
            compact: true,
            variant: AppButtonVariant.ghost,
            icon: AppIcon.refresh,
            onPressed: _more ? null : _loadMore,
          ),
        ),
      Gap(
        Text(
          'رقم الزبون مخفي · تشوف عدد العروض بس، مو أسعارها',
          textAlign: TextAlign.center,
          style: AppText.muted,
        ),
        top: 10,
      ),
    ];
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.filter,
    required this.total,
    required this.loading,
  });
  final FeedFilter filter;
  final int total;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final parts = [
      sinceLabel(filter.since),
      sortLabel(filter.sort),
      if (filter.minPrice != null || filter.maxPrice != null)
        priceRangeLabel(filter.minPrice, filter.maxPrice),
    ];
    return Row(
      children: [
        Expanded(
          child: Text(
            '${loading ? '...' : '$total طلب'} · ${parts.join(' · ')}',
            style: AppText.muted,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (loading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.blue,
            ),
          ),
      ],
    );
  }
}

String sinceLabel(FeedSince s) => switch (s) {
  FeedSince.all => 'كل الأوقات',
  FeedSince.today => 'اليوم',
  FeedSince.week => 'آخر ٧ أيام',
  FeedSince.month => 'آخر ٣٠ يوم',
};

String sortLabel(FeedSort s) => switch (s) {
  FeedSort.newest => 'الأحدث',
  FeedSort.oldest => 'الأقدم',
  FeedSort.priceAsc => 'الأرخص',
  FeedSort.priceDesc => 'الأغلى',
};

String priceRangeLabel(int? min, int? max) => switch ((min, max)) {
  (final a?, final b?) => '${thousands(a)}–${thousands(b)} د.ع',
  (final a?, null) => 'من ${thousands(a)} د.ع',
  (null, final b?) => 'لحد ${thousands(b)} د.ع',
  _ => '',
};

/// Bottom sheet: category, publish date, sort and price range.
class FeedFilterSheet extends StatefulWidget {
  const FeedFilterSheet({
    super.key,
    required this.initial,
    required this.categories,
  });
  final FeedFilter initial;
  final List<CatalogCategoryRef> categories;

  @override
  State<FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<FeedFilterSheet> {
  late FeedFilter _f = widget.initial;
  late final _min = TextEditingController(
    text: widget.initial.minPrice?.toString() ?? '',
  );
  late final _max = TextEditingController(
    text: widget.initial.maxPrice?.toString() ?? '',
  );
  String? _err;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _submit() {
    final min = int.tryParse(_min.text.trim());
    final max = int.tryParse(_max.text.trim());
    if (min != null && max != null && min > max) {
      setState(() => _err = 'أقل سعر لازم يكون أصغر من أعلى سعر');
      return;
    }
    Navigator.pop(
      context,
      _f.copyWith(minPrice: () => min, maxPrice: () => max),
    );
  }

  Widget _group(String title, List<Widget> chips) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.label),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheet(
        children: [
          Row(
            children: [
              const AppSvgIcon(AppIcon.filter, color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'فلترة الطلبات',
                  style: AppText.strong.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          _group('القسم', [
            choiceChip(
              'الكل',
              _f.categoryId == null,
              () => setState(() => _f = _f.copyWith(categoryId: () => null)),
            ),
            for (final c in widget.categories)
              choiceChip(
                '${c.emoji ?? ''} ${c.name}'.trim(),
                _f.categoryId == c.id,
                () => setState(() => _f = _f.copyWith(categoryId: () => c.id)),
              ),
          ]),
          _group('تاريخ النشر', [
            for (final v in FeedSince.values)
              choiceChip(
                sinceLabel(v),
                _f.since == v,
                () => setState(() => _f = _f.copyWith(since: v)),
              ),
          ]),
          _group('الترتيب', [
            for (final v in FeedSort.values)
              choiceChip(
                sortLabel(v),
                _f.sort == v,
                () => setState(() => _f = _f.copyWith(sort: v)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('حد سعر الزبون (د.ع)', style: AppText.label),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _PriceField(_min, 'من', digits)),
              const SizedBox(width: 10),
              Expanded(child: _PriceField(_max, 'إلى', digits)),
            ],
          ),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _err!,
                style: AppText.muted.copyWith(color: AppColors.danger),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(flex: 2, child: AppButton('طبّق', onPressed: _submit)),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  'صفّر',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.pop(context, const FeedFilter()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField(this.controller, this.hint, this.formatters);
  final TextEditingController controller;
  final String hint;
  final List<TextInputFormatter> formatters;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: formatters,
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    style: AppText.body,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppText.muted,
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.cardRing),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.cardRing),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    ),
  );
}

class _EarlyBanner extends StatelessWidget {
  const _EarlyBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.card),
      gradient: const LinearGradient(
        begin: Alignment(-0.866, -0.5),
        end: Alignment(0.866, 0.5),
        colors: [AppColors.navy, AppColors.blue],
      ),
    ),
    child: Row(
      children: [
        const AppSvgIcon(AppIcon.zap, color: AppColors.goldSoft, size: 24),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إشعار قبل غيرك',
                style: AppText.strong.copyWith(color: AppColors.white),
              ),
              const Text(
                'مشترك: الطلبات توصلك قبل دقيقتين',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.headerSub,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard(this.r);
  final SellerRequest r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(sellerProvider).config;
    final locked = r.locked(c.maxOffers);
    final sub = [
      if (r.category.isNotEmpty) r.category,
      r.governorate,
      r.condition,
    ].where((x) => x.isNotEmpty).join(' · ');
    return ThumbCard(
      image: r.image,
      title: r.title,
      sub: '$sub\nحد السعر ${iqd(r.maxPrice)} · ${agoLabel(r.postedAt)}',
      footer: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (r.earlyUntil != null)
                    Countdown(
                      until: r.earlyUntil!,
                      builder: (_, left) => left == Duration.zero
                          ? const SizedBox.shrink()
                          : PillTone.gold.pill(
                              'مبكر · ${mmss(left)}',
                              icon: AppIcon.zap,
                            ),
                    ),
                  locked
                      ? PillTone.blue.pill(
                          '${c.maxOffers}/${c.maxOffers} · انقفل',
                        )
                      : PillTone.blue.pill('${r.offers}/${c.maxOffers} عروض'),
                  GestureDetector(
                    onTap: () => ReasonSheet.show(
                      context,
                      title: 'بلّغ عن الطلب',
                      sub: 'الزبون ما يعرف إنك بلّغت',
                      reasons: requestReportReasons,
                      onSend: (_) => showAppToast(context, 'وصل بلاغك، نراجعه'),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgIcon(
                          AppIcon.flag,
                          color: AppColors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text('بلّغ', style: AppText.muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SmallButton(
              r.offeredByMe ? 'دزيت عرضك' : (locked ? 'انقفل' : 'قدّم عرض'),
              icon: locked || r.offeredByMe ? AppIcon.lock : AppIcon.camera,
              variant: locked || r.offeredByMe
                  ? AppButtonVariant.disabled
                  : AppButtonVariant.primary,
              onPressed: locked || r.offeredByMe
                  ? null
                  : () => context.push(Routes.sellerSubmit(r.id)),
            ),
          ],
        ),
      ),
    );
  }
}
