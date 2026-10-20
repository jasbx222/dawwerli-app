import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../data/post_providers.dart';
import '../domain/request_draft.dart';
import 'widgets/post_widgets.dart';

/// 07 · What are you looking for? (photo / text / voice).
class PostRequestScreen extends ConsumerStatefulWidget {
  const PostRequestScreen({super.key});

  @override
  ConsumerState<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends ConsumerState<PostRequestScreen> {
  static const _samplePhoto = 'assets/images/mock/cat_shoes_1.webp';
  late final _desc = TextEditingController(
    text: ref.read(draftProvider).description,
  );

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  void _next() {
    final notifier = ref.read(draftProvider.notifier);
    // Strip phones/links/@handles before they leave the device (server re-checks).
    final (clean, removed) = PostRules.stripContactInfo(_desc.text);
    notifier.update(
      (d) => d.copyWith(description: clean, removedContactInfo: removed),
    );
    _desc.text = clean;
    context.push(Routes.postDetails);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftProvider);
    final notifier = ref.read(draftProvider.notifier);
    final cats = ref.watch(suggestedCategoriesProvider).value ?? const [];
    final voice = draft.voiceSeconds;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(
              title: AppStrings.postTitle,
              subtitle: Text(AppStrings.postSub),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegTabs(
                    labels: const [
                      AppStrings.modePhoto,
                      AppStrings.modeText,
                      AppStrings.modeVoice,
                    ],
                    icons: const [AppIcon.camera, AppIcon.text, AppIcon.mic],
                    selected: draft.mode.index,
                    onSelect: (i) => notifier.update(
                      (d) => d.copyWith(mode: InputMode.values[i]),
                    ),
                  ),
                  if (draft.mode == InputMode.photo) ...[
                    const SizedBox(height: 14),
                    _PhotoBox(
                      photo: draft.photo,
                      // Mock picker: real app opens camera/gallery (image_picker).
                      onPick: () => notifier.update(
                        (d) => d.copyWith(photo: _samplePhoto),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const FieldLabel(AppStrings.shortDesc),
                  SizedBox(
                    height: 70,
                    child: InputShell(
                      focused: true,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: BareTextField(controller: _desc),
                      ),
                    ),
                  ),
                  if (voice != null || draft.mode == InputMode.voice) ...[
                    const SizedBox(height: 14),
                    _VoiceCard(
                      seconds: voice ?? 0,
                      onRecord: () =>
                          notifier.update((d) => d.copyWith(voiceSeconds: 24)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const FieldLabel(AppStrings.suggestedCat),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in cats)
                        AppChip(
                          c.label,
                          selected:
                              c.name == (draft.category ?? cats.first.name),
                          onTap: () => notifier.update(
                            (d) => d.copyWith(category: c.name),
                          ),
                        ),
                      AppChip(
                        AppStrings.changeCat,
                        onTap: () => context.push(Routes.comingSoon),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    AppStrings.next,
                    onPressed: () {
                      if (draft.category == null && cats.isNotEmpty) {
                        notifier.update(
                          (d) => d.copyWith(category: cats.first.name),
                        );
                      }
                      _next();
                    },
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

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.photo, required this.onPick});
  final String? photo;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo != null)
                // CSS: background center/cover.
                Image.asset(
                  photo!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                )
              else
                const ColoredBox(color: AppColors.slotBg),
              PositionedDirectional(
                bottom: 12,
                start: 12,
                child: SmallPill(
                  label: photo == null
                      ? AppStrings.addPhoto
                      : AppStrings.changePhoto,
                  bg: const Color(0xCC0F1E3D),
                  icon: AppIcon.camera,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({required this.seconds, required this.onRecord});
  final int seconds;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(
      fontSize: 12.5,
      height: 1.52,
      color: AppColors.grey,
    );
    return AppCard(
      insets: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onRecord,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const AppSvgIcon(
                    AppIcon.mic,
                    size: 20,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Waveform(
                  // CSS mask is a fixed 60% split; we use the real playback ratio.
                  progress: seconds == 0 ? 0 : .6,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.voiceProgress(
                  mss(seconds),
                  mss(PostRules.maxVoiceSeconds),
                ),
                style: AppText.number.copyWith(
                  fontSize: 14,
                  height: AppText.lh(14),
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(AppStrings.voiceNote, style: muted),
          const SizedBox(height: 6),
          const Text(
            AppStrings.voiceWarn,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.52,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
