// «حطها على حايطك»: see a product at its real size on your own wall.
//
// Flow: instructions → camera / gallery → match the A4 sheet's corners →
// the product drawn to scale, draggable, with its other sizes, «اطلبها»
// and a shareable image. The wall photo never leaves the device: it is held
// in memory only and is not sent to the API.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/router/routes.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/loading_block.dart';
import '../../core/widgets/seg_tabs.dart';
import '../guest/guest.dart';
import '../store/data/store_data.dart';
import '../store/presentation/widgets/store_widgets.dart';
import 'wall_math.dart';
import 'wall_photo.dart';
import 'wall_save.dart';

/// Set once the customer ticks «لا تعرض الشرح مرة ثانية».
const wallIntroHiddenKey = 'wall.intro.hidden';

/// Product-details card that opens the preview. Only shown for products
/// whose [StoreProduct.wall] is set (size + kind).
class WallPreviewEntry extends StatelessWidget {
  const WallPreviewEntry({super.key, required this.size, required this.onTap});
  final WallSize size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'حطها على حايطك',
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: .22),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.navyFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AppSvgIcon(
                _kindIcon(size.kind),
                color: AppColors.gold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حطها على حايطك',
                    style: AppText.strong.copyWith(fontSize: 15.5),
                  ),
                  Text(
                    'صوّر حايطك ويا ورقة A4 وشوفها بحجمها الحقيقي',
                    style: AppText.muted.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            AppSvgIcon(AppIcon.chevronLeft, color: AppColors.blue, size: 20),
          ],
        ),
      ),
    ),
  );
}

AppIcon _kindIcon(WallKind k) => switch (k) {
  WallKind.tv => AppIcon.tv,
  WallKind.frame || WallKind.art => AppIcon.image,
  WallKind.clock => AppIcon.clock,
  _ => AppIcon.ruler,
};

/// Route target: loads the product (same cache as the details screen).
class WallPreviewScreen extends ConsumerWidget {
  const WallPreviewScreen({
    super.key,
    required this.pageId,
    required this.productId,
  });
  final String pageId;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (pageId, productId);
    return ref
        .watch(productProvider(key))
        .when(
          loading: () => const AppPage(
            title: 'حطها على حايطك',
            children: [Gap(LoadingBlock(), top: 16)],
          ),
          error: (e, _) => AppPage(
            title: 'حطها على حايطك',
            children: [
              Gap(
                _Note(
                  e is ApiException && e.status == 404
                      ? 'هالمنتج ما بقى متوفر.'
                      : 'ما قدرنا نفتح المنتج. تأكد من النت وجرّب مرة ثانية.',
                ),
                top: 16,
              ),
            ],
          ),
          data: (p) {
            final pid = pageId.isEmpty ? p.pageId : pageId;
            final sizes = wallChoices(p);
            if (sizes.isEmpty) {
              return const AppPage(
                title: 'حطها على حايطك',
                children: [Gap(_Note('هالمنتج ما بي قياس للحايط.'), top: 16)],
              );
            }
            return WallFlow(product: p, pageId: pid, choices: sizes);
          },
        );
  }
}

/// The sizes the preview can switch between: wall-ready variants of the
/// same kind, or just the product itself.
List<ProductVariant> wallChoices(StoreProduct p) {
  final own = p.wall;
  if (own == null) return const [];
  final list = [
    for (final v in p.variants)
      if (v.wall?.kind == own.kind) v,
  ];
  if (!list.any((v) => v.id == p.id)) {
    return [ProductVariant.of(p)];
  }
  return list;
}

enum _Step { intro, align, result }

class WallFlow extends ConsumerStatefulWidget {
  const WallFlow({
    super.key,
    required this.product,
    required this.pageId,
    required this.choices,
    this.initialPhoto,
  });
  final StoreProduct product;
  final String pageId;
  final List<ProductVariant> choices;

  /// Tests start on the align step with a ready image.
  final ui.Image? initialPhoto;

  @override
  ConsumerState<WallFlow> createState() => _WallFlowState();
}

class _WallFlowState extends ConsumerState<WallFlow> {
  _Step _step = _Step.intro;
  ui.Image? _photo;
  var _busy = false;

  /// Sheet corners in photo px (TL, TR, BR, BL as placed).
  List<Offset> _quad = const [];

  /// null = follow the quad's shape.
  bool? _landscapeChoice;
  QuadIssue? _issue;

  /// Top-edge direction of the last corner labelling, so a sheet rolled
  /// near 45° keeps its orientation instead of flipping (hysteresis).
  double? _topDeg;

  late int _sel = math.max(
    0,
    widget.choices.indexWhere((v) => v.id == widget.product.id),
  );

  /// Product top-left on the wall, cm from the sheet's top-left.
  Offset? _pos;
  Homography? _h;
  bool _landscape = false;

  /// The ordered sheet corners [_h] was built from (for the accuracy check).
  List<Offset> _hQuad = const [];

  @override
  void initState() {
    super.initState();
    final photo = widget.initialPhoto;
    if (photo != null) {
      _setPhoto(photo);
    }
  }

  @override
  void dispose() {
    if (widget.initialPhoto == null) _photo?.dispose();
    super.dispose();
  }

  ProductVariant get _v => widget.choices[_sel];
  WallSize get _size => _v.wall!;
  Size get _photoSize =>
      Size(_photo!.width.toDouble(), _photo!.height.toDouble());

  bool get _hideIntro =>
      ref.read(sharedPrefsProvider).getBool(wallIntroHiddenKey) ?? false;

  void _setPhoto(ui.Image img) {
    if (_photo != widget.initialPhoto) _photo?.dispose();
    _photo = img;
    _quad = defaultQuad(_photoSize);
    _landscapeChoice = null;
    _issue = null;
    _topDeg = null;
    _pos = null;
    _h = null;
    _step = _Step.align;
  }

