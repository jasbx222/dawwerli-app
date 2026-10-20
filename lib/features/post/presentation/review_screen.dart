import 'package:flutter/material.dart';

import 'package:dawwerli/core/widgets/emoji_text.dart';

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
import '../../home/data/home_providers.dart';
import '../data/post_providers.dart';
import '../domain/post_repository.dart';
import '../domain/request_draft.dart';
import 'widgets/post_widgets.dart';

/// 09 · Review & publish; 09b · rejection states + offline queue banner.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({
    super.key,
    this.initialErrors = const {},
    this.initialOffline = false,
  });

  final Set<PostError> initialErrors;
  final bool initialOffline;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late Set<PostError> _errors = widget.initialErrors;
  late bool _offline = widget.initialOffline;
  bool _busy = false;

  Future<void> _publish() async {
    setState(() => _busy = true);
    final r = await ref
        .read(postRepositoryProvider)
        .publish(ref.read(draftProvider));
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case Published(:final requestId):
        ref.invalidate(openCountProvider);
        ref.read(draftProvider.notifier).clear();
        ref.invalidate(homeDataProvider);
        context.go(Routes.liveRequest(requestId));
      case Rejected(:final errors):
        setState(() => _errors = errors);
      case QueuedOffline():
        setState(() => _offline = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftProvider);
    final notifier = ref.read(draftProvider.notifier);
    final open = ref.watch(openCountProvider).value ?? 0;
    final hasErrors = _errors.isNotEmpty;
    final canPublish = draft.readyToBuy && !hasErrors && !_busy;
    final confirm = _ReadyCard(
      checked: draft.readyToBuy,
      body: draft.readyToBuy ? AppStrings.ready48Body : AppStrings.ready48Tick,
      onTap: () =>
          notifier.update((d) => d.copyWith(readyToBuy: !d.readyToBuy)),
    );
    final publish = AppButton(
      AppStrings.publish,
      variant: canPublish
          ? AppButtonVariant.primary
          : AppButtonVariant.disabled,
      onPressed: _publish,
    );

    return Scaffold(
      body: Stack(
        // Expand so the offline banner anchors to the screen bottom, not the content.
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  title: AppStrings.reviewTitle,
                  subtitle: hasErrors
                      ? const Text(AppStrings.reviewErrorsSub)
                      : null,
                  trailing: hasErrors
                      ? null
                      : SmallPill(
                          label: AppStrings.draftSaved,
                          icon: AppIcon.check,
                          bg: AppColors.white.withValues(alpha: .18),
                        ),
                ),
                if (hasErrors) ...[
                  _m(14, confirm),
                  for (final e in PostError.values)
                    if (_errors.contains(e)) _m(10, _issue(e)),
                  _m(16, publish),
                ] else ...[
                  _m(14, _SummaryCard(draft: draft)),
                  _m(14, confirm),
                  _m(14, _PrivacyCard(draft: draft)),
                  _m(14, _OpenCountCard(open: open)),
                  _m(20, publish),
                  const SizedBox(height: 10),
                  const Text(
                    AppStrings.offlineDraftNote,
                    textAlign: TextAlign.center,
                    style: AppText.muted,
                  ),
                ],
              ],
            ),
          ),
          if (_offline)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: OfflineBanner(AppStrings.offlineToast),
            ),
        ],
      ),
    );
  }

  static Widget _m(double top, Widget child) =>
      Padding(padding: EdgeInsets.fromLTRB(16, top, 16, 0), child: child);

  static Widget _issue(PostError e) => switch (e) {
    PostError.incomplete => const IssueCard(
      title: AppStrings.errIncomplete,
      body: AppStrings.errIncompleteBody2,
    ),
    PostError.prohibited => const IssueCard(
      title: AppStrings.errProhibited,
      body: AppStrings.errProhibitedBody,
    ),
    PostError.contactInfo => const IssueCard(
      title: AppStrings.errContact,
      body: AppStrings.errContactBody,
    ),
    PostError.maxOpen => const IssueCard(
      title: AppStrings.errMaxOpen,
      body: AppStrings.errMaxOpenBody,
    ),
    PostError.voiceTooLong => const IssueCard(
      title: AppStrings.errVoice,
      body: AppStrings.errVoiceBody,
      warning: true,
    ),
    PostError.priceZero => const IssueCard(
      title: AppStrings.errPrice,
      body: AppStrings.errPriceBody,
    ),
    PostError.sizeMissing => const IssueCard(
      title: AppStrings.errSize,
      body: AppStrings.errSizeBody,
    ),
  };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.draft});
  final RequestDraft draft;

  @override
  Widget build(BuildContext context) {
    final title = draft.description.split('،').first.trim();
    final cond = switch (draft.condition) {
      ItemCondition.brandNew => AppStrings.condNew,
      ItemCondition.used => AppStrings.condUsed,
      ItemCondition.any => AppStrings.condAny,
    };
    final meta = [
      draft.category,
      draft.size,
      draft.color,
      cond,
    ].whereType<String>().join(' · ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: draft.photo == null
                      ? const ColoredBox(color: AppColors.slotBg)
                      : Image.asset(
                          draft.photo!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.strong.copyWith(
                        fontSize: 16,
                        height: AppText.lh(16),
                      ),
                    ),
                    Text(meta, style: AppText.muted),
                    if (draft.voiceSeconds != null)
                      EmojiText(
                        AppStrings.voiceLen(mss(draft.voiceSeconds!)),
                        style: AppText.muted,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Line(
            label: AppStrings.maxPrice,
            value: '${thousands(draft.maxPrice ?? 0)} ${AppStrings.currency}',
            number: true,
            top: true,
            bottom: true,
          ),
          _Line(label: AppStrings.govLabel, value: draft.governorate),
        ],
      ),
    );
  }
}

