// Builds map assets from Natural Earth data. Run from the repo root:
//   dart run tool/build_geo.dart
// Needs Node (npx mapshaper). Raw downloads are cached in tool/raw/ (gitignored).
//
// Boundaries follow Natural Earth's "Poland point of view" file, which
// settles disputed areas the way Polish maps draw them.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _src = 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson';
const _width = 2000.0;
// Rings smaller than this (px² on the 2000-wide canvas) are dropped unless
// they are a playable country's largest ring.
const _minRingArea = 5.0;

typedef Pt = List<double>;
typedef Ring = List<Pt>;

Future<void> main() async {
  final raw = Directory('tool/raw')..createSync(recursive: true);
  for (final (file, name) in [
    ('countries_pol.geojson', 'ne_10m_admin_0_countries_pol.geojson'),
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
  final continents = (ov['continents'] as Map).map((k, v) => MapEntry(k as String, (v as List).cast<String>()));
  final continentOf = {for (final e in continents.entries) for (final c in e.value) c: e.key};
  final playable = continentOf.keys.toSet();
  final merge = (ov['merge'] as Map).cast<String, String>();
  final drop = (ov['drop'] as List).cast<String>();

  // Topology-preserving simplification: shared borders stay shared.
  final codeExpr = 'code=(ISO_A2_EH!="-99"?ISO_A2_EH.toLowerCase():ADM0_A3.toLowerCase());'
      '${merge.entries.map((e) => 'if(code=="${e.key}")code="${e.value}";').join()}';
  final ms = await Process.run('npx', [
    '-y', 'mapshaper', '${raw.path}/countries_pol.geojson',
    '-filter-fields', 'ISO_A2_EH,ADM0_A3',
    '-each', codeExpr,
    '-filter', drop.map((d) => 'code!="$d"').join(' && '),
    '-simplify', '2.2%', 'keep-shapes',
    '-dissolve', 'code',
    '-clean',
    '-o', 'precision=0.001', '${raw.path}/world.geojson',
  ]);
  if (ms.exitCode != 0) throw 'mapshaper failed: ${ms.stderr}';

  final geo = jsonDecode(File('${raw.path}/world.geojson').readAsStringSync());
  // code -> polygons -> rings in lon/lat (first ring of a polygon is the outer one)
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

  // Capitals: Natural Earth lists several for some countries; the content
  // file names the one we teach, so match on that.
  final en = jsonDecode(File('assets/i18n/geo_en.json').readAsStringSync()) as Map<String, dynamic>;
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  final places = jsonDecode(File('${raw.path}/places.geojson').readAsStringSync());
  final capitals = <String, Pt>{};
  final capitalNote = <String>[];
  for (final f in places['features']) {
    final p = f['properties'];
    if (!(p['FEATURECLA'] as String).startsWith('Admin-0 capital')) continue;
    final code = (p['ISO_A2'] as String).toLowerCase();
    final c = f['geometry']['coordinates'];
    final pt = [(c[0] as num).toDouble(), (c[1] as num).toDouble()];
    final want = norm((en[code]?['capital'] as String?) ?? '');
    final exact = want.isNotEmpty && (norm(p['NAME'] as String) == want || norm((p['NAME_EN'] as String?) ?? '') == want);
    if (exact) {
      capitals[code] = pt;
      capitalNote.remove(code);
    } else if (!capitals.containsKey(code)) {
      capitals[code] = pt;
      capitalNote.add(code);
    }
  }
  (ov['capitals'] as Map).forEach((k, v) {
    capitals[k as String] = (v as List).cast<num>().map((e) => e.toDouble()).toList();
    capitalNote.remove(k);
  });

  // Centre of each country's largest ring, for distances between islands.
  double ringArea(Ring r) {
    var s = 0.0;
    for (var i = 0; i + 1 < r.length; i++) {
      s += r[i][0] * r[i + 1][1] - r[i + 1][0] * r[i][1];
    }
    return s / 2;
  }

  final centre = <String, Pt>{};
  shapes.forEach((code, polys) {
    final big = polys.map((p) => p.first).reduce((a, b) => ringArea(a).abs() >= ringArea(b).abs() ? a : b);
    centre[code] = [big.map((c) => c[0]).reduce((a, b) => a + b) / big.length, big.map((c) => c[1]).reduce((a, b) => a + b) / big.length];
  });
  double dist(Pt a, Pt b) {
    final p1 = a[1] * pi / 180, p2 = b[1] * pi / 180, dl = (a[0] - b[0]) * pi / 180;
    return acos((sin(p1) * sin(p2) + cos(p1) * cos(p2) * cos(dl)).clamp(-1.0, 1.0));
  }

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

  final nearOv = (ov['near'] as Map).cast<String, dynamic>();
  final similar = (ov['similarFlags'] as Map).cast<String, dynamic>();
  final problems = <String>[];
  final countries = <String, dynamic>{};
  for (final c in playable.toList()..sort()) {
    if (!shapes.containsKey(c)) { problems.add('$c: no geometry'); continue; }
    if (capitals[c] == null) problems.add('$c: no capital');
    if (!File('assets/flags/$c.svg').existsSync()) problems.add('$c: no flag asset');
    final ns = neighbors[c]!.where(playable.contains).toList()..sort();
    // Islands: the three closest countries of the same continent stand in
    // for neighbours.
    var near = (nearOv[c] as List?)?.cast<String>() ?? const <String>[];
    if (ns.isEmpty && near.isEmpty) {
      final same = continents[continentOf[c]]!.where((o) => o != c && shapes.containsKey(o)).toList()
        ..sort((a, b) => dist(centre[c]!, centre[a]!).compareTo(dist(centre[c]!, centre[b]!)));
      near = same.take(3).toList();
    }
    countries[c] = {
      'continent': continentOf[c],
      'neighbors': ns,
      'near': near,
      'color': color[c],
      'similarFlags': similar[c] ?? [],
    };
  }

  Directory('assets/geo').createSync(recursive: true);
  final labels = (ov['labels'] as Map).cast<String, dynamic>();
  final views = (ov['views'] as Map).cast<String, dynamic>();
  for (final name in views.keys) {
    final cfg = views[name] as Map<String, dynamic>;
    final world = cfg['projection'] == 'equal_earth';
    final inView = world ? playable : continents[name]!.toSet();
    late final Pt Function(Pt) proj;
    if (world) {
      proj = _equalEarth;
    } else {
      final c = (cfg['center'] as List).cast<num>();
      proj = (p) => _laea(p, c[0].toDouble(), c[1].toDouble());
    }
    // Scale so the frame is _width wide.
    final framePts = world
        ? [for (final polys in shapes.values) for (final p in polys) ...p.first.map(proj)]
        : [for (final p in cfg['frame'] as List) proj((p as List).cast<num>().map((e) => e.toDouble()).toList())];
    final fx = framePts.map((p) => p[0]), fy = framePts.map((p) => p[1]);
    final minX = fx.reduce(min), maxX = fx.reduce(max), minY = fy.reduce(min), maxY = fy.reduce(max);
    final scale = _width / (maxX - minX);
    Pt project(Pt lonLat) {
      final q = proj(lonLat);
      return [(q[0] - minX) * scale, (q[1] - minY) * scale];
    }

    final height = (maxY - minY) * scale;
    // Geometry is cut a little outside the frame so panning shows land, not a cliff.
    final padX = world ? 0.0 : _width * 0.22, padY = world ? 0.0 : height * 0.22;
    final clip = [-padX, -padY, _width + padX, height + padY];

    final out = <String, dynamic>{};
    shapes.forEach((code, polys) {
      // Outer rings only: enclaves are drawn on top of their host.
      var rings = <Ring>[];
      for (final p in polys) {
        if (!world && p.first.every((c) => _far(c, cfg))) continue; // other side of the globe
        var r = p.first.map(project).toList();
        if (!world) r = _clipRing(r, clip);
        if (r.length >= 4) rings.add(r);
      }
      if (rings.isEmpty) {
        if (inView.contains(code)) problems.add('$name: $code falls outside the frame');
        return;
      }
      rings.sort((a, b) => ringArea(b).abs().compareTo(ringArea(a).abs()));
      final keepTiny = inView.contains(code);
      final minArea = world ? 2.0 : _minRingArea;
      rings = [
        if (keepTiny || ringArea(rings.first).abs() >= minArea) rings.first,
        ...rings.skip(1).where((r) => ringArea(r).abs() >= minArea),
      ];
      if (rings.isEmpty) return;
      // Largest ring: clockwise on screen, starting at its northernmost point,
      // so the border ribbon grows clockwise from the north.
      var main = rings.first.sublist(0, rings.first.length - 1);
      if (ringArea([...main, main.first]) < 0) main = main.reversed.toList();
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
      Pt label;
      final lo = labels[code];
      final lp = lo == null ? null : project((lo as List).cast<num>().map((e) => e.toDouble()).toList());
      if (lp != null && lp[0] > clip[0] && lp[0] < clip[2] && lp[1] > clip[1] && lp[1] < clip[3]) {
        label = lp;
      } else {
        var cx = 0.0, cy = 0.0;
        final r = rings.first, a = ringArea(r);
        for (var i = 0; i + 1 < r.length; i++) {
          final cr = r[i][0] * r[i + 1][1] - r[i + 1][0] * r[i][1];
          cx += (r[i][0] + r[i + 1][0]) * cr;
          cy += (r[i][1] + r[i + 1][1]) * cr;
        }
        label = a.abs() < 1e-6 ? [r[0][0], r[0][1]] : [cx / (6 * a), cy / (6 * a)];
      }
      final cap = inView.contains(code) && capitals[code] != null ? project(capitals[code]!) : null;
      out[code] = {
        'rings': [for (final r in rings) [for (final c in r) ...[r1(c[0]), r1(c[1])]]],
        'bbox': b.map(r1).toList(),
        'label': label.map(r1).toList(),
        'area': r1(rings.fold(0.0, (s, r) => s + ringArea(r).abs())),
        if (cap != null) 'capital': cap.map(r1).toList(),
      };
    });
    File('assets/geo/view_$name.json').writeAsStringSync(jsonEncode({
      'size': [_width, r1(height)],
      'frame': [0, 0, _width, r1(height)],
      'playable': (inView.toList()..sort()),
      'countries': out,
    }));
    stdout.writeln('$name: ${out.length} shapes, ${File('assets/geo/view_$name.json').lengthSync() ~/ 1024} kB');
  }

  if (problems.isNotEmpty) {
    stderr.writeln(problems.join('\n'));
    exit(1);
  }
  File('assets/geo/countries.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(countries));
  stdout.writeln('ok: ${countries.length} countries, max colour ${color.values.reduce(max)}');
  if (capitalNote.isNotEmpty) stdout.writeln('capital not matched by name (first listed used): ${capitalNote.where(playable.contains).join(' ')}');
}

double r1(double v) => (v * 10).round() / 10;

/// Lambert azimuthal equal-area, y down.
Pt _laea(Pt p, double lon0, double lat0) {
  var dl = p[0] - lon0;
  while (dl > 180) { dl -= 360; }
  while (dl < -180) { dl += 360; }
  final ph = p[1] * pi / 180, l = dl * pi / 180, p0 = lat0 * pi / 180;
  final d = 1 + sin(p0) * sin(ph) + cos(p0) * cos(ph) * cos(l);
  final k = sqrt(2 / max(d, 1e-9));
  return [k * cos(ph) * sin(l), -k * (cos(p0) * sin(ph) - sin(p0) * cos(ph) * cos(l))];
}

/// More than 100° from the view centre: not part of this continent's map.
bool _far(Pt p, Map<String, dynamic> cfg) {
  final c = (cfg['center'] as List).cast<num>();
  final p1 = p[1] * pi / 180, p2 = c[1] * pi / 180, dl = (p[0] - c[0]) * pi / 180;
  return acos((sin(p1) * sin(p2) + cos(p1) * cos(p2) * cos(dl)).clamp(-1.0, 1.0)) > 100 * pi / 180;
}

/// Equal Earth (equal-area world projection), y down.
Pt _equalEarth(Pt p) {
  const a1 = 1.340264, a2 = -0.081106, a3 = 0.000893, a4 = 0.003796;
  final m = sqrt(3) / 2;
  final t = asin(m * sin(p[1] * pi / 180)), t2 = t * t, t6 = t2 * t2 * t2;
  final x = (p[0] * pi / 180) * cos(t) / (m * (a1 + 3 * a2 * t2 + t6 * (7 * a3 + 9 * a4 * t2)));
  final y = t * (a1 + a2 * t2 + t6 * (a3 + a4 * t2));
  return [x, -y];
}

/// Sutherland–Hodgman clip of a closed ring to a rectangle [l, t, r, b].
Ring _clipRing(Ring ring, List<double> c) {
  var pts = ring.sublist(0, ring.length - 1);
  bool inside(Pt p, int e) => switch (e) { 0 => p[0] >= c[0], 1 => p[0] <= c[2], 2 => p[1] >= c[1], _ => p[1] <= c[3] };
  Pt cross(Pt a, Pt b, int e) {
    if (e < 2) {
      final x = e == 0 ? c[0] : c[2];
      return [x, a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0])];
    }
    final y = e == 2 ? c[1] : c[3];
    return [a[0] + (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]), y];
  }

  for (var e = 0; e < 4 && pts.isNotEmpty; e++) {
    final out = <Pt>[];
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      if (inside(b, e)) {
        if (!inside(a, e)) out.add(cross(a, b, e));
        out.add(b);
      } else if (inside(a, e)) {
        out.add(cross(a, b, e));
      }
    }
    pts = out;
  }
  return pts.length < 3 ? [] : [...pts, pts.first];
}