  Future<void> _pick({required bool camera}) async {
    if (_busy) return;
    setState(() => _busy = true);
    WallPickFailure? failed;
    try {
      final img = await pickWallPhoto(camera: camera);
      if (!mounted) {
        img?.dispose();
        return;
      }
      if (img != null) setState(() => _setPhoto(img));
    } on WallPickException catch (e) {
      failed = e.failure;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    // After clearing _busy, so the sheet's gallery fallback can pick.
    if (failed != null && mounted) await _pickFailed(failed, camera: camera);
  }

  Future<void> _pickFailed(WallPickFailure f, {required bool camera}) async {
    final (title, body) = switch (f) {
      WallPickFailure.denied when camera => (
        'نحتاج إذن الكاميرا',
        'حتى تصوّر حايطك، فعّل الكاميرا لدوّرلي من إعدادات التلفون. أو اختار صورة جاهزة من المعرض.',
      ),
      WallPickFailure.denied => (
        'نحتاج إذن الصور',
        'حتى تختار صورة حايطك، اسمح لدوّرلي يوصل للصور من إعدادات التلفون.',
      ),
      WallPickFailure.noCamera => (
        'ما لكينا كاميرا',
        'هالجهاز ما بي كاميرا نكدر نفتحها. اختار صورة الحايط من المعرض.',
      ),
      WallPickFailure.unreadable => (
        'ما كدرنا نفتح الصورة',
        'جرّب صورة ثانية (JPG أو PNG).',
      ),
    };
    final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => AppSheet(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.big.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppText.muted.copyWith(fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 18),
          if (f == WallPickFailure.denied && ios) ...[
            AppButton(
              'افتح الإعدادات',
              onPressed: () => Navigator.of(c).pop('settings'),
            ),
            const SizedBox(height: 10),
          ],
          if (camera && f != WallPickFailure.unreadable) ...[
            AppButton(
              'اختار صورة من المعرض',
              icon: AppIcon.image,
              variant: f == WallPickFailure.denied && ios
                  ? AppButtonVariant.ghost
                  : AppButtonVariant.primary,
              onPressed: () => Navigator.of(c).pop('gallery'),
            ),
            const SizedBox(height: 10),
          ],
          AppButton(
            'تمام',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(c).pop(),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'gallery') return _pick(camera: false);
    if (action == 'settings') {
      try {
        await launchUrl(Uri.parse('app-settings:'));
      } catch (_) {
        // No settings deep link on this device: nothing else to do.
      }
    }
  }

  // ------------------------------------------------------------ align

  bool get _effLandscape => _landscapeChoice ?? quadLooksLandscape(_ordered);
  List<Offset> get _ordered => orderCornersStable(_quad, prevTopDeg: _topDeg);

  /// The customer picked an orientation the photo clearly disagrees with.
  bool get _orientationOff =>
      _landscapeChoice != null &&
      orientationContradicts(_ordered, landscape: _landscapeChoice!);

  void _quadChanged(List<Offset> q) => setState(() {
    _quad = q;
    _issue = null;
    _topDeg = topEdgeDeg(_ordered);
  });

  Future<void> _confirmQuad() async {
    final issue = validateQuad(_ordered, _photoSize);
    if (issue != null) {
      setState(() => _issue = issue);
      return;
    }
    if (_orientationOff) {
      final forced = _landscapeChoice!;
      final fix = await _askOrientation(forced);
      if (fix == null || !mounted) return;
      if (fix) setState(() => _landscapeChoice = !forced);
    }
    final q = _ordered;
    final land = _effLandscape;
    final h = wallToPhoto(q, landscape: land);
    if (h == null) {
      setState(() => _issue = QuadIssue.notConvex);
      return;
    }
    setState(() {
      _issue = null;
      _h = h;
      _hQuad = q;
      _landscape = land;
      _pos = centredOnSheet(_size, landscape: land);
      _step = _Step.result;
    });
  }

  /// true = switch to what the photo shows, false = keep the forced choice,
  /// null = dismissed (stay on the align step).
  Future<bool?> _askOrientation(bool forcedLandscape) {
    final shown = forcedLandscape ? 'عمودية' : 'عرضية';
    final forced = forcedLandscape ? 'عرضية' : 'عمودية';
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => AppSheet(
        children: [
          Text(
            'الورقة بالصورة تبين $shown',
            textAlign: TextAlign.center,
            style: AppText.big.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'اخترت «$forced» بس الزوايا اللي حددتها شكلها $shown. إذا الاختيار غلط، ال${_size.kind.label} تطلع أكبر أو أصغر من حجمها الحقيقي.',
            textAlign: TextAlign.center,
            style: AppText.muted.copyWith(fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 18),
          AppButton(
            'صلّحها لـ $shown',
            icon: AppIcon.check,
            onPressed: () => Navigator.of(c).pop(true),
          ),
          const SizedBox(height: 10),
          AppButton(
            'متأكد، خليها $forced',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(c).pop(false),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ result

  void _select(int i) {
    if (i == _sel) return;
    final old = _size;
    setState(() {
      _sel = i;
      final h = _h;
      if (h == null || _pos == null) return;
      // Keep the centre where the customer put it.
      final c = _pos! + Offset(old.widthCm / 2, old.heightCm / 2);
      final next = c - Offset(_size.widthCm / 2, _size.heightCm / 2);
      _pos = placementOk(h, next, _size, _photoSize)
          ? next
          : centredOnSheet(_size, landscape: _landscape);
    });
  }

  Future<void> _order() async {
    final v = _v;
    final ok = await addToCart(context, ref, v.id);
    if (!ok || !mounted) return;
    final goCart = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => AppSheet(
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: AppSvgIcon(AppIcon.check, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'انضاف للسلة',
            textAlign: TextAlign.center,
            style: AppText.big.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            v.name,
            textAlign: TextAlign.center,
            style: AppText.muted.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          AppButton(
            'روح للسلة',
            icon: AppIcon.cart,
            onPressed: () => Navigator.of(c).pop(true),
          ),
          const SizedBox(height: 10),
          AppButton(
            'كمّل',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(c).pop(false),
          ),
        ],
      ),
    );
    if (goCart == true && mounted) context.push(Routes.cart);
  }

  final _shotKey = GlobalKey();
  var _stamp = false;
  var _sharing = false;
  var _saving = false;

  /// «حفظ بالصور»: the same stamped image as «شارك», into the gallery
  /// (phones) or downloaded as a PNG (web).
  Future<void> _save() async {
    if (_saving || _sharing) return;
    setState(() {
      _saving = true;
      _stamp = true;
    });
    var result = WallSaveResult.failed;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final png = await _capture();
      if (png != null) {
        result = await saveWallImage(png, name: 'dawwerli-wall');
      }
    } catch (_) {
      result = WallSaveResult.failed;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _stamp = false;
        });
      }
    }
    if (!mounted) return;
    final (text, icon) = switch (result) {
      WallSaveResult.saved => ('انحفظت الصورة بالصور', AppIcon.check),
      WallSaveResult.downloaded => ('نزّلنا الصورة على جهازك', AppIcon.check),
      WallSaveResult.denied => (
        'نحتاج إذن الصور حتى نحفظها. فعّله من إعدادات التلفون، أو استخدم «شارك».',
        AppIcon.alert,
      ),
      WallSaveResult.failed => (
        'ما كدرنا نحفظ الصورة. جرّب «شارك».',
        AppIcon.alert,
      ),
    };
    showAppToast(context, text, icon: icon);
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _stamp = true;
    });
    final origin = _originRect();
    try {
      await WidgetsBinding.instance.endOfFrame;
      final png = await _capture();
      if (png == null) throw StateError('capture');
      final s = _size;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: 'dawwerli-wall.png',
            ),
          ],
          fileNameOverrides: const ['dawwerli-wall.png'],
          text: '${_v.name} على حايطي · ${sizeText(s)} · دوّرلي',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          'ما كدرنا نشارك الصورة. جرّب مرة ثانية.',
          icon: AppIcon.alert,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
          _stamp = false;
        });
      }
    }
  }

  Rect? _originRect() {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  /// Composited PNG at (close to) the photo's own resolution.
  Future<Uint8List?> _capture() async {
    final b =
        _shotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null || !b.hasSize || b.size.width <= 0) return null;
    final ratio = (_photo!.width / b.size.width).clamp(1.0, 4.0);
    final img = await b.toImage(pixelRatio: ratio);
    try {
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      img.dispose();
    }
  }

  void _back() {
    switch (_step) {
      case _Step.result:
        setState(() => _step = _Step.align);
      case _Step.align:
        setState(() => _step = _Step.intro);
      case _Step.intro:
        popOr(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_step) {
      _Step.intro => _intro(compact: _hideIntro),
      _Step.align => _align(),
      _Step.result => _result(),
    };
    return PopScope(
      canPop: _step == _Step.intro,
      onPopInvokedWithResult: (did, _) {
        if (!did) _back();
      },
      child: body,
    );
  }

  // ---------------------------------------------------------- 1. intro

  Widget _intro({required bool compact}) {
    final s = _size;
    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wallCameraAvailable) ...[
          AppButton(
            _busy ? 'دا نفتح...' : 'افتح الكاميرا',
            icon: _busy ? null : AppIcon.camera,
            onPressed: _busy ? null : () => _pick(camera: true),
          ),
          const SizedBox(height: 10),
        ],
        AppButton(
          wallCameraAvailable
              ? 'اختار صورة من المعرض'
              : (_busy ? 'دا نفتح...' : 'اختار صورة الحايط'),
          icon: AppIcon.image,
          variant: wallCameraAvailable
              ? AppButtonVariant.ghost
              : AppButtonVariant.primary,
          onPressed: _busy ? null : () => _pick(camera: false),
        ),
      ],
    );
    return AppPage(
      title: 'حطها على حايطك',
      subtitle: '${_v.name} · ${sizeText(s)}',
      onBack: _back,
      bottom: _Narrow(560, buttons),
      children: [
        for (final w in _introBody(compact: compact, s: s)) _Narrow(640, w),
      ],
    );
  }

  List<Widget> _introBody({required bool compact, required WallSize s}) {
    final steps = [
      (
        1,
        'لزّق ورقة A4 بيضة على الحايط',
        'بالمكان اللي تريد تحط بي ال${s.kind.label}، عمودية أو عرضية، وخلّيها مستوية وما بيها طيّات.',
      ),
      (
        2,
        'صوّر الحايط وانت مقابله',
        'لازم الورقة كلها تبين بالصورة، والضوّة تكون زينة.',
      ),
      (
        3,
        'طابق زوايا الورقة',
        'من الورقة نعرف القياس الحقيقي ونرسم ال${s.kind.label} بحجمها على حايطك.',
      ),
    ];
    return [
      if (!compact)
        Gap(
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 196,
              child: CustomPaint(
                painter: _IntroArt(AppColors.dark, sizeText(s)),
              ),
            ),
          ),
          top: 16,
        ),
      if (!compact) const SectionLabel('بثلاث خطوات بسيطة'),
      for (final (i, t, b) in steps)
        Gap(
          _StepRow(i, t, compact ? null : b),
          top: compact && i == 1 ? 18 : 14,
        ),
      Gap(
        AppCard(
          flat: true,
          color: AppColors.blueTint,
          insets: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AppSvgIcon(AppIcon.ruler, color: AppColors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'الورقة هي المسطرة: 21 × 29.7 سم. صورتك تبقى على تلفونك وما نرفعها لأي مكان.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.7,
                    color: AppColors.infoText,
                  ),
                ),
              ),
            ],
          ),
        ),
        top: 18,
      ),
      if (!compact)
        Gap(
          _HideIntroToggle(
            value: _hideIntro,
            onChanged: (v) async {
              await ref
                  .read(sharedPrefsProvider)
                  .setBool(wallIntroHiddenKey, v);
              if (mounted) setState(() {});
            },
          ),
          top: 10,
        )
      else
        Gap(
          Center(
            child: TextButton(
              onPressed: () async {
                await ref
                    .read(sharedPrefsProvider)
                    .setBool(wallIntroHiddenKey, false);
                if (mounted) setState(() {});
              },
              child: Text(
                'شوف الشرح كامل',
                style: AppText.strong.copyWith(
                  color: AppColors.blue,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          top: 8,
        ),
    ];
  }

  // ---------------------------------------------------------- 2. align

  Widget _align() {
    final land = _effLandscape;
    return _FixedPage(
      title: 'طابق الزوايا',
      subtitle: 'اسحب كل دائرة لزاوية من زوايا الورقة',
      onBack: _back,
      bottom: AppButton('تم', icon: AppIcon.check, onPressed: _confirmQuad),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _AlignView(
              photo: _photo!,
              quad: _quad,
              onChanged: _quadChanged,
            ),
          ),
          const SizedBox(height: 12),
          SegTabs(
            labels: const ['الورقة عمودية', 'الورقة عرضية'],
            selected: land ? 1 : 0,
            onSelect: (i) => setState(() => _landscapeChoice = i == 1),
          ),
          const SizedBox(height: 10),
          if (_issue != null)
            _Note(_issue!.message, danger: true)
          else ...[
            if (_orientationOff)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Note(
                  land
                      ? 'الورقة بالصورة تبين عمودية. متأكد إنها معلّكة عرضية؟'
                      : 'الورقة بالصورة تبين عرضية. متأكد إنها معلّكة عمودية؟',
                  warn: true,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    land
                        ? 'A4 عرضية · 29.7 × 21 سم'
                        : 'A4 عمودية · 21 × 29.7 سم',
                    style: AppText.muted.copyWith(fontSize: 12.5),
                  ),
                ),
                _LinkButton(
                  'رجّع الزوايا',
                  icon: AppIcon.refresh,
                  onTap: () => setState(() {
                    _quad = defaultQuad(_photoSize);
                    _landscapeChoice = null;
                    _issue = null;
                    _topDeg = null;
                  }),
                ),
                const SizedBox(width: 6),
                _LinkButton(
                  'صورة ثانية',
                  icon: AppIcon.camera,
                  onTap: () => setState(() => _step = _Step.intro),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------- 3. result

  Widget _result() {
    final v = _v, s = _size;
    final low = v.available && v.stock > 0 && v.stock <= 3;
    final acc = wallAccuracy(
      _hQuad,
      _photoSize,
      s,
      _pos!,
      landscape: _landscape,
    );
    final order = v.available
        ? AppButton(
            'اطلبها',
            icon: AppIcon.cart,
            onPressed: () => memberOnly(
              context,
              ref,
              _order,
              returnTo: Routes.wallPreview(widget.pageId, _v.id),
            ),
          )
        : const AppButton('نفدت', variant: AppButtonVariant.disabled);
    final keep = Row(
      children: [
        Expanded(
          child: AppButton(
            _saving ? 'دا نحفظ...' : 'حفظ بالصور',
            icon: _saving ? null : AppIcon.image,
            variant: AppButtonVariant.ghost,
            onPressed: _saving || _sharing ? null : _save,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            _sharing ? 'دا نجهّز...' : 'شارك',
            icon: _sharing ? null : AppIcon.share,
            variant: AppButtonVariant.ghost,
            onPressed: _saving || _sharing ? null : _share,
          ),
        ),
      ],
    );
    final badge = Align(
      alignment: AlignmentDirectional.centerStart,
      child: acc.approximate
          ? _Pill(
              'حجم تقريبي · الورقة صغيرة بالصورة',
              icon: AppIcon.alert,
              bg: AppColors.warnBg,
              fg: AppColors.warnText,
              size: 11.5,
            )
          : _Pill(
              'حجم حقيقي · محسوب من ورقة A4',
              icon: AppIcon.check,
              bg: AppColors.turquoise.withValues(alpha: .94),
              size: 11.5,
            ),
    );
    final hints = [
      if (acc.approximate)
        'القياس تقريبي لأن الورقة صغيرة بالصورة. حتى يطلع أدق: قرّب من الحايط وصوّر مرة ثانية حتى تبين الورقة أكبر، وحطها قريبة من مكان ال${s.kind.label}.',
      if (acc.tilted)
        'الصورة مايلة على الحايط. صوّر وانت مقابل الحايط حتى يطلع القياس أدق.',
    ];
    final photo = _ResultView(
      photo: _photo!,
      h: _h!,
      pos: _pos!,
      size: s,
      imageUrl: v.imageUrl,
      stamp: _stamp,
      stampText: 'دوّرلي · ${v.label.isEmpty ? sizeText(s) : v.label}',
      shotKey: _shotKey,
      onMove: (p) => setState(() => _pos = p),
    );
    final sizes = widget.choices.length < 2
        ? null
        : SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.choices.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _SizeChip(
                label: widget.choices[i].label.isEmpty
                    ? sizeText(widget.choices[i].wall!)
                    : widget.choices[i].label,
                selected: i == _sel,
                soldOut: !widget.choices[i].available,
                onTap: () => _select(i),
              ),
            ),
          );
    final info = AppCard(
      insets: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          AppSvgIcon(AppIcon.ruler, color: AppColors.blue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sizeText(s, depth: true),
                  style: AppText.big.copyWith(fontSize: 17),
                ),
                Text(
                  !v.available
                      ? 'نفدت الكمية'
                      : low
                      ? 'باقي ${v.stock} بس'
                      : s.kind == WallKind.tv
                      ? 'عرض × ارتفاع بدون الستاند'
                      : 'عرض × ارتفاع',
                  style: AppText.muted.copyWith(
                    fontSize: 12.5,
                    color: !v.available || low ? AppColors.danger : null,
                  ),
                ),
              ],
            ),
          ),
          Text(
            storePrice(v.price),
            style: AppText.number.copyWith(
              color: AppColors.blue,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
    final subtitle =
        '${v.label.isEmpty ? v.name : v.label} · ${acc.approximate ? 'حجم تقريبي' : 'حجم حقيقي'}';
    return LayoutBuilder(
      builder: (context, c) {
        // Desktop / tablet landscape: photo on one side, controls beside it.
        if (c.maxWidth >= 900) {
          return _FixedPage(
            title: 'على حايطك',
            subtitle: subtitle,
            onBack: _back,
            maxWidth: 1240,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: photo),
                const SizedBox(width: 20),
                SizedBox(
                  width: 360,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        badge,
                        for (final h in hints) ...[
                          const SizedBox(height: 10),
                          _Note(h, warn: true),
                        ],
                        const SizedBox(height: 12),
                        info,
                        if (sizes != null) ...[
                          const SizedBox(height: 12),
                          sizes,
                        ],
                        const SizedBox(height: 16),
                        order,
                        const SizedBox(height: 10),
                        keep,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return _FixedPage(
          title: 'على حايطك',
          subtitle: subtitle,
          onBack: _back,
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [order, const SizedBox(height: 10), keep],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              badge,
              const SizedBox(height: 8),
              Expanded(child: photo),
              for (final h in hints) ...[
                const SizedBox(height: 8),
                _Note(h, warn: true),
              ],
              if (sizes != null) ...[const SizedBox(height: 10), sizes],
              const SizedBox(height: 10),
              info,
            ],
          ),
        );
      },
    );
  }
}

/// Header + non-scrolling body: the align and result steps own their drag
/// gestures, so no scroll view may compete for them.
class _FixedPage extends StatelessWidget {
  const _FixedPage({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.body,
    this.bottom,
    this.maxWidth = 720,
  });
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget body;
  final Widget? bottom;

  /// Content stays this wide at most, centred, so desktop browsers don't get
  /// a 1280px-wide segmented control or button row.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(title: title, subtitle: Text(subtitle), onBack: onBack),
          Expanded(
            child: _Narrow(
              maxWidth,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: body,
              ),
            ),
          ),
          if (bottom != null)
            _Narrow(
              math.min(maxWidth, 560),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + inset),
                child: bottom,
              ),
            )
          else
            SizedBox(height: 16 + inset),
        ],
      ),
    );
  }
}

