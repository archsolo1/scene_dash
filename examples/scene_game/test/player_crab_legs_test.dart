import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:scene_game/player/config.dart';
import 'package:scene_game/player/player.dart';

void main() {
  test('player leg definitions include three legs per side', () {
    expect(crabLegsPerSide, 3);
    expect(crabLegCount, 6);
    expect(crabLegForwardOffsets, <double>[
      crabLegFrontOffset,
      crabLegMiddleOffset,
      crabLegRearOffset,
    ]);
  });

  test('extension clamps and staggers front, middle and rear legs', () {
    expect(crabLegExtensionFor(-1, 0), 0);
    expect(crabLegExtensionFor(2, 0), 1);

    final front = crabLegExtensionFor(0.3, 0);
    final middle = crabLegExtensionFor(0.3, crabLegExtensionStagger);
    final rear = crabLegExtensionFor(0.3, crabLegExtensionStagger * 2);

    expect(front, greaterThan(middle));
    expect(middle, greaterThan(rear));
  });

  test('gait groups are approximately half a cycle apart', () {
    final leftFront = crabLegPhaseOffset(CrabLegSide.left, 0);
    final rightFront = crabLegPhaseOffset(CrabLegSide.right, 0);

    expect((rightFront - leftFront).abs(), closeTo(math.pi, 0.1));
  });

  test('zero movement keeps gait influence at rest', () {
    final sample = sampleCrabLegGait(
      globalExtension: 1,
      extensionDelay: 0,
      movement01: 0,
      direction: 1,
      gaitPhase: 0,
      phaseOffset: 0,
    );

    expect(sample.gaitWeight, 0);
    expect(sample.lift, 0);
    expect(sample.stride, 0);
    expect(sample.bend, 0);
  });

  test('movement advances phase and direction mirrors stride only', () {
    expect(advanceCrabGaitPhase(2, 0, 0.25), 2);
    expect(advanceCrabGaitPhase(2, 1, 0.25), greaterThan(2));

    final right = sampleCrabLegGait(
      globalExtension: 1,
      extensionDelay: 0,
      movement01: 1,
      direction: 1,
      gaitPhase: 0,
      phaseOffset: 0,
    );
    final left = sampleCrabLegGait(
      globalExtension: 1,
      extensionDelay: 0,
      movement01: 1,
      direction: -1,
      gaitPhase: 0,
      phaseOffset: 0,
    );

    expect(left.stride, closeTo(-right.stride, 1e-9));
    expect(left.lift, right.lift);
  });

  test('folded legs suppress gait influence', () {
    final folded = sampleCrabLegGait(
      globalExtension: 0,
      extensionDelay: 0,
      movement01: 1,
      direction: 1,
      gaitPhase: 0,
      phaseOffset: 0,
    );

    expect(folded.gaitWeight, 0);
  });

  test('visual leg span does not change central body hit radius', () {
    final visualSpan =
        crabLegSideOffset + crabLegUpperLength + crabLegLowerLength;

    expect(visualSpan, greaterThan(playerBodyVisualRadius));
    expect(playerCollisionRadius, playerBodyVisualRadius);
    expect(playerCollisionRadius, lessThan(visualSpan));
  });
}
