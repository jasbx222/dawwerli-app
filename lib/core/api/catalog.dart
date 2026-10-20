import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

class CatalogSchema {
  const CatalogSchema(
    this.hint,
    this.required,
    this.sizes,
    this.colors,
    this.prices,
  );
  final String hint;
  final List<String> required;
  final List<String> sizes;
  final List<String> colors;
  final List<int> prices;
}

class CatalogCategoryRef {
  const CatalogCategoryRef({
    required this.id,
    required this.slug,
    required this.name,
    required this.emoji,
    required this.image,
    required this.badge,
    required this.schema,
  });
  final int id;
  final String slug;
  final String name;
  final String? emoji;
  final String image;
  final String badge;
  final CatalogSchema schema;
}

class GovernorateRef {
  const GovernorateRef(this.id, this.name);
  final int id;
  final String name;
}

/// Categories and governorates from the API (cached for the session); maps names ⇄ ids.
class Catalog {
  const Catalog(this.categories, this.governorates);
  final List<CatalogCategoryRef> categories;
  final List<GovernorateRef> governorates;

  CatalogCategoryRef? category(String nameOrSlugOrId) => categories
      .where(
        (c) =>
            c.name == nameOrSlugOrId ||
            c.slug == nameOrSlugOrId ||
            '${c.id}' == nameOrSlugOrId,
      )
      .firstOrNull;
  CatalogCategoryRef? categoryById(int id) =>
      categories.where((c) => c.id == id).firstOrNull;
  int? governorateId(String name) =>
      governorates.where((g) => g.name == name).firstOrNull?.id;
  String governorateName(int id) =>
      governorates.where((g) => g.id == id).firstOrNull?.name ?? '';
  List<int> categoryIds(Iterable<String> names) => [
    for (final n in names) ?category(n)?.id,
  ];
  List<int> governorateIds(Iterable<String> names) => [
    for (final n in names) ?governorateId(n),
  ];
  Set<String> categoryNames(Iterable<int> ids) => {
    for (final i in ids) ?categoryById(i)?.name,
  };
  Set<String> governorateNames(Iterable<int> ids) =>
      {for (final i in ids) governorateName(i)}..remove('');
}

class CatalogRepository {
  const CatalogRepository(this.api);
  final ApiClient api;

  Future<Catalog> load() async {
    final cats = asList(await api.get<List<dynamic>>('/api/v1/categories'));
    final govs = asList(await api.get<List<dynamic>>('/api/v1/governorates'));
    return Catalog(
      [
        for (final c in cats)
          CatalogCategoryRef(
            id: c.i('id'),
            slug: c.s('slug'),
            name: c.s('name'),
            emoji: c.os('emoji'),
            image: c.s('image'),
            badge: c.s('badge'),
            schema: CatalogSchema(
              c.m('schema').s('hint'),
              c.m('schema').list<String>('required'),
              c.m('schema').list<String>('sizes'),
              c.m('schema').list<String>('colors'),
              [
                for (final p in c.m('schema').list<num>('priceSuggestions'))
                  p.toInt(),
              ],
            ),
          ),
      ],
      [for (final g in govs) GovernorateRef(g.i('id'), g.s('name'))],
    );
  }
}

final catalogProvider = FutureProvider<Catalog>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)).load(),
);

/// Public business config (`GET /api/v1/config`): limits, fees, rating tags…
final appConfigProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async => ((await ref
      .watch(apiClientProvider)
      .get<Map<String, dynamic>>('/api/v1/config'))),
);