/// Centres [child] at no more than [maxWidth].
class _Narrow extends StatelessWidget {
  const _Narrow(this.maxWidth, this.child);
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow(this.i, this.title, this.body);
  final int i;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.navyFill,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$i',
          style: AppText.number.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: body == null ? 5 : 0),
              child: Text(title, style: AppText.strong.copyWith(fontSize: 15)),
            ),
            if (body != null) ...[
              const SizedBox(height: 2),
              Text(
                body!,
                style: AppText.muted.copyWith(fontSize: 13, height: 1.6),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _HideIntroToggle extends StatelessWidget {
  const _HideIntroToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: value,
    label: 'لا تعرض هالشرح مرة ثانية',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? AppColors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: value ? AppColors.blue : AppColors.border,
                  width: 2,
                ),
              ),
              child: value
                  ? const AppSvgIcon(
                      AppIcon.check,
                      color: AppColors.white,
                      size: 15,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              'لا تعرض هالشرح مرة ثانية',
              style: AppText.body.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton(this.text, {required this.icon, required this.onTap});
  final String text;
  final AppIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(icon, color: AppColors.blue, size: 16),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppText.strong.copyWith(
                color: AppColors.blue,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text, {this.danger = false, this.warn = false});
  final String text;
  final bool danger;

  /// Amber: something to double-check, not an error.
  final bool warn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: danger
          ? AppColors.dangerBg
          : warn
          ? AppColors.warnBg
          : AppColors.blueTint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        AppSvgIcon(
          AppIcon.alert,
          color: danger
              ? AppColors.danger
              : warn
              ? AppColors.warn
              : AppColors.blue,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AppText.family,
              fontSize: 13,
              height: 1.6,
              color: danger
                  ? AppColors.dangerText
                  : warn
                  ? AppColors.warnText
                  : AppColors.infoText,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.soldOut,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool soldOut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.navyFill : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          soldOut ? '$label · نفدت' : label,
          style: AppText.strong.copyWith(
            fontSize: 13,
            color: selected ? AppColors.white : AppColors.ink,
            decoration: soldOut ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.grey,
          ),
        ),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.icon, this.bg, this.fg, this.size = 12.5});
  final String text;
  final AppIcon? icon;
  final Color? bg;
  final Color? fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final f = fg ?? AppColors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? AppColors.navy.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppSvgIcon(icon!, color: f, size: size + 3),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppText.family,
                fontSize: size,
                fontWeight: FontWeight.w600,
                color: f,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centers [child] on [at].
