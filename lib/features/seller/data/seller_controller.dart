import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../../../core/storage/prefs.dart';
import '../domain/seller_models.dart';

const _img = 'assets/images/mock';

/// Why an offer can't be sent (19b / 20b / 22b states).
enum OfferError {
  closed,
  alreadyOffered,
  earlySlotsFull,
  priceAboveMax,
  contactInNote,
  noPhoto,
  noBalance,
}

enum TopupError { duplicateRef, missingRef, missingReceipt }

/// Banned contact patterns in offer notes / ad text: phones (Arabic or Latin
/// digits, spaced), links and @handles (§3.4).
final _contact = RegExp(
  r'(@\w+)|(https?://|www\.|\.com|\.iq)|([0-9٠-٩][\s\-]*){7,}',
  caseSensitive: false,
);
bool hasContact(String text) => _contact.hasMatch(text);

class SellerState {
  const SellerState({
    required this.config,
    required this.status,
    required this.shopName,
    required this.handle,
    required this.phone,
    required this.verifyCode,
    required this.inbox,
    required this.offers,
    required this.balance,
    required this.freeUsed,
    required this.ledger,
    required this.topups,
    required this.ads,
    required this.earlyAccess,
    required this.marks,
    required this.appealed,
    required this.settings,
    required this.rating,
    required this.deals,
    required this.openReport,
    required this.lastRating,
    required this.notices,
    this.suspendedUntil,
    this.rejectReason,
  });
  final SellerConfig config;
  final VerifyStatus status;
  final String shopName;
  final String handle;
  final String phone;
  final String verifyCode;
  final List<SellerRequest> inbox;
  final List<SellerOffer> offers;
  final int balance;
  final int freeUsed;
  final List<LedgerEntry> ledger;
  final List<Topup> topups;
  final List<AdCampaign> ads;
  final bool earlyAccess;
  final List<PageMark> marks;
  final Set<String> appealed;
  final PageSettings settings;
  final double rating;
  final int deals;
  final bool openReport;
  final ReceivedRating lastRating;
  final List<SellerNotice> notices;
  final DateTime? suspendedUntil;
  final String? rejectReason;

  bool get freeLeft => freeUsed < config.freeSelections;
  bool get suspended =>
      suspendedUntil != null && DateTime.now().isBefore(suspendedUntil!);
  bool get trusted => deals >= 100;

  /// Ads only for verified pages, rating ≥ min, no open report, not suspended (§13).
  bool get canAdvertise =>
      status == VerifyStatus.verified &&
      rating >= config.minAdRating &&
      !openReport &&
      !suspended;

  SellerState copyWith({
    VerifyStatus? status,
    String? shopName,
    String? handle,
    String? phone,
    List<SellerRequest>? inbox,
    List<SellerOffer>? offers,
    int? balance,
    int? freeUsed,
    List<LedgerEntry>? ledger,
    List<Topup>? topups,
    List<AdCampaign>? ads,
    bool? earlyAccess,
    Set<String>? appealed,
    PageSettings? settings,
    String? rejectReason,
  }) => SellerState(
    config: config,
    status: status ?? this.status,
    shopName: shopName ?? this.shopName,
    handle: handle ?? this.handle,
    phone: phone ?? this.phone,
    verifyCode: verifyCode,
    inbox: inbox ?? this.inbox,
    offers: offers ?? this.offers,
    balance: balance ?? this.balance,
    freeUsed: freeUsed ?? this.freeUsed,
    ledger: ledger ?? this.ledger,
    topups: topups ?? this.topups,
    ads: ads ?? this.ads,
    earlyAccess: earlyAccess ?? this.earlyAccess,
    marks: marks,
    appealed: appealed ?? this.appealed,
    settings: settings ?? this.settings,
    rating: rating,
    deals: deals,
    openReport: openReport,
    lastRating: lastRating,
    notices: notices,
    suspendedUntil: suspendedUntil,
    rejectReason: rejectReason ?? this.rejectReason,
  );
}

