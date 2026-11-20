import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../../data/geo_repository.dart';
import '../../../domain/models.dart';
import '../theme.dart';

/// How one country is drawn right now.
class CountryStyle {
  const CountryStyle({
    this.stage = Stage.known,
    this.ribbon = 1,
    this.home = false,
    this.dim = false,
    this.hidden = false,
  });

  final Stage stage;

  /// Share of the border ribbon that is drawn, 0–1.
  final double ribbon;
  final bool home;
  final bool dim;

  /// Lifted out of the map (puzzle piece): only its empty slot shows.
  final bool hidden;
}

class GeoMapController extends ChangeNotifier {
  _GeoMapState? _state;

  /// Current screen pixels per map unit.
  double get scale => _state?._tc.value.getMaxScaleOnAxis() ?? 1;

  Offset toScreen(Offset mapPoint) =>
      _state == null ? mapPoint : MatrixUtils.transformPoint(_state!._tc.value, mapPoint);

  /// Animates the camera so the given countries fill the free map area.
  void focusOn(Iterable<String> codes) => _state?._focus(codes);

  void reset() => _state?._focus(const []);

  /// Country under a global screen position (drag and drop).
  String? codeAt(Offset global) => _state?._codeAtGlobal(global);
  void zoomBy(double factor) => _state?._zoom(factor);
}

/// The map. One widget for every mode; the border ribbon and fill patterns
/// are the app's signature (docs/02 §2).
class GeoMap extends StatefulWidget {
  const GeoMap({
    super.key,
    required this.view,
    required this.geo,
    required this.styleOf,
    this.labelOf,
    this.blink = const {},
    this.pins = const {},
    this.onTap,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.interactive = true,
    this.markers = true,
  });

  final GeoView view;
  final GeoRepository geo;
  final CountryStyle Function(String code) styleOf;

  /// Label text per country; null hides labels (test questions).
  final String? Function(String code)? labelOf;

  /// Countries whose outline flashes (the right answer after a miss).
  final Set<String> blink;

  /// Countries whose capital is marked.
  final Set<String> pins;
  final ValueChanged<String>? onTap;
  final GeoMapController? controller;

  /// Screen area covered by UI; the camera frames countries inside the rest.
  final EdgeInsets padding;
  final bool interactive;

  /// Draw round markers for countries too small to see. Off on overview
  /// maps, where dozens of markers would bury the continents.
  final bool markers;

  @override
  State<GeoMap> createState() => _GeoMapState();
}

