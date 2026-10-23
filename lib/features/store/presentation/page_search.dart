import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_toggle.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/notes.dart';
import '../../discover/data/discover_data.dart';
import '../../discover/presentation/discover_widgets.dart';
import '../data/page_search_data.dart';
import '../data/store_data.dart';
import 'widgets/store_widgets.dart';

/// Wait after the last key press before searching.
const pageSearchDebounce = Duration(milliseconds: 300);

/// «250 ألف», «مليون», «1,250,500».
String priceShort(int v) {
  if (v >= 1000000 && v % 1000000 == 0) {
    return v == 1000000 ? 'مليون' : '${thousands(v ~/ 1000000)} مليون';
  }
  if (v >= 1000 && v % 1000 == 0) return '${thousands(v ~/ 1000)} ألف';
  return thousands(v);
}

String priceRangeLabel(int? min, int? max) {
  if (min != null && max != null) {
    return min == max
        ? priceShort(min)
        : '${priceShort(min)} – ${priceShort(max)}';
  }
  if (min != null) return 'من ${priceShort(min)}';
  if (max != null) return 'لحد ${priceShort(max)}';
  return '';
}

/// The next page of the products a page screen shows (infinite scroll).
void loadMorePageProducts(WidgetRef ref, String pageId) {
  final q = ref.read(pageFilterProvider(pageId));
  ref.read(pageSearchProvider((pageId, q)).notifier).loadMore();
}

/// Pull-to-refresh: the current search and the drawer's options again.
void refreshPageProducts(WidgetRef ref, String pageId) {
  final q = ref.read(pageFilterProvider(pageId));
  ref
    ..invalidate(pageSearchProvider((pageId, q)))
    ..invalidate(pageFacetsProvider(pageId));
}

// ───────────────────────── products section ─────────────────────────

/// Products of one page with a search box, the filters button, active
/// filter chips, results and their loading / empty / error states. Needs an
/// [AppPage] with `endDrawer: PageFilterDrawer(pageId)` and
/// `onNearEnd: () => loadMorePageProducts(ref, pageId)`.
class PageProductsSection extends ConsumerStatefulWidget {
  const PageProductsSection({super.key, required this.pageId});
  final String pageId;

  @override
  ConsumerState<PageProductsSection> createState() =>
      _PageProductsSectionState();
}

class _PageProductsSectionState extends ConsumerState<PageProductsSection> {
  late final _c = TextEditingController(
    text: ref.read(pageFilterProvider(widget.pageId)).q,
  );
  final _focus = FocusNode();
  Timer? _debounce;

  PageFilterNotifier get _filter =>
      ref.read(pageFilterProvider(widget.pageId).notifier);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _typed(String v) {
    setState(() {}); // the ✕ button
    _debounce?.cancel();
    _debounce = Timer(pageSearchDebounce, () {
      if (mounted) _filter.setText(v);
    });
  }

  void _submit(String v) {
    _debounce?.cancel();
    _filter.setText(v);
  }

  void _clearText() {
    _debounce?.cancel();
    _c.clear();
    _filter.setText('');
    setState(() {});
  }

