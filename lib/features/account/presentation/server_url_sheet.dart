import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_config.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_sheet.dart';

/// Lets testers point the app at another API (e.g. the PC's LAN IP from a real phone).
class ServerUrlSheet extends ConsumerStatefulWidget {
  const ServerUrlSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C070E1F),
    builder: (_) => const ServerUrlSheet(),
  );

  @override
  ConsumerState<ServerUrlSheet> createState() => _ServerUrlSheetState();
}

class _ServerUrlSheetState extends ConsumerState<ServerUrlSheet> {
  late final _url = TextEditingController(text: ref.read(apiBaseUrlProvider));

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _save(String v) {
    ref.read(apiBaseUrlProvider.notifier).set(v);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: AppSheet(
      children: [
        Text('عنوان الخادم', style: AppText.strong),
        const SizedBox(height: 6),
        Text('الافتراضي ${ApiDefaults.baseUrl}', style: AppText.muted),
        const SizedBox(height: 12),
        LabeledField(
          controller: _url,
          ltr: true,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 14),
        AppButton('احفظ', onPressed: () => _save(_url.text)),
        const SizedBox(height: 10),
        AppButton(
          'رجّع الافتراضي',
          variant: AppButtonVariant.ghost,
          onPressed: () => _save(''),
        ),
      ],
    ),
  );
}