class _GeoMapState extends State<GeoMap> with TickerProviderStateMixin {
  final _tc = TransformationController();
  late final _camera = AnimationController(vsync: this, duration: Tok.camera);
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Animation<Matrix4>? _move;
  Size _viewport = Size.zero;
  double _baseScale = 1;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _camera.addListener(() {
      if (_move != null) _tc.value = _move!.value;
    });
    _syncPulse();
  }

  @override
  void didUpdateWidget(GeoMap old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._state = null;
      widget.controller?._state = this;
    }
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.blink.isEmpty) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _camera.dispose();
    _pulse.dispose();
    _tc.dispose();
    super.dispose();
  }

  Rect get _inner => widget.padding.deflateRect(Offset.zero & _viewport);

  Matrix4 _fit(Rect r, {double maxScale = double.infinity}) {
    final inner = _inner;
    final s = math.min(math.min(inner.width / r.width, inner.height / r.height), maxScale);
    return Matrix4.identity()
      ..translateByDouble(inner.center.dx - r.center.dx * s, inner.center.dy - r.center.dy * s, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  void _layout(Size size) {
    if (size == _viewport) return;
    _viewport = size;
    final m = _fit(widget.view.frame);
    _baseScale = m.getMaxScaleOnAxis();
    _tc.value = m;
  }

  void _animateTo(Matrix4 target) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _tc.value = target;
      return;
    }
    _move = Matrix4Tween(begin: _tc.value, end: target)
        .animate(CurvedAnimation(parent: _camera, curve: Curves.easeOutCubic));
    _camera.forward(from: 0);
  }

  void _focus(Iterable<String> codes) {
    if (_viewport.isEmpty) return;
    final shapes = [for (final c in codes) ?widget.view.shapes[c]];
    bool giant(CountryShape s) => s.bbox.longestSide > 560;
    Rect? r;
    for (final shape in shapes) {
      // A giant neighbour (Russia, Canada) must not drag the camera across
      // the continent: it is framed only when it is the sole target.
      if (giant(shape) && shapes.length > 1) continue;
      r = r == null ? shape.bbox : r.expandToInclude(shape.bbox);
    }
    if (r == null) return _animateTo(_fit(widget.view.frame));
    // Room around the target so its neighbours stay in sight.
    final pad = (r.longestSide * 0.45).clamp(40.0, 110.0);
    _animateTo(_fit(r.inflate(pad), maxScale: _baseScale * 10));
  }

  void _zoom(double factor) {
    final s = _tc.value.getMaxScaleOnAxis();
    final next = (s * factor).clamp(_baseScale * 0.9, _baseScale * 12);
    final c = _inner.center;
    final scene = _tc.toScene(c);
    _animateTo(Matrix4.identity()
      ..translateByDouble(c.dx - scene.dx * next, c.dy - scene.dy * next, 0, 1)
      ..scaleByDouble(next, next, 1, 1));
  }

  String? _codeAtGlobal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return _hit(_tc.toScene(box.globalToLocal(global)));
  }

  /// Small countries get a round marker that is also their touch target.
  bool _isSmall(CountryShape s, double scale) => widget.markers && s.bbox.longestSide * scale < 26;

  String? _hit(Offset p) {
    final scale = _tc.value.getMaxScaleOnAxis();
    final playable = widget.view.byAreaDesc.where((s) => widget.view.playable.contains(s.code)).toList().reversed;
    for (final s in playable) {
      if (_isSmall(s, scale) && (s.bbox.center - p).distance * scale < 26) return s.code;
    }
    String? at(Offset q) {
      for (final s in playable) {
        if (s.bbox.contains(q) && s.path.contains(q)) return s.code;
      }
      return null;
    }

    final direct = at(p);
    if (direct != null) return direct;
    // Finger on sea or a border: nearest country within 16 dp.
    for (final r in [8.0, 16.0]) {
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final hit = at(p + Offset(math.cos(a), math.sin(a)) * (r / scale));
        if (hit != null) return hit;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _layout(c.biggest);
      final map = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onTap == null
            ? null
            : (d) {
                final code = _hit(d.localPosition);
                if (code != null) widget.onTap!(code);
              },
        child: RepaintBoundary(
          child: CustomPaint(
            size: widget.view.size,
            painter: _MapPainter(this, Listenable.merge([_tc, _pulse])),
          ),
        ),
      );
      return ClipRect(
        child: InteractiveViewer(
          transformationController: _tc,
          constrained: false,
          minScale: _baseScale * 0.9,
          maxScale: _baseScale * 12,
          boundaryMargin: const EdgeInsets.all(240),
          panEnabled: widget.interactive,
          scaleEnabled: widget.interactive,
          child: map,
        ),
      );
    });
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.s, Listenable repaint) : w = s.widget, super(repaint: repaint);
  final _GeoMapState s;
  final GeoMap w;

  static final _labels = <String, TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = s._tc.value.getMaxScaleOnAxis();
    final px = 1 / scale; // one screen pixel in map units
    final visible = Rect.fromPoints(
      s._tc.toScene(Offset.zero),
      s._tc.toScene(Offset(s._viewport.width, s._viewport.height)),
    ).inflate(20 * px);
    // Pattern step snaps to powers of two so dots and hatching hold still
    // between zoom levels instead of swimming.
    final step = 9 * math.pow(2, (math.log(px) / math.ln2).round()).toDouble();

    final fill = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    for (final shape in w.view.byAreaDesc) {
      if (!shape.bbox.overlaps(visible)) continue;
      if (!w.view.playable.contains(shape.code)) {
        canvas.drawPath(shape.path, fill..color = Tok.land);
        canvas.drawPath(shape.path, line..color = Tok.paper..strokeWidth = 1.5 * px);
        continue;
      }
      final st = w.styleOf(shape.code);
      if (st.hidden) {
        canvas.drawPath(shape.path, fill..color = Color.lerp(Tok.sea, Tok.ink, 0.18)!);
        canvas.drawPath(shape.path, line..color = Tok.paper..strokeWidth = 2 * px);
        continue;
      }
      if (s._isSmall(shape, scale)) continue; // drawn as a marker below
      _country(canvas, shape, st, px, step, visible, fill, line);
    }

    for (final shape in w.view.byAreaDesc) {
      if (!w.view.playable.contains(shape.code) || !shape.bbox.overlaps(visible)) continue;
      final st = w.styleOf(shape.code);
      final small = s._isSmall(shape, scale);
      if (small && !st.hidden) _marker(canvas, shape, st, px, fill, line);
      if (w.blink.contains(shape.code)) {
        final on = s._pulse.value > 0.5;
        final p = small ? (Path()..addOval(Rect.fromCircle(center: shape.bbox.center, radius: 15 * px))) : shape.path;
        canvas.drawPath(p, line..color = on ? Tok.ink : Tok.paper..strokeWidth = 5 * px);
      }
      if (st.hidden) continue; // an empty puzzle slot: outline only
      if (st.home && !small) _house(canvas, shape.label, px);
      if (w.pins.contains(shape.code) && shape.capital != null) _pin(canvas, shape.capital!, px, fill, line);
      final text = w.labelOf?.call(shape.code);
      if (text != null && !small) _label(canvas, shape, text, st, scale);
    }
  }

  (Color, Color) _colors(String code, CountryStyle st) {
    var tint = st.home ? Tok.homeTint : Tok.tints[w.geo.tint[code]!];
    var ribbon = st.home ? Tok.homeRibbon : Tok.ribbons[w.geo.tint[code]!];
    if (st.dim) {
      tint = Color.lerp(tint, Tok.sea, 0.6)!;
      ribbon = Color.lerp(ribbon, Tok.sea, 0.6)!;
    }
    return (tint, ribbon);
  }

  void _country(Canvas canvas, CountryShape shape, CountryStyle st, double px, double step, Rect visible, Paint fill,
      Paint line) {
    final (tint, ribbon) = _colors(shape.code, st);
    final paper = st.dim ? Color.lerp(Tok.paper, Tok.sea, 0.6)! : Tok.paper;
    canvas.drawPath(shape.path, fill..color = st.stage == Stage.known ? tint : paper);

    canvas.save();
    canvas.clipPath(shape.path);
    final box = shape.bbox.intersect(visible);
    if (st.stage == Stage.fresh) {
      final dots = <Offset>[];
      for (var y = (box.top / step).floor() * step; y < box.bottom; y += step) {
        for (var x = (box.left / step).floor() * step; x < box.right; x += step) {
          dots.add(Offset(x, y));
        }
      }
      canvas.drawPoints(
          PointMode.points,
          dots,
          Paint()
            ..color = tint
            ..strokeWidth = step * 0.5
            ..strokeCap = StrokeCap.round);
    } else if (st.stage == Stage.learning) {
      final hatch = Paint()
        ..color = tint
        ..strokeWidth = step * 0.45;
      final h = box.height;
      for (var x = ((box.left - h) / step).floor() * step; x < box.right; x += step) {
        canvas.drawLine(Offset(x, box.bottom), Offset(x + h, box.top), hatch);
      }
    }
    // Border ribbon: an inner band, so neighbours' ribbons never overlap.
    final width = math.min((st.home ? 14 : 9) * px, math.sqrt(shape.area) * 0.16);
    canvas.drawPath(shape.path, line..color = ribbon.withValues(alpha: 0.55)..strokeWidth = 4 * px);
    final frac = st.stage == Stage.unseen ? 0.0 : st.ribbon.clamp(0.0, 1.0);
    if (frac > 0) {
      line
        ..color = ribbon
        ..strokeWidth = width * 2;
      if (frac >= 1) {
        canvas.drawPath(shape.path, line);
      } else {
        for (final m in shape.mainRing.computeMetrics()) {
          canvas.drawPath(m.extractPath(0, m.length * frac), line);
        }
      }
    }
    canvas.restore();
    canvas.drawPath(shape.path, line..color = paper..strokeWidth = 2 * px);
  }

  void _marker(Canvas canvas, CountryShape shape, CountryStyle st, double px, Paint fill, Paint line) {
    final (tint, ribbon) = _colors(shape.code, st);
    final c = shape.bbox.center, r = 13 * px;
    canvas.drawCircle(c, r, fill..color = st.stage == Stage.unseen ? Tok.paper : tint);
    canvas.drawCircle(c, r - 2 * px, line..color = ribbon..strokeWidth = 4 * px);
    canvas.drawCircle(c, r, line..color = Tok.paper..strokeWidth = 2 * px);
    if (st.home) _house(canvas, c, px * 0.7);
  }

  void _house(Canvas canvas, Offset at, double px) {
    final p = Path()
      ..moveTo(-9, 1)
      ..lineTo(0, -8)
      ..lineTo(9, 1)
      ..lineTo(9, 10)
      ..lineTo(-9, 10)
      ..close();
    canvas.save();
    canvas.translate(at.dx, at.dy - 20 * px);
    canvas.scale(px);
    canvas.drawPath(p, Paint()..color = Tok.paper);
    canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..color = Tok.ink);
    canvas.restore();
  }

  void _pin(Canvas canvas, Offset at, double px, Paint fill, Paint line) {
    canvas.drawCircle(at, 7 * px, fill..color = Tok.paper);
    canvas.drawCircle(at, 7 * px, line..color = Tok.ink..strokeWidth = 2.5 * px);
    canvas.drawCircle(at, 2.5 * px, fill..color = Tok.ink);
  }

  void _label(Canvas canvas, CountryShape shape, String text, CountryStyle st, double scale) {
    final size = st.home ? 19.0 : 16.0;
    final tp = _labels.putIfAbsent(
        '$text|$size',
        () => TextPainter(
              text: TextSpan(text: text.toUpperCase(), style: Tok.mapLabel(size)),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: 190));
    // Label detail follows zoom: a name appears once its country can hold it.
    if (shape.bbox.width * scale < tp.width * 0.85 || shape.bbox.height * scale < tp.height * 1.4) return;
    canvas.save();
    canvas.translate(shape.label.dx, shape.label.dy);
    canvas.scale(1 / scale);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MapPainter old) => true;
}