/// Mock page backend (replace with the API client: /pages/me, /inbox, /offers, wallet, ads).
class SellerController extends Notifier<SellerState> {
  static const _kStatus = 'seller.status';

  @override
  SellerState build() {
    final now = DateTime.now();
    final saved = ref.watch(sharedPrefsProvider).getString(_kStatus);
    return SellerState(
      config: const SellerConfig(),
      status: VerifyStatus.values.firstWhere(
        (v) => v.name == saved,
        orElse: () => VerifyStatus.none,
      ),
      shopName: 'ستايل بغداد',
      handle: '@style.baghdad',
      phone: '+964 780 555 0101',
      verifyCode: 'DWR-7K42',
      inbox: [
        SellerRequest(
          id: 'r101',
          title: 'حذاء رياضي أسود · 43',
          image: '$_img/cat_shoes_1.webp',
          governorate: 'بغداد',
          condition: 'جديد',
          maxPrice: 45000,
          postedAt: now.subtract(const Duration(minutes: 1)),
          offers: 3,
          earlyUntil: now.add(const Duration(seconds: 72)),
          earlyTaken: 1,
        ),
        SellerRequest(
          id: 'r102',
          title: 'قمصلة شتوية رجالي XL',
          image: '$_img/cat_clothes_1.webp',
          governorate: 'بابل',
          condition: 'ما يفرق',
          maxPrice: 60000,
          postedAt: now.subtract(const Duration(minutes: 4)),
          offers: 1,
        ),
        SellerRequest(
          id: 'r104',
          title: 'جزمة رياضية أطفال 30',
          image: '$_img/cat_shoes_2.webp',
          governorate: 'بغداد',
          condition: 'جديد',
          maxPrice: 25000,
          postedAt: now.subtract(const Duration(seconds: 40)),
          offers: 2,
          earlyUntil: now.add(const Duration(seconds: 80)),
          earlyTaken: 2,
        ),
        SellerRequest(
          id: 'r103',
          title: 'بوت جلد نسائي 38',
          image: '$_img/cat_shoes_2.webp',
          governorate: 'بغداد',
          condition: 'جديد',
          maxPrice: 50000,
          postedAt: now.subtract(const Duration(minutes: 30)),
          offers: 5,
        ),
      ],
      offers: [
        SellerOffer(
          id: 'o201',
          requestId: 'r90',
          title: 'حذاء رياضي',
          image: '$_img/cat_shoes_1.webp',
          price: 35000,
          state: OfferState.chosen,
          orderNo: 'DW-20481',
          chosenAt: now.subtract(const Duration(minutes: 8)),
          selectionNo: 11,
          customerPhone: '9647701234567',
        ),
        SellerOffer(
          id: 'o202',
          requestId: 'r91',
          title: 'قمصلة جلد',
          image: '$_img/cat_clothes_2.webp',
          price: 55000,
          state: OfferState.chosen,
          orderNo: 'DW-20410',
          chosenAt: now.subtract(const Duration(hours: 26)),
          contacted: true,
          selectionNo: 10,
          customerPhone: '9647809876543',
        ),
        const SellerOffer(
          id: 'o203',
          requestId: 'r92',
          title: 'ساعة كاسيو',
          image: '$_img/cat_watches_1.webp',
          price: 30000,
          state: OfferState.waiting,
        ),
        const SellerOffer(
          id: 'o204',
          requestId: 'r93',
          title: 'بوت جلد',
          image: '$_img/cat_shoes_2.webp',
          price: 48000,
          state: OfferState.notChosen,
        ),
        const SellerOffer(
          id: 'o205',
          requestId: 'r94',
          title: 'عطر عود',
          image: '$_img/cat_perfumes_1.webp',
          price: 40000,
          state: OfferState.closed,
        ),
      ],
      balance: 24000,
      freeUsed: 10,
      ledger: const [
        LedgerEntry(
          'الاختيار 11 · ساعة كاسيو',
          'مدفوع · خلصت المجانية',
          -1000,
          LedgerKind.debit,
        ),
        LedgerEntry(
          'اختيار رقم 10 · حذاء رياضي',
          'مجاني (10 من 10)',
          0,
          LedgerKind.free,
        ),
        LedgerEntry('حجز · قمصلة جلد', 'محجوز', -1000, LedgerKind.held),
        LedgerEntry('تعبئة رصيد · زين كاش', 'مؤكدة', 25000, LedgerKind.credit),
        LedgerEntry(
          'إعلان بانر · يوم',
          'الرئيسية · بغداد',
          -5000,
          LedgerKind.debit,
        ),
      ],
      topups: [
        Topup(
          'ZC-88412093',
          'ZainCash',
          25000,
          now.subtract(const Duration(hours: 1)),
          TopupStatus.pending,
        ),
      ],
      ads: const [
        AdCampaign(
          id: 'a1',
          slot: AdSlot.homeBanner,
          title: 'بانر «كل الأحذية خصم 20%»',
          place: 'من 20/10 لحد 26/10 · بغداد',
          image: '$_img/cat_shoes_2.webp',
          status: AdStatus.pending,
          note: 'المبلغ محجوز، ويرجع إذا انرفض',
        ),
        AdCampaign(
          id: 'a2',
          slot: AdSlot.homeBanner,
          title: 'بانر «ساعات أصلية»',
          place: 'الرئيسية · البصرة',
          image: '$_img/cat_watches_2.webp',
          status: AdStatus.rejected,
          note: 'السبب: بالصورة رقم تلفون. شيله ودزه مرة ثانية. رجعنالك 5,000 د.ع',
        ),
        AdCampaign(
          id: 'a3',
          slot: AdSlot.featuredPage,
          title: 'صفحة مميزة · ملابس',
          place: 'بغداد · بالأسبوع',
          image: '$_img/cat_clothes_1.webp',
          status: AdStatus.pausedBalance,
          note: 'توقف إعلانك، الرصيد خلص. عبّي حتى يرجع يشتغل',
        ),
        AdCampaign(
          id: 'a4',
          slot: AdSlot.homeBanner,
          title: 'بانر «عطور العيد»',
          place: 'الرئيسية · بغداد',
          image: '$_img/cat_perfumes_1.webp',
          status: AdStatus.pausedSuspended,
          note: 'توقف إعلانك لأن الصفحة موقوفة. رجعنالك فلوس الأيام الباقية (3 أيام · 15,000 د.ع)',
        ),
        AdCampaign(
          id: 'a5',
          slot: AdSlot.sponsoredOffer,
          title: 'عرض مُموّل',
          place: 'أحذية · بغداد',
          image: '$_img/cat_shoes_1.webp',
          status: AdStatus.active,
          note: 'ينثبت أول بطلب واحد بس، ويبين عليه «مُموّل»',
        ),
        AdCampaign(
          id: 'a0',
          slot: AdSlot.homeBanner,
          title: 'إعلانك السابق',
          place: 'الرئيسية · بغداد',
          image: '$_img/cat_shoes_1.webp',
          status: AdStatus.ended,
          impressions: 12480,
          clicks: 742,
          selections: 18,
        ),
      ],
      earlyAccess: true,
      marks: const [
        PageMark(
          'm1',
          'ما ردت على زبون',
          '12/10 · طلب #DW-19870',
          MarkKind.mark,
          orderNo: 'DW-19870',
        ),
        PageMark(
          'm2',
          'ما ردت على زبون',
          '15/10 · طلب #DW-20011',
          MarkKind.mark,
          orderNo: 'DW-20011',
        ),
        PageMark(
          'm3',
          'ما ردت على زبون',
          '19/10 · طلب #DW-20402',
          MarkKind.mark,
          orderNo: 'DW-20402',
        ),
        PageMark('m4', 'شكوى «مو نفس الصورة»', 'قيد المراجعة', MarkKind.review),
      ],
      appealed: const {},
      settings: const PageSettings(),
      rating: 4.8,
      deals: 121,
      openReport: false,
      lastRating: const ReceivedRating(
        orderNo: 'DW-20481',
        stars: 5,
        tags: ['نفس الصورة', 'توصيل سريع'],
        comment: 'الحذاء أصلي ووصل قبل الموعد',
        governorate: 'بغداد',
      ),
      notices: [
        const SellerNotice(
          'اختارك زبون',
          'حذاء رياضي · رد خلال ساعة',
          '/seller/offers/o201',
          'قبل 8 د',
        ),
        const SellerNotice(
          'طلب جديد يناسبك',
          'حذاء رياضي أسود · 43 · مبكر',
          Routes.sellerInbox,
          'قبل 1 د',
        ),
        const SellerNotice(
          'وصلك تقييم',
          '5 نجوم · طلب #DW-20481',
          Routes.sellerRating,
          'أمس',
        ),
        const SellerNotice(
          'الزبون اختار غيرك',
          'بوت جلد · الحجز رجع لرصيدك',
          Routes.sellerOffers,
          'أمس',
        ),
        const SellerNotice(
          'إعلانك قيد المراجعة',
          'بانر «كل الأحذية خصم 20%»',
          Routes.sellerMyAds,
          '20/10',
        ),
        const SellerNotice(
          'علامة «ما ردت»',
          'طلب #DW-20402 · تكدر تعترض',
          Routes.sellerStanding,
          '19/10',
        ),
      ],
      suspendedUntil: null,
    );
  }

