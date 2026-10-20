import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh tokens in secure storage, mirrored in memory for sync reads.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
    : _s = storage ?? const FlutterSecureStorage();

  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';
  static const _kDevice = 'auth.device';

  final FlutterSecureStorage _s;
  String? access;
  String? refresh;
  String? deviceId;
  bool _loaded = false;

  bool get signedIn => refresh != null;

  Future<void> load() async {
    if (_loaded) return;
    try {
      access = await _s.read(key: _kAccess);
      refresh = await _s.read(key: _kRefresh);
      deviceId = await _s.read(key: _kDevice);
    } on Object {
      // Secure storage unavailable (tests/desktop): keep in-memory only.
    }
    _loaded = true;
  }

  Future<void> save(String a, String r) async {
    access = a;
    refresh = r;
    await _write(_kAccess, a);
    await _write(_kRefresh, r);
  }

  Future<String> device(String Function() create) async {
    await load();
    if (deviceId != null) return deviceId!;
    deviceId = create();
    await _write(_kDevice, deviceId!);
    return deviceId!;
  }

  Future<void> clear() async {
    access = null;
    refresh = null;
    try {
      await _s.delete(key: _kAccess);
      await _s.delete(key: _kRefresh);
    } on Object {
      // ignore
    }
  }

  Future<void> _write(String k, String v) async {
    try {
      await _s.write(key: k, value: v);
    } on Object {
      // ignore
    }
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
