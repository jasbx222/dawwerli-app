import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_inputs.dart';
import '../domain/phone_number.dart';

/// «+964 | number | 🇮🇶» input shared by every auth screen.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.focusNode,
    this.focused = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool focused;
  final ValueChanged<String>? onChanged;

  static final _style = AppText.number.copyWith(
    fontSize: 18,
    height: AppText.lh(18),
    color: AppColors.ink,
  );

  @override
  Widget build(BuildContext context) => InputShell(
    focused: focused,
    exactLine: false,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Text(AppStrings.countryCode, style: _style),
          const SizedBox(width: 9),
          Expanded(
            child: BareTextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              style: _style,
              onChanged: onChanged,
            ),
          ),
          const Text('🇮🇶', style: TextStyle(fontSize: 15)),
        ],
      ),
    ),
  );
}

/// Password input built on the same shell as [PhoneField].
class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.focused = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool focused;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => InputShell(
    focused: focused,
    exactLine: false,
    child: BareTextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textDirection: TextDirection.ltr,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    ),
  );
}

/// Alert cards for phone validation errors.
class PhoneErrorCards extends StatelessWidget {
  const PhoneErrorCards(this.errors, {super.key});
  final Set<PhoneError> errors;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (errors.contains(PhoneError.incomplete))
        const AlertCard(
          title: AppStrings.errIncompleteTitle,
          body: AppStrings.errIncompleteBody,
        ),
      if (errors.length > 1) const SizedBox(height: 10),
      if (errors.contains(PhoneError.notIraqi))
        const AlertCard(
          title: AppStrings.errNotIraqiTitle,
          body: AppStrings.errNotIraqiBody,
        ),
    ],
  );
}
