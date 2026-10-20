import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';
import 'mock_auth_repository.dart';

/// Swap for the real API implementation later.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
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
