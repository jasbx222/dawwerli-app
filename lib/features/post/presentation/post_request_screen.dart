import 'package:flutter/material.dart';

import 'dart:async';

import '../../../core/api/picker.dart';
import '../../../core/api/voice_recorder.dart';
import '../../../core/widgets/app_image.dart';

import 'package:dawwerli/core/widgets/emoji_text.dart';

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
  late final _desc = TextEditingController(
    text: ref.read(draftProvider).description,
  )..addListener(_saveDesc);

  // Keep the typed text in the saved draft so a restart/reload doesn't lose it.
  void _saveDesc() {
    final t = _desc.text;
    if (t == ref.read(draftProvider).description) return;
    ref.read(draftProvider.notifier).update((d) => d.copyWith(description: t));
  }

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
    final cats = ref.watch(suggestedCategoriesProvider).value ?? [];
    final voice = draft.voiceSeconds;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: AppStrings.postTitle,
              subtitle: Text(AppStrings.postSub),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegTabs(
                    labels: [
                      AppStrings.modePhoto,
                      AppStrings.modeText,
                      AppStrings.modeVoice,
                    ],
                    icons: [AppIcon.camera, AppIcon.text, AppIcon.mic],
                    selected: draft.mode.index,
                    onSelect: (i) => notifier.update(
                      (d) => d.copyWith(mode: InputMode.values[i]),
                    ),
                  ),
                  if (draft.mode == InputMode.photo) ...[
                    SizedBox(height: 14),
                    _PhotoBox(
                      photo: draft.photo,
                      onPick: () async {
                        final path = await pickPhoto();
                        if (path != null) {
                          notifier.update((d) => d.copyWith(photo: path));
                        }
                      },
                    ),
                  ],
                  SizedBox(height: 14),
                  FieldLabel(AppStrings.shortDesc),
                  SizedBox(
                    height: 70,
                    child: InputShell(
                      focused: true,
                      exactLine: false,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: BareTextField(controller: _desc),
                      ),
                    ),
                  ),
                  if (voice != null || draft.mode == InputMode.voice) ...[
                    SizedBox(height: 14),
                    _VoiceCard(
                      seconds: voice ?? 0,
                      onRecorded: (path, secs) => notifier.update(
                        (d) => d.copyWith(voice: path, voiceSeconds: secs),
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  FieldLabel(AppStrings.suggestedCat),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in cats)
                        AppChip(
                          c.label,
                          categoryKey: c.slug ?? '',
                          selected:
                              c.name == (draft.category ?? cats.first.name),
                          onTap: () => notifier.update(
                            (d) => d.copyWith(category: c.name),
                          ),
                        ),
                      AppChip(
                        AppStrings.changeCat,
                        onTap: () => context.push(Routes.postCategory),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
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
                AppImage(photo!, fit: BoxFit.cover, alignment: Alignment.center)
              else
                ColoredBox(color: AppColors.slotBg),
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

class _VoiceCard extends StatefulWidget {
  const _VoiceCard({required this.seconds, required this.onRecorded});
  final int seconds;
  final void Function(String path, int seconds) onRecorded;

  @override
  State<_VoiceCard> createState() => _VoiceCardState();
}

class _VoiceCardState extends State<_VoiceCard> {
  final _rec = VoiceRecorder(maxSeconds: PostRules.maxVoiceSeconds);
  StreamSubscription<int>? _sub;
  int? _live;

  @override
  void dispose() {
    _sub?.cancel();
    _rec.dispose();
    super.dispose();
  }

  /// Tap to start, tap again to stop (auto-stops at the max length).
  Future<void> onRecord() async {
    if (_rec.recording) {
      final r = await _rec.stop();
      setState(() => _live = null);
      if (r != null) widget.onRecorded(r.$1, r.$2);
      return;
    }
    if (!await _rec.start()) return;
    _sub ??= _rec.ticks.listen((s) {
      if (mounted) setState(() => _live = s);
    });
    setState(() => _live = 0);
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _live ?? widget.seconds;
    final muted = TextStyle(
      fontSize: 12.5,
      height: 1.502222,
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
                  child: AppSvgIcon(
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
              // Design: the time label box is 72 wide (waveform 192).
              SizedBox(
                width: MediaQuery.textScalerOf(context).scale(72),
                child: Text(
                  AppStrings.voiceProgress(
                    mss(seconds),
                    mss(PostRules.maxVoiceSeconds),
                  ),
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: AppText.number.copyWith(
                    fontSize: 14,
                    height: AppText.lh(14),
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(AppStrings.voiceNote, style: muted),
          const SizedBox(height: 6),
          EmojiText(
            AppStrings.voiceWarn,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.502222,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