Widget _at(Offset at, Widget child) => Positioned(
  left: at.dx,
  top: at.dy,
  child: FractionalTranslation(
    translation: const Offset(-.5, -.5),
    child: child,
  ),
);

/// Fits the photo (no letterbox) inside the available space, centered.
class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.photo, required this.builder});
  final ui.Image photo;
  final Widget Function(double scale, Size box) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final pw = photo.width.toDouble(), ph = photo.height.toDouble();
      final s = math.min(c.maxWidth / pw, c.maxHeight / ph);
      final box = Size(pw * s, ph * s);
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox.fromSize(size: box, child: builder(s, box)),
        ),
      );
    },
  );
}

// ------------------------------------------------------------- align view

class _AlignView extends StatefulWidget {
  const _AlignView({
    required this.photo,
    required this.quad,
    required this.onChanged,
  });
  final ui.Image photo;
  final List<Offset> quad;
  final ValueChanged<List<Offset>> onChanged;

  @override
  State<_AlignView> createState() => _AlignViewState();
}

class _AlignViewState extends State<_AlignView> {
  int? _active;

  static const _grab = 40.0;

  /// Screen px per accessibility nudge.
  static const _step = 4.0;
  static const _nudges = [
    ('حرّك لفوك', Offset(0, -1)),
    ('حرّك لجوّه', Offset(0, 1)),
    ('حرّك لليمين', Offset(1, 0)),
    ('حرّك لليسار', Offset(-1, 0)),
  ];

