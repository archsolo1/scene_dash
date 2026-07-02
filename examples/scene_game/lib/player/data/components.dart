part of '../player.dart';

@Tag()
final class Player {
  const Player();
}

enum CrabLegSide {
  left(-1),
  right(1);

  const CrabLegSide(this.sign);

  final int sign;
}

/// Local-space target (collapsed or extended) for one crab leg.
final class CrabLegPose {
  const CrabLegPose({
    required this.rootX,
    required this.rootY,
    required this.rootZ,
    required this.rootYaw,
    required this.rootRoll,
    required this.upperAngle,
    required this.lowerAngle,
    required this.upperScale,
    required this.lowerScale,
  });

  final double rootX;
  final double rootY;
  final double rootZ;
  final double rootYaw;
  final double rootRoll;
  final double upperAngle;
  final double lowerAngle;
  final double upperScale;
  final double lowerScale;
}

final class CrabLegVisual {
  const CrabLegVisual({
    required this.root,
    required this.upper,
    required this.upperSegment,
    required this.lower,
    required this.lowerSegment,
    required this.collapsedPose,
    required this.extendedPose,
    required this.phaseOffset,
    required this.extensionDelay,
    required this.side,
    required this.slot,
  });

  final Node root;
  final Node upper;
  final Node upperSegment;
  final Node lower;
  final Node lowerSegment;
  final CrabLegPose collapsedPose;
  final CrabLegPose extendedPose;
  final double phaseOffset;
  final double extensionDelay;
  final CrabLegSide side;
  final int slot;
}

final class CrabLegGaitSample {
  const CrabLegGaitSample({
    required this.extension,
    required this.gaitWeight,
    required this.lift,
    required this.stride,
    required this.bend,
  });

  final double extension;
  final double gaitWeight;
  final double lift;
  final double stride;
  final double bend;
}

double crabLegExtensionFor(double globalExtension, double delay) {
  final span = (1 - delay).clamp(0.001, 1.0);
  return ((globalExtension - delay) / span).clamp(0.0, 1.0).toDouble();
}

double crabLegSmoothStep(double value) {
  final t = value.clamp(0.0, 1.0).toDouble();
  return t * t * (3 - 2 * t);
}

double crabLegPhaseOffset(CrabLegSide side, int slot) {
  final groupA =
      (side == CrabLegSide.left && slot != 1) ||
      (side == CrabLegSide.right && slot == 1);
  final groupPhase = groupA ? 0.0 : math.pi;
  return groupPhase + slot * 0.23 + (side == CrabLegSide.left ? 0.07 : 0.0);
}

double advanceCrabGaitPhase(double phase, double movement01, double dt) {
  return phase + crabGaitSpeed * movement01.clamp(0.0, 1.0).toDouble() * dt;
}

CrabLegGaitSample sampleCrabLegGait({
  required double globalExtension,
  required double extensionDelay,
  required double movement01,
  required double direction,
  required double gaitPhase,
  required double phaseOffset,
}) {
  final extension = crabLegSmoothStep(
    crabLegExtensionFor(globalExtension, extensionDelay),
  );
  final gaitWeight = movement01.clamp(0.0, 1.0).toDouble() * extension;
  final phase = gaitPhase + phaseOffset;
  final wave = math.sin(phase);
  return CrabLegGaitSample(
    extension: extension,
    gaitWeight: gaitWeight,
    lift: math.max(0.0, wave) * crabLegLift * gaitWeight,
    stride: math.cos(phase) * crabLegStride * direction.sign * gaitWeight,
    bend: wave * crabLegBend * gaitWeight,
  );
}

/// Player-owned feedback nodes (charge and shield VFX, crab legs), children of
/// the player root so the physics-driven sync never disturbs them. Hidden with
/// a zero-scale transform rather than added/removed; materials are unique to
/// the player so per-frame colour changes never leak into other entities.
@ObjectComponent()
final class PlayerVisuals {
  PlayerVisuals._({
    required this.chargeOrb,
    required this.chargeOrbMaterial,
    required this.chargeBeam,
    required this.chargeBeamMaterial,
    required this.chargeMotes,
    required this.chargeMoteMaterial,
    required this.leftLegs,
    required this.rightLegs,
    required this.shieldBubble,
    required this.shieldBubbleMaterial,
    required this.shieldBadge,
    required this.shieldBadgeMaterial,
  });

