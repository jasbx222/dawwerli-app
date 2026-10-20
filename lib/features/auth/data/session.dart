import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/role/app_role.dart';
import '../../seller/data/seller_controller.dart';
import 'auth_providers.dart';

/// Server role names for [AppRole].
const _serverRole = {AppRole.buyer: 'customer', AppRole.seller: 'page'};

/// Switches buyer ⇄ seller on the server (new tokens) and locally.
/// Returns where the app should open.
Future<String> switchAppRole(WidgetRef ref, AppRole role) async {
  await ref.read(apiAuthRepositoryProvider).switchRole(_serverRole[role]!);
  ref.read(appRoleProvider.notifier).set(role);
  if (role == AppRole.buyer) return role.home;
  final status = await ref.read(sellerProvider.notifier).refresh();
  return sellerEntryRoute(status);
}

/// Revokes the refresh token and clears the local session.
Future<void> signOut(WidgetRef ref) async {
  await ref.read(apiAuthRepositoryProvider).logout();
  ref.read(sellerProvider.notifier).reset();
}

