import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/picker.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/notes.dart';
import '../../../core/widgets/pill.dart';
import '../../auth/data/auth_providers.dart';
import '../../more/more_data.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';

/// 17 · page signup (phone already verified by OTP).
class SellerRegisterScreen extends ConsumerStatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  ConsumerState<SellerRegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends ConsumerState<SellerRegisterScreen> {
  late final s = ref.read(sellerProvider);
  late final _name = TextEditingController(text: s.shopName);
  late final _handle = TextEditingController(text: s.handle);
  late Set<String> _cats = {...s.settings.categories};
  late Set<String> _govs = {...s.settings.governorates};
  bool _terms = true;
  String? _photo;

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    super.dispose();
  }

  Set<String> _flip(Set<String> s, String v) =>
      s.contains(v) ? ({...s}..remove(v)) : {...s, v};

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _handle.text.trim().isNotEmpty &&
      _cats.isNotEmpty &&
      _govs.isNotEmpty &&
      _terms;

  @override
  Widget build(BuildContext context) {
    final govs = ref.watch(governoratesProvider).value ?? const <String>[];
    return AppPage(
      title: 'سجّل صفحتك',
      subtitle: 'وخلّي الزباين يجوك بطلباتهم',
      onBack: () => context.go(Routes.onboarding),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: 'اسم المحل',
                controller: _name,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              LabeledField(
                label: 'حساب انستغرام',
                controller: _handle,
                ltr: true,
                onChanged: (_) => setState(() {}),
                trailing: const AppSvgIcon(
                  AppIcon.camera,
                  color: AppColors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(height: 14),
              const _Label('صورة الصفحة'),
              GestureDetector(
                onTap: () async {
                  final path = await pickPhoto(camera: false);
                  if (path != null) setState(() => _photo = path);
                },
                child: AppCard(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _photo == null
                            ? ColoredBox(
                                color: AppColors.blueTint,
                                child: const SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Icon(Icons.add_a_photo_outlined),
                                ),
                              )
                            : AppImage(_photo!, width: 56, height: 56, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _photo == null ? 'اختار صورة للبيج' : 'تگدر تغيّر الصورة',
                          style: AppText.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _VerifiedPhone(),
              const SizedBox(height: 14),
              const _Label('شتبيع؟'),
              ChipPicker(
                options: [for (final c in ref.watch(catalogCategoriesProvider)) c.name],
                selected: _cats,
                limit: 4,
                categoryKeyOf: ref.watch(catalogCategoriesProvider).slugOf,
                onToggle: (v) => setState(() => _cats = _flip(_cats, v)),
              ),
              const SizedBox(height: 14),
              const _Label('توصل لوين؟'),
              ChipPicker(
                options: govs,
                selected: _govs,
                limit: 3,
                onToggle: (v) => setState(() => _govs = _flip(_govs, v)),
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: () => setState(() => _terms = !_terms),
                child: AppCard(
                  child: Row(
                    children: [
                      _CheckBox(on: _terms),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Text(
                          'أوافق: الزبون يفحص الغرض قبل الدفع، والسعر المرسل مقفول',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                'التالي: التوثيق',
                variant: _valid
                    ? AppButtonVariant.primary
                    : AppButtonVariant.disabled,
                onPressed: !_valid
                    ? null
                    : () async {
                        await ref
                            .read(sellerProvider.notifier)
                            .register(
                              name: _name.text.trim(),
                              handle: _handle.text.trim(),
                              categories: _cats,
                              governorates: _govs,
                              photo: _photo,
                            );
                        if (context.mounted) context.go(Routes.sellerVerify);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(text, style: AppText.label),
  );
}

class _VerifiedPhone extends ConsumerWidget {
  const _VerifiedPhone();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Label('رقم الموبايل (OTP)'),
      AppCard(
        flat: true,
        color: AppColors.surface,
        insets: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Text(
              ref.watch(sellerProvider).phone,
              style: AppText.body.copyWith(fontSize: 15),
            ),
            const Spacer(),
            const AppSvgIcon(
              AppIcon.verified,
              color: AppColors.success,
              size: 18,
            ),
          ],
        ),
      ),
    ],
  );
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: on ? AppColors.blue : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: on ? null : Border.all(color: AppColors.border, width: 1.5),
    ),
    alignment: Alignment.center,
    child: on
        ? const AppSvgIcon(AppIcon.check, color: AppColors.white, size: 16)
        : null,
  );
}

/// 18 · bio code + manual review (first 20 pages).
class SellerVerifyScreen extends ConsumerWidget {
  const SellerVerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    final ctl = ref.read(sellerProvider.notifier);
    final verified = s.status == VerifyStatus.verified;
    return AppPage(
      title: 'وثّق صفحتك',
      subtitle: 'نتأكد إن الصفحة إلك',
      onBack: () => popOr(context, Routes.sellerRegister),
      children: [
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('1. حط هذا الكود ببايو انستغرام', style: AppText.strong),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.verifyCode,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                      color: AppColors.goldSoft,
                    ),
                  ),
                ),
                AppButton(
                  'نسخ الكود',
                  variant: AppButtonVariant.ghost,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: s.verifyCode));
                    showAppToast(context, 'انسخ الكود');
                  },
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
                Text('2. ارجع اضغط «تحقق»', style: AppText.strong),
                const SizedBox(height: 4),
                Text('بعدها تكدر تشيله من البايو', style: AppText.muted),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  verified ? 'افتح صندوق الطلبات' : 'تحقق',
                  onPressed: () async {
                    if (verified) return context.go(Routes.sellerHome);
                    final status = await ctl.checkBio();
                    if (!context.mounted) return;
                    switch (status) {
                      case VerifyStatus.rejected:
                        context.go(Routes.sellerRejected);
                      case VerifyStatus.verified:
                        context.go(Routes.sellerHome);
                      case VerifyStatus.pending || VerifyStatus.none:
                        showAppToast(context, 'صفحتك بالمراجعة، نبلغك أول ما تتوثق');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Gap(_ReviewCard(status: s.status)),
        Gap(
          Text(
            'الطلبات توصل بس للصفحات الموثقة',
            textAlign: TextAlign.center,
            style: AppText.muted,
          ),
          top: AppSpacing.md,
        ),
        if (s.status == VerifyStatus.pending)
          Gap(
            AppButton(
              'حدّث حالة المراجعة',
              icon: AppIcon.refresh,
              variant: AppButtonVariant.ghost,
              // GET /pages/me — the first 20 pages are approved by hand.
              onPressed: () async {
                final status = await ctl.refresh();
                if (!context.mounted) return;
                showAppToast(
                  context,
                  status == VerifyStatus.verified
                      ? 'صفحتك صارت موثّقة'
                      : 'بعدها بالمراجعة',
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.status});
  final VerifyStatus status;

  @override
  Widget build(BuildContext context) {
    final done = status == VerifyStatus.verified;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSize.iconTile,
                height: AppSize.iconTile,
                decoration: BoxDecoration(
                  color: done ? PillTone.teal.bg : AppColors.warnBg,
                  borderRadius: BorderRadius.circular(AppRadius.iconBox),
                ),
                alignment: Alignment.center,
                child: AppSvgIcon(
                  done ? AppIcon.verified : AppIcon.hourglass,
                  color: done ? PillTone.teal.fg : AppColors.warn,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? 'صفحتك موثّقة' : 'قيد المراجعة',
                      style: AppText.strong,
                    ),
                    Text(
                      done ? 'هسه توصلك الطلبات اللي تناسب أصنافك ومحافظاتك' : 'أول 20 صفحة يراجعها فريقنا يدوياً، عادة خلال 24 ساعة',
                      style: AppText.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            children: [
              PillTone.teal.pill('الكود', icon: AppIcon.check),
              done
                  ? PillTone.teal.pill('مراجعة', icon: AppIcon.check)
                  : PillTone.gold.pill('مراجعة', icon: AppIcon.clock),
              done
                  ? PillTone.teal.pill('موثقة', icon: AppIcon.check)
                  : PillTone.stone.pill('موثقة'),
            ],
          ),
        ],
      ),
    );
  }
}

/// 18b · verification rejected.
class SellerRejectedScreen extends ConsumerWidget {
  const SellerRejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    return AppPage(
      title: 'توثيق الصفحة',
      onBack: () => context.go(Routes.sellerRegister),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            'أعد طلب التوثيق',
            onPressed: () async {
              await ref.read(sellerProvider.notifier).retryVerification();
              if (context.mounted) context.go(Routes.sellerVerify);
            },
          ),
          const SizedBox(height: 10),
          AppButton(
            'اعترض على الرفض',
            variant: AppButtonVariant.ghost,
            onPressed: () => context.push(Routes.sellerAppeal('verify')),
          ),
        ],
      ),
      children: [
        Gap(
          BannerCard(
            icon: AppIcon.x,
            title: 'انرفضت صفحتك',
            body: 'السبب: ${s.rejectReason ?? ''}',
          ),
        ),
        Gap(
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('شتسوي هسه؟', style: AppText.strong),
                const SizedBox(height: 6),
                Text(
                  '1. حط الكود ببايو الحساب نفسه اللي سجلت بيه\n2. تأكد الحساب عام مو خاص\n3. اضغط «أعد الطلب»',
                  style: AppText.muted.copyWith(height: 1.9),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