  factory PlayerVisuals.create() {
    final chargeOrbMaterial = _blendMaterial(_chargeBaseColor, _chargeEmissive);
    final chargeBeamMaterial = _blendMaterial(
      Vector4(0.4, 0.85, 1.0, 0.5),
      Vector4(0.5, 1.0, 1.4, 1),
    );
    final chargeMoteMaterial = _blendMaterial(
      Vector4(0.7, 0.92, 1.0, 0.8),
      Vector4(0.5, 0.85, 1.0, 1),
    );
    final legMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = Vector4(0.06, 0.52, 0.75, 1)
      ..metallicFactor = 0.18
      ..roughnessFactor = 0.28
      ..emissiveFactor = Vector4(0.0, 0.08, 0.16, 1);
    final shieldBubbleMaterial = _blendMaterial(
      Vector4(0.4, 0.8, 1.0, 0.16),
      Vector4(0.25, 0.6, 1.1, 1),
    );
    final shieldBadgeMaterial = _blendMaterial(
      Vector4(0.7, 0.9, 1.0, 0.8),
      Vector4(0.6, 1.0, 1.4, 1),
    );

    final chargeOrb = Node(
      mesh: Mesh(_orbGeometry, chargeOrbMaterial),
      localTransform: _hiddenAt(
        Vector3(0, 0, -(playerBodyVisualRadius + 0.55)),
      ),
    )..frustumCulled = false;
    final chargeBeam = Node(
      mesh: Mesh(_beamGeometry, chargeBeamMaterial),
      localTransform: _hiddenAt(Vector3(0, 0, -(playerBodyVisualRadius + 0.3))),
    )..frustumCulled = false;
    final chargeMotes = List<Node>.generate(
      _chargeMoteCount,
      (_) => Node(
        mesh: Mesh(_moteGeometry, chargeMoteMaterial),
        localTransform: _hiddenAt(Vector3.zero()),
      )..frustumCulled = false,
    );
    final shieldBubble = Node(
      mesh: Mesh(_bubbleGeometry, shieldBubbleMaterial),
      localTransform: _hiddenAt(Vector3.zero()),
    )..frustumCulled = false;
    final shieldBadge = Node(
      mesh: Mesh(_badgeGeometry, shieldBadgeMaterial),
      localTransform: _hiddenAt(
        Vector3(
          0,
          playerBodyVisualRadius * 0.6,
          -(playerBodyVisualRadius + 0.4),
        ),
      ),
    )..frustumCulled = false;
    final leftLegs = _createCrabLegs(CrabLegSide.left, legMaterial);
    final rightLegs = _createCrabLegs(CrabLegSide.right, legMaterial);

    return PlayerVisuals._(
      chargeOrb: chargeOrb,
      chargeOrbMaterial: chargeOrbMaterial,
      chargeBeam: chargeBeam,
      chargeBeamMaterial: chargeBeamMaterial,
      chargeMotes: chargeMotes,
      chargeMoteMaterial: chargeMoteMaterial,
      leftLegs: leftLegs,
      rightLegs: rightLegs,
      shieldBubble: shieldBubble,
      shieldBubbleMaterial: shieldBubbleMaterial,
      shieldBadge: shieldBadge,
      shieldBadgeMaterial: shieldBadgeMaterial,
    );
  }

  void attachTo(Node root) {
    root
      ..add(chargeOrb)
      ..add(chargeBeam);
    for (final mote in chargeMotes) {
      root.add(mote);
    }
    for (final leg in allLegs) {
      root.add(leg.root);
    }
    root
      ..add(shieldBubble)
      ..add(shieldBadge);
  }

