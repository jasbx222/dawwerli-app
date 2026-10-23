import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/app_page.dart';
import 'courier_tracking.dart';

const _tiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _agent = 'iq.dawwerli.app';

/// How often the screen re-reads the position when no push arrives.
const courierPollEvery = Duration(seconds: 5);

/// Live courier block for an order: map with the moving courier and the
/// delivery pin, ETA line and last update. Renders nothing while the courier
/// link is not sharing. Polls every [courierPollEvery] and listens to the
/// live hub; both stop when the widget leaves the screen.
class LiveCourierSection extends ConsumerStatefulWidget {
  const LiveCourierSection({
    super.key,
    required this.storeOrderId,
    this.pinLatitude,
    this.pinLongitude,
    this.forPage = false,
    this.wrap,
  });

  final String storeOrderId;
  final double? pinLatitude;
  final double? pinLongitude;

  /// Read through the page's endpoint instead of the customer's.
  final bool forPage;

  /// Wraps the block (section card etc.) when there is something to show.
  final Widget Function(Widget child)? wrap;

  @override
  ConsumerState<LiveCourierSection> createState() => _LiveCourierState();
}

class _LiveCourierState extends ConsumerState<LiveCourierSection> {
  CourierLocation _at = CourierLocation.inactive;
  Timer? _timer;
  StreamSubscription<CourierLocation>? _push;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(courierPollEvery, (_) => _fetch());
    try {
      _push = ref
          .read(courierPushesProvider)
          .watch(widget.storeOrderId)
          .listen(_set, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _push?.cancel();
    super.dispose();
  }

  void _set(CourierLocation l) {
    if (mounted) setState(() => _at = l);
  }

  Future<void> _fetch() async {
    if (_loading) return;
    _loading = true;
    try {
      final repo = ref.read(courierTrackingRepoProvider);
      _set(
        widget.forPage
            ? await repo.forPage(widget.storeOrderId)
            : await repo.forCustomer(widget.storeOrderId),
      );
    } on ApiException catch (e) {
      if (e.status == 404) _set(CourierLocation.inactive);
    } catch (_) {
      // Keep the last good position; the next tick retries.
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _at;
    if (!l.hasPoint) return const SizedBox.shrink();
    final courier = LatLng(l.latitude!, l.longitude!);
    final pin = widget.pinLatitude != null && widget.pinLongitude != null
        ? LatLng(widget.pinLatitude!, widget.pinLongitude!)
        : null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.turquoise,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                courierEtaLabel(l),
                style: AppText.strong.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
        if (l.updatedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            courierUpdatedLabel(l.updatedAt!.toLocal()),
            style: AppText.muted,
          ),
        ],
        const SizedBox(height: 12),
        LiveCourierMap(courier: courier, pin: pin),
        const SizedBox(height: 8),
        Text(
          'الوقت تقريبي، حسب المسافة بين المندوب وموقع التوصيل.',
          style: AppText.muted.copyWith(fontSize: 12),
        ),
      ],
    );
    return widget.wrap?.call(body) ?? body;
  }
}

/// Read-only map with the courier marker and the delivery pin, kept in view.
class LiveCourierMap extends StatefulWidget {
  const LiveCourierMap({
    super.key,
    required this.courier,
    this.pin,
    this.height = 210,
  });
  final LatLng courier;
  final LatLng? pin;
  final double height;

  @override
  State<LiveCourierMap> createState() => _LiveCourierMapState();
}

class _LiveCourierMapState extends State<LiveCourierMap> {
  final _map = MapController();
  bool _ready = false;

  CameraFit get _fit => widget.pin == null
      ? CameraFit.coordinates(
          coordinates: [widget.courier],
          maxZoom: 15.5,
          minZoom: 15.5,
        )
      : CameraFit.coordinates(
          coordinates: [widget.courier, widget.pin!],
          padding: const EdgeInsets.all(48),
          maxZoom: 16.5,
        );

  @override
  void didUpdateWidget(LiveCourierMap old) {
    super.didUpdateWidget(old);
    if (_ready && (old.courier != widget.courier || old.pin != widget.pin)) {
      try {
        _map.fitCamera(_fit);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          IgnorePointer(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCameraFit: _fit,
                onMapReady: () => _ready = true,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(urlTemplate: _tiles, userAgentPackageName: _agent),
                MarkerLayer(
                  markers: [
                    if (widget.pin case final p?)
                      Marker(
                        point: p,
                        width: 34,
                        height: 34,
                        child: const _Dot(
                          color: AppColors.blue,
                          icon: AppIcon.pin,
                        ),
                      ),
                    Marker(
                      point: widget.courier,
                      width: 44,
                      height: 44,
                      child: const _Dot(
                        color: AppColors.navy,
                        ring: AppColors.gold,
                        icon: AppIcon.truck,
                        semantics: 'المندوب',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: AppColors.white.withValues(alpha: .8),
              child: const Text(
                '© OpenStreetMap',
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 10, color: Color(0xFF555555)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.icon,
    this.ring = AppColors.white,
    this.semantics,
  });
  final Color color;
  final Color ring;
  final AppIcon icon;
  final String? semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semantics,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: AppSvgIcon(icon, color: AppColors.white, size: 18),
    ),
  );
}

/// «رابط تتبع المندوب»: the page copies or shares the courier link, or makes
/// a new one (the old link stops working).
class CourierLinkCard extends StatefulWidget {
  const CourierLinkCard({
    super.key,
    required this.link,
    required this.onRegenerate,
  });
  final CourierTrackingLink link;
  final Future<void> Function() onRegenerate;

  @override
  State<CourierLinkCard> createState() => _CourierLinkCardState();
}

class _CourierLinkCardState extends State<CourierLinkCard> {
  bool _busy = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link.url));
    if (mounted) showAppToast(context, 'انسخ الرابط');
  }

  Future<void> _share() async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'رابط توصيل الطلب: ${widget.link.url}',
          subject: 'رابط تتبع المندوب',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      await _copy();
    }
  }

  Future<void> _regenerate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تسوي رابط جديد؟'),
        content: const Text(
          'الرابط القديم يوكف هسه، ولازم تدز الجديد للمندوب.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('سوّي رابط جديد'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onRegenerate();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.link;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'دز هالرابط للمندوب. يفتحه بالمتصفح ويشوف العنوان والدبوس ورقم الزبون، '
          'ومن يدوس «ابدأ التوصيل» الزبون يشوف وين وصل.',
          style: AppText.muted,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const AppSvgIcon(AppIcon.link, color: AppColors.blue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: AppText.body.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: l.sharing ? AppColors.turquoise : AppColors.dotOff,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l.sharing
                    ? 'المندوب يشارك موقعه${l.lastLocationAt == null ? '' : ' · ${courierUpdatedLabel(l.lastLocationAt!.toLocal())}'}'
                    : 'المندوب بعده ما بدأ التوصيل من الرابط',
                style: AppText.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                'انسخ',
                compact: true,
                icon: AppIcon.copy,
                variant: AppButtonVariant.ghost,
                onPressed: _copy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                'شارك',
                compact: true,
                icon: AppIcon.link,
                onPressed: _share,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                'رابط جديد',
                compact: true,
                icon: AppIcon.refresh,
                variant: AppButtonVariant.ghost,
                onPressed: _busy ? null : _regenerate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
