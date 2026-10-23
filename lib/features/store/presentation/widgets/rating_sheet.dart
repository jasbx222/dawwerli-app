import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../data/page_search_data.dart';
import '../../data/store_data.dart';
import 'store_widgets.dart';

/// Opens the rate sheet for a received product; refreshes product, reviews and
/// lists afterwards. Returns true when the rating was saved.
Future<bool> showRateSheet(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
  required String productName,
  String pageId = '',
}) async {
  final mine = await ref.read(myRatingProvider(productId).future);
  if (!context.mounted) return false;
  if (!mine.canRate) {
    showAppToast(
      context,
      'ما تكدر تقيّم هذا المنتج إلا بعد ما تطلبه ويوصلك',
      icon: AppIcon.alert,
    );
    return false;
  }
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RateProductSheet(
      productId: productId,
      productName: productName,
      initial: mine,
    ),
  );
  if (saved != true) return false;
  ref
    ..invalidate(myRatingProvider(productId))
    ..invalidate(productReviewsProvider(productId))
    ..invalidate(favoriteProductsProvider)
    ..invalidate(productProvider(('', productId)));
  if (pageId.isNotEmpty) {
    ref
      ..invalidate(productProvider((pageId, productId)))
      // Its card's stars on the page's product list.
      ..invalidate(pageSearchProvider);
  }
  if (context.mounted) showAppToast(context, 'شكراً، انحفظ تقييمك');
  return true;
}

/// Five big tappable SVG stars and an optional short comment.
class RateProductSheet extends ConsumerStatefulWidget {
  const RateProductSheet({
    super.key,
    required this.productId,
    required this.productName,
    required this.initial,
  });
  final String productId;
  final String productName;
  final MyRating initial;

  @override
  ConsumerState<RateProductSheet> createState() => _RateProductSheetState();
}

class _RateProductSheetState extends ConsumerState<RateProductSheet> {
  static const _labels = ['', 'سيء', 'مقبول', 'زين', 'كلش زين', 'ممتاز'];
  late int _stars = widget.initial.stars ?? 0;

  /// A first rating is POSTed once; after that it can only be edited (PUT).
  late bool _editing = widget.initial.stars != null;
  late final _comment = TextEditingController(text: widget.initial.comment);
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final body = {'stars': _stars, 'comment': _comment.text.trim()};
      if (_editing) {
        await api.put<Object?>(
          '/api/v1/products/${widget.productId}/rating',
          body,
        );
      } else {
        await api.post<Object?>(
          '/api/v1/products/${widget.productId}/ratings',
          body,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          final duplicate = e.code == 'rating.duplicate' || e.status == 409;
          // Already rated from another device: the next save edits it.
          if (duplicate) _editing = true;
          _error = duplicate
              ? 'قيّمت هذا المنتج من قبل، تكدر تعدّل تقييمك بس'
              : switch (e.code) {
                  'rating.prohibited' => 'التعليق بيه كلمة ممنوعة، عدّله وجرّب',
                  'rating.not_received' =>
                    'ما تكدر تقيّم هذا المنتج إلا بعد ما تطلبه ويوصلك',
                  _ => storeError(e),
                };
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = storeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: AppSheet(
      children: [
        Text(
          _editing ? 'عدّل تقييمك' : 'قيّم المنتج',
          textAlign: TextAlign.center,
          style: AppText.big.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          widget.productName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.muted,
        ),
        if (!_editing)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'تكدر تقيّم مرة وحدة بس، وبعدين تعدّل تقييمك إذا تريد.',
              textAlign: TextAlign.center,
              style: AppText.muted.copyWith(fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              Semantics(
                button: true,
                selected: i <= _stars,
                label: '$i من 5',
                child: GestureDetector(
                  onTap: () => setState(() => _stars = i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: AnimatedScale(
                      scale: i == _stars ? 1.15 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: AppSvgIcon(
                        i <= _stars ? AppIcon.star : AppIcon.starOutline,
                        size: 38,
                        color: AppColors.gold,
                        strokeWidth: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 24,
          child: Center(
            child: Text(
              _stars == 0
                  ? 'اختار عدد النجوم'
                  : '${_labels[_stars]} · $_stars من 5',
              style: AppText.label.copyWith(color: AppColors.warn),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(hintText: 'تعليق قصير (اختياري)'),
        ),
        if (_error != null) ...[
          Text(_error!, style: AppText.body.copyWith(color: AppColors.danger)),
          const SizedBox(height: 8),
        ],
        AppButton(
          _busy
              ? 'دا نحفظ...'
              : _editing
              ? 'احفظ التعديل'
              : 'أرسل التقييم',
          variant: _stars == 0
              ? AppButtonVariant.disabled
              : AppButtonVariant.primary,
          onPressed: _stars == 0 || _busy ? null : _save,
        ),
      ],
    ),
  );
}
