import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icons.dart';

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
