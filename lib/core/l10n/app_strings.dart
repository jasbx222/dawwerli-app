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
  static const comingSoon = 'هاي الشاشة بالمجموعة الجاية';

  // Home (06 / 06b)
  static String hello(String name) => 'هلا $name 👋';
  static const homeQ1 = 'شتدوّر اليوم؟';
  static String homeQ2(String gov) => 'كول، و$gov تتسابق عليك';
  static String locationLabel(String area, String gov) => '$area، $gov';
  static const live = 'مباشر';
  static String reachedPages(int n, String gov) => 'وصل لـ $n صفحة موثقة ب$gov';
  static String pagesCompeting(int n) => '$n صفحات دا تتعارك عليك 🔥';
  static String slotsLeft(int n) => switch (n) {
        1 => 'باقي مكان واحد',
        2 => 'باقي مكانين',
        _ => 'باقي $n أماكن',
      };
  static const cheapest = 'الأرخص';
  static const goodOffer = 'خوش عرض 👌';
  static const closesIn = 'يتسكر بعد ';
  static const compareOffers = 'قارن العروض';
  static const postNew = 'انشر طلب جديد';
  static const postNewSub = 'صوّر أو اكتب أو احجي، وخلّي العروض تجيك';
  static String offersCount(int n) => switch (n) {
        1 => 'عرض واحد',
        2 => 'عرضين',
        _ => '$n عروض',
      };
  static const statPages = 'صفحة موثقة';
  static const statGovs = 'محافظة';
  static const statFirstOffer = 'أول عرض بالمعدل';
  static String minutesShort(int n) => '$n د';
  static const statsSoon = 'الأرقام تطلع قريباً';
  static const statsSoonSub = 'نعرضها أول ما تصير عدنا بيانات حقيقية كافية';
  static const secTrending = 'شنو الناس تدوّر';
  static const secNow = 'الناس هسه تطلب';
  static const secDeals = 'صفقات تمت اليوم';
  static const secAds = 'عروض اليوم';
  static const secFeatured = 'صفحات مميزة';
  static const seeAll = 'الكل';
  static String trendingIn(String gov) => '🔥 ترند ب$gov';
  static const badgeNew = 'جديد';
  static const save = 'وفّر ';
  static const vsHighest = ' عن أغلى عرض';
  static const sponsored = 'إعلان · مُموّل';
  static const discount = 'خصم';
  static const viewPage = 'شوف الصفحة';
  static const ad = 'إعلان';
  static String dealsCount(int n) => '$n صفقة';

  // Bottom nav
  static const navHome = 'الرئيسية';
  static const navRequests = 'طلباتي';
  static const navNotifications = 'الإشعارات';
  static const navAccount = 'حسابي';

  // Featured pages (45)
  static String featuredTitle(String cat, String gov) => 'أفضل صفحات $cat ب$gov';
  static const featuredSub = 'تقييم 4 وفوق وبدون شكاوى مؤكدة';
  static String inAppDeals(int n) => '$n صفقة بالتطبيق';
  static const featuredFoot = 'الصفحات المعلّمة «إعلان» مدفوعة، الباقي حسب التقييم';
}
