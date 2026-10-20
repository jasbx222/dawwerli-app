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
import '../data/post_providers.dart';
import '../domain/request_draft.dart';
import 'widgets/post_widgets.dart';

/// 08 · Category details (size/colour/condition), max price, governorate.
class RequestDetailsScreen extends ConsumerStatefulWidget {
  const RequestDetailsScreen({super.key});

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
  }

  @override
  void dispose() {
    _price.dispose();
    _priceFocus.dispose();
    super.dispose();
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
      backgroundColor: AppColors.white,
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
    final draft = ref.watch(draftProvider);
    final notifier = ref.read(draftProvider.notifier);
    final schema = ref.watch(detailSchemaProvider(draft.category ?? '')).value;
    final priceFocused = _priceFocus.hasFocus || draft.maxPrice != null;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: AppStrings.detailsTitle,
              subtitle: Text(schema?.hint ?? ''),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (schema != null &&
                      (schema.sizes.isNotEmpty ||
                          schema.colors.isNotEmpty)) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _Dropdown(
                            label: AppStrings.sizeLabel,
                            value: draft.size,
                            // Size is the active field in the flow (`.inp.f`).
                            focused: _sizeOpen || draft.size != null,
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
                              (v) =>
                                  notifier.update((d) => d.copyWith(color: v)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  const FieldLabel(AppStrings.conditionLabel),
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
                  const SizedBox(height: 16),
                  const FieldLabel(AppStrings.maxPriceLabel),
                  SizedBox(
                    height: 58,
                    child: InputShell(
                      focused: priceFocused,
                      child: Row(
                        children: [
                          Expanded(
                            child: BareTextField(
                              controller: _price,
                              focusNode: _priceFocus,
                              keyboardType: TextInputType.number,
                              style: AppText.number.copyWith(
                                fontSize: 20,
                                height: 29 / 20,
                                color: AppColors.navy,
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
                          const Text(AppStrings.currency, style: AppText.muted),
                        ],
                      ),
                    ),
                  ),
                  if (schema != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in schema.priceSuggestions)
                          AppChip(
                            thousands(p),
                            gold: true,
                            onTap: () => _setPrice(p),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const FieldLabel(AppStrings.govLabel),
                  InputShell(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.fromAccount(draft.governorate)),
                        const AppSvgIcon(
                          AppIcon.pin,
                          size: 18,
                          color: AppColors.blue,
                        ),
                      ],
                    ),
                  ),
                  if (draft.removedContactInfo) ...[
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
                    AppStrings.reviewRequest,
                    onPressed: () => context.push(Routes.postReview),
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
                  '<svg width="72" height="67" viewBox="0 0 72 67"><path d="M0 0H72L36 67Z" fill="#0F1E3D"/></svg>',
                  width: 6.5,
                  height: 7.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
