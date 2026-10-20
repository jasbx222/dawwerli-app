import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/phone_number.dart';
import '../../features/auth/presentation/login_phone_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/otp_states_screen.dart';
import '../../features/home/data/home_providers.dart';
import '../../features/home/data/mock_home_repository.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/live/data/live_providers.dart';
import '../../features/live/data/mock_live_repository.dart';
import '../../features/live/presentation/live_waiting_screen.dart';
import '../../features/post/data/post_providers.dart';
import '../../features/post/domain/request_draft.dart';
import '../../features/post/presentation/post_request_screen.dart';
import '../../features/post/presentation/request_details_screen.dart';
import '../../features/post/presentation/review_screen.dart';
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
    // Post-request flow shares one draft across 07 → 08 → 09.
    GoRoute(
      path: Routes.post,
      builder: (_, s) => _seeded(s, const PostRequestScreen()),
      routes: [
        GoRoute(
          path: 'details',
          builder: (_, s) => _seeded(s, const RequestDetailsScreen()),
        ),
        GoRoute(
          path: 'review',
          builder: (_, s) => s.uri.queryParameters['preview'] == 'errors'
              ? ProviderScope(
                  overrides: [
                    draftProvider.overrideWith(
                      () => SeededDraftNotifier(
                        sampleDraft.copyWith(readyToBuy: false),
                      ),
                    ),
                  ],
                  child: const ReviewScreen(
                    initialErrors: {...PostError.values},
                    initialOffline: true,
                  ),
                )
              : _seeded(s, const ReviewScreen()),
        ),
      ],
    ),
    // 10 · `?preview=1` freezes the countdown; `=cancel` opens 10b; `=widened` is 10c.
    GoRoute(
      path: '/requests/:id/live',
      builder: (_, s) {
        final id = s.pathParameters['id']!;
        final p = s.uri.queryParameters['preview'];
        final screen = LiveWaitingScreen(
          requestId: id,
          frozenClock: p != null,
          openCancel: p == 'cancel',
        );
        return p == 'widened'
            ? ProviderScope(
                overrides: [
                  liveRepositoryProvider.overrideWithValue(
                    const MockLiveRequestRepository(widened: true),
                  ),
                  // Family must be scoped too, or it keeps reading the root repo.
                  liveRequestProvider.overrideWith(
                    (ref, id) =>
                        const MockLiveRequestRepository(widened: true)
                            .watch(id),
                  ),
                ],
                child: screen,
              )
            : screen;
      },
    ),
    GoRoute(
      path: Routes.comingSoon,
      builder: (_, _) => const ComingSoonScreen(),
    ),
  ],
);

Widget _seeded(GoRouterState s, Widget child) => _preview(s)
    ? ProviderScope(
        overrides: [
          draftProvider.overrideWith(() => SeededDraftNotifier(sampleDraft)),
        ],
        child: child,
      )
    : child;
