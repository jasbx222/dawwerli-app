/// How the customer describes what they want (07 tabs).
enum InputMode { photo, text, voice }

enum ItemCondition { brandNew, used, any }

/// A request being composed (07 → 08 → 09). Saved as a draft on every step.
class RequestDraft {
  const RequestDraft({
    this.mode = InputMode.photo,
    this.photo,
    this.description = '',
    this.voiceSeconds,
    this.category,
    this.size,
    this.color,
    this.condition = ItemCondition.brandNew,
    this.maxPrice,
    this.governorate = 'بغداد',
    this.readyToBuy = false,
    this.removedContactInfo = false,
  });

  final InputMode mode;

  /// Asset/file path of the photo (mock uses bundled assets).
  final String? photo;
  final String description;

  /// Length of the voice note; null when nothing recorded.
  final int? voiceSeconds;
  final String? category;
  final String? size;
  final String? color;
  final ItemCondition condition;

  /// Max price in IQD, delivery included.
  final int? maxPrice;
  final String governorate;

  /// "جاهز أشتري خلال 48 ساعة" commitment (required to publish).
  final bool readyToBuy;

  /// True when we stripped a phone/link/@handle from the description (08 notice).
  final bool removedContactInfo;

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'photo': photo,
    'description': description,
    'voiceSeconds': voiceSeconds,
    'category': category,
    'size': size,
    'color': color,
    'condition': condition.name,
    'maxPrice': maxPrice,
    'governorate': governorate,
    'readyToBuy': readyToBuy,
    'removedContactInfo': removedContactInfo,
  };

  factory RequestDraft.fromJson(Map<String, Object?> j) => RequestDraft(
    mode: InputMode.values.asNameMap()[j['mode']] ?? InputMode.photo,
    photo: j['photo'] as String?,
    description: j['description'] as String? ?? '',
    voiceSeconds: j['voiceSeconds'] as int?,
    category: j['category'] as String?,
    size: j['size'] as String?,
    color: j['color'] as String?,
    condition:
        ItemCondition.values.asNameMap()[j['condition']] ??
        ItemCondition.brandNew,
    maxPrice: j['maxPrice'] as int?,
    governorate: j['governorate'] as String? ?? 'بغداد',
    readyToBuy: j['readyToBuy'] as bool? ?? false,
    removedContactInfo: j['removedContactInfo'] as bool? ?? false,
  );

  RequestDraft copyWith({
    InputMode? mode,
    String? photo,
    String? description,
    int? voiceSeconds,
    String? category,
    String? size,
    String? color,
    ItemCondition? condition,
    int? maxPrice,
    String? governorate,
    bool? readyToBuy,
    bool? removedContactInfo,
  }) => RequestDraft(
    mode: mode ?? this.mode,
    photo: photo ?? this.photo,
    description: description ?? this.description,
    voiceSeconds: voiceSeconds ?? this.voiceSeconds,
    category: category ?? this.category,
    size: size ?? this.size,
    color: color ?? this.color,
    condition: condition ?? this.condition,
    maxPrice: maxPrice ?? this.maxPrice,
    governorate: governorate ?? this.governorate,
    readyToBuy: readyToBuy ?? this.readyToBuy,
    removedContactInfo: removedContactInfo ?? this.removedContactInfo,
  );
}

/// Publish rejections shown on 09b (server is the source of truth; the app pre-checks).
enum PostError {
  incomplete,

  /// REQ-03: shoes/clothes need a size (server re-checks).
  sizeMissing,
  prohibited,
  contactInfo,
  maxOpen,
  voiceTooLong,
  priceZero,
}

/// Category-specific required fields (08). Shoes need size + colour.
class DetailSchema {
  const DetailSchema({
    required this.hint,
    this.sizes = const [],
    this.colors = const [],
    this.priceSuggestions = const [],
  });

  final String hint;
  final List<String> sizes;
  final List<String> colors;
  final List<int> priceSuggestions;
}

abstract final class PostRules {
  static const maxVoiceSeconds = 60;
  static const maxOpenRequests = 3;
  static const minWordsWithoutPhoto = 10;

  static final _digits = RegExp(r'[0-9٠-٩۰-۹]');
  // 7+ digits (Western/Arabic-Indic), allowing spaces/dashes/dots between them.
  static final _phone = RegExp(r'(?:[0-9٠-٩۰-۹][\s\-.]*){7,}');
  static final _link = RegExp(
    r'(https?://\S+|www\.\S+|\b\S+\.(com|net|org|iq|me|ly|co)\b\S*)',
    caseSensitive: false,
  );
  static final _handle = RegExp(r'@\w+');

  static bool hasContactInfo(String s) =>
      _phone.hasMatch(s) || _link.hasMatch(s) || _handle.hasMatch(s);

  /// Removes phones, links and @handles; returns the cleaned text and whether anything was removed.
  static (String, bool) stripContactInfo(String s) {
    var out = s
        .replaceAll(_phone, ' ')
        .replaceAll(_link, ' ')
        .replaceAll(_handle, ' ');
    out = out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return (out, out != s.trim());
  }

  static bool hasDigits(String s) => _digits.hasMatch(s);

  /// REQ-03 «أحذية بدون قياس → يطلب القياس».
  static bool needsSize(RequestDraft d) => d.category == 'أحذية';

  /// Client-side pre-check; [openCount] = requests already open.
  static Set<PostError> validate(RequestDraft d, {required int openCount}) {
    final words = d.description
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return {
      if (d.photo == null &&
          words < minWordsWithoutPhoto &&
          d.voiceSeconds == null)
        PostError.incomplete,
      if (hasContactInfo(d.description)) PostError.contactInfo,
      if (openCount >= maxOpenRequests) PostError.maxOpen,
      if ((d.voiceSeconds ?? 0) > maxVoiceSeconds) PostError.voiceTooLong,
      if (d.maxPrice == null || d.maxPrice! <= 0) PostError.priceZero,
      if (needsSize(d) && d.size == null) PostError.sizeMissing,
    };
  }
}

/// Category suggested by the classifier (emoji shown before the name when set).
class CategoryOption {
  const CategoryOption(this.name, {this.emoji});
  final String name;
  final String? emoji;
  String get label => emoji == null ? name : '$emoji $name';
}
