import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/routes.dart';
import '../storage/prefs.dart';

/// «أشتري» (customer app) or «أبيع» (page app); chosen on 02, switchable from settings.
enum AppRole { buyer, seller }

class AppRoleNotifier extends Notifier<AppRole> {
  static const _k = 'app.role';

  @override
  AppRole build() => ref.watch(sharedPrefsProvider).getString(_k) == 'seller'
      ? AppRole.seller
      : AppRole.buyer;

  void set(AppRole r) {
    ref.read(sharedPrefsProvider).setString(_k, r.name);
    state = r;
  }
}

final appRoleProvider = NotifierProvider<AppRoleNotifier, AppRole>(
  AppRoleNotifier.new,
);

extension AppRoleHome on AppRole {
  String get home => this == AppRole.seller ? Routes.sellerInbox : Routes.home;
}
