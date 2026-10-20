/// Copy for delivery status + rating (15, 16, 16b), verbatim from the designs.
abstract final class OrderStrings {
  static const statusTitle = 'وين وصل طلبك؟';
  static String statusSub(String no, String page) => '#$no · $page';
  static const arrivedQ = 'وصلك؟';
  static const inspect = 'افحص الغرض قدام المندوب قبل ما تدفع';
  static const yesReceived = 'إي، استلمت';
  static const notArrived = 'ما وصل';
  static const mismatch = 'مو نفس الصورة';
  static const askAgain = 'إذا ما جاوبت، نسألك بعد 3 أيام، ويتسكر بعد 7';

  static String rateTitle(String page) => 'قيّم $page';
  static const rateSub = 'تقييمك يساعد غيرك يختار صح';
  static const starLabels = [
    'ما عجبني',
    'مو زين',
    'عادي',
    'خوش صفحة',
    'ممتازة',
  ];
  static const pickStars = 'اختار عدد النجوم';
  static const disliked = 'شنو ما عجبك؟';
  static const sendFailed = 'ما انرسل، تأكد من النت وجرّب مرة ثانية';
  static const receivedTitle = 'وصلك الطلب';
  static const rateNow = 'قيّم هسه';
  static const reportedTitle = 'بلّغت عن مشكلة';
  static const reportedBody = 'راح نتابعها ويا الصفحة وانرد عليك خلال 24 ساعة';
  static const viewReport = 'شوف البلاغ';
  static const liked = 'شنو عجبك؟';
  static const comment = 'تعليق (اختياري)';
  static const oneRating = 'تقييم واحد لكل طلب، وبس بعد ما تأكد الاستلام.';
  static const send = 'دز التقييم';
  static const rated = 'قيّمت';
  static const ratedBefore = 'قيّمت هالطلب قبل';
  static const oneOnly = 'تقييم واحد بس لكل طلب';
}
