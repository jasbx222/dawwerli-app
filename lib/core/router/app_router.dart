import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/presentation/login_phone_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/password_login_screen.dart';
import '../../features/auth/presentation/set_password_screen.dart';
import '../../features/auth/presentation/otp_states_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/live/presentation/live_waiting_screen.dart';
import '../../features/post/data/post_providers.dart';
import '../../features/post/presentation/post_request_screen.dart';
import '../../features/post/presentation/request_details_screen.dart';
import '../../features/post/presentation/review_screen.dart';
import '../../features/pages/presentation/featured_pages_screen.dart';
import '../../features/more/more_screens.dart';
import '../../features/seller/domain/seller_models.dart';
import '../../features/seller/presentation/ads_screens.dart';
import '../../features/seller/presentation/inbox_screen.dart';
import '../../features/seller/presentation/my_offers_screens.dart';
import '../../features/seller/presentation/page_account_screens.dart';
import '../../features/seller/presentation/reports_screen.dart';
import '../../features/seller/presentation/register_screens.dart';
import '../../features/seller/presentation/submit_offer_screen.dart';
import '../../features/seller/presentation/wallet_screen.dart';
import '../../features/offers/presentation/chosen_screen.dart';
import '../../features/offers/presentation/offer_details_screen.dart';
import '../../features/offers/presentation/offers_screen.dart';
import '../../features/offers/presentation/recover_offers_screen.dart';
import '../../features/orders/presentation/order_status_screen.dart';
import '../../features/orders/presentation/rating_screen.dart';
import '../../features/orders/presentation/my_requests_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/states/state_screens.dart';
import '../../features/account/presentation/account_screens.dart';
import '../../features/account/presentation/standing_screens.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/store/presentation/store_screens.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: Routes.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (_, _) => const PasswordLoginScreen(),
      routes: [
        GoRoute(path: 'phone', builder: (_, _) => const LoginPhoneScreen()),
        GoRoute(path: 'password', builder: (_, _) => const SetPasswordScreen()),
        GoRoute(
          path: 'otp',
          redirect: (context, s) =>
              s.uri.path == Routes.otp &&
                  ProviderScope.containerOf(context)
                          .read(pendingPhoneProvider) ==
                      null
              ? Routes.loginPhone
              : null,
          builder: (_, _) => const OtpScreen(),
          routes: [
            GoRoute(path: 'states', builder: (_, _) => const OtpStatesScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.profileSetup,
      builder: (_, _) => const ProfileSetupScreen(),
    ),
    GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: Routes.featuredPages,
      builder: (_, _) => const FeaturedPagesScreen(),
    ),
    // Post-request flow shares one draft across 07 → 08 → 09.
    GoRoute(
      path: Routes.post,
      builder: (_, _) => const PostRequestScreen(),
      routes: [
        GoRoute(
          path: 'details',
          builder: (context, s) {
            // 10c «ارفع السعر» → 08 with the suggested price prefilled;
            // saving goes to the live request.
            final edit = s.uri.queryParameters['editPrice'];
            if (edit == null) return const RequestDetailsScreen();
            final price = int.tryParse(s.uri.queryParameters['price'] ?? '');
            return ProviderScope(
              overrides: [
                draftProvider.overrideWith(
                  () => SeededDraftNotifier(
                    ProviderScope.containerOf(context)
                        .read(draftProvider)
                        .copyWith(maxPrice: price),
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
        GoRoute(path: 'review', builder: (_, _) => const ReviewScreen()),
      ],
    ),
    // 10 · live request (polls the API).
    GoRoute(
      path: '/requests/:id/live',
      builder: (_, s) => LiveWaitingScreen(requestId: s.pathParameters['id']!),
    ),
    // 11 · offers board; 12 under `/:offerId`; `?confirm=` opens 13.
    GoRoute(
      path: '/requests/:id/offers',
      builder: (_, s) => OffersScreen(
        requestId: s.pathParameters['id']!,
        confirmId: s.uri.queryParameters['confirm'],
      ),
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
    // 14 · chosen offer, waiting for the page to call.
    GoRoute(
      path: '/requests/:id/chosen',
      builder: (_, s) => ChosenScreen(requestId: s.pathParameters['id']!),
    ),
    // 15 · order status; 16 under `/rate`; 27 under `/report`.
    GoRoute(
      path: '/orders/:id',
      builder: (_, s) => OrderStatusScreen(orderId: s.pathParameters['id']!),
      routes: [
        // 27 · `?reason=` preselects (0-based).
        GoRoute(
          path: 'report',
          builder: (_, s) => ReportScreen(
            orderId: s.pathParameters['id']!,
            initialReason:
                int.tryParse(s.uri.queryParameters['reason'] ?? '') ?? 1,
          ),
          routes: [
            GoRoute(
              path: 'sent',
              builder: (_, s) => ReportSentScreen(
                orderId: s.pathParameters['id']!,
                trackNo: s.uri.queryParameters['no'] ?? '',
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'rate',
          builder: (_, s) => RatingScreen(orderId: s.pathParameters['id']!),
        ),
      ],
    ),
    // 28 · «حسابي» tab; 29 privacy; 30 delete.
    GoRoute(
      path: Routes.account,
      builder: (_, _) => const AccountScreen(),
      routes: [
        GoRoute(path: 'privacy', builder: (_, _) => const PrivacyScreen()),
        // 46 · strikes / ban state.
        GoRoute(path: 'standing', builder: (_, _) => const StandingScreen()),
        // 49 new dispute; 50 its status.
        GoRoute(
          path: 'dispute',
          builder: (_, s) =>
              DisputeNewScreen(orderId: s.uri.queryParameters['orderId']),
          routes: [
            GoRoute(
              path: 'status',
              builder: (_, s) =>
                  DisputeStatusScreen(id: s.uri.queryParameters['id']),
            ),
          ],
        ),
        GoRoute(path: 'delete', builder: (_, _) => const DeleteAccountScreen()),
        GoRoute(path: 'region', builder: (_, _) => const RegionScreen()),
        GoRoute(
          path: 'notifications',
          builder: (_, _) => const NotificationSettingsScreen(),
        ),
        GoRoute(path: 'blocked', builder: (_, _) => const BlockedPagesScreen()),
        GoRoute(path: 'terms', builder: (_, _) => const TermsScreen()),
        GoRoute(path: 'contact', builder: (_, _) => const ContactScreen()),
      ],
    ),
    // 31, 35–38 full-screen states (34 is the offers error state).
    GoRoute(path: Routes.offline, builder: (_, _) => const OfflineScreen()),
    GoRoute(path: Routes.maxOpen, builder: (_, _) => const MaxOpenScreen()),
    GoRoute(
      path: Routes.forceUpdate,
      builder: (_, _) => const ForceUpdateScreen(),
    ),
    GoRoute(
      path: '/requests/:id/no-offers',
      builder: (_, s) => NoOffersScreen(requestId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/requests/:id/no-pages',
      builder: (_, s) => NoPagesScreen(requestId: s.pathParameters['id']!),
    ),
    // 47b · other offers kept 48h after choosing.
    GoRoute(
      path: '/requests/:id/others',
      builder: (_, s) =>
          RecoverOffersScreen(requestId: s.pathParameters['id']!),
    ),
    // 26 · «الإشعارات» tab.
    GoRoute(
      path: Routes.notifications,
      builder: (_, _) => const NotificationsScreen(),
    ),
    // 25 · «طلباتي» tab.
    GoRoute(
      path: Routes.myRequests,
      builder: (_, _) => const MyRequestsScreen(),
    ),
    GoRoute(
      path: '/pages/p/:id',
      builder: (_, s) => PageProfileScreen(pageId: s.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'products',
          builder: (_, s) => PageProductsScreen(pageId: s.pathParameters['id']!),
          routes: [
            GoRoute(
              path: ':productId',
              builder: (_, s) => ProductDetailsScreen(pageId: s.pathParameters['id']!, productId: s.pathParameters['productId']!),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: Routes.cart, builder: (_, _) => const CartScreen()),
    GoRoute(path: Routes.topProducts, builder: (_, _) => const TopProductsScreen()),
    GoRoute(path: Routes.checkout, builder: (_, _) => const CheckoutScreen()),
    GoRoute(path: Routes.storeOrders, builder: (_, _) => const StoreOrdersScreen()),
    GoRoute(path: '/store/orders/:id', builder: (_, s) => StoreOrderScreen(id: s.pathParameters['id']!)),
    GoRoute(
      path: Routes.categories,
      builder: (_, _) => const CategoriesScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, s) =>
              CategoryScreen(categoryId: s.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: Routes.sellerRegister,
      builder: (_, _) => const SellerRegisterScreen(),
    ),
    GoRoute(
      path: Routes.sellerVerify,
      builder: (_, _) => const SellerVerifyScreen(),
    ),
    GoRoute(
      path: Routes.sellerRejected,
      builder: (_, _) => const SellerRejectedScreen(),
    ),
    GoRoute(
      path: Routes.sellerInbox,
      builder: (_, _) => const SellerInboxScreen(),
    ),
    GoRoute(
      path: '/seller/requests/:id/offer',
      builder: (_, s) => SubmitOfferScreen(requestId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.sellerOffers,
      builder: (_, _) => const SellerOffersScreen(),
    ),
    GoRoute(
      path: '/seller/offers/:id',
      builder: (_, s) => SellerChosenScreen(offerId: s.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'view',
          builder: (_, s) => SellerOfferDetailsScreen(offerId: s.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: Routes.sellerRating,
      builder: (_, _) => const SellerRatingScreen(),
    ),
    GoRoute(
      path: Routes.sellerWallet,
      builder: (_, _) => const SellerWalletScreen(),
    ),
    GoRoute(path: Routes.sellerAds, builder: (_, _) => const SellerAdsScreen()),
    GoRoute(
      path: Routes.sellerMyAds,
      builder: (_, _) => const SellerMyAdsScreen(),
    ),
    GoRoute(
      path: Routes.sellerAdsEligibility,
      builder: (_, _) => const AdsEligibilityScreen(),
    ),
    GoRoute(
      path: '/seller/ads/book/:slot',
      builder: (_, s) =>
          AdBookScreen(slot: AdSlot.values.byName(s.pathParameters['slot']!)),
    ),
    GoRoute(
      path: Routes.sellerStanding,
      builder: (_, _) => const SellerStandingScreen(),
    ),
    GoRoute(
      path: '/seller/standing/appeal/:id',
      builder: (_, s) => SellerAppealScreen(markId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.sellerSettings,
      builder: (_, _) => const SellerSettingsScreen(),
    ),
    GoRoute(
      path: Routes.sellerAccount,
      builder: (_, _) => const SellerAccountScreen(),
    ),
    GoRoute(
      path: Routes.sellerReports,
      builder: (_, _) => const SellerReportsScreen(),
    ),
    GoRoute(
      path: Routes.sellerNotifications,
      builder: (_, _) => const SellerNotificationsScreen(),
    ),
    GoRoute(
      path: Routes.sellerDelete,
      builder: (_, _) => const SellerDeleteScreen(),
    ),
    GoRoute(path: Routes.feed, builder: (_, _) => const FeedScreen()),
    GoRoute(
      path: Routes.postCategory,
      builder: (_, _) => const CategoryPickerScreen(),
    ),
  ],
);
