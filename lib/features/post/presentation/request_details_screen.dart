import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../live/data/live_providers.dart';
import '../data/post_providers.dart';
import '../domain/request_draft.dart';
import 'widgets/post_widgets.dart';

/// 08 · Category details (size/colour/condition), max price, governorate.
class RequestDetailsScreen extends ConsumerStatefulWidget {
  const RequestDetailsScreen({super.key, this.editPriceFor, this.currentPrice});

  /// Price before raising (shown under the field in raise-price mode).
  final int? currentPrice;

  /// Raise-price mode from 10c («ارفع السعر»): saves the new max price to the
  /// live request [editPriceFor] instead of continuing to 09.
  final String? editPriceFor;

  @override
  ConsumerState<RequestDetailsScreen> createState() =>
      _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends ConsumerState<RequestDetailsScreen> {
  late final _price = TextEditingController(
    text: _fmt(ref.read(draftProvider).maxPrice),
  );
  final _priceFocus = FocusNode();
  bool _sizeOpen = false;

  static String _fmt(int? v) => v == null ? '' : thousands(v);

  @override
  void initState() {
    super.initState();
    _priceFocus.addListener(() => setState(() {}));
    if (widget.editPriceFor != null) _priceFocus.requestFocus();
  }

  @override
  void dispose() {
    _price.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final id = widget.editPriceFor;
    if (id == null) {
      context.push(Routes.postReview);
      return;
    }
    final price = ref.read(draftProvider).maxPrice;
    if (price == null || price <= 0) return;
    await ref.read(liveRepositoryProvider).raisePrice(id, price);
    if (mounted) context.pop();
  }

  void _setPrice(int v) {
    _price.text = thousands(v);
    ref.read(draftProvider.notifier).update((d) => d.copyWith(maxPrice: v));
  }

  Future<void> _pick(
    List<String> options,
    void Function(String) onPicked,
  ) async {
    setState(() => _sizeOpen = true);
    final v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
          children: [
            for (final o in options)
              ListTile(
                title: Text(o, style: AppText.strong),
                onTap: () => Navigator.pop(context, o),
              ),
          ],
        ),
      ),
    );
    if (mounted) setState(() => _sizeOpen = false);
    if (v != null) onPicked(v);
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.editPriceFor != null;
    // Raise-price mode: other fields stay visible at .5 and can't be changed.
    Widget dim(Widget w) => edit
        ? ExcludeFocus(
            child: IgnorePointer(child: Opacity(opacity: .5, child: w)),
          )
        : w;
    final draft = ref.watch(draftProvider);
    // REQ-03: shoes can't continue without a size (price edit skips this).
    // Price must be above zero (server rejects 0 too).
    final canContinue =
        (draft.maxPrice ?? 0) > 0 &&
        (widget.editPriceFor != null ||
            !(PostRules.needsSize(draft) && draft.size == null));
    final notifier = ref.read(draftProvider.notifier);
    final schema = ref.watch(detailSchemaProvider(draft.category ?? '')).value;
    final priceFocused = edit || _priceFocus.hasFocus || draft.maxPrice != null;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: edit ? AppStrings.raisePrice : AppStrings.detailsTitle,
              subtitle: Text(
                edit ? AppStrings.raiseSubtitle : schema?.hint ?? '',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (schema != null &&
                      (schema.sizes.isNotEmpty ||
                          schema.colors.isNotEmpty)) ...[
                    dim(
                      Row(
                        children: [
                          Expanded(
                            child: _Dropdown(
                              label: AppStrings.sizeLabel,
                              value: draft.size,
                              // Size is the active field in the flow (`.inp.f`).
                              focused:
                                  !edit && (_sizeOpen || draft.size != null),
                              onTap: () => _pick(
                                schema.sizes,
                                (v) =>
                                    notifier.update((d) => d.copyWith(size: v)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Dropdown(
                              label: AppStrings.colorLabel,
                              value: draft.color,
                              onTap: () => _pick(
                                schema.colors,
                                (v) => notifier.update(
                                  (d) => d.copyWith(color: v),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  dim(const FieldLabel(AppStrings.conditionLabel)),
                  dim(
                    SegTabs(
                      labels: const [
                        AppStrings.condNew,
                        AppStrings.condUsed,
                        AppStrings.condAny,
                      ],
                      selected: draft.condition.index,
                      onSelect: (i) => notifier.update(
                        (d) => d.copyWith(condition: ItemCondition.values[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel(AppStrings.maxPriceLabel),
                  SizedBox(
                    height: 58.86, // design render (device-rounded line box)
                    child: InputShell(
                      focused: priceFocused,
                      exactLine: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: BareTextField(
                              controller: _price,
                              focusNode: _priceFocus,
                              keyboardType: TextInputType.number,
                              style: AppText.number.copyWith(
                                fontSize: 20,
                                height: 29.86 / 20,
                                color: AppColors.ink,
                              ),
                              onChanged: (s) {
                                final v = int.tryParse(
                                  s.replaceAll(RegExp(r'[^0-9]'), ''),
                                );
                                notifier.update(
                                  (d) => d.copyWith(maxPrice: v ?? 0),
                                );
                              },
                            ),
                          ),
                          Text(AppStrings.currency, style: AppText.muted),
                        ],
                      ),
                    ),
                  ),
                  if (edit && widget.currentPrice != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${AppStrings.currentPrice}${thousands(widget.currentPrice!)} ${AppStrings.currency}',
                      style: AppText.muted,
                    ),
                  ],
                  if (schema != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      // Design: 68.9-wide chips, 7.9 apart.
                      spacing: 7.9,
                      runSpacing: 8,
                      children: [
                        for (final p
                            in edit
                                ? const [50000, 55000, 60000]
                                : schema.priceSuggestions)
                          AppChip(
                            thousands(p),
                            gold: true,
                            width: MediaQuery.textScalerOf(context).scale(68.9),
                            onTap: () => _setPrice(p),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  dim(const FieldLabel(AppStrings.govLabel)),
                  dim(
                    InputShell(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppStrings.fromAccount(draft.governorate)),
                          AppSvgIcon(
                            AppIcon.pin,
                            size: 18,
                            color: AppColors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!edit && draft.removedContactInfo) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      flat: true,
                      color: AppColors.dangerBg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.removedPhoneTitle,
                            style: AppText.strong.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                          Text(
                            AppStrings.removedPhoneBody,
                            style: AppText.muted.copyWith(
                              color: AppColors.dangerText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  AppButton(
                    edit ? AppStrings.updatePrice : AppStrings.reviewRequest,
                    variant: canContinue
                        ? AppButtonVariant.primary
                        : AppButtonVariant.disabled,
                    onPressed: canContinue ? _continue : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  static const _gap = 3.6;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.onTap,
    this.focused = false,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool focused;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldLabel(label),
      GestureDetector(
        onTap: onTap,
        child: InputShell(
          focused: focused,
          // Design `43 ▾`: filled navy triangle, ink 6.8×6.9 on the hi-res render,
          // 22.7px below the box's outer top, 4.7px ink gap to the value.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value ?? '', maxLines: 1),
              const SizedBox(width: _gap),
              Padding(
                padding: const EdgeInsets.only(top: 8.4),
                child: SvgPicture.string(
                  '<svg viewBox="0 0 10 10" preserveAspectRatio="none"><path d="M0 0H10L5 10Z" fill="#0F1E3D"/></svg>',
                  width: 7.5,
                  height: 7.6,
                  // Box chosen so the antialiased ink matches the design's 6.8×6.9.
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