  void _setStatus(VerifyStatus s, {String? reason}) {
    ref.read(sharedPrefsProvider).setString(_kStatus, s.name);
    state = state.copyWith(status: s, rejectReason: reason);
  }

  /// 17 → POST /pages/register.
  void register({
    required String name,
    required String handle,
    required Set<String> categories,
    required Set<String> governorates,
  }) {
    state = state.copyWith(
      shopName: name,
      handle: handle,
      settings: state.settings.copyWith(
        categories: categories,
        governorates: governorates,
      ),
    );
    _setStatus(VerifyStatus.pending);
  }

  /// 18 «تحقق»: the server reads the Instagram bio for [SellerState.verifyCode].
  /// Mock: a handle must look like `@name` or the bio check fails (18b).
  VerifyStatus checkBio() {
    final ok = RegExp(r'^@[\w.]{3,}$').hasMatch(state.handle);
    if (ok) {
      _setStatus(VerifyStatus.pending);
    } else {
      _setStatus(
        VerifyStatus.rejected,
        reason: 'ما لكينا الكود ${state.verifyCode} ببايو ${state.handle}',
      );
    }
    return state.status;
  }

  /// Admin decision (first 20 pages are reviewed by hand).
  void approve() => _setStatus(VerifyStatus.verified);
  void retryVerification() => _setStatus(VerifyStatus.pending);
  void reset() => _setStatus(VerifyStatus.none);

