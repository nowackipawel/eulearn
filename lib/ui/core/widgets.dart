import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/geo_repository.dart';
import '../../domain/models.dart';
import 'theme.dart';

enum ButtonKind { plain, primary, voice }

/// The one button. Flat, ink outline; colours invert while pressed.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    this.icon,
    this.label,
    required this.onTap,
    this.kind = ButtonKind.plain,
    this.semanticLabel,
    this.fontSize = 24,
    this.child,
  });

  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  final ButtonKind kind;
  final String? semanticLabel;
  final double fontSize;

  /// Custom content instead of icon + label (flags, country shapes).
  final Widget? child;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (widget.kind) {
      ButtonKind.plain => (Tok.paper, Tok.ink),
      ButtonKind.primary => (Tok.ink, Tok.paper),
      ButtonKind.voice => (Tok.voice, Tok.ink),
    };
    final enabled = widget.onTap != null;
    final back = _down ? (widget.kind == ButtonKind.primary ? Tok.paper : Tok.ink) : bg;
    final fore = _down ? (widget.kind == ButtonKind.primary ? Tok.ink : Tok.paper) : fg;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onTap!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: AnimatedContainer(
            duration: Tok.press,
            constraints: const BoxConstraints(minWidth: Tok.touch, minHeight: Tok.touch),
            padding: EdgeInsets.symmetric(horizontal: widget.label == null && widget.child == null ? 0 : 18, vertical: 8),
            decoration: BoxDecoration(
              color: back,
              borderRadius: BorderRadius.circular(Tok.radius),
              border: Border.all(color: Tok.ink, width: Tok.stroke),
            ),
            child: widget.child ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) Icon(widget.icon, color: fore, size: 32),
                    if (widget.icon != null && widget.label != null) const SizedBox(width: 10),
                    if (widget.label != null)
                      Flexible(
                        child: Text(widget.label!,
                            textAlign: TextAlign.center, style: Tok.display(widget.fontSize, color: fore)),
                      ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

/// White ruled box: legend, cards, answer panels.
class AppPanel extends StatelessWidget {
  const AppPanel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color = Tok.paper});
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Tok.panelRadius),
          border: Border.all(color: Tok.ink, width: Tok.stroke),
        ),
        child: child,
      );
}

/// Always yellow, always the same: "say it". [tag] names the language (PL/EN),
/// never a flag — flags mean countries here.
class SpeakerButton extends StatelessWidget {
  const SpeakerButton({super.key, required this.onTap, this.tag, required this.semanticLabel});
  final VoidCallback onTap;
  final String? tag;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => AppButton(
        kind: ButtonKind.voice,
        icon: Icons.volume_up_rounded,
        label: tag,
        fontSize: 20,
        semanticLabel: tag == null ? semanticLabel : '$semanticLabel $tag',
        onTap: onTap,
      );
}

class FlagImage extends StatelessWidget {
  const FlagImage(this.code, {super.key, this.height = 72});
  final String code;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: height * 4 / 3,
        decoration: BoxDecoration(border: Border.all(color: Tok.ink, width: 2)),
        child: SvgPicture.asset('assets/flags/$code.svg', fit: BoxFit.cover),
      );
}

/// Swatch showing one fill pattern, for the legend.
class StageSwatch extends StatelessWidget {
  const StageSwatch(this.stage, {super.key, this.home = false});
  final Stage stage;
  final bool home;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 34, height: 22, child: CustomPaint(painter: _SwatchPainter(stage, home)));
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.stage, this.home);
  final Stage stage;
  final bool home;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final tint = home ? Tok.homeTint : Tok.tints[1];
    final ribbon = home ? Tok.homeRibbon : Tok.ribbons[1];
    canvas.drawRect(r, Paint()..color = stage == Stage.known ? tint : Tok.paper);
    canvas.save();
    canvas.clipRect(r);
    if (stage == Stage.fresh) {
      final p = Paint()..color = tint;
      for (var y = 3.0; y < size.height; y += 6) {
        for (var x = 3.0; x < size.width; x += 6) {
          canvas.drawCircle(Offset(x, y), 1.7, p);
        }
      }
    } else if (stage == Stage.learning) {
      final p = Paint()
        ..color = tint
        ..strokeWidth = 3;
      for (var x = -size.height; x < size.width; x += 7) {
        canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
      }
    }
    canvas.restore();
    canvas.drawRect(
        r.deflate(1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = home ? 4 : 3
          ..color = stage == Stage.unseen ? ribbon.withValues(alpha: 0.55) : ribbon);
  }

  @override
  bool shouldRepaint(_SwatchPainter old) => old.stage != stage || old.home != home;
}

/// One country drawn alone, with its fill and border ribbon: passport cells,
/// puzzle pieces, country card.
class CountryThumb extends StatelessWidget {
  const CountryThumb({
    super.key,
    required this.shape,
    required this.tint,
    required this.ribbonColor,
    this.stage = Stage.known,
    this.ribbon = 1,
    this.size = const Size(72, 56),
  });

