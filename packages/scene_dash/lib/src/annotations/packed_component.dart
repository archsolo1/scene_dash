/// Numeric precision for a packed-component field.
///
/// Reserved for the optional future packed-storage phase (see below); unused by
/// the current object-first runtime.
enum Precision {
  /// 64-bit IEEE float, stored in a `Float64List`. The default for `double`.
  float64,

  /// 32-bit IEEE float, stored in a `Float32List`.
  float32,

  /// 32-bit signed integer, stored in an `Int32List`.
  int32,
}

/// Reserved annotation for a future *packed* (typed-array) component.
///
/// Scene-Dash is object-first: ordinary mutable Dart objects (`@ObjectComponent`)
/// are the default and only supported component model. Packed typed-array
/// storage is an optional, benchmark-gated future phase (see `docs/concept.md`),
/// not part of the active roadmap.
///
/// This annotation is kept only so the generator can **recognize and reject**
/// it with a clear diagnostic rather than silently ignoring it. Applying it to a
/// class is a build-time error today; do not use it.
final class PackedComponent {
  /// The precision applied to `double` fields unless overridden per field.
  final Precision defaultPrecision;

  const PackedComponent({this.defaultPrecision = Precision.float64});
}
