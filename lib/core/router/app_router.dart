import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../mock/mock_backend.dart';
import '../l10n/offer_strings.dart';
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
import '../../features/offers/data/mock_offers_repository.dart';
import '../../features/offers/data/offers_providers.dart';
import '../../features/offers/presentation/chosen_screen.dart';
import '../../features/offers/presentation/offer_details_screen.dart';
import '../../features/offers/presentation/offers_screen.dart';
import '../../features/orders/data/mock_orders_repository.dart';
import '../../features/orders/data/orders_providers.dart';
import '../../features/orders/domain/order.dart';
import '../../features/orders/presentation/order_status_screen.dart';
import '../../features/orders/presentation/rating_screen.dart';
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
                  (ref) => MockHomeRepository(
                    ref.watch(mockBackendProvider),
                    withData: true,
                  ).load(governorate: 'بغداد'),
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
          builder: (_, s) {
            // 10c «ارفع السعر» → 08 with the request's details and the
            // suggested price prefilled; saving goes to the live request.
            final edit = s.uri.queryParameters['editPrice'];
            if (edit == null) return _seeded(s, const RequestDetailsScreen());
            final price = int.tryParse(s.uri.queryParameters['price'] ?? '');
            return ProviderScope(
              overrides: [
                draftProvider.overrideWith(
                  () => SeededDraftNotifier(
                    sampleDraft.copyWith(maxPrice: price),
                  ),
                ),
              ],
              child: RequestDetailsScreen(
                editPriceFor: edit,
                currentPrice: price,
              ),
            );
          },
        ),
        GoRoute(
          path: 'review',
          builder: (_, s) => s.uri.queryParameters['preview'] == 'size'
              ? ProviderScope(
                  overrides: [
                    draftProvider.overrideWith(
                      () => SeededDraftNotifier(sampleDraft.copyWith()),
                    ),
                  ],
                  child: const ReviewScreen(
                    initialErrors: {
                      PostError.incomplete,
                      PostError.sizeMissing,
                    },
                  ),
                )
              : s.uri.queryParameters['preview'] == 'errors'
              ? ProviderScope(
                  overrides: [
                    draftProvider.overrideWith(
                      () => SeededDraftNotifier(
                        sampleDraft.copyWith(readyToBuy: false),
                      ),
                    ),
                  ],
                  child: ReviewScreen(
                    initialErrors: {...PostError.values}
                      ..remove(PostError.sizeMissing),
                    initialOffline: true,
                  ),
                )
              : _seeded(s, const ReviewScreen()),
        ),
      ],
    ),
    // 10 · `?preview=cancel` opens 10b; `=widened` is 10c. Countdowns tick from
    // the mock expiry time in every mode.
    GoRoute(
      path: '/requests/:id/live',
      builder: (_, s) {
        final id = s.pathParameters['id']!;
        final p = s.uri.queryParameters['preview'];
        final screen = LiveWaitingScreen(
          requestId: id,
          openCancel: p == 'cancel',
        );
        if (p == 'expired' || p == 'expired_offers') {
          MockLiveRequestRepository repo(Ref ref) => MockLiveRequestRepository(
            ref.watch(mockBackendProvider),
            expired: true,
            expiredOffers: p == 'expired_offers',
          );
          return ProviderScope(
            overrides: [
              liveRepositoryProvider.overrideWith(repo),
              liveRequestProvider.overrideWith(
                (ref, id) => repo(ref).watch(id),
              ),
            ],
            child: screen,
          );
        }
        return p == 'widened'
            ? ProviderScope(
                overrides: [
                  liveRepositoryProvider.overrideWith(
                    (ref) => MockLiveRequestRepository(
                      ref.watch(mockBackendProvider),
                      widened: true,
                    ),
                  ),
                  // Family must be scoped too, or it keeps reading the root repo.
                  liveRequestProvider.overrideWith(
                    (ref, id) => MockLiveRequestRepository(
                      ref.watch(mockBackendProvider),
                      widened: true,
                    ).watch(id),
                  ),
                ],
                child: screen,
              )
            : screen;
      },
    ),
    // 11 · `?preview=confirm` opens 13 for the cheapest offer; 12 under `/:offerId`.
    GoRoute(
      path: '/requests/:id/offers',
      builder: (context, s) {
        _seedChosen(context, s);
        return OffersScreen(
          requestId: s.pathParameters['id']!,
          confirmId: s.uri.queryParameters['preview'] == 'confirm'
              ? 'o1'
              : s.uri.queryParameters['confirm'],
        );
      },
      routes: [
        GoRoute(
          path: ':offerId',
          builder: (_, s) => OfferDetailsScreen(
            requestId: s.pathParameters['id']!,
            offerId: s.pathParameters['offerId']!,
          ),
        ),
      ],
    ),
    // 14 · `?preview=1` = 17:50 after choosing (42:10 left); `=noreply` is 14b.
    GoRoute(
      path: '/requests/:id/chosen',
      builder: (context, s) {
        final id = s.pathParameters['id']!;
        final p = s.uri.queryParameters['preview'];
        if (p == null) return ChosenScreen(requestId: id);
        final none = p == 'nooffers';
        final noReply = p == 'noreply' || none;
        final elapsed = noReply
            ? const Duration(hours: 1, minutes: 2)
            : const Duration(minutes: 17, seconds: 50);
        // Seed the app-wide mock so «ما ردت» → 11 continues on the same data.
        final repo = ProviderScope.containerOf(context)
            .read(offersRepositoryProvider);
        if (repo is MockOffersRepository) {
          repo.seedSelection('o1', elapsed, onlyThis: none);
        }
        return ChosenScreen(
          requestId: id,
          frozenElapsed: elapsed,
          noneLeft: none,
          toast: noReply && !none
              ? OfferStrings.backToOffers('رياضة الكرادة', '39,000')
              : null,
        );
      },
    ),
    // 15 · `?preview=1`; 16 under `/rate` (`?preview=1` = 4 stars filled,
    // `=rated` is 16b).
    GoRoute(
      path: '/orders/:id',
      builder: (_, s) => OrderStatusScreen(orderId: s.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'rate',
          builder: (context, s) {
            final p = s.uri.queryParameters['preview'];
            const sample = Rating(
              stars: 4,
              tags: {'نفس الصورة', 'توصيل سريع'},
              comment: 'الحذاء أصلي ووصل قبل الموعد',
            );
            final repo = ProviderScope.containerOf(context)
                .read(ordersRepositoryProvider);
            if (p != null && repo is MockOrdersRepository) {
              repo.seed(received: true, rating: p == 'rated' ? sample : null);
              // 15 underneath already loaded the order; reload it seeded.
              ProviderScope.containerOf(context)
                  .invalidate(orderProvider(s.pathParameters['id']!));
            }
            return p == '1'
                ? RatingScreen(
                    orderId: s.pathParameters['id']!,
                    initialStars: sample.stars,
                    initialTags: sample.tags,
                    initialComment: sample.comment,
                  )
                : RatingScreen(orderId: s.pathParameters['id']!);
          },
        ),
      ],
    ),
    GoRoute(
      path: Routes.comingSoon,
      builder: (_, _) => const ComingSoonScreen(),
    ),
  ],
);

/// `/offers?preview=chosen`: ستايل بغداد already selected (11 «اخترت…» state).
void _seedChosen(BuildContext context, GoRouterState s) {
  if (s.uri.queryParameters['preview'] != 'chosen') return;
  final repo = ProviderScope.containerOf(context)
      .read(offersRepositoryProvider);
  if (repo is MockOffersRepository) repo.seedSelection('o1', Duration.zero);
}

Widget _seeded(GoRouterState s, Widget child) => _preview(s)
    ? ProviderScope(
        overrides: [
          draftProvider.overrideWith(() => SeededDraftNotifier(sampleDraft)),
        ],
        child: child,
      )
    : child;