  final Node chargeOrb;
  final PhysicallyBasedMaterial chargeOrbMaterial;
  final Node chargeBeam;
  final PhysicallyBasedMaterial chargeBeamMaterial;
  final List<Node> chargeMotes;
  final PhysicallyBasedMaterial chargeMoteMaterial;
  final List<CrabLegVisual> leftLegs;
  final List<CrabLegVisual> rightLegs;
  final Node shieldBubble;
  final PhysicallyBasedMaterial shieldBubbleMaterial;
  final Node shieldBadge;
  final PhysicallyBasedMaterial shieldBadgeMaterial;

  // Visual-only animation state, eased across frames by the VFX systems; the
  // blaster and shield resources own the gameplay truth.
  double chargePhase = 0;
  double shieldPhase = 0;
  double chargeShow = 0;
  double legExtension01 = 0;
  double gaitPhase = 0;
  double shieldShow = 0;
  double badgePop = 0;

  /// Lets the shield VFX system fire the pop on the inactive -> active edge.
  bool shieldWasActive = false;

  Iterable<CrabLegVisual> get allLegs sync* {
    yield* leftLegs;
    yield* rightLegs;
  }

  void resetLegs() {
    legExtension01 = 0;
    gaitPhase = 0;
    for (final leg in allLegs) {
      _applyLegPose(leg, leg.collapsedPose, 0, 0, 0);
    }
  }

  static final Vector4 _chargeBaseColor = Vector4(0.4, 0.9, 1.0, 0.7);
  static final Vector4 _chargeEmissive = Vector4(0.3, 0.9, 1.2, 1);

  static const int _chargeMoteCount = 10;
  static final _orbGeometry = SphereGeometry(
    radius: 0.3,
    segments: 16,
    rings: 10,
  );
  static final _moteGeometry = SphereGeometry(
    radius: 0.07,
    segments: 8,
    rings: 6,
  );
  // Scaled long in Y into a beam — flutter_scene 0.18 has no cylinder primitive.
  static final _beamGeometry = SphereGeometry(
    radius: 1,
    segments: 12,
    rings: 8,
  );
  static final _bubbleGeometry = SphereGeometry(
    radius: shieldBubbleRadius,
    segments: 24,
    rings: 16,
  );
  static final _badgeGeometry = SphereGeometry(
    radius: 0.22,
    segments: 12,
    rings: 8,
  );
  static final _legUpperGeometry = CuboidGeometry(
    Vector3(crabLegUpperLength, crabLegThickness, crabLegThickness),
  );
  static final _legLowerGeometry = CuboidGeometry(
    Vector3(
      crabLegLowerLength,
      crabLegThickness * 0.86,
      crabLegThickness * 0.86,
    ),
  );

  static PhysicallyBasedMaterial _blendMaterial(
    Vector4 base,
    Vector4 emissive,
  ) {
    return PhysicallyBasedMaterial()
      ..baseColorFactor = base
      ..emissiveFactor = emissive
      ..metallicFactor = 0
      ..roughnessFactor = 0.2
      ..alphaMode = AlphaMode.blend;
  }

  /// A zero-scale transform at [position]: present in the tree but invisible.
  static Matrix4 _hiddenAt(Vector3 position) =>
      Matrix4.translation(position)..scaleByDouble(0, 0, 0, 1);
}

List<CrabLegVisual> _createCrabLegs(CrabLegSide side, Material material) {
  return List<CrabLegVisual>.generate(crabLegsPerSide, (slot) {
    final upperSegment = Node(
      mesh: Mesh(PlayerVisuals._legUpperGeometry, material),
    )..frustumCulled = false;
    final lowerSegment = Node(
      mesh: Mesh(PlayerVisuals._legLowerGeometry, material),
    )..frustumCulled = false;
    final lower = Node()
      ..frustumCulled = false
      ..add(lowerSegment);
    final upper = Node()
      ..frustumCulled = false
      ..add(upperSegment)
      ..add(lower);
    final root = Node()..frustumCulled = false;
    root.add(upper);
    final collapsed = _crabLegPose(side, slot, extended: false);
    final extended = _crabLegPose(side, slot, extended: true);
    final leg = CrabLegVisual(
      root: root,
      upper: upper,
      upperSegment: upperSegment,
      lower: lower,
      lowerSegment: lowerSegment,
      collapsedPose: collapsed,
      extendedPose: extended,
      phaseOffset: crabLegPhaseOffset(side, slot),
      extensionDelay: slot * crabLegExtensionStagger,
      side: side,
      slot: slot,
    );
    _applyLegPose(leg, collapsed, 0, 0, 0);
    return leg;
  }, growable: false);
}

