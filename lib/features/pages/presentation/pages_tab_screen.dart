import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/catalog.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_page.dart';
import '../../discover/data/discover_data.dart';
import '../../discover/presentation/discover_widgets.dart';
import '../../guest/guest.dart';
import '../../store/presentation/widgets/store_widgets.dart';

/// «الصفحات» tab: search, category chips, «أتابعها» and page cards.
class PagesTabScreen extends ConsumerStatefulWidget {
  const PagesTabScreen({super.key});

  @override
  ConsumerState<PagesTabScreen> createState() => _PagesTabScreenState();
}

class _PagesTabScreenState extends ConsumerState<PagesTabScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  var _q = '';
  int? _category;
  var _following = false;

  DirectoryQuery get _query =>
      (q: _q, categoryId: _category, following: _following);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted && v.trim() != _q) setState(() => _q = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = pagesDirectoryProvider(_query);
    final s = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final categories = ref.watch(catalogProvider).value?.categories ?? const [];
    return LoadMoreListener(
      onLoadMore: notifier.loadMore,
      child: AppPage(
        title: 'الصفحات',
        subtitle: s.page > 0 && !_following && _q.isEmpty && _category == null
            ? '${s.total} صفحة موثّقة تبيع بالتطبيق'
            : 'لكه الصفحة اللي تريدها وتابعها',
        showBack: false,
        onRefresh: notifier.reload,
        nav: AppBottomNav(
          current: NavTab.pages,
          onTab: (t) => switch (t) {
            NavTab.home => context.go(Routes.home),
            NavTab.requests => memberOnly(
              context,
              ref,
              () => context.go(Routes.myRequests),
            ),
            NavTab.pages => null,
            NavTab.account => memberOnly(
              context,
              ref,
              () => context.go(Routes.account),
            ),
          },
          onPost: () =>
              memberOnly(context, ref, () => context.push(Routes.post)),
        ),
        children: [
          StoreWidth(
            maxWidth: 820,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchBox(controller: _search, onChanged: _onSearch),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        selected: _category == null && !_following,
                        onTap: () => setState(() {
                          _category = null;
                          _following = false;
                        }),
                      ),
                      _FilterChip(
                        label: 'أتابعها',
                        icon: AppIcon.heart,
                        selected: _following,
                        onTap: () => memberOnly(
                          context,
                          ref,
                          () => setState(() => _following = !_following),
                        ),
                      ),
                      for (final c in categories)
                        _FilterChip(
                          label: c.name,
                          categoryKey: c.slug,
                          selected: _category == c.id,
                          onTap: () => setState(
                            () => _category = _category == c.id ? null : c.id,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._results(s, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _results(PagedState<PageCard> s, PagesDirectoryNotifier n) {
    if (s.firstLoad) {
      return [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppColors.cardRing, spreadRadius: 1),
              ],
            ),
          ),
        ],
      ];
    }
    if (s.error != null && s.items.isEmpty) {
      return [
        StoreMessage(
          icon: AppIcon.wifiOff,
          title: 'ما قدرنا نجيب الصفحات',
          body: 'تأكد من النت وجرّب مرة ثانية.',
          onRetry: n.reload,
        ),
      ];
    }
    if (s.empty) {
      return [
        _following
            ? const StoreMessage(
                icon: AppIcon.heart,
                title: 'بعدك ما تتابع أي صفحة',
                body: 'تابع الصفحات اللي تعجبك حتى تلكاها هنا بسرعة.',
              )
            : StoreMessage(
                icon: AppIcon.search,
                title: 'ما لكينا صفحة',
                body: _q.isEmpty
                    ? 'ماكو صفحات بهالقسم حالياً.'
                    : 'ماكو صفحة باسم «$_q». جرّب كلمة ثانية.',
              ),
      ];
    }
    return [
      LayoutBuilder(
        builder: (context, box) {
          final cols = box.maxWidth >= 720 ? 2 : 1;
          if (cols == 1) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < s.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  PageDirectoryCard(page: s.items[i]),
                ],
              ],
            );
          }
          const gap = 16.0;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final p in s.items)
                SizedBox(
                  width: (box.maxWidth - gap) / 2,
                  child: PageDirectoryCard(page: p),
                ),
            ],
          );
        },
      ),
      LoadMoreFooter(
        loading: s.loading,
        done: s.done,
        failed: s.error != null,
        onRetry: n.loadMore,
        endText: 'شفت كل الصفحات',
      ),
    ];
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: AppColors.border, spreadRadius: 1.5)],
    ),
    child: Row(
      children: [
        AppSvgIcon(AppIcon.search, color: AppColors.grey, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: AppText.body.copyWith(fontSize: 15),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'دوّر على صفحة بالاسم',
              hintStyle: AppText.muted.copyWith(fontSize: 14.5),
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, v, _) => v.text.isEmpty
              ? const SizedBox.shrink()
              : GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: AppSvgIcon(AppIcon.x, color: AppColors.grey, size: 18),
                ),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.categoryKey,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppIcon? icon;
  final String? categoryKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: icon == null
        ? Center(
            child: AppChip(
              label,
              selected: selected,
              onTap: onTap,
              categoryKey: categoryKey,
            ),
          )
        : GestureDetector(
            onTap: onTap,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.gold
                      : AppColors.goldSoft.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      selected ? AppIcon.heart : icon!,
                      color: AppColors.ink,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: AppText.label.copyWith(
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}
