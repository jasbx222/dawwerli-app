import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../router/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_icons.dart';

/// Delivery pin on OpenStreetMap tiles. A pin only — no live tracking.
const _tiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _agent = 'iq.dawwerli.app';

/// Baghdad, used when the customer has not dropped a pin yet.
const baghdad = LatLng(33.3152, 44.3661);

TileLayer _tileLayer() =>
    TileLayer(urlTemplate: _tiles, userAgentPackageName: _agent);

/// Opens the pin in the phone's maps app (Google Maps link works everywhere).
Future<void> openPinInMaps(double lat, double lng) => launchUrl(
  Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
  mode: LaunchMode.externalApplication,
);

class _PinMarker extends StatelessWidget {
  const _PinMarker();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const AppSvgIcon(AppIcon.pin, color: AppColors.white, size: 18),
      ),
      Container(width: 3, height: 12, color: AppColors.blue),
    ],
  );
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    color: AppColors.white.withValues(alpha: .8),
    child: const Text(
      '© OpenStreetMap',
      textDirection: TextDirection.ltr,
      style: TextStyle(fontSize: 10, color: Color(0xFF555555)),
    ),
  );
}

/// Read-only mini map of an order's pin, with «افتح بالخريطة».
class OrderPinMap extends StatelessWidget {
  const OrderPinMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 170,
  });
  final double latitude;
  final double longitude;
  final double height;

  @override
  Widget build(BuildContext context) {
    final at = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Preview only: never steal the page's scroll.
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: at,
                  initialZoom: 15.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  _tileLayer(),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: at,
                        width: 40,
                        height: 52,
                        alignment: Alignment.topCenter,
                        child: const _PinMarker(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(left: 0, bottom: 0, child: _Attribution()),
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => openPinInMaps(latitude, longitude),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppSvgIcon(
                          AppIcon.pin,
                          color: AppColors.blue,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'افتح بالخريطة',
                          style: AppText.strong.copyWith(
                            fontSize: 12.5,
                            color: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen picker: drag the map under a fixed pin, then «ثبّت الموقع».
/// Pops with the chosen [LatLng]. No GPS: the customer places it by hand.
class PinPickerScreen extends StatefulWidget {
  const PinPickerScreen({super.key, this.initial});
  final LatLng? initial;

  @override
  State<PinPickerScreen> createState() => _PinPickerScreenState();
}

class _PinPickerScreenState extends State<PinPickerScreen> {
  final _map = MapController();
  late LatLng _center = widget.initial ?? baghdad;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _zoom(double by) => _map.move(_map.camera.center, _map.camera.zoom + by);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initial == null ? 12.5 : 16,
              minZoom: 5,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, _) =>
                  setState(() => _center = camera.center),
            ),
            children: [_tileLayer()],
          ),
          // The pin tip sits on the map centre.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 52),
                child: _PinMarker(),
              ),
            ),
          ),
          Positioned(
            top: top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _RoundButton(
                  icon: AppIcon.back,
                  label: 'رجوع',
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.home),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'حرّك الخريطة وخلّي الدبوس على باب البيت',
                      style: AppText.strong.copyWith(
                        color: AppColors.white,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 200,
            child: Column(
              children: [
                _RoundButton(
                  icon: AppIcon.plus,
                  label: 'كبّر',
                  onTap: () => _zoom(1),
                ),
                const SizedBox(height: 8),
                _RoundButton(
                  icon: AppIcon.minus,
                  label: 'صغّر',
                  onTap: () => _zoom(-1),
                ),
              ],
            ),
          ),
          const Positioned(right: 0, bottom: 172, child: _Attribution()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 30,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'موقع التوصيل',
                    style: AppText.strong.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الدبوس يوصل للصفحة ويا الطلب حتى المندوب يلكاك بسهولة. ما نتابع موقعك.',
                    style: AppText.muted,
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    'ثبّت الموقع',
                    icon: AppIcon.check,
                    onPressed: () => context.canPop()
                        ? context.pop(_center)
                        : context.go(Routes.home),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final AppIcon icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AppSvgIcon(icon, color: AppColors.ink, size: 20),
          ),
        ),
      ),
    ),
  );
}

/// Opens [PinPickerScreen]; null when the customer backs out.
Future<LatLng?> pickDeliveryPin(BuildContext context, {LatLng? initial}) =>
    context.push<LatLng>(
      Routes.pinPicker(initial?.latitude, initial?.longitude),
    );
