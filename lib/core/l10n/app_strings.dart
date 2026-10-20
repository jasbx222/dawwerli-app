/// All user-facing Arabic copy (Iraqi dialect), exactly as in the approved designs.
abstract final class AppStrings {
  // Brand
  static const appName = 'دوّرلي';
  static const logoLetter = 'د';
  static const logoDot = '.';
  static const tagline = 'كول شتريد، والصفحات تتسابق عليك';
  static const madeInIraq = 'صُنع بالعراق 🇮🇶';

  // Onboarding
  static const onbOffersArrived = '3 عروض وصلت';
  static const currency = 'د.ع';
  static const onbSticker = 'لكيته! 🎯';
  static const onbTitle1 = 'دز طلبك مرة وحدة';
  static const onbTitle2 = 'والصفحات تجيك بعروضها';
  static const onbBody =
      'صوّر الغرض أو اكتبه أو احجيه. أول 5 صفحات موثقة تنطيك سعر ثابت، وإنت تختار. الدفع عند الاستلام.';
  static const onbStart = 'يلا نبلش';
  static const onbBrowse = 'تصفح بدون حساب';

  // Login (phone)
  static const loginTitle = 'سجّل برقمك';
  static const loginSub = 'حتى ننشر طلبك. مسودتك محفوظة وما تضيع ✍️';
  static const loginPhoneLabel = 'رقم الموبايل';
  static const countryCode = '+964';
  static const loginHint = 'نرسلك كود بالـ SMS. رقمك ما ينكشف لأي صفحة إلا اللي تختارها إنت.';
  static const errIncompleteTitle = 'الرقم ناقص';
  static const errIncompleteBody = 'اكتب رقم عراقي من 10 أرقام يبدي بـ 7';
  static const errNotIraqiTitle = 'هذا مو رقم عراقي';
  static const errNotIraqiBody = 'حالياً نشتغل بس بالأرقام العراقية (+964)';
  static const loginSend = 'دزلي الكود';
  static const termsPrefix = 'بالتسجيل توافق على ';
  static const privacy = 'سياسة الخصوصية';
  static const and = ' و';
  static const terms = 'الشروط';

  // OTP
  static const otpTitle = 'اكتب الكود';
  static const otpSentTo = 'دزيناه على ';
  static const otpExpiresIn = 'الكود ينتهي بعد ';
  static const otpNoSmsTitle = 'ما وصلك الـ SMS؟';
  static const otpNoSmsBody = 'بعد 3 محاولات نرسلك الكود على الواتساب';
  static const otpLockedTitle = 'انقفل الرقم 15 دقيقة';
  static const otpLockedBody = 'بعد 5 أكواد غلط';
  static const otpResendIn = 'أعد الإرسال بعد ';
  static const otpResend = 'دزلي كود جديد';
  static const otpStatesSub = 'حالات الدخول';

  static const stExpiredTitle = 'الكود انتهى';
  static const stExpiredBody = 'مرت 5 دقايق على الكود.';
  static const stWhatsTitle = 'دزيناه على الواتساب';
  static const stWhatsBody = 'الـ SMS ما وصل 3 مرات، شوف رسائل الواتساب.';
  static const stWhatsAction = 'افتح الواتساب';
  static const stWrongTitle = 'الكود غلط';
  static const stWrongBodyPre = 'باقيلك ';
  static const stWrongBodyPost = ' قبل ما ينقفل الرقم.';
  static const stWrongAction = 'امسح واكتب من جديد';
  static const stLockedTitle = 'الرقم مقفول مؤقتاً';
  static const stLockedBodyPre = 'كتبت 5 أكواد غلط. تكدر تجرب بعد ';
  static const stLockedBodyPost = '.';
  static const stLockedAction = 'غيّر الرقم';
  static const stRateTitle = 'هواية طلبات';
  static const stRateBody = 'استنى شوية وجرب مرة ثانية.';

  static String attemptsLeft(int n) => switch (n) {
        1 => 'محاولة وحدة',
        2 => 'محاولتين',
        _ => '$n محاولات',
      };

  // Profile setup
  static const profileTitle = 'كمّل معلوماتك';
  static const profileSub = 'مرة وحدة بس، حتى نوصلك للصفحات اللي توصل لمنطقتك';
  static const profileName = 'شسمك؟';
  static const profileGov = 'محافظتك';
  static const profileArea = 'منطقتك';
  static const profileAreaHint = 'المنطقة ما تنعرض للصفحات، بس المحافظة.';
  static const profileDone = 'خلصنا، يلا 🚀';

  // Placeholder for screens of later groups
  static const comingSoon = 'الرئيسية — بالمجموعة الجاية';
}