CrabLegPose _crabLegPose(CrabLegSide side, int slot, {required bool extended}) {
  final sign = side.sign.toDouble();
  final z = crabLegForwardOffsets[slot];
  final slotYaw = (slot - 1) * 0.34;
  if (!extended) {
    return CrabLegPose(
      rootX: sign * playerBodyVisualRadius * 0.32,
      rootY: -playerBodyVisualRadius * 0.08,
      rootZ: z * 0.56,
      rootYaw: slotYaw * 0.55,
      rootRoll: sign * 0.28,
      upperAngle: sign * 0.32,
      lowerAngle: sign * -0.95,
      upperScale: crabLegCollapsedScale,
      lowerScale: crabLegCollapsedScale,
    );
  }
  return CrabLegPose(
    rootX: sign * crabLegSideOffset,
    rootY: -playerBodyVisualRadius * 0.2,
    rootZ: z,
    rootYaw: slotYaw,
    rootRoll: sign * -0.06,
    upperAngle: sign * 0.46,
    lowerAngle: sign * -1.18,
    upperScale: 1,
    lowerScale: 1,
  );
}

CrabLegPose _mixCrabLegPose(CrabLegPose a, CrabLegPose b, double t) {
  double lerp(double x, double y) => x + (y - x) * t;
  return CrabLegPose(
    rootX: lerp(a.rootX, b.rootX),
    rootY: lerp(a.rootY, b.rootY),
    rootZ: lerp(a.rootZ, b.rootZ),
    rootYaw: lerp(a.rootYaw, b.rootYaw),
    rootRoll: lerp(a.rootRoll, b.rootRoll),
    upperAngle: lerp(a.upperAngle, b.upperAngle),
    lowerAngle: lerp(a.lowerAngle, b.lowerAngle),
    upperScale: lerp(a.upperScale, b.upperScale),
    lowerScale: lerp(a.lowerScale, b.lowerScale),
  );
}

void _applyLegPose(
  CrabLegVisual leg,
  CrabLegPose pose,
  double lift,
  double stride,
  double bend,
) {
  final root = leg.root.localTransform
    ..setIdentity()
    ..setTranslationRaw(pose.rootX, pose.rootY + lift, pose.rootZ + stride)
    ..rotateY(pose.rootYaw)
    ..rotateZ(pose.rootRoll);
  leg.root.localTransform = root;

  final sign = leg.side.sign.toDouble();
  final upperScale = pose.upperScale;
  final upper = leg.upper.localTransform
    ..setIdentity()
    ..rotateZ(pose.upperAngle + sign * bend * 0.35);
  leg.upper.localTransform = upper;

  final upperSegment = leg.upperSegment.localTransform
    ..setIdentity()
    ..setTranslationRaw(sign * crabLegUpperLength * upperScale * 0.5, 0, 0)
    ..scaleByDouble(upperScale, 1, 1, 1);
  leg.upperSegment.localTransform = upperSegment;

  final lowerScale = pose.lowerScale;
  final lower = leg.lower.localTransform
    ..setIdentity()
    ..setTranslationRaw(
      sign * crabLegUpperLength * upperScale,
      -crabLegThickness * 0.25,
      0,
    )
    ..rotateZ(pose.lowerAngle - sign * bend);
  leg.lower.localTransform = lower;

  final lowerSegment = leg.lowerSegment.localTransform
    ..setIdentity()
    ..setTranslationRaw(sign * crabLegLowerLength * lowerScale * 0.5, 0, 0)
    ..scaleByDouble(lowerScale, 1, 1, 1);
  leg.lowerSegment.localTransform = lowerSegment;
}
