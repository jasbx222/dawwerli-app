import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/order_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../data/orders_providers.dart';
import '../domain/order.dart';
import 'order_widgets.dart';

/// 16 · Rate the page; 16b · already rated (button off + toast).
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({
    super.key,
    required this.orderId,
    this.initialStars = 0,
    this.initialTags = const {},
    this.initialComment = '',
    this.initialFailed = false,
  });

  /// Design QA: show the send-failed toast.
  final bool initialFailed;
  final String orderId;
  final int initialStars;
  final Set<String> initialTags;
  final String initialComment;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  late int _stars = widget.initialStars;
  late final Set<String> _tags = {...widget.initialTags};
  late final _comment = TextEditingController(text: widget.initialComment);

  /// Saved rating already applied to the form.
  bool _toast = false;
  late bool _failed = widget.initialFailed;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_stars == 0) return;
    try {
      await ref
          .read(ordersRepositoryProvider)
          .rate(
            widget.orderId,
            Rating(stars: _stars, tags: {..._tags}, comment: _comment.text),
          );
    } on AlreadyRated {
      // falls through to the 16b state
    } catch (_) {
      // Keep the written rating; button stays active for a retry.
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (mounted) setState(() => _failed = false);
    ref.invalidate(orderProvider(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    final o = ref.watch(orderProvider(widget.orderId)).value;
    if (o == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }
    final rated = o.rated;
    final saved = o.rating;
    if (saved != null && !_toast) {
      _toast = true;
      _stars = saved.stars;
      _tags
        ..clear()
        ..addAll(saved.tags);
      _comment.text = saved.comment;
    }
    final showToast = rated || _failed;
    final off = rated || _stars == 0;
    final repo = ref.read(ordersRepositoryProvider);
    final low = _stars > 0 && _stars <= 2;
    final tags = low ? repo.lowRatingTags : repo.ratingTags;
    final locked = rated;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: OrderStrings.rateTitle(o.pageName),
                  subtitle: const Text(OrderStrings.rateSub),
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.home),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: AppCard(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            o.pageImage,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 1; i <= 5; i++) ...[
                                if (i > 1) const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: locked
                                      ? null
                                      : () => setState(() {
                                          if ((i <= 2) !=
                                              (_stars > 0 && _stars <= 2)) {
                                            _tags.clear();
                                          }
                                          _stars = i;
                                        }),
                                  child: AppSvgIcon(
                                    AppIcon.star,
                                    size: 44,
                                    color: i <= _stars
                                        ? AppColors.gold
                                        : AppColors.border,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          _stars == 0
                              ? const TextSpan(text: OrderStrings.pickStars)
                              : TextSpan(
                                  text:
                                      '${OrderStrings.starLabels[_stars - 1]} ',
                                  children: [
                                    svgSpan(
                                      _stars >= 3
                                          ? OrderIcon.ok.of(AppColors.gold, 18)
                                          : OrderIcon.alert.of(
                                              const Color(0xFFA8A29E),
                                              18,
                                            ),
                                    ),
                                  ],
                                ),
                          style: AppText.strong.copyWith(
                            fontSize: 17,
                            height: AppText.lh(17),
                            color: _stars == 0 ? AppColors.grey : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FieldLabel(
                        low ? OrderStrings.disliked : OrderStrings.liked,
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in tags)
                            AppChip(
                              t,
                              selected: _tags.contains(t),
                              onTap: locked
                                  ? null
                                  : () => setState(
                                      () => _tags.contains(t)
                                          ? _tags.remove(t)
                                          : _tags.add(t),
                                    ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel(OrderStrings.comment),
                      SizedBox(
                        height: 90,
                        child: InputShell(
                          exactLine: false,
                          // Caret margin offset, same as BareTextField (RTL).
                          child: Transform.translate(
                            offset: const Offset(3, 0),
                            child: TextField(
                              controller: _comment,
                              readOnly: locked,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: const TextStyle(
                                fontFamily: AppText.family,
                                fontSize: 15,
                                height: 1.492593,
                                color: AppColors.navy,
                              ),
                              decoration: const InputDecoration.collapsed(
                                hintText: '',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(OrderStrings.oneRating, style: AppText.muted),
                      const SizedBox(height: 20),
                      LabelIconButton(
                        label: rated ? OrderStrings.rated : OrderStrings.send,
                        icon: rated ? AppIcon.check : null,
                        bg: off ? AppColors.disabledBg : AppColors.gold,
                        fg: off ? AppColors.disabledText : AppColors.navy,
                        shadow: !off,
                        onPressed: off ? null : _send,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showToast)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 14),
                        blurRadius: 30,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (rated)
                        const AppSvgIcon(
                          AppIcon.verified,
                          size: 20,
                          color: AppColors.white,
                        )
                      else
                        OrderIcon.alert.of(const Color(0xFFDC2626), 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          !rated
                              ? const TextSpan(text: OrderStrings.sendFailed)
                              : TextSpan(
                                  text: '${OrderStrings.ratedBefore} ',
                                  children: [
                                    svgSpan(
                                      const AppSvgIcon(
                                        AppIcon.check,
                                        size: 13,
                                        color: AppColors.white,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' ${OrderStrings.oneOnly}',
                                    ),
                                  ],
                                ),
                          style: TextStyle(
                            fontSize: 13.5,
                            height: AppText.lh(13.5),
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
