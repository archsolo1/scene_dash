import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_state.dart';

/// Plain Flutter HUD over the scene. Scene-Dash deliberately does not own UI:
/// this widget reads [GameState] (via the [HudState] snapshot) and writes touch
/// intent through callbacks.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.hud,
    required this.onLeftChanged,
    required this.onRightChanged,
    required this.onFireChanged,
    required this.onFireCanceled,
    required this.onRestart,
  });

  final HudState hud;
  final ValueChanged<bool> onLeftChanged;
  final ValueChanged<bool> onRightChanged;
  final ValueChanged<bool> onFireChanged;
  final VoidCallback onFireCanceled;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameHudSnapshot>(
      valueListenable: hud,
      builder: (context, snapshot, _) {
        final lost = snapshot.status == GameStatus.lost;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 24,
              left: 24,
              child: IgnorePointer(
                child: _shadowed(
                  'Survived: ${snapshot.survivedLabel}s',
                  fontSize: 22,
                ),
              ),
            ),
            Positioned(
              top: 24,
              right: 24,
              child: IgnorePointer(
                child: _shadowed('FPS: ${snapshot.fps}', fontSize: 18),
              ),
            ),
            if (snapshot.shieldActive)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: IgnorePointer(child: _ShieldBadge(snapshot: snapshot)),
              ),
            if (!lost)
              _Controls(
                snapshot: snapshot,
                onLeftChanged: onLeftChanged,
                onRightChanged: onRightChanged,
                onFireChanged: onFireChanged,
                onFireCanceled: onFireCanceled,
              ),
            if (lost) _GameOverPanel(snapshot: snapshot, onRestart: onRestart),
          ],
        );
      },
    );
  }

  static Widget shadowed(String text, {required double fontSize}) {
    return _shadowed(text, fontSize: fontSize);
  }

  static Widget _shadowed(String text, {required double fontSize}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        shadows: const [
          Shadow(blurRadius: 4, color: Colors.black, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

/// Movement grouped bottom-left; a large fire control bottom-right.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.snapshot,
    required this.onLeftChanged,
    required this.onRightChanged,
    required this.onFireChanged,
    required this.onFireCanceled,
  });

  final GameHudSnapshot snapshot;
  final ValueChanged<bool> onLeftChanged;
  final ValueChanged<bool> onRightChanged;
  final ValueChanged<bool> onFireChanged;
  final VoidCallback onFireCanceled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HoldButton(
                  icon: Icons.arrow_left_rounded,
                  semanticLabel: 'Move left',
                  onChanged: onLeftChanged,
                ),
                const SizedBox(width: 16),
                _HoldButton(
                  icon: Icons.arrow_right_rounded,
                  semanticLabel: 'Move right',
                  onChanged: onRightChanged,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _FireControl(
              snapshot: snapshot,
              onChanged: onFireChanged,
              onCanceled: onFireCanceled,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.icon,
    required this.semanticLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String semanticLabel;
  final ValueChanged<bool> onChanged;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _held = false;

  void _setHeld(bool value) {
    if (_held == value) return;
    setState(() => _held = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setHeld(true),
        onTapUp: (_) => _setHeld(false),
        onTapCancel: () => _setHeld(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: _held ? Colors.white30 : Colors.black38,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 54),
        ),
      ),
    );
  }
}

/// Hold-capable fire control. A press starts holding; release fires (burst or
/// charged, decided by the ECS blaster); `onTapCancel` cancels rather than
/// fires. The ring shows live charge while held and cooldown recovery while
/// cooling, both read from the immutable snapshot — never the mutable Blaster.
class _FireControl extends StatefulWidget {
  const _FireControl({
    required this.snapshot,
    required this.onChanged,
    required this.onCanceled,
  });

  final GameHudSnapshot snapshot;
  final ValueChanged<bool> onChanged;
  final VoidCallback onCanceled;

  @override
  State<_FireControl> createState() => _FireControlState();
}

