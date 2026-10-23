import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/ishtar_pattern.dart';
import '../../../core/widgets/state_card.dart';
import '../../../core/api/picker.dart';
import '../data/seller_controller.dart';
import '../domain/seller_models.dart';
import 'widgets/seller_widgets.dart';


/// Top-up form shared by 22 (inline card) and 22b (sheet when the balance is 0).
class TopupForm extends ConsumerStatefulWidget {
  const TopupForm({super.key, this.onDone});
  final VoidCallback? onDone;

  @override
  ConsumerState<TopupForm> createState() => _TopupFormState();
}

class _TopupFormState extends ConsumerState<TopupForm> {
  final _ref = TextEditingController();
  final _amount = TextEditingController(text: '25000');
  String? _method;
  String? _receipt;
  TopupError? _error;

  @override
  void dispose() {
    _ref.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    final methods = ref.read(sellerProvider).config.topupMethods;
    final e = await ref
        .read(sellerProvider.notifier)
        .topup(_method ?? methods.first, _ref.text, amount, _receipt);
    if (!mounted) return;
    setState(() => _error = e);
    if (e == null) {
      _ref.clear();
      setState(() => _receipt = null);
      widget.onDone?.call();
    }
  }

  Future<void> _pickReceipt() async {
    final path = await pickPhoto(camera: false);
    if (path != null && mounted) setState(() => _receipt = path);
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref
        .watch(sellerProvider)
        .topups
        .where((t) => t.status == TopupStatus.pending)
        .toList();
    final config = ref.watch(sellerProvider).config;
    final methods = config.topupMethods;
    final method = _method ?? methods.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final m in methods)
              AppChip(
                m,
                selected: m == method,
                onTap: () => setState(() => _method = m),
              ),
          ],
        ),
        const SizedBox(height: 10),
        LabeledField(
          controller: _amount,
          keyboardType: TextInputType.number,
          trailing: Text('د.ع', style: AppText.muted),
        ),
        const SizedBox(height: 10),
        LabeledField(
          label: 'رقم العملية *',
          controller: _ref,
          ltr: true,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 10),
        UploadBox(
          label: 'ارفع صورة وصل التحويل',
          done: _receipt != null,
          onTap: _pickReceipt,
        ),
        if (_error case final e?) ...[
          const SizedBox(height: 10),
          StateCard(
            icon: AppIcon.alert,
            tint: AppColors.dangerBg,
            tone: AppColors.danger,
            title: switch (e) {
              TopupError.duplicateRef => 'رقم العملية مستخدم قبل',
              TopupError.missingRef => 'اكتب رقم العملية',
              TopupError.missingReceipt => 'ارفع صورة الوصل',
              TopupError.belowMin => 'المبلغ أقل من الحد الأدنى',
            },
            body: TextSpan(
              text: switch (e) {
                TopupError.duplicateRef =>
                  'هذا الرقم انرفع بوصل ثاني. تأكد منه وارجع جرّب.',
                TopupError.missingRef =>
                  'المالية تطابقه ويا كشف الحساب قبل الموافقة.',
                TopupError.missingReceipt => 'بدون وصل ما نكدر نأكد التحويل.',
                TopupError.belowMin => 'أقل تعبئة ${iqd(config.minTopUp)}.',
              },
            ),
            action: e == TopupError.duplicateRef ? 'عدّل رقم العملية' : null,
            actionVariant: AppButtonVariant.ghost,
            onAction: () => setState(() {
              _ref.clear();
              _error = null;
            }),
          ),
        ],
        for (final t in pending) ...[
          const SizedBox(height: 10),
          StateCard(
            icon: AppIcon.hourglass,
            tint: AppColors.warnBg,
            tone: AppColors.warn,
            title: 'وصل التحويل بانتظار موافقة المالية',
            body: TextSpan(
              text:
                  '${iqd(t.amount)} · ${t.method} · ${t.ref} · رفعته ${t.at.hour}:${t.at.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppButton('دز للمراجعة', onPressed: _send),
      ],
    );
  }
}

/// 22b · «عبّي رصيدك» sheet raised when an offer can't be paid for.
class TopupSheet extends ConsumerWidget {
  const TopupSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C070E1F),
    builder: (_) => const TopupSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sellerProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: AppSheet(
          children: [
            Center(
              child: IshtarBackground(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.blue, AppColors.navy],
                ),
                child: const SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: AppSvgIcon(
                      AppIcon.cash,
                      color: AppColors.goldSoft,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'عبّي رصيدك',
              textAlign: TextAlign.center,
              style: AppText.strong.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 6),
            Text(
              'خلصت الاختيارات المجانية العشرة، ورصيدك ${iqd(s.balance)}. لازم ${iqd(s.config.selectionFee)} حتى تدز العرض.',
              textAlign: TextAlign.center,
              style: AppText.muted,
            ),
            const SizedBox(height: 14),
            TopupForm(
              onDone: () {
                Navigator.pop(context);
                context.push(Routes.sellerWallet);
              },
            ),
          ],
        ),
      ),
    );
  }
}
