import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/app_inputs.dart';
import '../../core/widgets/page_tile.dart';
import '../auth/data/auth_providers.dart';
import '../guest/guest.dart';
import '../home/presentation/widgets/home_sections.dart';
import '../post/data/post_providers.dart';
import '../post/presentation/widgets/post_widgets.dart';
import 'more_data.dart';

void _back(BuildContext c) => c.canPop() ? c.pop() : c.go(Routes.home);

/// Header + scrolling body shared by every screen in this file.
class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    this.subtitle,
    this.titleIcon,
    required this.children,
    this.bottom,
  });
  final String title;
  final String? subtitle;
  final Widget? titleIcon;
  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppHeader(
                title: title,
                titleIcon: titleIcon,
                subtitle: subtitle == null ? null : Text(subtitle!),
                onBack: () => _back(context),
              ),
              ...children,
            ],
          ),
        ),
        if (bottom != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: bottom,
          ),
      ],
    ),
  );
}

Widget _pad(Widget w, {double top = 14}) =>
    Padding(padding: EdgeInsets.fromLTRB(16, top, 16, 0), child: w);

Widget _sectionLabel(String t) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
  child: Text(t, style: AppText.strong.copyWith(fontSize: 15)),
);

void _toast(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      content: OfflineBanner(
        text,
        icon: AppIcon.check,
        iconColor: AppColors.gold,
      ),
    ),
  );

