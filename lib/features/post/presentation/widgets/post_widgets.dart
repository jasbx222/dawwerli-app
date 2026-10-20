import 'package:flutter/material.dart';

export '../../../../core/widgets/toast_bar.dart';

import 'package:dawwerli/core/widgets/emoji_text.dart';

import '../../../../core/widgets/exact_line.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';

/// `.ptab` segmented control (track #EEEAE0, pad 4, gap 4; item pad 9, radius 12).
class SegTabs extends StatelessWidget {
  const SegTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.icons,
  });

  final List<String> labels;
  final List<AppIcon>? icons;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Item height = line box + 2×9 padding, device-rounded like the design render:
    // 13px text line 19.5; with the inline 16px icon the line box is 21.41.
    final h = icons == null ? AppText.lh(13) * 13 + 18 : 21.41 + 18;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tabTrack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  height: h,
                  alignment: Alignment.center,
                  decoration: i == selected
                      ? BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icons != null) ...[
                        AppSvgIcon(
                          icons![i],
                          size: 16,
                          color: i == selected
                              ? AppColors.blue
                              : AppColors.tabText,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          height: AppText.lh(13),
                          fontWeight: FontWeight.w700,
                          color: i == selected
                              ? AppColors.blue
                              : AppColors.tabText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.pill` (12px bold, pad 5/10, radius 99).
class SmallPill extends StatelessWidget {
  const SmallPill({
    super.key,
    required this.label,
    required this.bg,
    this.fg = AppColors.white,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final AppIcon? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppSvgIcon(icon!, size: 14, color: fg),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: AppText.lh(12),
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

/// Tinted rejection/warning card (`.card` margin 10, pad 12/14, flat).
class IssueCard extends StatelessWidget {
  const IssueCard({
    super.key,
    required this.title,
    required this.body,
    this.warning = false,
  });

  final String title;
  final String body;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final fg = warning ? AppColors.warnText : AppColors.dangerText;
    return AppCard(
      flat: true,
      color: warning ? AppColors.warnBg : AppColors.dangerBg,
      insets: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExactLine(
            fontSize: 14,
            child: EmojiText(
              title,
              style: TextStyle(
                fontSize: 14,
                height: AppText.lh(14),
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
          ExactText(
            body,
            style: TextStyle(
              fontSize: 12.5,
              height: AppText.lh(12.5),
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Voice waveform: 3px bars every 7px (left→right), played part (60%) solid, rest at .25.
class Waveform extends StatelessWidget {
  const Waveform({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 26, child: CustomPaint(painter: _WavePainter(progress)));
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
    );
    final split = size.width * progress;
    for (double x = 0; x < size.width; x += 7) {
      final played = x < split;
      final paint = Paint()
        ..color = AppColors.blue.withValues(alpha: played ? 1 : .25);
      final right = (x + 3).clamp(0, size.width).toDouble();
      if (played && right > split) {
        canvas.drawRect(Rect.fromLTRB(x, 0, split, size.height), paint);
        canvas.drawRect(
          Rect.fromLTRB(split, 0, right, size.height),
          Paint()..color = AppColors.blue.withValues(alpha: .25),
        );
      } else {
        canvas.drawRect(Rect.fromLTRB(x, 0, right, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

String mss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
