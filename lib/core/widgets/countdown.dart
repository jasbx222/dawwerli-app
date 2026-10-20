import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds every second with the time left until [until] (never negative).
/// Driven by the wall clock, so it stays right after pauses/rebuilds.
class Countdown extends StatefulWidget {
  const Countdown({super.key, required this.until, required this.builder});

  final DateTime until;
  final Widget Function(BuildContext context, Duration left) builder;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.until.difference(DateTime.now());
    return widget.builder(context, left.isNegative ? Duration.zero : left);
  }
}