  SellerRequest? request(String id) =>
      state.inbox.where((r) => r.id == id).firstOrNull;

  /// Client-side mirror of the server rules; the API re-checks everything.
  OfferError? validate(
    SellerRequest r, {
    int? price,
    String note = '',
    bool photo = true,
  }) {
    final c = state.config;
    if (r.offeredByMe) return OfferError.alreadyOffered;
    if (r.locked(c.maxOffers)) return OfferError.closed;
    if (r.isEarly(DateTime.now()) && r.earlyTaken >= c.maxEarlySlots) {
      return OfferError.earlySlotsFull;
    }
    if (!photo) return OfferError.noPhoto;
    if (price != null && price > r.maxPrice) return OfferError.priceAboveMax;
    if (hasContact(note)) return OfferError.contactInNote;
    if (!state.freeLeft && state.balance < c.selectionFee) {
      return OfferError.noBalance;
    }
    return null;
  }

  /// POST /requests/{id}/offers — reserves the fee (released if not chosen).
  OfferError? submit(String requestId, int price, String note) {
    final r = request(requestId);
    if (r == null) return OfferError.closed;
    final e = validate(r, price: price, note: note);
    if (e != null) return e;
    final fee = state.freeLeft ? 0 : state.config.selectionFee;
    state = state.copyWith(
      inbox: [
        for (final x in state.inbox)
          x.id == r.id
              ? x.copyWith(
                  offers: x.offers + 1,
                  offeredByMe: true,
                  earlyTaken: x.isEarly(DateTime.now())
                      ? x.earlyTaken + 1
                      : null,
                )
              : x,
      ],
      offers: [
        SellerOffer(
          id: 'o${r.id}',
          requestId: r.id,
          title: r.title,
          image: r.image,
          price: price,
          state: OfferState.waiting,
          governorate: r.governorate,
        ),
        ...state.offers,
      ],
      balance: state.balance - fee,
      ledger: [
        if (fee > 0)
          LedgerEntry('حجز · ${r.title}', 'محجوز', -fee, LedgerKind.held),
        ...state.ledger,
      ],
    );
    return null;
  }

