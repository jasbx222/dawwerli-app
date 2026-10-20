abstract final class ReportStrings {
  static const title = 'بلّغ عن مشكلة';
  static const what = 'شنو صار؟';
  static const reasons = [
    'ما وصل',
    'مو نفس الصورة',
    'السعر تغيّر بالواتساب',
    'طلبت مني عربون أو تحويل',
    'طلب مني رقم أو حساب',
    'كلام مسيء',
    'غرض ممنوع',
  ];
  static const addPhoto = 'أضف صورة';
  static const evidence =
      'نرفق العرض المقفول وصورته كدليل تلقائياً. البلاغ الكاذب ياخذ إنذار.';
  static const blockToggle = 'حظر هالصفحة، ما تشوف طلباتي بعد';
  static const send = 'دز البلاغ';
  static const sentTitle = 'وصلنا بلاغك';
  static const trackLabel = 'رقم المتابعة';
  static const sentBody =
      'رفقنا العرض المقفول وصورته كدليل. فريقنا يراجعه ويرد عليك خلال 48 ساعة.';
  static const done = 'تمام';
  static String blockTitle(String page) => 'تحظر «$page»؟';
  static const blockBody =
      'ما تشوف طلباتك بعد، ولا توصلك عروضها. تكدر تفك الحظر من «حسابي».';
  static const blockYes = 'احظر';
  static const blockNo = 'لا';
}
