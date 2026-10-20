/// Copy for the offers flow (11 → 14b), verbatim from the approved designs.
abstract final class OfferStrings {
  static String offersArrived(int n) => switch (n) {
    1 => 'عرض واحد وصلك',
    2 => 'عرضين وصلوك',
    _ => '$n عروض وصلتك',
  };
  static const hiddenOne = 'خفيت عرض واحد';
  static String hiddenCount(int n) => n == 1 ? hiddenOne : 'خفيت $n عروض';
  static String hiddenChip(int n) => 'المخفية ($n)';
  static String hiddenTag(String page) => '$page · مخفي';
  static String hiddenSub(String price) => '$price د.ع · يبقى محسوب من الـ 5';
  static String hiddenPlaces(String places) =>
      '$places · المخفي ينحسب من الخمسة';
  static String hiddenToast(String page) =>
      'خفينا عرض «$page». تكدر ترجعه لحد ما يتسكر الطلب';
  static const unhide = 'رجّعه';
  static const pricesFixed = 'الأسعار ثابتة وتشمل التوصيل';
  static const sortCheapest = 'الأرخص';
  static const sortTopRated = 'الأعلى تقييم';
  static const sortFastest = 'الأسرع';
  static const sponsored = 'مُموّل';
  static const cheapest = 'الأرخص';
  static const trustedCheck = 'موثوقة ';
  static const trusted = 'موثوقة';
  static String ratingDeals(String r, int d, {bool more = false}) =>
      ' $r · $d صفقة${more ? ' ·' : ''}';
  static String delivers(String d) => 'يوصل $d';
  static const iqd = 'د.ع';
  static String placesLeft(String places, int max) =>
      '$places، العروض تجي لحد $max';
  static const sponsoredNote =
      'العرض المُموّل يبقى بالأول، بس تكدر ترتب بالسعر بضغطة';

  // 12
  static const liveCamera = 'صورة كاميرا حية';
  static String pageVerified(String name) => '$name ';
  static String detailStats(String r, int d, int m) =>
      ' $r · $d صفقة بالتطبيق · يرد بـ $m د';
  static const finalLocked = ' السعر النهائي، مقفول';
  static const delivery = 'التوصيل';
  static String deliveryIncluded(String d) => 'خلال $d · مشمول';
  static const condition = 'الحالة';
  static const pageNote = 'ملاحظة الصفحة';
  static const noPrepay = 'لا تحوّل ولا دينار مقدماً، الدفع بس عند الاستلام';
  static const inspectTip =
      'افحص الغرض قدام المندوب قبل ما تدفع. إذا تغيّر السعر بالواتساب بلّغنا.';
  static const want = 'أريده';

  // 13
  static String confirmTitle(String name) => 'تختار $name؟';
  static String confirmSub(String price, String d) => '$price د.ع · توصيل $d';
  static const pointPhone = 'رقمك ينكشف لهالصفحة بس';
  static const pointWhatsapp =
      'ينفتح الواتساب برسالة جاهزة بالطلب والسعر المقفول';
  static const pointNoReply = 'إذا ما ردت خلال ساعة، تختار العرض الثاني بضغطة';
  static const pointPrivacy =
      'الصفحة ما تشوف اسمك الكامل ولا عنوانك إلا إذا إنت دزيته بالواتساب';
  static const confirmYes = 'إي، أريده';
  static const confirmNo = 'لا، أرجع للعروض';

  // 14 / 14b
  static const foundIt = 'لكيته!';
  static const foundSticker = 'لكيته!';
  static String orderWaiting(String no) => 'الطلب #$no · بانتظار التواصل';
  static String pageSawPhone(String name) => '$name شافت رقمك';
  static const lockedPrice = 'السعر المقفول ';
  static String waMessage(String no, String item, String price) =>
      'هلا، اخترت عرضكم بدوّرلي 👋\nالطلب: #$no · $item\nالسعر المقفول: $price د.ع';
  static const openWhatsapp = 'افتح الواتساب';
  static const noReplyQ = 'ما ردت؟';
  static const noReplyLocked = 'ينفتح الزر بعد ساعة من الاختيار · باقي ';
  static const noReplyOpen =
      'مرت ساعة · تختار العرض الثاني بضغطة، والصفحة ما تنخصم';
  static const noReplyBtn = 'ما ردت، شوفلي غيرها';
  static const priceChanged = 'تغيّر السعر بالواتساب؟';
  static const report = 'بلّغ';
  static String alreadyChose(String name) =>
      'اخترت $name. تكدر تتواصل وياهم من الواتساب';
  static const backToWhatsapp = 'ارجع للواتساب';
  static const noneLeftTitle = 'ما بقت عروض ثانية';
  static const noneLeftBody =
      'تكدر تعيد نشر طلبك أو ترفع السعر حتى توصل لصفحات أكثر';
  static const repost = 'أعد النشر';
  static const raisePrice = 'ارفع السعر';
  static String backToOffers(String name, String price) =>
      'رجعناك للعروض: $name $price د.ع جاهزة';
}
