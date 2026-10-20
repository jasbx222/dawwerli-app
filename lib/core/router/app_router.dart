import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/phone_number.dart';
import '../../features/auth/presentation/login_phone_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/otp_states_screen.dart';
import '../../features/home/data/home_providers.dart';
import '../../features/home/data/mock_home_repository.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pages/presentation/featured_pages_screen.dart';
import '../widgets/coming_soon_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'routes.dart';

/// `?preview=1` seeds each screen with the example data shown in the approved design
/// (used for design QA screenshots only; normal navigation never sets it).
bool _preview(GoRouterState s) => s.uri.queryParameters['preview'] == '1';

final appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (_, s) => SplashScreen(autoAdvance: !_preview(s)),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (_, s) => _preview(s)
          ? const LoginPhoneScreen(
              initialPhone: '770 123 4567',
              initialErrors: {PhoneError.incomplete, PhoneError.notIraqi},
            )
          : const LoginPhoneScreen(),
      routes: [
        GoRoute(
          path: 'otp',
          builder: (_, s) => _preview(s)
              ? const OtpScreen(
                  initialCode: '4819',
                  expiresIn: Duration(minutes: 4, seconds: 12),
                  resendIn: Duration(seconds: 42),
                  lockedFor: Duration(minutes: 15),
                  frozenClock: true,
                )
              : const OtpScreen(),
          routes: [
            GoRoute(path: 'states', builder: (_, _) => const OtpStatesScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.profileSetup,
      builder: (_, s) => _preview(s)
          ? const ProfileSetupScreen(
              initialName: 'أبو علي',
              initialArea: 'الكرادة',
            )
          : const ProfileSetupScreen(),
    ),
    GoRoute(
      path: Routes.home,
      builder: (_, s) => _preview(s)
          ? ProviderScope(
              overrides: [
                homeDataProvider.overrideWith(
                  (ref) =>
                      const MockHomeRepository(withData: true)
                          .load(governorate: 'بغداد'),
                ),
              ],
              child: const HomeScreen(),
            )
          : const HomeScreen(),
    ),
    GoRoute(
      path: Routes.featuredPages,
      builder: (_, _) => const FeaturedPagesScreen(),
    ),
    GoRoute(
      path: Routes.comingSoon,
      builder: (_, _) => const ComingSoonScreen(),
    ),
  ],
);