  void _nudge(int i, Offset by) {
    final p = widget.quad[i] + by;
    final next = [...widget.quad];
    next[i] = Offset(
      p.dx.clamp(0, widget.photo.width.toDouble()),
      p.dy.clamp(0, widget.photo.height.toDouble()),
    );
    widget.onChanged(next);
  }

  /// Where handle [i] sits on the sheet, as the customer sees it.
  String _cornerName(int i) {
    final o = orderCorners(widget.quad);
    final k = o.indexOf(widget.quad[i]);
    return const ['فوك يسار', 'فوك يمين', 'جوّه يمين', 'جوّه يسار'][k < 0
        ? i
        : k];
  }

  @override
  Widget build(BuildContext context) => _PhotoBox(
    photo: widget.photo,
    builder: (s, box) {
      final pts = [for (final p in widget.quad) p * s];
      final active = _active;
      // Loupe sits in the top corner away from the finger.
      final loupeLeft = active != null && pts[active].dx < box.width / 2;
      const loupe = 112.0;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          var best = -1;
          var dist = _grab;
          for (var i = 0; i < pts.length; i++) {
            final dd = (pts[i] - d.localPosition).distance;
            if (dd < dist) {
              dist = dd;
              best = i;
            }
          }
          setState(() => _active = best < 0 ? null : best);
        },
        onPanUpdate: (d) {
          final i = _active;
          if (i == null) return;
          final p = widget.quad[i] + d.delta / s;
          final next = [...widget.quad];
          next[i] = Offset(
            p.dx.clamp(0, widget.photo.width.toDouble()),
            p.dy.clamp(0, widget.photo.height.toDouble()),
          );
          widget.onChanged(next);
        },
        onPanEnd: (_) => setState(() => _active = null),
        onPanCancel: () => setState(() => _active = null),
        child: Stack(
          children: [
            Positioned.fill(
              child: RawImage(
                image: widget.photo,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _QuadPainter(pts, active)),
            ),
            // Screen readers: each handle is a node that can be nudged.
            for (var i = 0; i < pts.length; i++)
              Positioned(
                left: pts[i].dx - 22,
                top: pts[i].dy - 22,
                width: 44,
                height: 44,
                child: Semantics(
                  label: 'زاوية الورقة ${_cornerName(i)}',
                  hint: 'حرّكها حتى توكف على زاوية الورقة بالصورة',
                  customSemanticsActions: {
                    for (final (name, d) in _nudges)
                      CustomSemanticsAction(label: name): () =>
                          _nudge(i, d * (_step / s)),
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            if (active != null)
              Positioned(
                top: 10,
                left: loupeLeft ? null : 10,
                right: loupeLeft ? 10 : null,
                child: _Loupe(
                  photo: widget.photo,
                  center: widget.quad[active],
                  scale: s * 3,
                  size: loupe,
                ),
              )
            else
              const Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _Pill(
                    'طابق الدوائر ويا زوايا الورقة',
                    icon: AppIcon.hand,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _QuadPainter extends CustomPainter {
  _QuadPainter(this.pts, this.active);
  final List<Offset> pts;
  final int? active;

  @override
  void paint(Canvas canvas, Size size) {
    final ordered = orderCorners(pts);
    final path = Path()..addPolygon(ordered, true);
    canvas.drawPath(
      path,
      Paint()..color = AppColors.turquoise.withValues(alpha: .16),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.turquoise
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < pts.length; i++) {
      final on = i == active;
      final r = on ? 15.0 : 12.0;
      canvas.drawCircle(
        pts[i],
        r + 2,
        Paint()..color = Colors.black.withValues(alpha: .25),
      );
      canvas.drawCircle(
        pts[i],
        r,
        Paint()..color = AppColors.gold.withValues(alpha: on ? .35 : .18),
      );
      canvas.drawCircle(
        pts[i],
        r,
        Paint()
          ..color = on ? AppColors.gold : Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(pts[i], 2.4, Paint()..color = AppColors.navy);
    }
  }

  @override
  bool shouldRepaint(_QuadPainter old) =>
      old.active != active || !listEquals(old.pts, pts);
}

class _Loupe extends StatelessWidget {
  const _Loupe({
    required this.photo,
    required this.center,
    required this.scale,
    required this.size,
  });
  final ui.Image photo;
  final Offset center;
  final double scale;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ox = center.dx * scale - size / 2;
    final oy = center.dy * scale - size / 2;
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              Positioned(
                left: -ox,
                top: -oy,
                width: photo.width * scale,
                height: photo.height * scale,
                child: RawImage(
                  image: photo,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _Cross())),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cross extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2;
    canvas.drawLine(c.translate(-14, 0), c.translate(-4, 0), p);
    canvas.drawLine(c.translate(4, 0), c.translate(14, 0), p);
    canvas.drawLine(c.translate(0, -14), c.translate(0, -4), p);
    canvas.drawLine(c.translate(0, 4), c.translate(0, 14), p);
  }

  @override
  bool shouldRepaint(_Cross old) => false;
}

// ------------------------------------------------------------ result view

class _ResultView extends StatefulWidget {
  const _ResultView({
    required this.photo,
    required this.h,
    required this.pos,
    required this.size,
    required this.imageUrl,
    required this.stamp,
    required this.stampText,
    required this.shotKey,
    required this.onMove,
  });
  final ui.Image photo;

  /// Wall cm → photo px.
  final Homography h;
  final Offset pos;
  final WallSize size;
  final String? imageUrl;
  final bool stamp;
  final String stampText;
  final GlobalKey shotKey;
  final ValueChanged<Offset> onMove;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  Offset? _grabCm;
  Offset? _grabPos;

  Size get _photoSize =>
      Size(widget.photo.width.toDouble(), widget.photo.height.toDouble());

  @override
  Widget build(BuildContext context) => _PhotoBox(
    photo: widget.photo,
    builder: (s, box) {
      final d = widget.size;
      final h = widget.h;
      Offset g(double x, double y) => h.map(widget.pos + Offset(x, y)) * s;
      final local = [
        Offset.zero,
        Offset(d.widthCm, 0),
        Offset(d.widthCm, d.heightCm),
        Offset(0, d.heightCm),
      ];
      final toBox = Homography.tryFromPoints(local, [
        for (final p in local) g(p.dx, p.dy),
      ]);
      // Screen px → wall cm, for drags that track the finger exactly even
      // under perspective.
      final boxToPhoto = Homography([
        1 / s, 0, 0, //
        0, 1 / s, 0, //
        0, 0, 1,
      ]);
      final inv = h.inverse();
      Offset? cmAt(Offset box) {
        if (inv == null) return null;
        final p = boxToPhoto.map(box);
        if (inv.weight(p).abs() < 1e-12) return null;
        return inv.map(p);
      }

      final gap = math.max(4.0, math.max(d.widthCm, d.heightCm) * .07);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (e) {
          _grabCm = cmAt(e.localPosition);
          _grabPos = widget.pos;
        },
        onPanUpdate: (e) {
          final from = _grabCm, start = _grabPos;
          final now = cmAt(e.localPosition);
          if (from == null || start == null || now == null) return;
          final next = start + (now - from);
          widget.onMove(clampPlacement(h, widget.pos, next, d, _photoSize));
        },
        onPanEnd: (_) => _grabCm = _grabPos = null,
        child: Stack(
          children: [
            RepaintBoundary(
              key: widget.shotKey,
              child: SizedBox.fromSize(
                size: box,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: RawImage(
                        image: widget.photo,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    if (toBox != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Transform(
                          transform: Matrix4.fromList(toBox.toMatrix4Storage()),
                          child: SizedBox(
                            width: d.widthCm,
                            height: d.heightCm,
                            child: WallProductArt(
                              size: d,
                              imageUrl: widget.imageUrl,
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _DimPainter(g, d, gap)),
                      ),
                    ),
                    _at(
                      g(d.widthCm / 2, -gap),
                      _Pill(
                        '${cmText(d.widthCm)} سم',
                        bg: AppColors.gold,
                        fg: AppColors.navy,
                        size: 12,
                      ),
                    ),
                    _at(
                      g(d.widthCm + gap, d.heightCm / 2),
                      _Pill(
                        '${cmText(d.heightCm)} سم',
                        bg: AppColors.gold,
                        fg: AppColors.navy,
                        size: 12,
                      ),
                    ),
                    if (widget.stamp)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: _Pill(
                          widget.stampText,
                          bg: AppColors.navy.withValues(alpha: .85),
                          fg: AppColors.goldSoft,
                          size: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // The accuracy badge sits above the photo (not on it), so it can
            // never cover the dimension labels.
            if (!widget.stamp) ...[
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: _Pill(
                    'اسحب ال${d.kind.label} حتى تغيّر مكانها',
                    icon: AppIcon.hand,
                    size: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _DimPainter extends CustomPainter {
  _DimPainter(this.g, this.d, this.gap);
  final Offset Function(double x, double y) g;
  final WallSize d;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final t = gap * .45;
    final w = d.widthCm, h = d.heightCm;
    canvas.drawLine(g(0, -gap), g(w, -gap), p);
    canvas.drawLine(g(0, -gap + t), g(0, -gap - t), p);
    canvas.drawLine(g(w, -gap + t), g(w, -gap - t), p);
    canvas.drawLine(g(w + gap, 0), g(w + gap, h), p);
    canvas.drawLine(g(w + gap - t, 0), g(w + gap + t, 0), p);
    canvas.drawLine(g(w + gap - t, h), g(w + gap + t, h), p);
  }

  @override
  bool shouldRepaint(_DimPainter old) => true;
}

/// The product, drawn in a width × height box of centimetre units. Whenever
/// the product has a photo, that real photo is shown (contain-fit on a
/// transparent background, so it is never cropped or stretched). The
/// procedural TV / mirror / plain card is only a fallback: while the photo
/// loads, when it fails, or when there is none.
class WallProductArt extends StatelessWidget {
  const WallProductArt({super.key, required this.size, this.imageUrl});
  final WallSize size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final fallback = _fallback();
    if (url.isEmpty) return fallback;
    return Image(
      key: const ValueKey('wall-product-photo'),
      image: appImage(url),
      fit: BoxFit.contain,
      width: size.widthCm,
      height: size.heightCm,
      filterQuality: FilterQuality.medium,
      // Until the first frame arrives, keep the drawn stand-in in place.
      frameBuilder: (_, child, frame, sync) =>
          sync || frame != null ? child : fallback,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Widget _fallback() {
    final shadow = BoxShadow(
      color: const Color(0x66000000),
      blurRadius: math.max(1.5, size.widthCm * .03),
      offset: Offset(0, math.max(.8, size.heightCm * .02)),
    );
    switch (size.kind) {
      case WallKind.tv:
        return DecoratedBox(
          key: const ValueKey('wall-product-drawn'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(.8),
            boxShadow: [shadow],
          ),
          child: CustomPaint(painter: _TvPainter()),
        );
      case WallKind.mirror:
        return DecoratedBox(
          key: const ValueKey('wall-product-drawn'),
          decoration: BoxDecoration(
            shape: size.round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: size.round
                ? null
                : BorderRadius.circular(
                    math.min(size.widthCm, size.heightCm) * .06,
                  ),
            boxShadow: [shadow],
          ),
          child: CustomPaint(painter: _MirrorPainter(round: size.round)),
        );
      default:
        return DecoratedBox(
          key: const ValueKey('wall-product-drawn'),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E4D8),
            boxShadow: [shadow],
          ),
          child: const SizedBox.expand(),
        );
    }
  }
}

class _TvPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bezel = math.max(.6, math.min(w, h) * .012);
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(bezel),
    );
    canvas.drawRRect(outer, Paint()..color = const Color(0xFF0B0B0F));
    final screen = Rect.fromLTRB(bezel, bezel, w - bezel, h - bezel * 1.6);
    canvas.drawRect(
      screen,
      Paint()
        ..shader = ui.Gradient.linear(
          screen.topLeft,
          screen.bottomRight,
          const [Color(0xFF1B2540), Color(0xFF0A0F1C), Color(0xFF131B30)],
          const [0, .55, 1],
        ),
    );
    // Soft diagonal glare.
    final glare = Path()
      ..moveTo(screen.left + screen.width * .55, screen.top)
      ..lineTo(screen.left + screen.width * .8, screen.top)
      ..lineTo(screen.left + screen.width * .45, screen.bottom)
      ..lineTo(screen.left + screen.width * .2, screen.bottom)
      ..close();
    canvas.save();
    canvas.clipRect(screen);
    canvas.drawPath(
      glare,
      Paint()..color = Colors.white.withValues(alpha: .05),
    );
    canvas.restore();
    // Power LED.
    canvas.drawCircle(
      Offset(w / 2, h - bezel * .8),
      math.max(.15, bezel * .18),
      Paint()..color = const Color(0xFF3A3F4A),
    );
  }

  @override
  bool shouldRepaint(_TvPainter old) => false;
}

class _MirrorPainter extends CustomPainter {
  _MirrorPainter({required this.round});
  final bool round;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final frame = math.max(1.0, math.min(size.width, size.height) * .045);
    Path shape(Rect rect) => round
        ? (Path()..addOval(rect))
        : (Path()..addRRect(
            RRect.fromRectAndRadius(
              rect,
              Radius.circular(math.min(rect.width, rect.height) * .06),
            ),
          ));
    canvas.drawPath(
      shape(r),
      Paint()
        ..shader = ui.Gradient.linear(
          r.topLeft,
          r.bottomRight,
          const [Color(0xFFD9B46A), Color(0xFF9C7A35), Color(0xFFE6C98A)],
          const [0, .5, 1],
        ),
    );
    final glass = r.deflate(frame);
    canvas.drawPath(
      shape(glass),
      Paint()
        ..shader = ui.Gradient.linear(
          glass.topLeft,
          glass.bottomRight,
          const [Color(0xFFE8EEF2), Color(0xFFB9C6CF), Color(0xFFDCE4EA)],
          const [0, .6, 1],
        ),
    );
    canvas.save();
    canvas.clipPath(shape(glass));
    final streak = Paint()..color = Colors.white.withValues(alpha: .35);
    for (final (a, b) in [(.18, .3), (.36, .42)]) {
      canvas.drawPath(
        Path()
          ..moveTo(glass.left + glass.width * a, glass.top)
          ..lineTo(glass.left + glass.width * b, glass.top)
          ..lineTo(glass.left + glass.width * (b - .3), glass.bottom)
          ..lineTo(glass.left + glass.width * (a - .3), glass.bottom)
          ..close(),
        streak,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MirrorPainter old) => old.round != round;
}

class _IntroArt extends CustomPainter {
  _IntroArt(this.dark, this.sizeLabel);
  final bool dark;
  final String sizeLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? const Color(0xFF1A2847) : const Color(0xFFF1EADB),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h - 34, w, 34),
      Paint()..color = dark ? const Color(0xFF141F38) : const Color(0xFFE3D8C3),
    );
    final c = Offset(w * .58, 78);
    final piece = Rect.fromCenter(center: c, width: 188, height: 108);
    final dash = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    void dashed(Offset a, Offset b) {
      final d = (b - a).distance;
      final u = (b - a) / d;
      for (var t = 0.0; t < d; t += 10) {
        canvas.drawLine(a + u * t, a + u * math.min(t + 5, d), dash);
      }
    }

    dashed(piece.topLeft, piece.topRight);
    dashed(piece.topRight, piece.bottomRight);
    dashed(piece.bottomRight, piece.bottomLeft);
    dashed(piece.bottomLeft, piece.topLeft);
    final paper = Rect.fromCenter(center: c, width: 40, height: 56);
    canvas.drawRect(
      paper.shift(const Offset(2, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: .14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRect(paper, Paint()..color = Colors.white);
    final tape = Paint()..color = AppColors.goldSoft.withValues(alpha: .85);
    for (final (p, a) in [(paper.topLeft, -.6), (paper.topRight, .6)]) {
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 6),
        tape,
      );
      canvas.restore();
    }
    final label = dark ? AppColors.goldSoft : const Color(0xFF7A5300);
    _text(canvas, 'A4', c, 13, AppColors.navy, FontWeight.w700);
    _text(
      canvas,
      '21 × 29.7 سم',
      Offset(c.dx, paper.bottom + 12),
      10.5,
      label,
      FontWeight.w600,
    );
    _text(
      canvas,
      sizeLabel,
      Offset(piece.right - 40, piece.top - 10),
      10.5,
      label,
      FontWeight.w600,
    );
    final phone = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .1, 58, 70, 124),
      const Radius.circular(14),
    );
    canvas.drawRRect(phone, Paint()..color = AppColors.navy);
    final screen = phone.deflate(5);
    canvas.drawRRect(screen, Paint()..color = const Color(0xFFE9E1CF));
    final mini = Rect.fromCenter(
      center: screen.center.translate(0, -6),
      width: 16,
      height: 22,
    );
    canvas.drawRect(mini, Paint()..color = Colors.white);
    canvas.drawRect(
      mini.inflate(5),
      Paint()
        ..color = AppColors.turquoise
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      Offset(screen.center.dx, screen.bottom - 13),
      7,
      Paint()..color = Colors.white,
    );
  }

  void _text(
    Canvas c,
    String s,
    Offset at,
    double size,
    Color color,
    FontWeight wt,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: AppText.family,
          fontSize: size,
          color: color,
          fontWeight: wt,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_IntroArt old) =>
      old.dark != dark || old.sizeLabel != sizeLabel;
}
