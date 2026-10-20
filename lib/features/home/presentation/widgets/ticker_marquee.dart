import 'package:flutter/widgets.dart';

/// Endless horizontal marquee: [children] laid out twice back to back and slid
/// left → right at [speed] px/s, wrapping after one copy so the loop is seamless.
/// Press and hold pauses it; lifting resumes. Uses a raw [Listener] (no gesture
/// arena), so vertical drags still scroll the page.
class TickerMarquee extends StatefulWidget {
  const TickerMarquee({super.key, required this.children, this.speed = 40});

  final List<Widget> children;
  final double speed;

  @override
  State<TickerMarquee> createState() => _TickerMarqueeState();
}

class _TickerMarqueeState extends State<TickerMarquee>
    with SingleTickerProviderStateMixin {
  final _copyKey = GlobalKey();

  // Unbounded controller used as a clock: value = elapsed seconds.
  late final AnimationController _clock = AnimationController.unbounded(
    vsync: this,
  );
  double _offset = 0; // px travelled within the current copy
  double _lastT = 0;
  double _copyWidth = 0;

  @override
  void initState() {
    super.initState();
    _clock.addListener(_tick);
    _start();
  }

  void _start() {
    _lastT = _clock.value;
    // Linear "forever" run: 1 unit per second for ~11.5 days, then it simply stops.
    _clock.animateTo(
      _clock.value + 1e6,
      duration: const Duration(seconds: 1000000),
      curve: Curves.linear,
    );
  }

  void _tick() {
    final t = _clock.value;
    final dt = t - _lastT;
    _lastT = t;
    if (_copyWidth <= 0) {
      final box = _copyKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      _copyWidth = box.size.width;
    }
    setState(() => _offset = (_offset + dt * widget.speed) % _copyWidth);
  }

  void _pause() => _clock.stop();
  void _resume() {
    if (!_clock.isAnimating) _start();
  }

  @override
  void didUpdateWidget(TickerMarquee old) {
    super.didUpdateWidget(old);
    _copyWidth = 0; // children may have changed width
  }

  @override
  void dispose() {
    _clock
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget copy({Key? key}) => Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: widget.children,
    );
    return Listener(
      onPointerDown: (_) => _pause(),
      onPointerUp: (_) => _resume(),
      onPointerCancel: (_) => _resume(),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          child: Transform.translate(
            // Starts one copy to the left and slides right; wraps at one copy width.
            offset: Offset(_offset - _copyWidth, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                copy(key: _copyKey),
                copy(),
                copy(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