  final CountryShape shape;
  final Color tint;
  final Color ribbonColor;
  final Stage stage;
  final double ribbon;
  final Size size;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: size,
        child: CustomPaint(painter: _ThumbPainter(shape, tint, ribbonColor, stage, ribbon)),
      );
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.shape, this.tint, this.ribbonColor, this.stage, this.ribbon);
  final CountryShape shape;
  final Color tint, ribbonColor;
  final Stage stage;
  final double ribbon;

  @override
  void paint(Canvas canvas, Size size) {
    // Frame the main ring, so far-flung islands do not shrink the mainland.
    final b = shape.mainRing.getBounds();
    final s = math.min(size.width / b.width, size.height / b.height) * 0.9;
    canvas.translate(size.width / 2 - b.center.dx * s, size.height / 2 - b.center.dy * s);
    canvas.scale(s);
    final px = 1 / s;
    final p = shape.mainRing;
    canvas.drawPath(p, Paint()..color = stage == Stage.unseen ? Tok.paper : tint);
    canvas.save();
    canvas.clipPath(p);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(p, line..color = ribbonColor.withValues(alpha: 0.55)..strokeWidth = 4 * px);
    final frac = stage == Stage.unseen ? 0.0 : ribbon.clamp(0.0, 1.0);
    if (frac > 0) {
      line
        ..color = ribbonColor
        ..strokeWidth = math.min(10 * px, b.shortestSide * 0.3);
      for (final m in p.computeMetrics()) {
        canvas.drawPath(frac >= 1 ? p : m.extractPath(0, m.length * frac), line);
      }
    }
    canvas.restore();
    canvas.drawPath(p, line..color = Tok.ink..strokeWidth = 2 * px);
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.shape != shape || old.stage != stage || old.ribbon != ribbon || old.tint != tint;
}

/// Round progress as printed marks: done, missed, current, to do.
class ProgressStrip extends StatelessWidget {
  const ProgressStrip({super.key, required this.total, required this.done, this.missed = const {}});
  final int total;
  final int done;
  final Set<int> missed;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$done / $total',
        child: Row(children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Container(
                height: 14,
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 5),
                decoration: BoxDecoration(
                  color: i >= done ? Tok.paper : (missed.contains(i) ? Tok.miss : Tok.signal),
                  border: Border.all(color: Tok.ink, width: i == done ? 3 : 2),
                ),
              ),
            ),
        ]),
      );
}

enum MascotMood { idle, happy }

/// The guide: a stork, the bird that crosses borders every year. Drawn in
/// code so it can move without animation files. Its beak opens while the
/// narrator speaks.
class Mascot extends StatefulWidget {
  const Mascot({super.key, required this.talking, this.mood = MascotMood.idle, this.size = 96});
  final ValueListenable<bool> talking;
  final MascotMood mood;
  final double size;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final _beak = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

  @override
  void initState() {
    super.initState();
    widget.talking.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (old.talking != widget.talking) {
      old.talking.removeListener(_sync);
      widget.talking.addListener(_sync);
    }
  }

  void _sync() {
    if (!mounted) return;
    if (widget.talking.value) {
      _beak.repeat(reverse: true);
    } else {
      _beak.animateTo(0);
    }
  }

  @override
  void dispose() {
    widget.talking.removeListener(_sync);
    _beak.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: widget.size,
          height: widget.size * 1.2,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: widget.mood == MascotMood.happy ? 1 : 0),
            duration: const Duration(milliseconds: 300),
            builder: (_, lift, _) => CustomPaint(painter: _StorkPainter(_beak, lift)),
          ),
        ),
      );
}

class _StorkPainter extends CustomPainter {
  _StorkPainter(this.beak, this.lift) : super(repaint: beak);
  final Animation<double> beak;

  /// 0–1: the neck stretches up when the stork is pleased.
  final double lift;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    // Faces right, towards the map.
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    final ink = Paint()
      ..color = Tok.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final white = Paint()..color = Tok.paper;
    final red = Paint()..color = Tok.signal;
    final up = lift * 8;

    // Legs.
    final leg = Paint()
      ..color = Tok.signal
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(48, 88), const Offset(46, 114), leg);
    canvas.drawLine(const Offset(60, 88), const Offset(62, 114), leg);
    canvas.drawLine(const Offset(46, 114), const Offset(38, 114), leg);
    canvas.drawLine(const Offset(62, 114), const Offset(54, 114), leg);

    // Neck (behind the body).
    final neck = Path()
      ..moveTo(36, 70)
      ..quadraticBezierTo(22, 52, 30, 30 - up);
    canvas.drawPath(neck, Paint()
      ..color = Tok.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round);
    canvas.drawPath(neck, Paint()
      ..color = Tok.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round);

    // Body and wing.
    final body = Rect.fromCenter(center: const Offset(54, 72), width: 54, height: 36);
    canvas.drawOval(body, white);
    canvas.drawOval(body, ink);
    final wing = Path()
      ..moveTo(46, 62)
      ..quadraticBezierTo(70, 56, 82, 74)
      ..quadraticBezierTo(66, 86, 50, 80)
      ..close();
    canvas.drawPath(wing, Paint()..color = Tok.ink);

    // Head.
    final head = Offset(30, 26 - up);
    // Beak: the lower half drops while talking.
    final open = beak.value * 0.32 + lift * 0.2;
    final upper = Path()
      ..moveTo(head.dx - 8, head.dy - 3)
      ..lineTo(head.dx - 38, head.dy + 3)
      ..lineTo(head.dx - 8, head.dy + 3)
      ..close();
    canvas.drawPath(upper, red);
    canvas.save();
    canvas.translate(head.dx - 8, head.dy + 3);
    canvas.rotate(-open);
    canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(-30, 1)
          ..lineTo(0, 5)
          ..close(),
        red);
    canvas.restore();
    canvas.drawCircle(head, 11, white);
    canvas.drawCircle(head, 11, ink);
    canvas.drawCircle(head + const Offset(-3, -2), 2.2, Paint()..color = Tok.ink);
  }

  @override
  bool shouldRepaint(_StorkPainter old) => old.lift != lift;
}
