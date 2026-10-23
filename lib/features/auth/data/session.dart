import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/token_store.dart';
import '../../../core/role/app_role.dart';
import '../../seller/data/seller_controller.dart';
import '../../../core/router/routes.dart';
import '../../guest/guest.dart';
import 'auth_providers.dart';

/// Server role names for [AppRole].
const _serverRole = {AppRole.buyer: 'customer', AppRole.seller: 'page'};

/// Switches buyer ⇄ seller on the server (new tokens) and locally.
/// Returns where the app should open.
Future<String> switchAppRole(WidgetRef ref, AppRole role) async {
  await ref.read(apiAuthRepositoryProvider).switchRole(_serverRole[role]!);
  await ref.read(appRoleProvider.notifier).set(role);
  if (role == AppRole.buyer) return role.home;
  final status = await ref.read(sellerProvider.notifier).refresh();
  return sellerEntryRoute(status);
}

/// Revokes the refresh token and clears the local session.
Future<void> signOut(WidgetRef ref) async {
  await ref.read(apiAuthRepositoryProvider).logout();
  ref.read(sellerProvider.notifier).reset();
}

/// Where to go once tokens are saved (OTP, password login or reset).
/// Sellers without a page land on page sign-up (no `page.required` errors).
Future<String> afterSignIn(WidgetRef ref, {required bool needsProfile}) async {
  ref.read(guestProvider.notifier).set(false);
  final wanted = ref.read(appRoleProvider);
  // Login issues tokens for the role it was given. If that token is the other
  // side, switch so a seller doesn't come back inside the buyer account.
  if (ref.read(tokenStoreProvider).role != wanted.name) {
    try {
      await ref.read(apiAuthRepositoryProvider).switchRole(_serverRole[wanted]!);
    } on ApiException {
      // Open the side they chose anyway; a page-less seller lands on sign-up.
    }
  }
  await ref.read(appRoleProvider.notifier).set(wanted);
  if (wanted == AppRole.seller) {
    ref.read(signInReturnProvider.notifier).set(null);
    return sellerEntryRoute(await ref.read(sellerProvider.notifier).refresh());
  }
  // New accounts finish their profile first; profile setup then takes the
  // return path (see [signInReturnProvider]).
  if (needsProfile) return Routes.profileSetup;
  return ref.read(signInReturnProvider.notifier).take() ?? Routes.home;
}
