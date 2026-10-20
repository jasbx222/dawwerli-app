import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/catalog.dart';
import '../../../core/api/token_store.dart';
import '../../../core/role/app_role.dart';
import 'api_auth_repository.dart';

/// Swap for the real API implementation later.
final apiAuthRepositoryProvider = Provider<ApiAuthRepository>(
  (ref) => ApiAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
    () => ref.read(catalogProvider.future),
    () => ref.read(appRoleProvider) == AppRole.seller ? 'page' : 'customer',
    (code) => ref.read(devOtpCodeProvider.notifier).set(code),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(apiAuthRepositoryProvider),
);

/// Phone being verified in the current sign-in flow.
final pendingPhoneProvider = NotifierProvider<PendingPhone, PhoneNumber?>(
  PendingPhone.new,
);

class PendingPhone extends Notifier<PhoneNumber?> {
  @override
  PhoneNumber? build() => null;
  void set(PhoneNumber phone) => state = phone;
}

final governoratesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(authRepositoryProvider).governorates(),
);
