import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../auth/data/auth_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({
    super.key,
    this.initialName = '',
    this.initialArea = '',
    this.initialGov = 'بغداد',
  });

  final String initialName;
  final String initialArea;
  final String initialGov;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const _visibleGovs = 12;
  late final _name = TextEditingController(text: widget.initialName);
  late final _area = TextEditingController(text: widget.initialArea);
  final _areaFocus = FocusNode();
  final _nameFocus = FocusNode();
  late String _gov = widget.initialGov;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _areaFocus.addListener(() => setState(() {}));
    _nameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _areaFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(authRepositoryProvider)
        .saveProfile(
          name: _name.text.trim(),
          governorate: _gov,
          area: _area.text.trim(),
        );
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final govs = ref.watch(governoratesProvider).value ?? const <String>[];
    final shown = _showAll ? govs : govs.take(_visibleGovs).toList();
    final hidden = govs.length - shown.length;
    final areaFocused =
        _areaFocus.hasFocus ||
        (widget.initialArea.isNotEmpty && !_nameFocus.hasFocus);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppHeader(
              title: AppStrings.profileTitle,
              subtitle: const Text(AppStrings.profileSub),
              onBack: () => context.go(Routes.otp),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FieldLabel(AppStrings.profileName),
                InputShell(
                  focused: _nameFocus.hasFocus,
                  child: BareTextField(
                    controller: _name,
                    focusNode: _nameFocus,
                  ),
                ),
                const SizedBox(height: 18),
                const FieldLabel(AppStrings.profileGov),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in shown)
                      AppChip(
                        g,
                        selected: g == _gov,
                        onTap: () => setState(() => _gov = g),
                      ),
                    if (hidden > 0)
                      AppChip(
                        '+$hidden',
                        onTap: () => setState(() => _showAll = true),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const FieldLabel(AppStrings.profileArea),
                InputShell(
                  focused: areaFocused,
                  child: Row(
                    children: [
                      Expanded(
                        child: BareTextField(
                          controller: _area,
                          focusNode: _areaFocus,
                        ),
                      ),
                      const AppSvgIcon(
                        AppIcon.pin,
                        color: AppColors.blue,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(AppStrings.profileAreaHint, style: AppText.muted),
                const SizedBox(height: 22),
                AppButton(AppStrings.profileDone, onPressed: _save),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
