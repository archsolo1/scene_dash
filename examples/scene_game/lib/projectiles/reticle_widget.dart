/// The in-world lock-on reticle widget shown by a single `WidgetComponent`.
///
/// This is a visual reticle for the existing charge -> fire -> impact loop, not
/// a targeting mechanic: one widget is reused and moved onto the most relevant
/// rock by the projectiles reticle system, which drives [ReticleModel]. Charge,
/// lock, fire, impact and visibility are owned by ECS and pushed through
/// [ReticleModel.update]; only the decorative ring rotation and idle pulse phase
/// are owned by Flutter, derived independently from one elapsed visual clock.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// ECS-driven reticle state. A [ChangeNotifier] so Flutter repaints exactly when
/// charge/opacity/lock/fire/impact change — never by accident off the spin clock.
class ReticleModel extends ChangeNotifier {
  double _opacity = 0;
  double _charge01 = 0;
  bool _locked = false;
  double _firedFlash = 0;
  double _impactFlash = 0;

  /// Eased 0..1 overall visibility: 0 hides the reticle, 1 fully shows it.
  double get opacity => _opacity;

  /// 0..1 charge progress; the brackets contract as this rises.
  double get charge01 => _charge01;

  /// True at full charge: the brackets snap in and the colour goes hot.
  bool get locked => _locked;

  /// 0..1 transient flashes: a fire kick-out and an impact hit-confirmation.
  double get firedFlash => _firedFlash;
  double get impactFlash => _impactFlash;

  /// Pushes new ECS-owned state, notifying listeners only when something changed.
  void update({
    required double opacity,
    required double charge01,
    required bool locked,
    required double firedFlash,
    required double impactFlash,
  }) {
    if (_opacity == opacity &&
        _charge01 == charge01 &&
        _locked == locked &&
        _firedFlash == firedFlash &&
        _impactFlash == impactFlash) {
      return;
    }
    _opacity = opacity;
    _charge01 = charge01;
    _locked = locked;
    _firedFlash = firedFlash;
    _impactFlash = impactFlash;
    notifyListeners();
  }

  void reset() => update(
    opacity: 0,
    charge01: 0,
    locked: false,
    firedFlash: 0,
    impactFlash: 0,
  );
}

/// Logical canvas size captured for the reticle texture.
const double reticleCanvas = 220;

// The decorative clock period (a plain seconds base); rotation and pulse derive
// their own rates from it independently, so changing one never affects the other.
const double _clockSeconds = 600;
const double _ringRadPerSec = 1.4;
const double _pulseRadPerSec = 7;

class ReticleWidget extends StatefulWidget {
  const ReticleWidget(this.model, {super.key});

  final ReticleModel model;

  @override
  State<ReticleWidget> createState() => _ReticleWidgetState();
}

class _ReticleWidgetState extends State<ReticleWidget>
    with SingleTickerProviderStateMixin {
  // A long free-running clock used purely as an elapsed-seconds base.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 600),
  )..repeat();

  @override
  void dispose() {
    // The clock is owned here; the model is owned by the ECS resource and only
    // passed in, so it is not disposed here.
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: reticleCanvas,
      height: reticleCanvas,
      child: CustomPaint(
        painter: _ReticlePainter(widget.model, _clock),
        size: const Size.square(reticleCanvas),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  _ReticlePainter(this.model, this.animation)
    : super(repaint: Listenable.merge([model, animation]));

  final ReticleModel model;
  final Animation<double> animation;

  static const Color _loose = Color(0xFF35D0FF); // charging cyan
  static const Color _hot = Color(0xFFFFC83A); // locked amber
  static const Color _impact = Color(0xFFFF5A2C); // hit confirmation orange

  @override
  void paint(Canvas canvas, Size size) {
    final o = model.opacity.clamp(0.0, 1.0);
    if (o <= 0.01) return;

    final seconds = animation.value * _clockSeconds;
    final spinAngle = seconds * _ringRadPerSec;
    final pulsePhase = seconds * _pulseRadPerSec;

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 * 0.92;
    final t = model.charge01.clamp(0.0, 1.0);
    final locked = model.locked;
    final impact = model.impactFlash.clamp(0.0, 1.0);
    // Base colour goes cyan -> amber with charge; a hit pushes it toward orange
    // so the confirmation reads even mid-charge.
    var color = Color.lerp(_loose, _hot, locked ? 1.0 : t * t)!;
    color = Color.lerp(color, _impact, impact)!;

    // Outer rotating ring with tick marks (bold, opaque enough to read against a
    // bright scene).
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = color.withValues(alpha: 0.8 * o);
    canvas.drawCircle(center, r * 0.8, ringPaint);

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 1.0 * o);
    const ticks = 12;
    for (var i = 0; i < ticks; i++) {
      final a = spinAngle + i / ticks * 2 * math.pi;
      final inner = r * 0.82;
      final outer = r * 0.93;
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        tickPaint,
      );
    }

    // Brackets that contract toward the target as charge rises, kick outward on
    // fire, and snap tight at full charge.
    final bracketR = (r * (0.92 - 0.42 * t)) + model.firedFlash * r * 0.6;
    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = locked ? 6 : 4.5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 1.0 * o);
    final arc = locked ? 0.55 : 0.4; // radians half-span of each bracket
    for (var k = 0; k < 4; k++) {
      final mid = math.pi / 4 + k * math.pi / 2;
      final rect = Rect.fromCircle(center: center, radius: bracketR);
      canvas.drawArc(rect, mid - arc, arc * 2, false, bracketPaint);
    }

    // Lock-on pulse at full charge, on its own pulse rate.
    if (locked) {
      final pulse = 0.5 + 0.5 * math.sin(pulsePhase);
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _hot.withValues(alpha: 0.85 * pulse * o);
      canvas.drawCircle(center, bracketR + 8 + pulse * 8, pulsePaint);
    }

    // Centre dot.
    canvas.drawCircle(
      center,
      3.5,
      Paint()..color = color.withValues(alpha: 1.0 * o),
    );

    // Impact hit-confirmation: bold expanding rings in hot orange, not a washed
    // white disc.
    if (impact > 0.01) {
      final rExp = r * (0.45 + (1 - impact) * 0.7);
      canvas.drawCircle(
        center,
        rExp,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 + impact * 5
          ..color = _impact.withValues(alpha: impact * o),
      );
      canvas.drawCircle(
        center,
        rExp * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _impact.withValues(alpha: impact * 0.75 * o),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) {
    return oldDelegate.model != model || oldDelegate.animation != animation;
  }
}
