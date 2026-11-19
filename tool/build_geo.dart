// Builds map assets from Natural Earth data. Run from the repo root:
//   dart run tool/build_geo.dart
// Needs Node (npx mapshaper). Raw downloads are cached in tool/raw/ (gitignored).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _src = 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson';
const _bbox = '-25,33.5,50,72';
const _lat0 = 52.0, _lon0 = 12.0, _width = 2000.0;
// Rings smaller than this (px² on the 2000-wide canvas) are dropped unless
// they are the country's largest ring.
const _minRingArea = 5.0;

typedef Ring = List<List<double>>; // [[lon, lat], ...] then projected [[x, y], ...]

Future<void> main() async {
  final raw = Directory('tool/raw')..createSync(recursive: true);
  for (final (file, name) in [
    ('countries.geojson', 'ne_50m_admin_0_countries.geojson'),
    ('places.geojson', 'ne_50m_populated_places.geojson'),
  ]) {
    final f = File('${raw.path}/$file');
    if (!f.existsSync()) {
      stdout.writeln('downloading $name');
      final r = await Process.run('curl', ['-sSfL', '-o', f.path, '$_src/$name']);
      if (r.exitCode != 0) throw 'download failed: ${r.stderr}';
    }
  }
  final ov = jsonDecode(File('tool/overrides.json').readAsStringSync()) as Map<String, dynamic>;
  final playable = (ov['playable'] as List).cast<String>().toSet();
  final merge = (ov['merge'] as Map).cast<String, String>();

  // Topology-preserving simplification: shared borders stay shared.
  final codeExpr = 'code=(ADM0_A3=="CYN"?"cy":(ISO_A2_EH!="-99"?ISO_A2_EH.toLowerCase():ADM0_A3.toLowerCase()));'
      '${merge.entries.map((e) => 'if(code=="${e.key}")code="${e.value}";').join()}';
  final ms = await Process.run('npx', [
    '-y', 'mapshaper', '${raw.path}/countries.geojson',
    '-filter-fields', 'ISO_A2_EH,ADM0_A3',
    '-each', codeExpr,
    '-simplify', '28%', 'keep-shapes',
    '-clip', 'bbox=$_bbox',
    '-dissolve', 'code',
    '-clean',
    '-o', 'precision=0.0001', '${raw.path}/europe.geojson',
  ]);
  if (ms.exitCode != 0) throw 'mapshaper failed: ${ms.stderr}';

  final geo = jsonDecode(File('${raw.path}/europe.geojson').readAsStringSync());
  // code -> polygons -> rings (first ring of a polygon is the outer one)
  final shapes = <String, List<List<Ring>>>{};
  for (final f in geo['features']) {
    final g = f['geometry'];
    if (g == null) continue;
    final polys = g['type'] == 'MultiPolygon' ? g['coordinates'] as List : [g['coordinates']];
    shapes[f['properties']['code'] as String] = [
      for (final p in polys)
        [for (final r in p) [for (final c in r) [(c[0] as num).toDouble(), (c[1] as num).toDouble()]]]
    ];
  }

  // Adjacency: two countries are neighbours when they share an edge.
  final edgeOwner = <String, String>{};
  final neighbors = {for (final c in shapes.keys) c: <String>{}};
  shapes.forEach((code, polys) {
    for (final p in polys) {
      for (final r in p) {
        for (var i = 0; i + 1 < r.length; i++) {
          final a = '${r[i][0]},${r[i][1]}', b = '${r[i + 1][0]},${r[i + 1][1]}';
          final key = a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
          final other = edgeOwner[key];
          if (other == null) {
            edgeOwner[key] = code;
          } else if (other != code) {
            neighbors[code]!.add(other);
            neighbors[other]!.add(code);
          }
        }
      }
    }
  });

  // Projection: Lambert azimuthal equal-area, y down, scaled to _width.
  List<double> laea(double lon, double lat) {
    final p = lat * pi / 180, l = (lon - _lon0) * pi / 180, p0 = _lat0 * pi / 180;
    final k = sqrt(2 / (1 + sin(p0) * sin(p) + cos(p0) * cos(p) * cos(l)));
    return [k * cos(p) * sin(l), -k * (cos(p0) * sin(p) - sin(p0) * cos(p) * cos(l))];
  }

  var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
  for (final polys in shapes.values) {
    for (final p in polys) {
      for (final c in p.first) {
        final q = laea(c[0], c[1]);
        minX = min(minX, q[0]); maxX = max(maxX, q[0]);
        minY = min(minY, q[1]); maxY = max(maxY, q[1]);
      }
    }
  }
  final scale = _width / (maxX - minX);
  List<double> project(List<double> lonLat) {
    final q = laea(lonLat[0], lonLat[1]);
    return [r1((q[0] - minX) * scale), r1((q[1] - minY) * scale)];
  }

  double area(Ring r) {
    var s = 0.0;
    for (var i = 0; i + 1 < r.length; i++) {
      s += r[i][0] * r[i + 1][1] - r[i + 1][0] * r[i][1];
    }
    return s / 2;
  }

  final view = <String, dynamic>{};
  final frame = [double.infinity, double.infinity, -double.infinity, -double.infinity];
  final labels = (ov['labels'] as Map).cast<String, dynamic>();
  shapes.forEach((code, polys) {
    // Outer rings only: enclaves are drawn on top of their host.
    var rings = [for (final p in polys) p.first.map(project).toList()];
    rings.sort((a, b) => area(b).abs().compareTo(area(a).abs()));
    rings = [rings.first, ...rings.skip(1).where((r) => area(r).abs() >= _minRingArea)];
    // Largest ring: clockwise on screen, starting at its northernmost point,
    // so the border ribbon grows clockwise from the north.
    var main = rings.first.sublist(0, rings.first.length - 1);
    if (area(main + [main.first]) < 0) main = main.reversed.toList();
    var north = 0;
    for (var i = 1; i < main.length; i++) {
      if (main[i][1] < main[north][1]) north = i;
    }
    main = [...main.sublist(north), ...main.sublist(0, north)];
    rings[0] = [...main, main.first];

    final b = [double.infinity, double.infinity, -double.infinity, -double.infinity];
    for (final r in rings) {
      for (final c in r) {
        b[0] = min(b[0], c[0]); b[1] = min(b[1], c[1]);
        b[2] = max(b[2], c[0]); b[3] = max(b[3], c[1]);
      }
    }
    List<double> label;
    if (labels[code] != null) {
      label = project((labels[code] as List).cast<num>().map((e) => e.toDouble()).toList());
    } else {
      var cx = 0.0, cy = 0.0;
      final a = area(rings.first);
      final r = rings.first;
      for (var i = 0; i + 1 < r.length; i++) {
        final cr = r[i][0] * r[i + 1][1] - r[i + 1][0] * r[i][1];
        cx += (r[i][0] + r[i + 1][0]) * cr;
        cy += (r[i][1] + r[i + 1][1]) * cr;
      }
      label = [r1(cx / (6 * a)), r1(cy / (6 * a))];
    }
    if (playable.contains(code) && code != 'ru') {
      frame[0] = min(frame[0], b[0]); frame[1] = min(frame[1], b[1]);
      frame[2] = max(frame[2], b[2]); frame[3] = max(frame[3], b[3]);
    }
    view[code] = {
      'rings': [for (final r in rings) [for (final c in r) ...c]],
      'bbox': b,
      'label': label,
      'area': r1(rings.fold(0.0, (s, r) => s + area(r).abs())),
    };
  });

  // Capitals.
  final places = jsonDecode(File('${raw.path}/places.geojson').readAsStringSync());
  final capitals = <String, List<double>>{};
  for (final f in places['features']) {
    final p = f['properties'];
    if (p['FEATURECLA'] == 'Admin-0 capital') {
      final c = f['geometry']['coordinates'];
      capitals[(p['ISO_A2'] as String).toLowerCase()] = [(c[0] as num).toDouble(), (c[1] as num).toDouble()];
    }
  }
  (ov['capitals'] as Map).forEach((k, v) => capitals[k as String] = (v as List).cast<num>().map((e) => e.toDouble()).toList());

  // Colours: greedy, 4 tints, a 5th only when forced. Highest degree first.
  final order = playable.toList()
    ..sort((a, b) {
      final d = neighbors[b]!.length.compareTo(neighbors[a]!.length);
      return d != 0 ? d : a.compareTo(b);
    });
  final color = <String, int>{};
  for (final c in order) {
    final used = {for (final n in neighbors[c]!) if (color[n] != null) color[n]!};
    color[c] = [0, 1, 2, 3, 4].firstWhere((i) => !used.contains(i));
  }

  final near = (ov['near'] as Map).cast<String, dynamic>();
  final similar = (ov['similarFlags'] as Map).cast<String, dynamic>();
  final problems = <String>[];
  final countries = <String, dynamic>{};
  for (final c in playable.toList()..sort()) {
    if (!shapes.containsKey(c)) { problems.add('$c: no geometry'); continue; }
    if (capitals[c] == null) { problems.add('$c: no capital'); continue; }
    if (!File('assets/flags/$c.svg').existsSync()) problems.add('$c: no flag asset');
    final ns = neighbors[c]!.where(playable.contains).toList()..sort();
    for (final n in ns) {
      if (!neighbors[n]!.contains(c)) problems.add('$c-$n: asymmetric');
    }
    countries[c] = {
      'continent': 'europe',
      'neighbors': ns,
      'near': near[c] ?? [],
      'color': color[c],
      'similarFlags': similar[c] ?? [],
    };
    (view[c] as Map)['capital'] = project(capitals[c]!);
  }
  if (problems.isNotEmpty) {
    stderr.writeln(problems.join('\n'));
    exit(1);
  }

  Directory('assets/geo').createSync(recursive: true);
  File('assets/geo/countries.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(countries));
  File('assets/geo/view_europe.json').writeAsStringSync(jsonEncode({
    'size': [_width, r1((maxY - minY) * scale)],
    'frame': frame,
    'countries': view,
  }));
  stdout.writeln('ok: ${countries.length} countries, ${view.length} shapes, '
      'max colour ${color.values.reduce(max)}, '
      '${File('assets/geo/view_europe.json').lengthSync() ~/ 1024} kB');
}

double r1(double v) => (v * 10).round() / 10;