class _FireControlState extends State<_FireControl> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  String get _semanticLabel {
    final s = widget.snapshot;
    if (s.blasterCharging) {
      return 'Charging ${(s.blasterCharge01 * 100).round()} percent';
    }
    if (s.blasterCooldown01 > 0 && !s.blasterReady) {
      return 'Blaster cooling down';
    }
    return 'Blaster ready';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    final cooling = s.blasterCooldown01 > 0 && !s.blasterCharging;
    final fullCharge = s.blasterCharging && s.blasterCharge01 >= 0.999;

    // The ring shows charge while held and a faint ready ring otherwise; the
    // cooldown is shown separately as a vertical recovery meter above the button.
    final double ringProgress;
    final Color ringColor;
    if (s.blasterCharging) {
      ringProgress = s.blasterCharge01;
      ringColor = fullCharge
          ? const Color(0xFFFFE16A)
          : const Color(0xFF53E6FF);
    } else {
      ringProgress = 1;
      ringColor = const Color(0x5553E6FF);
    }

    final dim = cooling && !_pressed;
    final fireButton = Semantics(
      label: _semanticLabel,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _setPressed(true);
          widget.onChanged(true);
        },
        onTapUp: (_) {
          _setPressed(false);
          widget.onChanged(false);
        },
        onTapCancel: () {
          _setPressed(false);
          widget.onCanceled();
        },
        child: SizedBox(
          width: 116,
          height: 116,
          child: CustomPaint(
            painter: _FireRingPainter(
              progress: ringProgress.clamp(0.0, 1.0),
              color: ringColor,
              glow: fullCharge,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: _pressed
                      ? Colors.white30
                      : (dim ? Colors.black54 : Colors.black38),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: fullCharge
                        ? const Color(0xFFFFE16A)
                        : Colors.white54,
                    width: fullCharge ? 2.5 : 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: dim ? Colors.white54 : Colors.white,
                  size: 46,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 54,
          width: 18,
          child: cooling
              ? _CooldownBar(recovery: 1 - s.blasterCooldown01)
              : null,
        ),
        const SizedBox(height: 6),
        fireButton,
      ],
    );
  }
}

/// A vertical recovery meter shown above the fire button while the blaster cools down:
/// empty right after firing, full when the blaster is ready again.
class _CooldownBar extends StatelessWidget {
  const _CooldownBar({required this.recovery});

  /// 0..1 recovery progress (0 just after firing, 1 when ready).
  final double recovery;

  @override
  Widget build(BuildContext context) {
    final r = recovery.clamp(0.0, 1.0);
    final color = Color.lerp(
      const Color(0xFFFFB36A),
      const Color(0xFF6FE0FF),
      r,
    )!;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 10,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: r,
              child: Container(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _FireRingPainter extends CustomPainter {
  _FireRingPainter({
    required this.progress,
    required this.color,
    required this.glow,
  });

  final double progress;
  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white24;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = glow ? 7 : 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _FireRingPainter old) =>
      old.progress != progress || old.color != color || old.glow != glow;
}

/// A small shield-remaining indicator shown while a shield is active; it flashes
/// during the warning window so imminent expiry is clear from the HUD too.
class _ShieldBadge extends StatelessWidget {
  const _ShieldBadge({required this.snapshot});

  final GameHudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final expiring = snapshot.shieldExpiring;
    final color = expiring ? const Color(0xFFFFB36A) : const Color(0xFF6FD3FF);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: expiring ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, color: color, size: 18),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: snapshot.shieldNormalized.clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({required this.snapshot, required this.onRestart});

  final GameHudSnapshot snapshot;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameHud.shadowed('Game Over', fontSize: 32),
            const SizedBox(height: 8),
            GameHud.shadowed(snapshot.lostReason ?? '', fontSize: 18),
            const SizedBox(height: 18),
            IconButton.filled(
              tooltip: 'Restart',
              iconSize: 34,
              onPressed: onRestart,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
