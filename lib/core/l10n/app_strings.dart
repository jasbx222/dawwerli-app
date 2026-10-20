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
  static const helloGuest = 'هلا بيك 👋 (زائر)';
  static const guestTitle = 'كول شتريد، والصفحات تجيك بعروضها 🔥';
  static const guestSub = 'تكدر تتصفح هسه، والتسجيل بس من تنشر';
  static const guestSheetTitle = 'سجّل حتى تنشر طلبك ✍️';
  static const guestSheetBody =
      'مسودتك محفوظة. نرسلك كود على رقمك، ورقمك ما ينكشف إلا للصفحة اللي تختارها.';
  static const guestSend = 'دزلي الكود';
  static const guestKeepBrowsing = 'أكمل تصفح';
  static const onbBrowse = 'تصفح بدون حساب';

  // Login (phone)
  static const loginTitle = 'سجّل برقمك';
  static const loginSub = 'حتى ننشر طلبك. مسودتك محفوظة وما تضيع ✍️';
  static const loginPhoneLabel = 'رقم الموبايل';
  static const countryCode = '+964';
  static const loginHint =
      'نرسلك كود بالـ SMS. رقمك ما ينكشف لأي صفحة إلا اللي تختارها إنت.';
  static const errIncompleteTitle = 'الرقم ناقص';
  static const errIncompleteBody = 'اكتب رقم عراقي من 10 أرقام يبدي بـ 7';
  static const errNotIraqiTitle = 'هذا مو رقم عراقي';
  static const errNotIraqiBody = 'حالياً نشتغل بس بالأرقام العراقية (+964)';
  static const loginSend = 'دزلي الكود';
  static const termsPrefix = 'بالتسجيل توافق على ';
  static const privacy = 'سياسة الخصوصية';
  static const and = ' و';
  static const terms = 'الشروط';

  // Login (phone + password)
  static const signInTitle = 'سجّل دخولك';
  static const signInSub = 'برقمك والرمز السري';
  static const passwordLabel = 'الرمز السري';
  static const signIn = 'دخول';
  static const forgotPassword = 'نسيت الرمز';
  static const noAccount = 'ما عندك حساب؟ ';
  static const createAccount = 'سوّي حساب';
  static const wrongCredsTitle = 'الرقم أو الرمز غلط';
  static const wrongCredsBody = 'تأكد منهم وجرب مرة ثانية، أو اضغط «نسيت الرمز»';
  static const loginLockedTitle = 'انقفل الدخول مؤقتاً';
  static const loginLockedBody = 'محاولات غلط هواية. جرب بعد ';
  static const minutes = ' دقيقة';
  static const resetTitle = 'نسيت الرمز';
  static const resetSub = 'اكتب رقمك ونرسلك كود حتى تسوي رمز جديد';
  static const setPasswordTitle = 'سوّي رمز سري';
  static const setPasswordSub = 'حتى تدخل بعدين برقمك والرمز بدون كود';
  static const newPasswordTitle = 'رمز سري جديد';
  static const confirmPasswordLabel = 'أعد كتابة الرمز';
  static const passwordHint = 'على الأقل 8 حروف أو أرقام';
  static const passwordShortTitle = 'الرمز قصير';
  static const passwordShortBody = 'لازم يكون 8 حروف أو أرقام على الأقل';
  static const passwordMismatchTitle = 'الرمزين مو نفس الشي';
  static const passwordMismatchBody = 'اكتب نفس الرمز بالخانتين';
  static const codeInvalidTitle = 'الكود غلط أو انتهى';
  static const codeInvalidBody = 'ارجع واطلب كود جديد';
  static const savePassword = 'احفظ الرمز';
  static const genericErrorTitle = 'صار خطأ';
  static const genericErrorBody = 'تأكد من الاتصال وجرب مرة ثانية';

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
  static const profileDone = 'خلصنا، يلا';

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
  static String featuredTitle(String cat, String gov) =>
      'أفضل صفحات $cat ب$gov';
  static const featuredSub = 'تقييم 4 وفوق وبدون شكاوى مؤكدة';
  static String inAppDeals(int n) => '$n صفقة بالتطبيق';
  static const featuredFoot =
      'الصفحات المعلّمة «إعلان» مدفوعة، الباقي حسب التقييم';

  // Post request (07)
  static const postTitle = 'شتدوّر؟';
  static const postSub = 'صوّر أو اكتب أو احجي، اللي يريحك';
  static const modePhoto = 'صورة';
  static const modeText = 'نص';
  static const modeVoice = 'صوت';
  static const changePhoto = 'بدّل الصورة';
  static const addPhoto = 'ضيف صورة';
  static const shortDesc = 'وصف قصير';
  static String voiceProgress(String a, String b) => '$a / $b';
  static const voiceNote = 'الصوت يوصل للصفحات كتسجيل بس، أقصاه دقيقة';
  static const voiceWarn = '⚠️ لا تذكر رقمك أو حسابك بالتسجيل';
  static const suggestedCat = 'الصنف (اقترحناه إلك) ';
  static const changeCat = 'غيّر';
  static const next = 'التالي';

  // Details (08)
  static const detailsTitle = 'التفاصيل';
  static const sizeLabel = 'القياس *';
  static const colorLabel = 'اللون *';
  static const conditionLabel = 'الحالة';
  static const condNew = 'جديد';
  static const condUsed = 'مستعمل';
  static const condAny = 'ما يفرق';
  static const maxPriceLabel = 'أعلى سعر تدفعه (يشمل التوصيل)';
  static const govLabel = 'المحافظة';
  static String fromAccount(String gov) => '$gov (من حسابك)';
  static const removedPhoneTitle = 'شلنا رقم التلفون من الوصف';
  static const removedPhoneBody =
      'الأرقام والروابط و@الحسابات ممنوعة، الصفحة تتواصل وياك بعد ما تختارها.';
  static const reviewRequest = 'راجع الطلب';

  // Review (09 / 09b)
  static const reviewTitle = 'راجع طلبك';
  static const draftSaved = 'مسودة محفوظة';
  static const reviewErrorsSub = 'حالات الرفض';
  static String voiceLen(String t) => '🎙️ تسجيل $t';
  static const maxPrice = 'أعلى سعر';
  static const ready48 = 'جاهز أشتري خلال 48 ساعة';
  static const ready48Body =
      'ضروري حتى تثق بيك الصفحات. اللي يختار ويختفي ياخذ إنذار.';
  static const ready48Tick = 'أشّر حتى ينفتح زر «انشر»';
  static String privacyNote(String cat, String gov) =>
      'رقمك مخفي. يوصل الطلب بس للصفحات الموثقة اللي تبيع $cat وتوصل ل$gov.';
  static const openPrefix = 'عندك ';
  static String openOf(int n, int max) => '$n من $max';
  static const openSuffix = ' طلبات مفتوحة';
  static const publish = 'انشر';
  static const offlineDraftNote =
      'انقطع النت؟ نخليه بالمسودة وينرسل وحده لما يرجع';
  static const offlineToast = 'النت فاصل، طلبك انحفظ مسودة وينرسل وحده';
  static const errIncomplete = 'الطلب ناقص';
  static const errSize = 'القياس ناقص';
  static const errSizeBody = 'الأحذية والملابس تحتاج قياس. ارجع واختار القياس.';
  static const cancelledBar = 'انلغى طلبك. الصفحات تبلّغت';
  static const expiredPill = 'انتهى';
  static const expiredTitle = 'انتهى وقت طلبك';
  static const expiredBody =
      'ما وصلت عروض خلال 24 ساعة. تكدر تعيد نشره أو ترفع السعر.';
  static const republish = 'أعد النشر';
  static String expiredOffersBody(int n) =>
      'وصلك $n عروض. اختار واحد منها أو ارفع السعر حتى توصل لصفحات أكثر.';
  static const raiseSubtitle = 'فوق سعرك يوصل طلبك لصفحات أكثر';
  static const currentPrice = 'سعرك الحالي ';
  static const updatePrice = 'حدّث السعر';
  static const errIncompleteBody2 =
      'ضيف صورة، أو اكتب وصف أوضح (10 كلمات على الأقل).';
  static const errProhibited = 'هذا الغرض ممنوع 🚫';
  static const errProhibitedBody =
      'ما نكدر ننشر طلبات سلاح أو أدوية أو مواد ممنوعة.';
  static const errContact = 'شيل الرقم أو الرابط';
  static const errContactBody =
      'لا تكتب تلفون أو رابط أو @حساب بالوصف، حتى لو بأرقام عربية أو مفرّقة.';
  static const errMaxOpen = 'عندك 3 طلبات مفتوحة';
  static const errMaxOpenBody = 'سكّر واحد أو اختار عرض حتى تنشر الرابع.';
  static const errVoice = 'التسجيل وكف عند دقيقة 🎙️';
  static const errVoiceBody = 'أقصى طول للصوت 60 ثانية.';
  static const errPrice = 'السعر لازم يكون أكثر من صفر';
  static const errPriceBody = 'اكتب أعلى سعر تدفعه بالدينار.';

  // Live waiting (10 / 10b / 10c)
  static const liveTitle = 'طلبك مباشر';
  static String priceCap(String p) => 'حد السعر $p د.ع';
  static const statReached = 'صفحة وصلها';
  static const statSeen = 'شافوه';
  static const statOffers = 'عروض';
  static String pagesFighting(int n) => '$n صفحات دا تتعارك عليك 🔥';
  static const noOffersYet = 'بعد ما وصلت عروض';
  static String placesLeft(int n) => switch (n) {
    1 => 'باقي مكان واحد',
    2 => 'باقي مكانين',
    _ => 'باقي $n أماكن',
  };
  static String placesEmpty(int n) => '$n أماكن فاضية';
  static const widensIn = ' يتوسع للمحافظات المجاورة بعد';
  static String compareN(int n) => 'قارن العروض ($n)';
  static const cancelIt = 'ألغيه';
  static const cancelTitle = 'تلغي الطلب؟';
  static const cancelBody =
      'الصفحات اللي دزت عروض تتبلغ، ولا أحد ينخصم منه شي.';
  static const cancelYes = 'إي، ألغيه';
  static const cancelNo = 'لا، خليه';
  static const widenedTitle = 'وسّعنا طلبك للمحافظات المجاورة 📍';
  static String widenedBody(int min, String govs) =>
      'مرت $min دقيقة بدون عروض، فوصلنا طلبك ل$govs.';
  static String raiseTip(String p) =>
      '💡 إذا ترفع حد السعر لـ $p د.ع، تزيد فرصتك';
  static const raisePrice = 'ارفع السعر';
  static const keepAsIs = 'خليه مثل ما هو';
}