  /// POST /offers/{id}/withdraw — releases the held fee.
  void withdraw(String offerId) {
    final fee = state.freeLeft ? 0 : state.config.selectionFee;
    state = state.copyWith(
      offers: [
        for (final o in state.offers)
          o.id == offerId ? o.copyWith(state: OfferState.withdrawn) : o,
      ],
      balance: state.balance + fee,
    );
  }

  void markContacted(String offerId) => state = state.copyWith(
    offers: [
      for (final o in state.offers)
        o.id == offerId ? o.copyWith(contacted: true) : o,
    ],
  );

  /// POST /orders/{id}/report-ghost — never auto-accepted; the customer is asked first.
  void reportGhost(String offerId) => state = state.copyWith(
    offers: [
      for (final o in state.offers)
        o.id == offerId ? o.copyWith(ghostReported: true) : o,
    ],
  );

  /// POST /page/topups (unique transactionRef).
  TopupError? topup(String method, String refNo, int amount, bool receipt) {
    final r = refNo.trim().toUpperCase();
    if (r.isEmpty) return TopupError.missingRef;
    if (!receipt) return TopupError.missingReceipt;
    if (state.topups.any((t) => t.ref == r)) return TopupError.duplicateRef;
    state = state.copyWith(
      topups: [
        Topup(r, method, amount, DateTime.now(), TopupStatus.pending),
        ...state.topups,
      ],
    );
    return null;
  }

  void toggleEarly() => state = state.copyWith(earlyAccess: !state.earlyAccess);

  /// POST /pages/me/ads — reserved now, Pending until a moderator approves.
  void bookAd(AdSlot slot, String title, String place, int price) =>
      state = state.copyWith(
        balance: state.balance - price,
        ads: [
          AdCampaign(
            id: 'a${state.ads.length + 1}',
            slot: slot,
            title: title,
            place: place,
            image: '$_img/cat_shoes_1.webp',
            status: AdStatus.pending,
            note: 'المبلغ محجوز، ويرجع إذا انرفض',
          ),
          ...state.ads,
        ],
        ledger: [
          LedgerEntry('حجز إعلان · $title', place, -price, LedgerKind.held),
          ...state.ledger,
        ],
      );

  void appeal(String markId) =>
      state = state.copyWith(appealed: {...state.appealed, markId});

  void saveSettings(PageSettings s) => state = state.copyWith(settings: s);
}

final sellerProvider = NotifierProvider<SellerController, SellerState>(
  SellerController.new,
);

/// Where the page app opens for a verification status.
String sellerEntryRoute(VerifyStatus s) => switch (s) {
  VerifyStatus.none => Routes.sellerRegister,
  VerifyStatus.pending => Routes.sellerVerify,
  VerifyStatus.rejected => Routes.sellerRejected,
  VerifyStatus.verified => Routes.sellerInbox,
};
