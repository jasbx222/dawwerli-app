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
  static const comingSoon = '/soon';
}
