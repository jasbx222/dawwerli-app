import 'package:url_launcher/url_launcher.dart';

/// Opens a WhatsApp chat. api.whatsapp.com directly: the wa.me redirect
/// mangles emoji in `text`.
Future<void> openWhatsApp(String phone, [String text = '']) => launchUrl(
  Uri.parse(
    'https://api.whatsapp.com/send?phone=$phone'
    '${text.isEmpty ? '' : '&text=${Uri.encodeComponent(text)}'}',
  ),
  mode: LaunchMode.externalApplication,
);
