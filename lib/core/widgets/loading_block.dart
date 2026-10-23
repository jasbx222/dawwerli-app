import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered spinner used while a screen's data loads from the API.
class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key});

  static const _padding = 48.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(_padding),
    child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
  );
}
