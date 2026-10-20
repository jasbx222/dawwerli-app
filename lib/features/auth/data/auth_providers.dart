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

/// Current user's profile; invalidate after [AuthRepository.saveProfile].
final profileProvider = FutureProvider<UserProfile?>(
  (ref) => ref.watch(authRepositoryProvider).profile(),
);

/// Governorate from the profile (05); used to scope home feed, pages and requests.
final userGovernorateProvider = FutureProvider<String>(
  (ref) async =>
      (await ref.watch(profileProvider.future))?.governorate ?? 'بغداد',
);
