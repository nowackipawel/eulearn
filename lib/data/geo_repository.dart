import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../domain/models.dart';

/// Names of one country in one language.
class GeoText {
  const GeoText({
    required this.name,
    required this.capital,
    String? acc,
    String? gen,
    String? inSentence,
    this.hook,
    this.plural = false,
  })
      : acc = acc ?? inSentence ?? name,
        gen = gen ?? inSentence ?? name;

  final String name;
  final String capital;

  /// Polish accusative ("Pokaż Francję") / English in-sentence form ("the Netherlands").
  final String acc;

  /// Polish genitive ("stolica Francji") / English in-sentence form.
  final String gen;
  final String? hook;

  /// Polish plural-only names (Niemcy, Chiny) take a plural verb.
  final bool plural;

  factory GeoText.fromJson(Map<String, dynamic> j) => GeoText(
        name: j['name'] as String,
        capital: j['capital'] as String,
        acc: j['nameAcc'] as String?,
        gen: j['nameGen'] as String?,
        inSentence: j['nameInSentence'] as String?,
        hook: j['hook'] as String?,
        plural: j['plural'] as bool? ?? false,
      );
}

/// Geometry of one country in one view, already projected to canvas units.
class CountryShape {
  CountryShape({
    required this.code,
    required this.path,
    required this.mainRing,
    required this.bbox,
    required this.label,
    required this.area,
    this.capital,
  }) : ribbonLength = mainRing.computeMetrics().fold(0.0, (s, m) => s + m.length);

  final String code;

  /// All rings.
  final Path path;

  /// Largest ring, clockwise from its northernmost point (ribbon origin).
  final Path mainRing;
  final Rect bbox;
  final Offset label;
  final Offset? capital;
  final double area;
  final double ribbonLength;
}

class GeoView {
  GeoView({required this.size, required this.frame, required this.shapes, required this.playable})
      : byAreaDesc = shapes.values.toList()..sort((a, b) => b.area.compareTo(a.area));
  final Size size;

  /// Default camera rectangle: all playable countries.
  final Rect frame;
  final Map<String, CountryShape> shapes;

  /// Countries that are part of the game in this view; the rest is backdrop.
  final Set<String> playable;

  /// Draw order: big first, so enclaves land on top of their hosts.
  final List<CountryShape> byAreaDesc;
}

class GeoRepository {
  GeoRepository({required this.graph, required this.tint, required this.continent, required this.views, required this.texts});

  final Map<String, CountryNode> graph;

  /// Index into the map tint palette; neighbours never share one.
  final Map<String, int> tint;
  /// Continent of each country.
  final Map<String, String> continent;

  /// One view per continent, plus [world].
  final Map<String, GeoView> views;

  static const world = 'world';
  static const continents = ['europe', 'asia', 'africa', 'north_america', 'south_america', 'oceania'];

  /// Where learning starts on a continent that is not the child's own.
  static const anchors = {
    'europe': 'de',
    'asia': 'cn',
    'africa': 'eg',
    'north_america': 'us',
    'south_america': 'br',
    'oceania': 'au',
  };

  Set<String> members(String region) => views[region]!.playable;
  final Map<Lang, Map<String, GeoText>> texts;

  bool playable(String code) => graph.containsKey(code);
  GeoText text(String code, Lang lang) => texts[lang]![code]!;

  // ponytail: all views are parsed on the UI thread at start (≈550 kB JSON).
  // Load a continent on demand, or parse in an isolate, if startup shows jank.
  static Future<GeoRepository> load(AssetBundle bundle) async {
    Future<Map<String, dynamic>> read(String p) async =>
        jsonDecode(await bundle.loadString(p)) as Map<String, dynamic>;
    final countries = await read('assets/geo/countries.json');
    final texts = {
      for (final l in Lang.values)
        l: (await read('assets/i18n/geo_${l.name}.json'))
            .map((k, v) => MapEntry(k, GeoText.fromJson(v as Map<String, dynamic>))),
    };

    List<double> nums(dynamic l) => [for (final n in l as List) (n as num).toDouble()];
    Path ring(List<double> r) {
      final p = Path()..moveTo(r[0], r[1]);
      for (var i = 2; i < r.length; i += 2) {
        p.lineTo(r[i], r[i + 1]);
      }
      return p..close();
    }

    Future<GeoView> loadView(String name) async {
      final view = await read('assets/geo/view_$name.json');
      final shapes = <String, CountryShape>{};
      (view['countries'] as Map<String, dynamic>).forEach((code, v) {
        final rings = [for (final r in v['rings'] as List) ring(nums(r))];
        final path = Path();
        for (final r in rings) {
          path.addPath(r, Offset.zero);
        }
        final b = nums(v['bbox']), l = nums(v['label']);
        final c = v['capital'] == null ? null : nums(v['capital']);
        shapes[code] = CountryShape(
          code: code,
          path: path,
          mainRing: rings.first,
          bbox: Rect.fromLTRB(b[0], b[1], b[2], b[3]),
          label: Offset(l[0], l[1]),
          capital: c == null ? null : Offset(c[0], c[1]),
          area: (v['area'] as num).toDouble(),
        );
      });
      final size = nums(view['size']), f = nums(view['frame']);
      return GeoView(
        size: Size(size[0], size[1]),
        frame: Rect.fromLTRB(f[0], f[1], f[2], f[3]),
        shapes: shapes,
        playable: (view['playable'] as List).cast<String>().toSet(),
      );
    }

    return GeoRepository(
      graph: {
        for (final e in countries.entries)
          e.key: CountryNode(
            code: e.key,
            neighbors: (e.value['neighbors'] as List).cast(),
            near: (e.value['near'] as List).cast(),
            similarFlags: (e.value['similarFlags'] as List).cast(),
          ),
      },
      tint: {for (final e in countries.entries) e.key: e.value['color'] as int},
      continent: {for (final e in countries.entries) e.key: e.value['continent'] as String},
      views: {for (final v in [world, ...continents]) v: await loadView(v)},
      texts: texts,
    );
  }
}
