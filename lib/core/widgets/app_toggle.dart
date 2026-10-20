import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// `.tog` (44×26); off = `.tog.x`. [locked] dims a switch that can't change.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.on,
    this.onTap,
    this.locked = false,
  });
  final bool on;
  final bool locked;
  final VoidCallback? onTap;

  static const _w = 44.0, _h = 26.0, _knob = 20.0, _pad = 3.0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: locked ? null : onTap,
    child: Opacity(
      opacity: locked ? .5 : 1,
      child: Container(
        width: _w,
        height: _h,
        padding: const EdgeInsets.all(_pad),
        decoration: BoxDecoration(
          color: on ? AppColors.blue : AppColors.dotOff,
          borderRadius: BorderRadius.circular(99),
        ),
        // RTL: on = knob left (CSS left:3px), off = right.
        alignment: on
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          width: _knob,
          height: _knob,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}
