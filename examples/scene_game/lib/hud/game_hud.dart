import 'package:flutter/material.dart';

import '../game/game_state.dart';

/// Plain Flutter HUD over the scene. Scene-Dash deliberately does not own UI:
/// this widget reads [GameState] and writes touch intent through callbacks.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.hud,
    required this.onLeftChanged,
    required this.onRightChanged,
    required this.onRestart,
  });

  final HudState hud;
  final ValueChanged<bool> onLeftChanged;
  final ValueChanged<bool> onRightChanged;
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
            if (!lost)
              _TouchControls(
                onLeftChanged: onLeftChanged,
                onRightChanged: onRightChanged,
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

class _TouchControls extends StatelessWidget {
  const _TouchControls({
    required this.onLeftChanged,
    required this.onRightChanged,
  });

  final ValueChanged<bool> onLeftChanged;
  final ValueChanged<bool> onRightChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _HoldButton(
              icon: Icons.arrow_left_rounded,
              semanticLabel: 'Move left',
              onChanged: onLeftChanged,
            ),
            _HoldButton(
              icon: Icons.arrow_right_rounded,
              semanticLabel: 'Move right',
              onChanged: onRightChanged,
            ),
          ],
        ),
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
