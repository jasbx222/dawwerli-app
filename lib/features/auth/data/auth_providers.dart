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

/// Why the phone + OTP screens are open: new account, or «نسيت الرمز».
enum AuthFlow { signUp, reset }

final authFlowProvider = NotifierProvider<AuthFlowNotifier, AuthFlow>(
  AuthFlowNotifier.new,
);

class AuthFlowNotifier extends Notifier<AuthFlow> {
  @override
  AuthFlow build() => AuthFlow.signUp;
  void set(AuthFlow v) => state = v;
}

/// Reset flow only: the code typed on the OTP screen, sent with the new password.
final resetCodeProvider = NotifierProvider<ResetCode, String?>(ResetCode.new);

class ResetCode extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? v) => state = v;
}

/// Sign-up only: `needsProfile` from OTP verify, used after the password is set.
final postSignUpProvider = NotifierProvider<PostSignUp, bool>(PostSignUp.new);

class PostSignUp extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool needsProfile) => state = needsProfile;
}
