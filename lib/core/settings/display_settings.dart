import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/prefs.dart';

/// 28 «حجم الخط» · 39.
enum FontSize { normal, large, xlarge }

extension FontSizeLabel on FontSize {
  String get label => switch (this) {
    FontSize.normal => 'عادي',
    FontSize.large => 'كبير',
    FontSize.xlarge => 'كبير جداً',
  };

  /// 39 is drawn at «كبير جداً» ≈ 1.3× body text.
  double get scale => switch (this) {
    FontSize.normal => 1,
    FontSize.large => 1.15,
    FontSize.xlarge => 1.3,
  };
}

/// Text size only; light/dark lives in `themeModeProvider`.
class DisplaySettings {
  const DisplaySettings(this.font);
  final FontSize font;
}

class DisplaySettingsNotifier extends Notifier<DisplaySettings> {
  static const _kFont = 'display.font';

  @override
  DisplaySettings build() {
    final p = ref.watch(sharedPrefsProvider);
    return DisplaySettings(
      FontSize.values[(p.getInt(_kFont) ?? 0).clamp(0, 2)],
    );
  }

  /// No picker is designed; each tap moves to the next size.
  void nextFont() {
    final f = FontSize.values[(state.font.index + 1) % 3];
    ref.read(sharedPrefsProvider).setInt(_kFont, f.index);
    state = DisplaySettings(f);
  }
}

final displaySettingsProvider =
    NotifierProvider<DisplaySettingsNotifier, DisplaySettings>(
      DisplaySettingsNotifier.new,
    );

/// Colours are read from [AppColors] getters, so a switch has to rebuild every
/// element (const subtrees included) without resetting navigation state.
class RebuildOnChange extends StatefulWidget {
  const RebuildOnChange({super.key, required this.token, required this.child});
  final Object token;
  final Widget child;

  @override
  State<RebuildOnChange> createState() => _RebuildOnChangeState();
}

class _RebuildOnChangeState extends State<RebuildOnChange> {
  @override
  void didUpdateWidget(RebuildOnChange old) {
    super.didUpdateWidget(old);
    if (old.token != widget.token) {
      void mark(Element e) {
        e.markNeedsBuild();
        e.visitChildren(mark);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) (context as Element).visitChildren(mark);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
