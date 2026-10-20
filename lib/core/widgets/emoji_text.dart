import 'package:flutter/material.dart';

import 'app_icons.dart';

/// Emoji kept in copy strings as markers; each is drawn as an inline SVG in
/// the text colour (1.05em, stroke 2.1) so no emoji glyph reaches the screen.
const _icons = <String, AppIcon>{
  '🎯': AppIcon.target,
  '✍️': AppIcon.pencil,
  '👋': AppIcon.hand,
  '🔥': AppIcon.flame,
  '👌': AppIcon.verified,
  '⚠️': AppIcon.alert,
  '🎙️': AppIcon.mic,
  '🚫': AppIcon.ban,
  '📍': AppIcon.pin,
  '💡': AppIcon.bulb,
  '⚡': AppIcon.zap,
  '👟': AppIcon.footprints,
};

final _re = RegExp(_icons.keys.map(RegExp.escape).join('|'));

List<InlineSpan> emojiSpans(String text, Color color, double size) {
  final out = <InlineSpan>[];
  var i = 0;
  for (final m in _re.allMatches(text)) {
    if (m.start > i) out.add(TextSpan(text: text.substring(i, m.start)));
    out.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: AppSvgIcon(
          _icons[m.group(0)]!,
          color: color,
          size: size * 1.05,
          strokeWidth: 2.1,
        ),
      ),
    );
    i = m.end;
  }
  if (i < text.length) out.add(TextSpan(text: text.substring(i)));
  return out;
}

/// Drop-in for [Text] when the string may carry an emoji marker.
class EmojiText extends StatelessWidget {
  const EmojiText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.strutStyle,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    final s = DefaultTextStyle.of(context).style.merge(style);
    return Text.rich(
      TextSpan(
        children: emojiSpans(data, s.color ?? Colors.black, s.fontSize ?? 14),
      ),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      strutStyle: strutStyle,
    );
  }
}
