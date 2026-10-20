abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const otp = '/login/otp';
  static const otpStates = '/login/otp/states';
  static const profileSetup = '/profile/setup';
  static const home = '/home';
  static const featuredPages = '/pages/featured';
  static const post = '/post';
  static const postDetails = '/post/details';
  static const postReview = '/post/review';
  static String liveRequest(String id) => '/requests/$id/live';
  static String offers(String id) => '/requests/$id/offers';
  static String offerDetails(String id, String offerId) =>
      '/requests/$id/offers/$offerId';
  static String chosen(String id) => '/requests/$id/chosen';
  static String orderStatus(String id) => '/orders/$id';
  static String rateOrder(String id) => '/orders/$id/rate';
  static String report(String id, {int reason = 1}) =>
      '/orders/$id/report?reason=$reason';
  static String reportSent(String id) => '/orders/$id/report/sent';
  static const notifications = '/notifications';
  static const account = '/account';
  static const privacy = '/account/privacy';
  static const deleteAccount = '/account/delete';
  static const standing = '/account/standing';
  static const disputeNew = '/account/dispute';
  static const disputeStatus = '/account/dispute/status';
  static String recoverOffers(String id) => '/requests/$id/others';
  static const myRequests = '/requests';
  static const offline = '/offline';
  static const maxOpen = '/post-limit';
  static const forceUpdate = '/update';
  static String noOffers(String id) => '/requests/$id/no-offers';
  static String noPages(String id) => '/requests/$id/no-pages';
  static const comingSoon = '/soon';
}
