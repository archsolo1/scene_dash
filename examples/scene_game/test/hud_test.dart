import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scene_game/game/game_state.dart';
import 'package:scene_game/hud/game_hud.dart';

/// Widget coverage for the HUD: control placement, hold/release/cancel fire
/// transitions, and charge/cooldown/ready presentation.
void main() {
  GameHudSnapshot snap({
    GameStatus status = GameStatus.playing,
    double charge = 0,
    double cooldown = 0,
    bool charging = false,
    bool ready = true,
    bool shieldActive = false,
    double shieldNormalized = 0,
    bool shieldExpiring = false,
  }) {
    return GameHudSnapshot(
      status: status,
      survivedTenths: 0,
      lostReason: null,
      fps: 60,
      blasterCharge01: charge,
      blasterCooldown01: cooldown,
      blasterCharging: charging,
      blasterReady: ready,
      shieldActive: shieldActive,
      shieldNormalized: shieldNormalized,
      shieldExpiring: shieldExpiring,
    );
  }

  Future<HudState> pumpHud(
    WidgetTester tester,
    GameHudSnapshot snapshot, {
    void Function(bool)? onFireChanged,
    VoidCallback? onFireCanceled,
  }) async {
    final hud = HudState(GameState())..value = snapshot;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameHud(
            hud: hud,
            onLeftChanged: (_) {},
            onRightChanged: (_) {},
            onFireChanged: onFireChanged ?? (_) {},
            onFireCanceled: onFireCanceled ?? () {},
            onRestart: () {},
          ),
        ),
      ),
    );
    return hud;
  }

  testWidgets('movement is bottom-left and fire is bottom-right', (
    tester,
  ) async {
    await pumpHud(tester, snap());

    final left = tester.getCenter(find.byIcon(Icons.arrow_left_rounded));
    final right = tester.getCenter(find.byIcon(Icons.arrow_right_rounded));
    final fire = tester.getCenter(find.byIcon(Icons.bolt_rounded));
    final size = tester.getSize(find.byType(GameHud));

    // Movement grouped on the left, fire on the right.
    expect(left.dx, lessThan(size.width / 2));
    expect(right.dx, lessThan(size.width / 2));
    expect(fire.dx, greaterThan(size.width / 2));
    // All near the bottom.
    expect(fire.dy, greaterThan(size.height / 2));
  });

  testWidgets('touch down begins holding and release fires', (tester) async {
    final events = <bool>[];
    await pumpHud(tester, snap(), onFireChanged: events.add);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.bolt_rounded)),
    );
    await tester.pump();
    expect(events.last, isTrue, reason: 'press begins holding');

    await gesture.up();
    await tester.pump();
    expect(events.last, isFalse, reason: 'release fires (ends holding)');
  });

  testWidgets('tap cancel cancels rather than fires', (tester) async {
    var canceled = false;
    final events = <bool>[];
    await pumpHud(
      tester,
      snap(),
      onFireChanged: events.add,
      onFireCanceled: () => canceled = true,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.bolt_rounded)),
    );
    await tester.pump();
    await gesture.cancel();
    await tester.pump();
    expect(canceled, isTrue);
  });

  testWidgets('charge progress is shown in the fire semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHud(tester, snap(charging: true, charge: 0.6, ready: false));
    expect(find.bySemanticsLabel('Charging 60 percent'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('cooldown is shown in the fire semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHud(tester, snap(cooldown: 0.5, ready: false));
    expect(find.bySemanticsLabel('Blaster cooling down'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('ready state is shown in the fire semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHud(tester, snap());
    expect(find.bySemanticsLabel('Blaster ready'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an active shield shows the shield indicator', (tester) async {
    await pumpHud(tester, snap(shieldActive: true, shieldNormalized: 0.8));
    expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
  });
}