  /// A list shorter than the screen never scrolls, so ask for more here.
  void _fillScreen(PagedState<StoreProduct> s, PageProductQuery q) {
    if (s.loading || s.done || s.error != null || s.page == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pos = Scrollable.maybeOf(context)?.position;
      if (pos != null && pos.hasContentDimensions && pos.extentAfter < 600) {
        ref.read(pageSearchProvider((widget.pageId, q)).notifier).loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(pageFilterProvider(widget.pageId));
    final facets = ref.watch(pageFacetsProvider(widget.pageId)).value;
    final key = (widget.pageId, q);
    final s = ref.watch(pageSearchProvider(key));
    final notifier = ref.read(pageSearchProvider(key).notifier);

    // A page with nothing to sell: no search box, just say so.
    final nothing =
        !q.narrowed &&
        _c.text.isEmpty &&
        ((s.page > 0 && s.items.isEmpty) || facets?.total == 0);
    if (nothing && !s.loading && s.error == null) {
      return const StoreMessage(
        title: 'ماكو منتجات بعد',
        body:
            'هالصفحة بعدها ما ضافت منتجات. تكدر تنشر طلب وتخليها تقدّملك عرض.',
      );
    }

    _fillScreen(s, q);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _searchBox()),
            const SizedBox(width: 10),
            _FilterButton(
              count: q.activeCount,
              onTap: () {
                _focus.unfocus();
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ],
        ),
        if (q.activeCount > 0) ...[
          const SizedBox(height: 10),
          _ActiveChips(
            q: q,
            facets: facets,
            onChange: _filter.set,
            onClear: _filter.clearFilters,
          ),
        ],
        const SizedBox(height: 12),
        if (s.firstLoad)
          const ProductGrid(items: [], skeleton: 4)
        else if (s.page == 0 && s.error != null)
          StoreMessage(
            icon: AppIcon.wifiOff,
            title: 'ما قدرنا نجيب المنتجات',
            body: 'تأكد من النت وجرّب مرة ثانية.',
            onRetry: notifier.reload,
          )
        else if (s.empty)
          _empty(q)
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _countLine(q, s.total, facets),
          ),
          ProductGrid(
            items: [
              for (final p in s.items)
                cardOf(p, widget.pageId, highlight: q.searching ? q.q : null),
            ],
          ),
          if (!s.done || s.error != null)
            LoadMoreFooter(
              loading: s.loading,
              done: s.done,
              failed: s.error != null,
              onRetry: notifier.loadMore,
            ),
        ],
      ],
    );
  }

  Widget _countLine(PageProductQuery q, int total, PageFacets? facets) {
    if (!q.narrowed) {
      final soldOut = facets?.soldOut ?? 0;
      return Text(
        soldOut <= 0
            ? productCountLabel(total)
            : '${productCountLabel(total)} · $soldOut نفدت كميتها',
        style: AppText.muted,
      );
    }
    final all = facets?.total;
    return Text.rich(
      TextSpan(
        style: AppText.muted,
        children: [
          TextSpan(
            text: productCountLabel(total),
            style: AppText.strong.copyWith(fontSize: 13.5),
          ),
          if (q.searching) TextSpan(text: ' لـ «${q.q}»'),
          if (all != null) TextSpan(text: ' من أصل $all'),
          if (q.sort != PageSort.newest)
            TextSpan(text: ' · ${q.sort.label} أولاً'),
        ],
      ),
    );
  }

  Widget _empty(PageProductQuery q) {
    final byName = q.searching;
    return EmptyStateCard(
      icon: AppIcon.search,
      title: byName ? 'ما لكينا منتج بهذا الاسم' : 'ماكو منتج يطابق الفلاتر',
      body: byName
          ? 'تأكد من الكتابة، أو جرّب اسم أقصر مثل «آيفون» أو «شاشة».'
          : 'جرّب توسّع السعر أو تشيل فلتر.',
      action: AppButton(
        byName ? 'امسح البحث' : 'مسح الفلاتر',
        icon: AppIcon.x,
        compact: true,
        variant: AppButtonVariant.ghost,
        onPressed: byName ? _clearText : _filter.clearFilters,
      ),
    );
  }

  Widget _searchBox() {
    final focused = _focus.hasFocus;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: focused ? AppColors.blue : AppColors.border,
            spreadRadius: focused ? 2 : 1.5,
          ),
          if (focused)
            BoxShadow(
              color: AppColors.blue.withValues(alpha: .12),
              spreadRadius: 6,
            ),
        ],
      ),
      child: Row(
        children: [
          AppSvgIcon(
            AppIcon.search,
            color: focused ? AppColors.blue : AppColors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const ValueKey('page-search-field'),
              controller: _c,
              focusNode: _focus,
              onChanged: _typed,
              onSubmitted: _submit,
              textInputAction: TextInputAction.search,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  PageProductQuery.maxQueryLength,
                ),
              ],
              style: AppText.body.copyWith(fontSize: 15),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'دوّر بمنتجات هالصفحة',
                hintStyle: AppText.muted.copyWith(fontSize: 14.5),
              ),
            ),
          ),
          if (_c.text.isNotEmpty)
            Semantics(
              container: true,
              button: true,
              label: 'امسح البحث',
              child: GestureDetector(
                key: const ValueKey('page-search-clear'),
                onTap: _clearText,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.blueTint,
                    shape: BoxShape.circle,
                  ),
                  child: AppSvgIcon(AppIcon.x, color: AppColors.grey, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = count > 0;
    return Semantics(
      container: true,
      button: true,
      label: on ? 'الفلاتر ($count)' : 'الفلاتر',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('page-filter-button'),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.blue : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: on
                    ? null
                    : [BoxShadow(color: AppColors.border, spreadRadius: 1.5)],
              ),
              child: AppSvgIcon(
                AppIcon.filter,
                color: on ? AppColors.white : AppColors.blue,
                size: 20,
              ),
            ),
            if (on)
              PositionedDirectional(
                top: -6,
                end: -6,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.sand, width: 2),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChips extends StatelessWidget {
  const _ActiveChips({
    required this.q,
    required this.facets,
    required this.onChange,
    required this.onClear,
  });
  final PageProductQuery q;
  final PageFacets? facets;
  final ValueChanged<PageProductQuery> onChange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    String slugOf(int id) {
      for (final c in facets?.categories ?? const <PageCategoryFacet>[]) {
        if (c.id == id) return c.slug;
      }
      return '';
    }

    final chips = <Widget>[
      for (final id in q.categories)
        _RemovableChip(
          label: facets?.categoryName(id) ?? 'فئة',
          slug: slugOf(id),
          onRemove: () => onChange(
            q.copyWith(categories: q.categories.where((c) => c != id)),
          ),
        ),
      if (q.min != null || q.max != null)
        _RemovableChip(
          label: priceRangeLabel(q.min, q.max),
          icon: AppIcon.cash,
          onRemove: () =>
              onChange(q.copyWith(min: () => null, max: () => null)),
        ),
      if (q.sort != PageSort.newest)
        _RemovableChip(
          label: q.sort.label,
          icon: AppIcon.barChart,
          onRemove: () => onChange(q.copyWith(sort: PageSort.newest)),
        ),
      if (q.inStock)
        _RemovableChip(
          label: 'متوفر فقط',
          icon: AppIcon.check,
          onRemove: () => onChange(q.copyWith(inStock: false)),
        ),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final c in chips)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: c,
            ),
          Semantics(
            container: true,
            button: true,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                child: Text(
                  'مسح الكل',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
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

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({
    required this.label,
    required this.onRemove,
    this.icon,
    this.slug,
  });
  final String label;
  final VoidCallback onRemove;
  final AppIcon? icon;
  final String? slug;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
    decoration: BoxDecoration(
      color: AppColors.blueTint,
      borderRadius: BorderRadius.circular(99),
      boxShadow: [BoxShadow(color: AppColors.blueRing, spreadRadius: 1)],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (slug != null)
          CategoryIcon(slug, size: 15, color: AppColors.blue)
        else if (icon != null)
          AppSvgIcon(icon!, color: AppColors.blue, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
          ),
        ),
        const SizedBox(width: 6),
        Semantics(
          container: true,
          button: true,
          label: 'شيل $label',
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: AppSvgIcon(AppIcon.x, color: AppColors.blue, size: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

// ───────────────────────── filter drawer ─────────────────────────

/// End drawer of a page's filters. Works on a draft: nothing changes until
/// «طبّق»; closing it any other way drops the draft.
class PageFilterDrawer extends ConsumerStatefulWidget {
  const PageFilterDrawer({super.key, required this.pageId});
  final String pageId;

  @override
  ConsumerState<PageFilterDrawer> createState() => _PageFilterDrawerState();
}

class _PageFilterDrawerState extends ConsumerState<PageFilterDrawer> {
  late PageProductQuery d = ref.read(pageFilterProvider(widget.pageId));

  /// The draft the «طبّق» count is for; follows [d] after a pause.
  late PageProductQuery counted = d;
  Timer? _debounce;

  late final _min = TextEditingController(
    text: d.min == null ? '' : thousands(d.min!),
  );
  late final _max = TextEditingController(
    text: d.max == null ? '' : thousands(d.max!),
  );

  static const quick = [
    (null, 250000, 'أقل من 250 ألف'),
    (250000, 500000, '250 – 500 ألف'),
    (500000, 1000000, '500 ألف – مليون'),
    (1000000, null, 'أكثر من مليون'),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _edit(PageProductQuery next) {
    setState(() => d = next);
    _debounce?.cancel();
    _debounce = Timer(pageSearchDebounce, () {
      if (mounted) setState(() => counted = d);
    });
  }

  void _setRange(int? a, int? b) {
    _min.text = a == null ? '' : thousands(a);
    _max.text = b == null ? '' : thousands(b);
    _edit(d.copyWith(min: () => a, max: () => b));
  }

  void _apply() {
    ref.read(pageFilterProvider(widget.pageId).notifier).apply(d);
    Navigator.of(context).pop();
  }

  String _applyLabel() {
    if (counted != d) return 'طبّق';
    final n = ref
        .watch(pageSearchCountProvider((widget.pageId, counted.tidy)))
        .value;
    return n == null ? 'طبّق' : 'طبّق · ${productCountLabel(n)}';
  }

  @override
  Widget build(BuildContext context) {
    final facetsAsync = ref.watch(pageFacetsProvider(widget.pageId));
    final facets = facetsAsync.value;
    final w = MediaQuery.sizeOf(context).width;
    final inset = MediaQuery.viewPaddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final known = {for (final c in facets?.categories ?? const []) c.id};
    final stale = [
      for (final id in d.categories)
        if (facets != null && !known.contains(id)) id,
    ];
    return Drawer(
      key: const ValueKey('page-filter-drawer'),
      width: (w * .86).clamp(280, 380),
      backgroundColor: AppColors.sand,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          start: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(inset.top),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (facets == null)
                    _Section(
                      title: 'الفئة',
                      child: facetsAsync.hasError
                          ? Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                onPressed: () => ref.invalidate(
                                  pageFacetsProvider(widget.pageId),
                                ),
                                child: const Text(
                                  'ما انحمّلت الفئات، جرّب مرة ثانية',
                                ),
                              ),
                            )
                          : const _Spinner(),
                    )
                  else if (facets.categories.isNotEmpty || stale.isNotEmpty)
                    _Section(
                      title: 'الفئة',
                      child: Column(
                        children: [
                          for (final c in facets.categories)
                            _CheckRow(
                              slug: c.slug,
                              label: c.name,
                              count: c.count,
                              on: d.categories.contains(c.id),
                              onTap: () => _toggleCategory(c.id),
                            ),
                          for (final id in stale)
                            _CheckRow(
                              slug: '',
                              label: 'فئة ما بقى بيها منتجات',
                              count: 0,
                              on: true,
                              onTap: () => _toggleCategory(id),
                            ),
                        ],
                      ),
                    ),
                  _Section(
                    title: 'السعر (دينار)',
                    hint: facets?.minPrice == null || facets?.maxPrice == null
                        ? null
                        : 'بهالصفحة من ${thousands(facets!.minPrice!)} إلى ${thousands(facets.maxPrice!)}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _PriceBox(
                                key: const ValueKey('price-min'),
                                label: 'من',
                                c: _min,
                                onChanged: (v) =>
                                    _edit(d.copyWith(min: () => v)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text('–', style: AppText.muted),
                            ),
                            Expanded(
                              child: _PriceBox(
                                key: const ValueKey('price-max'),
                                label: 'إلى',
                                c: _max,
                                onChanged: (v) =>
                                    _edit(d.copyWith(max: () => v)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final (a, b, l) in quick)
                              _Pill(
                                label: l,
                                on: d.min == a && d.max == b,
                                onTap: () => d.min == a && d.max == b
                                    ? _setRange(null, null)
                                    : _setRange(a, b),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'الترتيب',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in PageSort.values)
                          _Pill(
                            label: s.label,
                            on: d.sort == s,
                            onTap: () => _edit(d.copyWith(sort: s)),
                          ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'التوفر',
                    child: _StockRow(
                      on: d.inStock,
                      onTap: () => _edit(d.copyWith(inStock: !d.inStock)),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + (keyboard > 0 ? 0 : inset.bottom),
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardRing)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppButton(
                      _applyLabel(),
                      key: const ValueKey('page-filter-apply'),
                      onPressed: _apply,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      'مسح الكل',
                      key: const ValueKey('page-filter-reset'),
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        _min.clear();
                        _max.clear();
                        _edit(d.cleared);
                      },
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

  void _toggleCategory(int id) => _edit(
    d.copyWith(
      categories: d.categories.contains(id)
          ? d.categories.where((c) => c != id)
          : [...d.categories, id],
    ),
  );

  Widget _header(double top) => Container(
    padding: EdgeInsets.fromLTRB(16, top + 18, 16, 16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: AppColors.cardRing)),
      borderRadius: const BorderRadiusDirectional.only(
        topStart: Radius.circular(24),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blueTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AppSvgIcon(AppIcon.filter, color: AppColors.blue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فلترة المنتجات',
                style: AppText.strong.copyWith(fontSize: 16.5),
              ),
              Text(
                'بس منتجات هالصفحة',
                style: AppText.muted.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
        Semantics(
          container: true,
          button: true,
          label: 'سكّر',
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sand,
                shape: BoxShape.circle,
              ),
              child: AppSvgIcon(AppIcon.x, color: AppColors.ink, size: 16),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(
      child: SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppColors.blue,
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.hint});
  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.strong.copyWith(fontSize: 14.5)),
        if (hint != null)
          Text(hint!, style: AppText.muted.copyWith(fontSize: 12)),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    excludeSemantics: true,
    toggled: on,
    label: 'متوفر فقط',
    hint: 'أخفي المنتجات اللي نفدت',
    onTap: onTap,
    child: GestureDetector(
      key: const ValueKey('page-filter-stock'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.cardRing, spreadRadius: 1)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'متوفر فقط',
                    style: AppText.strong.copyWith(fontSize: 14.5),
                  ),
                  Text(
                    'أخفي المنتجات اللي نفدت',
                    style: AppText.muted.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            AppToggle(on: on, onTap: onTap),
          ],
        ),
      ),
    ),
  );
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.slug,
    required this.label,
    required this.count,
    required this.on,
    required this.onTap,
  });
  final String slug, label;
  final int count;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      container: true,
      excludeSemantics: true,
      checked: on,
      label: '$label، ${productCountLabel(count)}',
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: on ? AppColors.blueTint : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: on ? AppColors.blue : AppColors.cardRing,
                spreadRadius: on ? 1.5 : 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? AppColors.blue : AppColors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: on ? AppColors.blue : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: on
                    ? const AppSvgIcon(
                        AppIcon.check,
                        color: AppColors.white,
                        size: 14,
                        strokeWidth: 3,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              CategoryIcon(slug, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: on ? AppColors.surface : AppColors.sand,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    selected: on,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: on ? AppColors.blue : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          boxShadow: on
              ? null
              : [BoxShadow(color: AppColors.border, spreadRadius: 1.2)],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: on ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
    ),
  );
}

/// Digits only (Arabic-Indic too), shown with thousands commas.
class PriceInputFormatter extends TextInputFormatter {
  const PriceInputFormatter();

  static const maxDigits = 12; // stays under the API's 10^12 limit

  /// The number in a price box; null when it is empty.
  static int? parse(String text) {
    final d = ArabicFold.digits(text);
    return d.isEmpty ? null : int.tryParse(d);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = ArabicFold.digits(newValue.text)
        .replaceFirst(RegExp('^0+(?=.)'), '');
    if (d.length > maxDigits) d = d.substring(0, maxDigits);
    final text = d.isEmpty ? '' : thousands(int.parse(d));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({
    super.key,
    required this.label,
    required this.c,
    required this.onChanged,
  });
  final String label;
  final TextEditingController c;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: AppColors.border, spreadRadius: 1.5)],
    ),
    child: Row(
      children: [
        Text(label, style: AppText.muted.copyWith(fontSize: 12.5)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: const [PriceInputFormatter()],
            onChanged: (v) => onChanged(PriceInputFormatter.parse(v)),
            style: AppText.body.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintText: '0',
              hintStyle: AppText.muted,
            ),
          ),
        ),
      ],
    ),
  );
}
