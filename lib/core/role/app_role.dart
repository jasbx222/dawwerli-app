import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/token_store.dart';
import '../router/routes.dart';
import '../storage/prefs.dart';

/// «أشتري» (customer app) or «أبيع» (page app); chosen on 02, switchable from settings.
enum AppRole { buyer, seller }

class AppRoleNotifier extends Notifier<AppRole> {
  static const _k = 'app.role';

  @override
  AppRole build() {
    // The signed-in token (or the side remembered after logout) beats a
    // missing preference, which otherwise always opens the buyer app.
    final session = ref.read(tokenStoreProvider).role;
    final saved = ref.watch(sharedPrefsProvider).getString(_k);
    return (session ?? saved) == 'seller' ? AppRole.seller : AppRole.buyer;
  }

  Future<void> set(AppRole r) async {
    state = r;
    await ref.read(sharedPrefsProvider).setString(_k, r.name);
    await ref.read(tokenStoreProvider).rememberRole(r.name);
  }
}

final appRoleProvider = NotifierProvider<AppRoleNotifier, AppRole>(
  AppRoleNotifier.new,
);

extension AppRoleHome on AppRole {
  String get home => this == AppRole.seller ? Routes.sellerHome : Routes.home;
}
