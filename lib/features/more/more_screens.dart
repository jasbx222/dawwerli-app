import 'package:flutter/material.dart';

import '../../core/widgets/app_image.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/app_inputs.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_toggle.dart';
import '../../core/widgets/notes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/page_tile.dart';
import '../auth/data/auth_providers.dart';
import '../guest/guest.dart';
import '../home/presentation/widgets/home_sections.dart';
import '../post/data/post_providers.dart';
import '../../core/api/api_client.dart';
import 'more_data.dart';

export '../pages/presentation/page_profile_screen.dart';

void _back(BuildContext c) => popOr(c);
Widget _pad(Widget w, {double top = 14}) => Gap(w, top: top);
Widget _sectionLabel(String t) => SectionLabel(t);
void _toast(BuildContext c, String t) => showAppToast(c, t);
Widget _avatar(String name, {double size = AppSize.iconTile, String? image}) {
  if (image != null && image.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 3),
      child: AppImage(image, width: size, height: size, fit: BoxFit.cover),
    );
  }
  return LetterAvatar(name, size: size);
}

// ───────────────────────── Categories ─────────────────────────

/// «الأكثر طلباً» → «شوف الكل»: every category.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gov = ref.watch(regionProvider).governorate;
    return AppPage(
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
              for (final c in ref.watch(catalogCategoriesProvider))
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
        image: DecorationImage(image: appImage(c.image), fit: BoxFit.cover),
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CategoryIconTile(
                c.slug,
                size: 34,
                color: AppColors.blue,
                background: AppColors.white.withValues(alpha: .92),
              ),
              Text(
                c.name,
                style: AppText.strong.copyWith(
                  color: AppColors.white,
                  fontSize: 15,
                ),
              ),
            ],
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
    final c = ref.watch(catalogCategoriesProvider).byId(categoryId);
    final gov = ref.watch(regionProvider).governorate;
    final pages =
        ref.watch(categoryPagesProvider(categoryId)).value ?? const [];
    return AppPage(
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
            child: AppImage(c.image, height: 140, fit: BoxFit.cover),
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
              page: p,
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
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPage(
    title: 'هسه يدوّرون',
    subtitle: 'طلبات صارت بآخر ساعة بكل العراق',
    children: [
      _pad(
        LiveFeedCard(items: ref.watch(fullFeedProvider).value ?? const []),
        top: 14,
      ),
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
    return AppPage(
      title: 'المحافظة والمنطقة',
      subtitle: 'طلباتك توصل للصفحات اللي توصّل لهنا',
      bottom: AppButton(
        'احفظ',
        onPressed: () async {
          await ref.read(regionProvider.notifier).save(_gov, _area.text.trim());
          if (!context.mounted) return;
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
                AppSvgIcon(AppIcon.pin, color: AppColors.blue, size: 18),
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
    return AppPage(
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
    final names = ref.read(blockedProvider.notifier);
    return AppPage(
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
                  _avatar(names.nameOf(id)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push(Routes.pageProfile(id)),
                      child: Text(names.nameOf(id), style: AppText.strong),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: AppButton(
                      'الغي الحظر',
                      compact: true,
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        names.unblock(id);
                        _toast(context, 'لغيت حظر ${names.nameOf(id)}');
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

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPage(
    title: 'الشروط',
    subtitle: 'آخر تحديث 19/10/2026',
    children: [
      _pad(
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (t, b)
                  in ref.watch(legalProvider('terms')).value ??
                      const <(String, String)>[]) ...[
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

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
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

  Future<void> _send() async {
    await ref.read(apiClientProvider).post<void>('/api/v1/contact', {
      'topic': _topic,
      'text': _text.text.trim(),
    });
    if (mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final ok = _text.text.trim().length >= 10;
    return AppPage(
      title: 'تواصل ويانا',
      subtitle: 'نرد خلال 48 ساعة',
      bottom: _sent
          ? AppButton('رجوع لحسابي', onPressed: () => _back(context))
          : AppButton(
              'دز الرسالة',
              variant: ok
                  ? AppButtonVariant.primary
                  : AppButtonVariant.disabled,
              onPressed: ok ? _send : null,
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
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: AppSvgIcon(
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
    return AppPage(
      title: 'غيّر الصنف',
      subtitle: 'الصنف يحدد أي صفحات يوصلها طلبك',
      children: [
        _pad(
          AppCard(
            insets: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final (i, c)
                    in ref.watch(catalogCategoriesProvider).indexed)
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
                      decoration:
                          i == ref.watch(catalogCategoriesProvider).length - 1
                          ? null
                          : BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.divider),
                              ),
                            ),
                      child: Row(
                        children: [
                          CategoryIconTile(
                            c.slug,
                            size: 40,
                            color: c.name == current
                                ? AppColors.white
                                : AppColors.blue,
                            background: c.name == current
                                ? AppColors.blue
                                : null,
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
                            AppSvgIcon(
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
