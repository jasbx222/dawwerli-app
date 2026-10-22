abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const loginPhone = '/login/phone';
  static const setPassword = '/login/password';
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
  static String reportSent(String id, String trackNo) =>
      '/orders/$id/report/sent?no=$trackNo';
  static const notifications = '/notifications';
  static const account = '/account';
  static const privacy = '/account/privacy';
  static const deleteAccount = '/account/delete';
  static const standing = '/account/standing';
  static const disputeNew = '/account/dispute';
  static const disputeStatus = '/account/dispute/status';
  static String disputeFor(String orderId) => '$disputeNew?orderId=$orderId';
  static String disputeStatusOf(String id) => '$disputeStatus?id=$id';
  static String recoverOffers(String id) => '/requests/$id/others';
  static const myRequests = '/requests';
  static const offline = '/offline';
  static const maxOpen = '/post-limit';
  static const forceUpdate = '/update';
  static String noOffers(String id) => '/requests/$id/no-offers';
  static String noPages(String id) => '/requests/$id/no-pages';
  static String pageProfile(String id) => '/pages/p/$id';
  static String pageProducts(String id) => '/pages/p/$id/products';
  static String product(String pageId, String id) => '/pages/p/$pageId/products/$id';
  static const cart = '/store/cart';
  static const topProducts = '/store/top-products';
  static const checkout = '/store/checkout';
  static const storeOrders = '/store/orders';
  static String storeOrder(String id) => '/store/orders/$id';
  static const categories = '/categories';
  static String category(String id) => '/categories/$id';
  static const feed = '/feed';
  static const region = '/account/region';
  static const notificationSettings = '/account/notifications';
  static const blocked = '/account/blocked';
  static const terms = '/account/terms';
  static const contact = '/account/contact';
  static const postCategory = '/post/category';

  // Page (seller) app.
  static const roleChoice = '/role';
  static const sellerRegister = '/seller/register';
  static const sellerVerify = '/seller/verify';
  static const sellerRejected = '/seller/verify/rejected';
  static const sellerInbox = '/seller';
  static String sellerSubmit(String requestId) =>
      '/seller/requests/$requestId/offer';
  static const sellerOffers = '/seller/offers';
  static String sellerChosen(String offerId) => '/seller/offers/$offerId';
  static String sellerOfferView(String offerId) => '/seller/offers/$offerId/view';
  static const sellerRating = '/seller/rating';
  static const sellerWallet = '/seller/wallet';
  static const sellerAds = '/seller/ads';
  static const sellerMyAds = '/seller/ads/mine';
  static const sellerAdsEligibility = '/seller/ads/eligibility';
  static String sellerAdBook(String slot) => '/seller/ads/book/$slot';
  static const sellerStanding = '/seller/standing';
  static String sellerAppeal(String markId) =>
      '/seller/standing/appeal/$markId';
  static const sellerSettings = '/seller/settings';
  static const sellerAccount = '/seller/account';
  static const sellerReports = '/seller/reports';
  static const sellerNotifications = '/seller/notifications';
  static const sellerDelete = '/seller/account/delete';
}
