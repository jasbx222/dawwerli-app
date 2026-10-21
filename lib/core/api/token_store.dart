import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh tokens in secure storage, mirrored in memory for sync reads.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
    : _s = storage ?? const FlutterSecureStorage();

  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';
  static const _kDevice = 'auth.device';
  static const _kRole = 'auth.role';

  final FlutterSecureStorage _s;
  String? access;
  String? refresh;
  String? deviceId;

  /// Last side of the app: `seller` or `buyer`. Kept after logout so the
  /// same account comes back on the side it left. A signed-in token wins.
  String? role;
  bool _loaded = false;

  bool get signedIn => refresh != null;

  Future<void> load() async {
    if (_loaded) return;
    try {
      access = await _s.read(key: _kAccess);
      refresh = await _s.read(key: _kRefresh);
      deviceId = await _s.read(key: _kDevice);
      role = await _s.read(key: _kRole);
      role = jwtAppRole(access) ?? role;
    } on Object {
      // Secure storage unavailable (tests/desktop): keep in-memory only.
    }
    _loaded = true;
  }

  Future<void> save(String a, String r) async {
    access = a;
    refresh = r;
    final fromToken = jwtAppRole(a);
    if (fromToken != null) role = fromToken;
    await _write(_kAccess, a);
    await _write(_kRefresh, r);
    if (fromToken != null) await _write(_kRole, fromToken);
  }

  /// Remember «أشتري» / «أبيع» even after the tokens are cleared.
  Future<void> rememberRole(String value) async {
    role = value;
    await _write(_kRole, value);
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

/// Active app side inside an access token, when the claim is unambiguous.
/// `page` / `seller` → seller, `customer` / `buyer` → buyer. Both or neither
/// returns null so a saved choice is left alone.
String? jwtAppRole(String? jwt) {
  if (jwt == null) return null;
  final parts = jwt.split('.');
  if (parts.length < 2) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final json = jsonDecode(payload);
    if (json is! Map) return null;
    for (final entry in json.entries) {
      final key = entry.key.toString().toLowerCase();
      if (key != 'role' && key != 'roles' && !key.endsWith('/claims/role')) {
        continue;
      }
      final names = entry.value is List ? entry.value as List : [entry.value];
      final values = names.map((e) => '$e'.toLowerCase()).toSet();
      final seller = values.contains('page') || values.contains('seller');
      final buyer = values.contains('customer') || values.contains('buyer');
      if (seller && !buyer) return 'seller';
      if (buyer && !seller) return 'buyer';
    }
  } on Object {
    return null;
  }
  return null;
}
