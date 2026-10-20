import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/catalog.dart';
import '../../../core/api/media.dart';
import '../../../core/api/token_store.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/format.dart';
import '../domain/seller_models.dart';

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

enum TopupError { duplicateRef, missingRef, missingReceipt, belowMin }

/// Banned contact patterns in offer notes / ad text: phones (Arabic or Latin
/// digits, spaced), links and @handles (§3.4). The server re-checks.
final _contact = RegExp(
  r'(@\w+)|(https?://|www\.|\.com|\.iq)|([0-9٠-٩][\s\-]*){7,}',
  caseSensitive: false,
);
bool hasContact(String text) => _contact.hasMatch(text);

class SellerState {
  const SellerState({
    this.config = const SellerConfig(),
    this.status = VerifyStatus.none,
    this.shopName = '',
    this.handle = '',
    this.phone = '',
    this.verifyCode = '',
    this.inbox = const [],
    this.offers = const [],
    this.balance = 0,
    this.freeUsed = 0,
    this.ledger = const [],
    this.topups = const [],
    this.ads = const [],
    this.earlyAccess = false,
    this.marks = const [],
    this.appealed = const {},
    this.settings = const PageSettings(),
    this.rating = 0,
    this.deals = 0,
    this.openReport = false,
    this.lastRating,
    this.notices = const [],
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
  final ReceivedRating? lastRating;
  final List<SellerNotice> notices;
  final DateTime? suspendedUntil;
  final String? rejectReason;

  bool get freeLeft => freeUsed < config.freeSelections;
  bool get suspended =>
      suspendedUntil != null && DateTime.now().isBefore(suspendedUntil!);
  bool get trusted => deals >= config.trustedDeals;

  /// Ads only for verified pages, rating ≥ min, no open report, not suspended (§13).
  bool get canAdvertise =>
      status == VerifyStatus.verified &&
      rating >= config.minAdRating &&
      !openReport &&
      !suspended;

  SellerState copyWith({
    SellerConfig? config,
    VerifyStatus? status,
    String? shopName,
    String? handle,
    String? phone,
    String? verifyCode,
    List<SellerRequest>? inbox,
    List<SellerOffer>? offers,
    int? balance,
    int? freeUsed,
    List<LedgerEntry>? ledger,
    List<Topup>? topups,
    List<AdCampaign>? ads,
    bool? earlyAccess,
    List<PageMark>? marks,
    Set<String>? appealed,
    PageSettings? settings,
    double? rating,
    int? deals,
    bool? openReport,
    ReceivedRating? lastRating,
    List<SellerNotice>? notices,
    DateTime? suspendedUntil,
    String? rejectReason,
  }) => SellerState(
    config: config ?? this.config,
    status: status ?? this.status,
    shopName: shopName ?? this.shopName,
    handle: handle ?? this.handle,
    phone: phone ?? this.phone,
    verifyCode: verifyCode ?? this.verifyCode,
    inbox: inbox ?? this.inbox,
    offers: offers ?? this.offers,
    balance: balance ?? this.balance,
    freeUsed: freeUsed ?? this.freeUsed,
    ledger: ledger ?? this.ledger,
    topups: topups ?? this.topups,
    ads: ads ?? this.ads,
    earlyAccess: earlyAccess ?? this.earlyAccess,
    marks: marks ?? this.marks,
    appealed: appealed ?? this.appealed,
    settings: settings ?? this.settings,
    rating: rating ?? this.rating,
    deals: deals ?? this.deals,
    openReport: openReport ?? this.openReport,
    lastRating: lastRating ?? this.lastRating,
    notices: notices ?? this.notices,
    suspendedUntil: suspendedUntil ?? this.suspendedUntil,
    rejectReason: rejectReason ?? this.rejectReason,
  );
}

/// Page side backed by the API: /pages/me, inbox, offers, wallet, ads, standing, ratings.
class SellerController extends Notifier<SellerState> {
  static const _notFound = 404;
  static const _offerErrors = {
    'offer.request_closed': OfferError.closed,
    'offer.full': OfferError.closed,
    'offer.not_dispatched': OfferError.closed,
    'offer.blocked': OfferError.closed,
    'offer.duplicate': OfferError.alreadyOffered,
    'offer.early_window': OfferError.earlySlotsFull,
    'offer.early_full': OfferError.earlySlotsFull,
    'offer.over_max': OfferError.priceAboveMax,
    'offer.price': OfferError.priceAboveMax,
    'offer.contact': OfferError.contactInNote,
    'wallet.insufficient': OfferError.noBalance,
  };
  static const _pageStatus = {
    'pending': VerifyStatus.pending,
    'verified': VerifyStatus.verified,
    'suspended': VerifyStatus.verified,
    'rejected': VerifyStatus.rejected,
    'banned': VerifyStatus.rejected,
  };
  static const _ledgerKinds = {
    'topUp': LedgerKind.credit,
    'adRefund': LedgerKind.credit,
    'freeSelection': LedgerKind.free,
  };
  static const _topupStatus = {
    'approved': TopupStatus.approved,
    'rejected': TopupStatus.rejected,
  };
  static const _appealType = 'strikeAppeal';
  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-');

  @override
  SellerState build() {
    if (ref.read(tokenStoreProvider).signedIn) Future.microtask(refresh);
    return const SellerState();
  }

  ApiClient get _api => ref.read(apiClientProvider);
  Future<Catalog> get _catalog => ref.read(catalogProvider.future);

  /// GET /pages/me (+ everything a verified page sees). Returns the verification status.
  Future<VerifyStatus> refresh() async {
    final config = SellerConfig.fromJson(await ref.read(appConfigProvider.future));
    final Map<String, dynamic> me;
    try {
      me = await _api.get<Map<String, dynamic>>('/api/v1/pages/me');
    } on ApiException catch (e) {
      if (e.status != _notFound) rethrow;
      state = SellerState(config: config);
      return state.status;
    }
    final cat = await _catalog;
    final st = me.m('settings');
    final status = _pageStatus[me.s('status')] ?? VerifyStatus.pending;
    state = state.copyWith(
      config: config,
      status: status,
      shopName: me.s('name'),
      handle: '@${me.s('instagram')}',
      phone: me.os('phone') ?? '',
      verifyCode: me.s('bioCode'),
      rejectReason: me.os('rejectReason'),
      rating: me.d('rating'),
      deals: me.i('deals'),
      freeUsed: me.i('freeUsed'),
      balance: me.i('balance'),
      earlyAccess: me.ot('earlyAccessUntil')?.isAfter(DateTime.now()) ?? false,
      suspendedUntil: me.ot('suspendedUntil'),
      settings: PageSettings(
        receiving: st.b('receiving'),
        sound: st.b('sound'),
        categories: cat.categoryNames(st.list<num>('categoryIds').map((e) => e.toInt())),
        governorates: cat.governorateNames(st.list<num>('governorateIds').map((e) => e.toInt())),
        from: st.i('from'),
        to: st.i('to'),
        days: st.list<num>('days').map((e) => e.toInt()).toSet(),
      ),
    );
    if (status == VerifyStatus.verified) {
      await Future.wait([
        loadInbox(),
        loadOffers(),
        loadWallet(),
        loadAds(),
        loadStanding(),
        loadRatings(),
        loadNotices(),
      ]);
    }
    return state.status;
  }

  Future<void> loadInbox() async {
    final list = asList(await _api.get<List<dynamic>>('/api/v1/pages/me/inbox'));
    state = state.copyWith(
      inbox: [
        for (final r in list)
          SellerRequest(
            id: r.s('id'),
            title: r.s('title'),
            image: r.os('image') ?? '',
            governorate: r.s('governorate'),
            condition: r.s('condition'),
            maxPrice: r.i('maxPrice'),
            postedAt: r.t('postedAt'),
            offers: r.i('offers'),
            earlyUntil: r.ot('earlyUntil'),
            earlyTaken: r.i('earlyTaken'),
            offeredByMe: r.b('offeredByMe'),
            cancelled: r.b('cancelled'),
          ),
      ],
    );
  }

  Future<void> loadOffers() async {
    final list = asList(await _api.get<List<dynamic>>('/api/v1/pages/me/offers'));
    state = state.copyWith(
      offers: [
        for (final o in list)
          SellerOffer(
            id: o.s('id'),
            requestId: o.s('requestId'),
            title: o.s('title'),
            image: o.os('image') ?? '',
            price: o.i('price'),
            state: OfferState.values.byName(o.s('state')),
            orderId: o.os('orderId'),
            orderNo: o.os('orderNo'),
            chosenAt: o.ot('chosenAt'),
            contacted: o.b('contacted'),
            ghostReported: o.b('ghostReported'),
            selectionNo: o.oi('selectionNo'),
            governorate: o.s('governorate'),
            customerPhone: o.os('customerPhone')?.replaceAll('+', ''),
          ),
      ],
    );
  }

  Future<void> loadWallet() async {
    final w = await _api.get<Map<String, dynamic>>('/api/v1/pages/me/wallet');
    state = state.copyWith(
      balance: w.i('available'),
      freeUsed: w.i('freeUsed'),
      ledger: [
        for (final e in w.l('ledger'))
          LedgerEntry(
            e.s('note'),
            dayMonth(e.t('at')),
            e.i('amount'),
            _ledgerKinds[e.s('type')] ??
                (e.i('amount') >= 0 ? LedgerKind.credit : LedgerKind.debit),
          ),
      ],
      topups: [
        for (final t in w.l('topUps'))
          Topup(
            t.s('ref'),
            t.s('method'),
            t.i('amount'),
            t.t('at'),
            _topupStatus[t.s('status')] ?? TopupStatus.pending,
          ),
      ],
    );
  }

  Future<void> loadAds() async {
    final list = asList(await _api.get<List<dynamic>>('/api/v1/pages/me/ads'));
    final el = await _api.get<Map<String, dynamic>>('/api/v1/pages/me/ads/eligibility');
    state = state.copyWith(
      openReport: !el.b('noOpenReports'),
      ads: [
        for (final a in list)
          AdCampaign(
            id: a.s('id'),
            slot: AdSlot.values.byName(a.s('slot')),
            title: a.s('title'),
            place: a.s('place'),
            image: a.os('image') ?? '',
            status: AdStatus.values.byName(a.s('status')),
            note: a.os('note'),
            impressions: a.i('impressions'),
            clicks: a.i('clicks'),
            selections: a.i('selections'),
          ),
      ],
    );
  }

  Future<void> loadStanding() async {
    final j = await _api.get<Map<String, dynamic>>('/api/v1/pages/me/standing');
    final disputes = asList(await _api.get<List<dynamic>>('/api/v1/disputes'));
    state = state.copyWith(
      suspendedUntil: j.ot('suspendedUntil'),
      marks: [
        for (final m in j.l('marks'))
          PageMark(
            m.s('id'),
            m.s('title'),
            [dayMonth(m.t('at')), if (m.os('orderNo') case final no?) 'طلب #$no'].join(' · '),
            m.b('underReview')
                ? MarkKind.review
                : MarkKind.mark,
            orderNo: m.os('orderNo'),
          ),
      ],
      appealed: {
        for (final d in disputes)
          if (d.s('type') == _appealType) ?d.os('subjectId'),
      },
    );
  }

  Future<void> loadRatings() async {
    final list = asList(await _api.get<List<dynamic>>('/api/v1/pages/me/ratings'));
    if (list.isEmpty) return;
    final r = list.first;
    state = state.copyWith(
      lastRating: ReceivedRating(
        orderNo: r.s('orderNo'),
        stars: r.i('stars'),
        tags: r.list<String>('tags'),
        comment: r.s('comment'),
        governorate: r.s('governorate'),
      ),
    );
  }

  Future<void> loadNotices() async {
    final j = await _api.get<Map<String, dynamic>>('/api/v1/notifications');
    state = state.copyWith(
      notices: [
        for (final n in j.l('items'))
          SellerNotice(n.s('title'), n.s('body'), n.s('route'), agoLabel(n.t('at'))),
      ],
    );
  }

  /// 17 → POST /pages/register.
  Future<void> register({
    required String name,
    required String handle,
    required Set<String> categories,
    required Set<String> governorates,
  }) async {
    final cat = await _catalog;
    await _api.post<void>('/api/v1/pages/register', {
      'name': name,
      'instagram': handle.replaceFirst('@', ''),
      'categoryIds': cat.categoryIds(categories),
      'governorateIds': cat.governorateIds(governorates),
      'acceptTerms': true,
    });
    await refresh();
  }

  /// 18 «تحقق»: re-reads the page status (bio code is checked by the reviewers).
  Future<VerifyStatus> checkBio() => refresh();

  /// After a rejection: POST /pages/me/resubmit.
  Future<void> retryVerification() async {
    await _api.post<void>('/api/v1/pages/me/resubmit');
    await refresh();
  }

  /// Account deleted / signed out: forget the page locally.
  void reset() => state = SellerState(config: state.config);

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
    if (r.isEarly(DateTime.now()) &&
        (!state.earlyAccess || r.earlyTaken >= c.maxEarlySlots)) {
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

  /// POST /media + POST /requests/{id}/offers — fee is reserved (released if not chosen).
  Future<OfferError?> submit(
    String requestId,
    int price,
    String note, {
    required String photo,
    required int deliveryHours,
    String condition = 'new',
  }) async {
    final r = request(requestId);
    if (r == null) return OfferError.closed;
    final e = validate(r, price: price, note: note);
    if (e != null) return e;
    try {
      final key = await uploadImage(_api, photo, 'offers');
      if (key == null) return OfferError.noPhoto;
      await _api.post<void>('/api/v1/requests/$requestId/offers', {
        'price': price,
        'deliveryHours': deliveryHours,
        'condition': condition,
        'note': note,
        'photoKey': key,
      });
    } on ApiException catch (x) {
      final mapped = _offerErrors[x.code];
      if (mapped == null) rethrow;
      return mapped;
    }
    await Future.wait([loadInbox(), loadOffers(), loadWallet()]);
    return null;
  }

  /// POST /offers/{id}/withdraw — releases the held fee.
  Future<void> withdraw(String offerId) async {
    await _api.post<void>('/api/v1/offers/$offerId/withdraw');
    await Future.wait([loadOffers(), loadWallet()]);
  }

  String? _orderOf(String offerId) =>
      state.offers.where((o) => o.id == offerId).firstOrNull?.orderId;

  Future<void> markContacted(String offerId) async {
    final id = _orderOf(offerId);
    if (id == null) return;
    await _api.post<void>('/api/v1/orders/$id/contacted');
    await loadOffers();
  }

  /// POST /orders/{id}/report-ghost — never auto-accepted; the customer is asked first.
  Future<void> reportGhost(String offerId) async {
    final id = _orderOf(offerId);
    if (id == null) return;
    await _api.post<void>('/api/v1/orders/$id/report-ghost');
    await loadOffers();
  }

  /// POST /media (receipt) + POST /pages/me/topups (unique transaction ref).
  Future<TopupError?> topup(
    String method,
    String refNo,
    int amount,
    String? receipt,
  ) async {
    final r = refNo.trim().toUpperCase();
    if (r.isEmpty) return TopupError.missingRef;
    if (receipt == null) return TopupError.missingReceipt;
    if (amount < state.config.minTopUp) return TopupError.belowMin;
    try {
      final key = await uploadImage(_api, receipt, 'receipts');
      await _api.post<void>('/api/v1/pages/me/topups', {
        'method': method,
        'transactionRef': r,
        'amount': amount,
        'receiptKey': key,
      });
    } on ApiException catch (e) {
      return switch (e.code) {
        'topup.duplicate_ref' => TopupError.duplicateRef,
        'topup.min' => TopupError.belowMin,
        _ => throw e,
      };
    }
    await loadWallet();
    return null;
  }

  /// Early access subscription on/off (monthly fee).
  Future<void> toggleEarly() async {
    final on = !state.earlyAccess;
    const path = '/api/v1/pages/me/subscriptions/early-access';
    await (on ? _api.post<void>(path) : _api.delete<void>(path));
    state = state.copyWith(earlyAccess: on);
    await loadWallet();
  }

  /// POST /pages/me/ads — reserved now, Pending until a moderator approves.
  Future<void> bookAd({
    required AdSlot slot,
    required String title,
    required String headline,
    required String category,
    required String governorate,
    required int days,
    String? image,
  }) async {
    final cat = await _catalog;
    final key = await uploadImage(_api, image, 'ads');
    await _api.post<void>('/api/v1/pages/me/ads', {
      'slot': slot.name,
      'title': title,
      'headline': headline,
      'discountPercent': 0,
      'governorateIds': cat.governorateIds([governorate]),
      'categoryIds': cat.categoryIds([category]),
      'startAt': DateTime.now().toUtc().toIso8601String(),
      'days': days,
      'imageKey': key,
    });
    await Future.wait([loadAds(), loadWallet()]);
  }

  /// POST /disputes {type: strikeAppeal} — decided within the appeal window.
  Future<void> appeal(String markId, String text) async {
    await _api.post<void>('/api/v1/disputes', {
      'type': _appealType,
      'subjectId': _uuid.hasMatch(markId) ? markId : null,
      'text': text,
    });
    state = state.copyWith(appealed: {...state.appealed, markId});
  }

  Future<void> saveSettings(PageSettings s) async {
    final cat = await _catalog;
    await _api.put<void>('/api/v1/pages/me/settings', {
      'receiving': s.receiving,
      'sound': s.sound,
      'categoryIds': cat.categoryIds(s.categories),
      'governorateIds': cat.governorateIds(s.governorates),
      'from': s.from,
      'to': s.to,
      'days': s.days.toList(),
    });
    state = state.copyWith(settings: s);
  }
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