/// `.li`: 13px vertical padding, #F1ECE0 1px rules.
class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.number = false,
    this.top = false,
    this.bottom = false,
  });

  final String label;
  final String value;
  final bool number;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    const rule = BorderSide(color: AppColors.divider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          top: top ? rule : BorderSide.none,
          bottom: bottom ? rule : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Text(label, style: AppText.muted),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              height: AppText.lh(14.5),
              fontWeight: number ? FontWeight.w600 : FontWeight.w700,
              fontFeatures: number
                  ? const [FontFeature.tabularFigures()]
                  : null,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({
    required this.checked,
    required this.body,
    required this.onTap,
  });

  final bool checked;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: checked ? AppColors.blue : null,
                  borderRadius: BorderRadius.circular(8),
                  border: checked
                      ? null
                      : Border.all(color: AppColors.checkOff, width: 2),
                ),
                alignment: Alignment.center,
                child: checked
                    ? const AppSvgIcon(
                        AppIcon.verified,
                        size: 16,
                        color: AppColors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              const Text(AppStrings.ready48, style: AppText.strong),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: AppText.muted),
        ],
      ),
    ),
  );
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.draft});
  final RequestDraft draft;

  @override
  Widget build(BuildContext context) => AppCard(
    flat: true,
    color: AppColors.blueTint,
    child: Row(
      children: [
        // Design: the 22px svg flex-shrinks to 17.4 next to the long note.
        const SizedBox(
          width: 17.4,
          height: 22,
          child: Center(
            child: AppSvgIcon(
              AppIcon.shield,
              size: 17.4,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppStrings.privacyNote(draft.category ?? '', draft.governorate),
            style: AppText.muted.copyWith(color: AppColors.infoText),
          ),
        ),
      ],
    ),
  );
}

class _OpenCountCard extends StatelessWidget {
  const _OpenCountCard({required this.open});
  final int open;

  @override
  Widget build(BuildContext context) => AppCard(
    flat: true,
    color: AppColors.warnBg,
    child: Text.rich(
      TextSpan(
        style: AppText.muted.copyWith(color: AppColors.warnText),
        children: [
          const TextSpan(text: AppStrings.openPrefix),
          TextSpan(
            text: AppStrings.openOf(open, PostRules.maxOpenRequests),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: AppStrings.openSuffix),
        ],
      ),
    ),
  );
}
