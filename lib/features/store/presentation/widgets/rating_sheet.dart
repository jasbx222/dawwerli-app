import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_sheet.dart';
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
      'تكدر تقيّم المنتج بعد ما يوصلك',
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
    ..invalidate(favoriteProductsProvider);
  if (pageId.isNotEmpty) {
    ref
      ..invalidate(productProvider((pageId, productId)))
      ..invalidate(pageProductsProvider(pageId));
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
      await ref.read(apiClientProvider).put<Object?>(
        '/api/v1/products/${widget.productId}/rating',
        {'stars': _stars, 'comment': _comment.text.trim()},
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.code) {
            'rating.prohibited' => 'التعليق بيه كلمة ممنوعة، عدّله وجرّب',
            'rating.not_received' => 'تكدر تقيّم المنتج بعد ما يوصلك',
            _ => storeError(e),
          },
        );
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
          widget.initial.stars == null ? 'قيّم المنتج' : 'عدّل تقييمك',
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
              _labels[_stars],
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
          _busy ? 'دا نحفظ...' : 'احفظ التقييم',
          variant: _stars == 0
              ? AppButtonVariant.disabled
              : AppButtonVariant.primary,
          onPressed: _stars == 0 || _busy ? null : _save,
        ),
      ],
    ),
  );
}