/// `.tog` 44×26 switch (same as 27).
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.on,
    this.onTap,
    this.locked = false,
  });
  final bool on;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Opacity(
      opacity: locked ? .5 : 1,
      child: Container(
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: on ? AppColors.blue : AppColors.dotOff,
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: on
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

Widget _avatar(String name, {double size = 44}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: AppColors.blueTint,
    borderRadius: BorderRadius.circular(size * .32),
  ),
  alignment: Alignment.center,
  child: Text(
    name.characters.first,
    style: TextStyle(
      fontSize: size * .41,
      height: 1.5,
      fontWeight: FontWeight.w700,
      color: AppColors.blue,
    ),
  ),
);

Widget _stat(String value, String label) => Expanded(
  child: Column(
    children: [
      Text(value, style: AppText.number.copyWith(fontSize: 18)),
      Text(label, style: AppText.muted.copyWith(fontSize: 12)),
    ],
  ),
);

// ───────────────────────── Page profile ─────────────────────────

/// Public page profile — opened from stories, «صفحات مميزة», 45 and ad banners.
class PageProfileScreen extends ConsumerWidget {
  const PageProfileScreen({super.key, required this.pageId});
  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = pageById(pageId);
    final blocked = ref.watch(blockedProvider).contains(p.id);
    return _Page(
      title: p.name,
      titleIcon: const AppSvgIcon(
        AppIcon.verified,
        color: AppColors.gold,
        size: 18,
        strokeWidth: 2.2,
      ),
      subtitle:
          'صفحة موثّقة · ${p.governorate} · توصّل لـ ${p.deliversTo} محافظات',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            'انشر طلب وخليها تقدّم عرض',
            icon: AppIcon.plus,
            onPressed: blocked
                ? null
                : () =>
                      memberOnly(context, ref, () => context.push(Routes.post)),
            variant: blocked
                ? AppButtonVariant.disabled
                : AppButtonVariant.primary,
          ),
          const SizedBox(height: 10),
          AppButton(
            blocked ? 'الغي الحظر' : 'احظر هالصفحة',
            icon: AppIcon.lock,
            variant: AppButtonVariant.ghost,
            onPressed: () => memberOnly(context, ref, () {
              final n = ref.read(blockedProvider.notifier);
              if (blocked) {
                n.unblock(p.id);
                _toast(context, 'لغيت حظر ${p.name}');
              } else {
                n.block(p.id);
                _toast(context, 'حظرت ${p.name}، ما تشوف طلباتك بعد');
              }
            }),
          ),
        ],
      ),
      children: [
        _pad(
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    _avatar(p.name, size: 58),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: AppText.strong.copyWith(fontSize: 17),
                          ),
                          RatingLine(
                            text: '${p.rating} · ${p.deals} صفقة بالتطبيق',
                            fontSize: 12.5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _stat('${p.rating}', 'التقييم'),
                    _stat('${p.deals}', 'صفقة مؤكدة'),
                    _stat('${p.replyMinutes} د', 'سرعة الرد'),
                  ],
                ),
              ],
            ),
          ),
        ),
        _sectionLabel('شنو تبيع'),
        _pad(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in p.categories) AppChip(c)],
          ),
          top: 10,
        ),
        _pad(
          AppCard(
            flat: true,
            color: AppColors.blueTint,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSvgIcon(
                  AppIcon.shieldCheck,
                  color: AppColors.blue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ما تكدر تراسل الصفحة من هنا. انشر طلبك، وإذا تبيع هالصنف وتوصّل لمحافظتك يوصلها وتقدّم عرض بسعر ثابت. رقمك ينكشف بس للصفحة اللي تختارها.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.7,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _pad(
          AppCard(
            flat: true,
            color: AppColors.warnBg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSvgIcon(
                  AppIcon.alert,
                  color: AppColors.warn,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'افحص الغرض قدام المندوب قبل ما تدفع. الدفع عند الاستلام بس، لا تحوّل عربون.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.7,
                      color: AppColors.warnText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (blocked)
          _pad(
            const AlertCard(
              title: 'هالصفحة محظورة',
              body: 'ما تشوف طلباتك ولا تكدر تقدّملك عروض.',
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Categories ─────────────────────────

/// «الأكثر طلباً» → «شوف الكل»: every category.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gov = ref.watch(regionProvider).governorate;
    return _Page(
      title: 'كل الأصناف',
      subtitle: 'اختار صنف حتى تشوف صفحاته ب$gov',
      children: [
        _pad(
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final c in catalogCategories)
                _CategoryTile(
                  c,
                  onTap: () => context.push(Routes.category(c.id)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(this.c, {this.onTap});
  final CatalogCategory c;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: AssetImage(c.image), fit: BoxFit.cover),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x000F1E3D), Color(0xCC0F1E3D)],
            stops: [.35, 1],
          ),
        ),
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              c.name,
              style: AppText.strong.copyWith(
                color: AppColors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// One category: post CTA + verified pages selling it in my governorate.
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = categoryById(categoryId);
    final gov = ref.watch(regionProvider).governorate;
    final pages = pagesInCategory(c.name);
    return _Page(
      title: c.name,
      subtitle: 'صفحات موثّقة تبيع ${c.name} وتوصّل ل$gov',
      bottom: AppButton(
        'اطلب ${c.name}',
        icon: AppIcon.plus,
        onPressed: () => memberOnly(context, ref, () {
          ref
              .read(draftProvider.notifier)
              .update((d) => d.copyWith(category: c.name));
          context.push(Routes.post);
        }),
      ),
      children: [
        _pad(
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(c.image, height: 140, fit: BoxFit.cover),
          ),
        ),
        _sectionLabel('أفضل صفحات ${c.name} ب$gov'),
        if (pages.isEmpty)
          _pad(
            AppCard(
              child: Column(
                children: [
                  AppSvgIcon(
                    AppIcon.clipboard,
                    color: AppColors.navy.withValues(alpha: .3),
                    size: 56,
                  ),
                  const SizedBox(height: 8),
                  Text('ماكو صفحات بهالصنف حالياً', style: AppText.strong),
                  Text(
                    'انشر طلبك، وأول ما تنضم صفحة توصلها',
                    style: AppText.muted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        for (final p in pages)
          _pad(
            PageTile(
              page: p.summary,
              onTap: () => context.push(Routes.pageProfile(p.id)),
            ),
            top: 10,
          ),
      ],
    );
  }
}

// ───────────────────────── Feed ─────────────────────────

/// «هسه يدوّرون» → «شوف الكل».
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) => _Page(
    title: 'هسه يدوّرون',
    subtitle: 'طلبات صارت بآخر ساعة بكل العراق',
    children: [
      _pad(const LiveFeedCard(items: fullFeed), top: 14),
      _pad(
        Text(
          'نعرض الصنف والمحافظة وعدد العروض بس، بدون صورة أو اسم أو منطقة الزبون.',
          textAlign: TextAlign.center,
          style: AppText.muted,
        ),
      ),
    ],
  );
}

// ───────────────────────── Region ─────────────────────────

class RegionScreen extends ConsumerStatefulWidget {
  const RegionScreen({super.key});

  @override
  ConsumerState<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends ConsumerState<RegionScreen> {
  late String _gov = ref.read(regionProvider).governorate;
  late final _area = TextEditingController(text: ref.read(regionProvider).area);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _area.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final govs = ref.watch(governoratesProvider).value ?? const <String>[];
    return _Page(
      title: 'المحافظة والمنطقة',
      subtitle: 'طلباتك توصل للصفحات اللي توصّل لهنا',
      bottom: AppButton(
        'احفظ',
        onPressed: () {
          ref.read(regionProvider.notifier).save(_gov, _area.text.trim());
          _toast(context, 'انحفظت منطقتك');
          _back(context);
        },
      ),
      children: [
        _pad(const FieldLabel('المحافظة'), top: 18),
        _pad(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in govs)
                AppChip(
                  g,
                  selected: g == _gov,
                  onTap: () => setState(() => _gov = g),
                ),
            ],
          ),
          top: 0,
        ),
        _pad(const FieldLabel('المنطقة'), top: 18),
        _pad(
          InputShell(
            focused: _focus.hasFocus,
            child: Row(
              children: [
                Expanded(
                  child: BareTextField(controller: _area, focusNode: _focus),
                ),
                const AppSvgIcon(AppIcon.pin, color: AppColors.blue, size: 18),
              ],
            ),
          ),
          top: 0,
        ),
        _pad(
          Text(
            'المنطقة ما تنعرض للصفحات إلا بعد ما تختار عرض',
            style: AppText.muted,
          ),
          top: 8,
        ),
      ],
    );
  }
}

// ───────────────────────── Notifications ─────────────────────────

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notifPrefsProvider);
    final n = ref.read(notifPrefsProvider.notifier);
    return _Page(
      title: 'الإشعارات',
      subtitle: 'اختار شنو يوصلك',
      children: [
        _pad(
          AppCard(
            insets: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final (i, p) in NotifPref.values.indexed)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: i == NotifPref.values.length - 1
                        ? null
                        : BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.divider),
                            ),
                          ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                p.locked ? '${p.sub} · ضروري، ما ينطفي' : p.sub,
                                style: AppText.muted.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AppToggle(
                          on: prefs[p] ?? true,
                          locked: p.locked,
                          onTap: () => n.toggle(p),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        _pad(
          Text(
            'إذا طفيت الإشعارات من إعدادات التلفون، ما توصلك حتى لو مفعّلة هنا.',
            style: AppText.muted,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Blocked pages ─────────────────────────

class BlockedPagesScreen extends ConsumerWidget {
  const BlockedPagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(blockedProvider);
    return _Page(
      title: 'الصفحات المحظورة',
      subtitle: 'الصفحة المحظورة ما تشوف طلباتك',
      children: [
        if (ids.isEmpty)
          _pad(
            AppCard(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  AppSvgIcon(
                    AppIcon.lock,
                    color: AppColors.navy.withValues(alpha: .3),
                    size: 56,
                  ),
                  const SizedBox(height: 10),
                  Text('ما حاظر أي صفحة', style: AppText.strong),
                  Text(
                    'تكدر تحظر صفحة من ملفها أو من شاشة البلاغ',
                    style: AppText.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        for (final id in ids)
          _pad(
            AppCard(
              insets: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _avatar(pageById(id).name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push(Routes.pageProfile(id)),
                      child: Text(pageById(id).name, style: AppText.strong),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: AppButton(
                      'الغي الحظر',
                      compact: true,
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        ref.read(blockedProvider.notifier).unblock(id);
                        _toast(context, 'لغيت حظر ${pageById(id).name}');
                      },
                    ),
                  ),
                ],
              ),
            ),
            top: 10,
          ),
      ],
    );
  }
}

// ───────────────────────── Terms ─────────────────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    (
      'شنو دوّرلي؟',
      'سوق عكسي: تنشر شتريد، والصفحات الموثّقة تقدّملك عروض بسعر ثابت.',
    ),
    (
      'الفلوس',
      'التطبيق ما يمسك فلوس. الدفع عند الاستلام بينك وبين الصفحة، وافحص الغرض قدام المندوب قبل ما تدفع.',
    ),
    (
      'السعر مقفول',
      'سعر العرض ما يتغيّر بعد ما ينرسل. إذا الصفحة غيّرته بالواتساب بلّغ «السعر تغيّر».',
    ),
    ('رقمك', 'ينكشف بس للصفحة اللي تختار عرضها، وينشال بعد ما يخلص الطلب.'),
    (
      'الممنوعات',
      'ممنوع طلب أسلحة، أدوية، مخدرات أو محتوى للكبار، وممنوع تكتب رقمك أو حسابك بالطلب.',
    ),
    (
      'الطلبات',
      'بحد أقصى 3 طلبات مفتوحة، وكل طلب ياخذ 5 عروض. تأكد إنك جاهز تشتري خلال 48 ساعة.',
    ),
    (
      'المخالفات',
      '3 مخالفات مؤكدة خلال 30 يوم توقف النشر 7 أيام، والإيقاف الثاني دائمي. تكدر تعترض على أي قرار.',
    ),
    (
      'الإعلانات',
      'كل شي مدفوع ينكتب عليه «مُموّل» أو «إعلان»، وما يخفي العروض الأرخص.',
    ),
  ];

  @override
  Widget build(BuildContext context) => _Page(
    title: 'الشروط',
    subtitle: 'آخر تحديث 19/10/2026',
    children: [
      _pad(
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (t, b) in _sections) ...[
                const SizedBox(height: 8),
                Text(
                  t,
                  style: AppText.strong.copyWith(fontSize: 15, height: 1.85),
                ),
                Text(
                  b,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.85,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

// ───────────────────────── Contact ─────────────────────────

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  static const _topics = [
    'مشكلة بالتطبيق',
    'مشكلة ويا صفحة',
    'اقتراح',
    'غيرها',
  ];
  String _topic = _topics.first;
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Widget _row(AppIcon icon, String label, String sub, VoidCallback onTap) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              AppSvgIcon(icon, color: AppColors.blue, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(sub, style: AppText.muted.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              AppSvgIcon(
                AppIcon.chevronLeft,
                color: AppColors.checkOff,
                size: 18,
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ok = _text.text.trim().length >= 10;
    return _Page(
      title: 'تواصل ويانا',
      subtitle: 'نرد خلال 48 ساعة',
      bottom: _sent
          ? AppButton('رجوع لحسابي', onPressed: () => _back(context))
          : AppButton(
              'دز الرسالة',
              variant: ok
                  ? AppButtonVariant.primary
                  : AppButtonVariant.disabled,
              onPressed: ok ? () => setState(() => _sent = true) : null,
            ),
      children: [
        _pad(
          AppCard(
            insets: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _row(
                  AppIcon.clipboard,
                  'مشكلة بطلب',
                  'افتح الطلب من «طلباتي» وبلّغ منه',
                  () => context.go(Routes.myRequests),
                ),
                Divider(height: 1, color: AppColors.divider),
                _row(
                  AppIcon.flag,
                  'اعترض على قرار أو مخالفة',
                  'نراجعه خلال 48 ساعة',
                  () => context.push(Routes.disputeNew),
                ),
                Divider(height: 1, color: AppColors.divider),
                _row(
                  AppIcon.shieldCheck,
                  'وضع حسابي',
                  'المخالفات والإيقاف',
                  () => context.push(Routes.standing),
                ),
              ],
            ),
          ),
        ),
        if (_sent)
          _pad(
            AppCard(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const AppSvgIcon(
                      AppIcon.check,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('وصلت رسالتك', style: AppText.strong),
                  Text(
                    'فريق دوّرلي يرد عليك بالإشعارات خلال 48 ساعة',
                    style: AppText.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          )
        else ...[
          _pad(const FieldLabel('شنو الموضوع؟'), top: 18),
          _pad(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _topics)
                  AppChip(
                    t,
                    selected: t == _topic,
                    onTap: () => setState(() => _topic = t),
                  ),
              ],
            ),
            top: 0,
          ),
          _pad(const FieldLabel('اكتبلنا'), top: 18),
          _pad(
            InputShell(
              focused: _focus.hasFocus,
              child: TextField(
                controller: _text,
                focusNode: _focus,
                minLines: 4,
                maxLines: 6,
                style: AppText.body,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'وصّف المشكلة بالتفصيل (10 حروف على الأقل)',
                ),
              ),
            ),
            top: 0,
          ),
          _pad(
            Text(
              'لا تكتب رقمك أو حسابك، نرد عليك داخل التطبيق.',
              style: AppText.muted,
            ),
            top: 8,
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── Post: change category ─────────────────────────

class CategoryPickerScreen extends ConsumerWidget {
  const CategoryPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(draftProvider).category;
    return _Page(
      title: 'غيّر الصنف',
      subtitle: 'الصنف يحدد أي صفحات يوصلها طلبك',
      children: [
        _pad(
          AppCard(
            insets: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final (i, c) in catalogCategories.indexed)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ref
                          .read(draftProvider.notifier)
                          .update((d) => d.copyWith(category: c.name));
                      _back(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: i == catalogCategories.length - 1
                          ? null
                          : BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.divider),
                              ),
                            ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              c.image,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c.name,
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (c.name == current)
                            const AppSvgIcon(
                              AppIcon.check,
                              color: AppColors.blue,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
