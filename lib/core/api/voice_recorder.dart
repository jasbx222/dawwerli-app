import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records a voice note to an .m4a file (AAC), capped at [maxSeconds].
class VoiceRecorder {
  VoiceRecorder({required this.maxSeconds});
  final int maxSeconds;
  final _rec = AudioRecorder();
  final _ticks = StreamController<int>.broadcast();
  Timer? _timer;
  DateTime? _startedAt;

  /// Elapsed seconds while recording.
  Stream<int> get ticks => _ticks.stream;
  bool get recording => _startedAt != null;

  /// Returns false when the microphone permission is denied.
  Future<bool> start() async {
    if (!await _rec.hasPermission()) return false;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = DateTime.now().difference(_startedAt!).inSeconds;
      _ticks.add(s);
      if (s >= maxSeconds) stop();
    });
    return true;
  }

  /// Stops and returns (file path, seconds), or null if nothing was recorded.
  Future<(String, int)?> stop() async {
    final started = _startedAt;
    _timer?.cancel();
    _startedAt = null;
    final path = await _rec.stop();
    if (started == null || path == null || !File(path).existsSync()) return null;
    final secs = DateTime.now().difference(started).inSeconds;
    return (path, secs.clamp(1, maxSeconds));
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _ticks.close();
    await _rec.dispose();
  }
}
