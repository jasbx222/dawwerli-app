import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/loading_block.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/radio_row.dart';
import '../data/page_store_orders.dart';
import 'widgets/page_side_widgets.dart';

/// «المناديب» — the page's own delivery people. Name + phone show to the
/// customer only once an order is out for delivery with them.
class CouriersScreen extends ConsumerWidget {
  const CouriersScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Courier? c]) async {
    final saved = await CourierFormSheet.show(context, courier: c);
    if (saved != null) ref.invalidate(couriersProvider);
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, Courier c) async {
    try {
      await ref.read(couriersRepoProvider).update(c, active: !c.active);
      ref.invalidate(couriersProvider);
    } catch (e) {
      if (context.mounted) showAppToast(context, pageOrderError(e));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Courier c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('تحذف ${c.name}؟'),
        content: const Text('الطلبات القديمة تبقى بيها اسمه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text(
              'احذف',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(couriersRepoProvider).delete(c.id);
      ref.invalidate(couriersProvider);
    } catch (e) {
      if (context.mounted) showAppToast(context, pageOrderError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(couriersProvider);
    return AppPage(
      title: 'المناديب',
      subtitle: 'منو يوصّل طلباتك',
      onRefresh: () => ref.refresh(couriersProvider.future),
      bottom: AppButton(
        'أضف مندوب',
        icon: AppIcon.userPlus,
        onPressed: () => _edit(context, ref),
      ),
      children: [
        Gap(
          AppCard(
            flat: true,
            color: AppColors.blueTint,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSvgIcon(
                  AppIcon.shield,
                  color: AppColors.blue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'لمن تطلّع الطلب للتوصيل تختار المندوب، والزبون يشوف اسمه ورقمه داخل الطلب بس. ما نتابع موقع المندوب.',
                    style: AppText.muted.copyWith(color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
        list.when(
          skipLoadingOnRefresh: true,
          loading: () => const Gap(LoadingBlock()),
          error: (e, _) => Gap(
            RetryCard(
              error: e,
              onRetry: () => ref.invalidate(couriersProvider),
            ),
          ),
          data: (items) => items.isEmpty
              ? Gap(
                  AppCard(
                    child: Column(
                      children: [
                        const AppSvgIcon(
                          AppIcon.truck,
                          color: AppColors.blue,
                          size: 34,
                        ),
                        const SizedBox(height: 8),
                        Text('ما عندك مناديب بعد', style: AppText.strong),
                        Text(
                          'أضف اسم ورقم المندوب حتى تكدر تطلّع الطلبات للتوصيل.',
                          style: AppText.muted,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final c in items)
                      Gap(
                        _CourierCard(
                          c,
                          onEdit: () => _edit(context, ref, c),
                          onToggle: () => _toggle(context, ref, c),
                          onDelete: () => _delete(context, ref, c),
                        ),
                        top: 10,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CourierCard extends StatelessWidget {
  const _CourierCard(
    this.c, {
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  final Courier c;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.active ? AppColors.blueTint : AppColors.tabTrack,
            borderRadius: BorderRadius.circular(14),
          ),
          child: AppSvgIcon(
            AppIcon.truck,
            color: c.active ? AppColors.blue : AppColors.grey,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      c.name,
                      style: AppText.strong,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  c.active
                      ? PillTone.teal.pill('شغّال')
                      : PillTone.stone.pill('موقوف'),
                ],
              ),
              Text(
                c.phone,
                style: AppText.muted,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        PopupMenuButton<int>(
          tooltip: 'خيارات',
          icon: AppSvgIcon(AppIcon.pencil, color: AppColors.grey, size: 18),
          onSelected: (v) => switch (v) {
            0 => onEdit(),
            1 => onToggle(),
            _ => onDelete(),
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 0, child: Text('عدّل')),
            PopupMenuItem(value: 1, child: Text(c.active ? 'أوقفه' : 'فعّله')),
            const PopupMenuItem(value: 2, child: Text('احذف')),
          ],
        ),
      ],
    ),
  );
}

/// Add / edit a courier; pops with the saved [Courier].
class CourierFormSheet extends ConsumerStatefulWidget {
  const CourierFormSheet({super.key, this.courier});
  final Courier? courier;

  static Future<Courier?> show(BuildContext context, {Courier? courier}) =>
      showModalBottomSheet<Courier>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x8C070E1F),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: CourierFormSheet(courier: courier),
        ),
      );

  @override
  ConsumerState<CourierFormSheet> createState() => _CourierFormState();
}

class _CourierFormState extends ConsumerState<CourierFormSheet> {
  late final _name = TextEditingController(text: widget.courier?.name);
  late final _phone = TextEditingController(text: widget.courier?.phone);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'اكتب اسم ورقم المندوب');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(couriersRepoProvider);
    try {
      final c = widget.courier;
      final saved = c == null
          ? await repo.create(name, phone)
          : await repo.update(c, name: name, phone: phone);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) setState(() => _error = pageOrderError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppSheet(
    children: [
      Text(
        widget.courier == null ? 'مندوب جديد' : 'عدّل المندوب',
        style: AppText.strong.copyWith(fontSize: 18),
      ),
      const SizedBox(height: AppSpacing.md),
      LabeledField(label: 'الاسم', controller: _name, hint: 'مثلاً: علي'),
      const SizedBox(height: AppSpacing.md),
      LabeledField(
        label: 'رقم التلفون',
        controller: _phone,
        hint: '07xxxxxxxxx',
        ltr: true,
        keyboardType: TextInputType.phone,
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: AppText.body.copyWith(color: AppColors.danger)),
      ],
      const SizedBox(height: AppSpacing.lg),
      AppButton(_busy ? '...' : 'احفظ', onPressed: _busy ? null : _save),
    ],
  );
}

/// «منو يوصّله؟» — picks an active courier before «طلع للتوصيل».
class CourierPickerSheet extends ConsumerStatefulWidget {
  const CourierPickerSheet({super.key});

  static Future<Courier?> show(BuildContext context) =>
      showModalBottomSheet<Courier>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x8C070E1F),
        builder: (_) => const CourierPickerSheet(),
      );

  @override
  ConsumerState<CourierPickerSheet> createState() => _PickerState();
}

class _PickerState extends ConsumerState<CourierPickerSheet> {
  String? _sel;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(couriersProvider);
    final active = [
      for (final c in async.value ?? const <Courier>[])
        if (c.active) c,
    ];
    final chosen =
        active.where((c) => c.id == _sel).firstOrNull ??
        (active.length == 1 ? active.first : null);
    return AppSheet(
      children: [
        Text('منو يوصّل الطلب؟', style: AppText.strong.copyWith(fontSize: 18)),
        const SizedBox(height: 4),
        Text('الزبون يشوف اسم المندوب ورقمه داخل الطلب.', style: AppText.muted),
        const SizedBox(height: AppSpacing.md),
        if (async.isLoading && async.value == null)
          const LoadingBlock()
        else if (active.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'ما عندك مندوب شغّال. أضف واحد حتى تطلّع الطلب.',
              style: AppText.body,
            ),
          )
        else
          for (final c in active)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RadioRow(
                label: '${c.name} · \u202A${c.phone}\u202C',
                on: chosen?.id == c.id,
                onTap: () => setState(() => _sel = c.id),
              ),
            ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          'طلّعه ويا المندوب',
          variant: AppButtonVariant.navy,
          icon: AppIcon.truck,
          onPressed: chosen == null
              ? null
              : () => Navigator.of(context).pop(chosen),
        ),
        const SizedBox(height: 10),
        AppButton(
          'إدارة المناديب',
          variant: AppButtonVariant.ghost,
          icon: AppIcon.userPlus,
          onPressed: () async {
            await context.push(Routes.sellerCouriers);
            ref.invalidate(couriersProvider);
          },
        ),
      ],
    );
  }
}
