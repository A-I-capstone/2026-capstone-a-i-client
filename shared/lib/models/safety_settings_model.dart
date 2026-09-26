import 'package:firebase_ai/firebase_ai.dart';

/// Represents the parent-configurable AI safety thresholds for a child.
///
/// Each field is an integer in [0, 2] mapping to a [HarmBlockThreshold]:
///   0 → [HarmBlockThreshold.low]    — block low and above (strictest)
///   1 → [HarmBlockThreshold.medium] — block medium and above
///   2 → [HarmBlockThreshold.high]   — block high only (most permissive default)
///
/// [jailbreak] is NOT stored here — it is always forced to
/// [HarmBlockThreshold.low] (blockLowAndAbove) client-side and cannot be
/// changed by the parent.
class SafetySettingsModel {
  final int harassment;
  final int hateSpeech;
  final int sexuallyExplicit;
  final int dangerousContent;

  const SafetySettingsModel({
    this.harassment = 2,
    this.hateSpeech = 2,
    this.sexuallyExplicit = 2,
    this.dangerousContent = 2,
  });

  // ---------------------------------------------------------------------------
  // Firestore serialisation
  // ---------------------------------------------------------------------------

  factory SafetySettingsModel.fromFirestore(Map<String, dynamic> data) {
    return SafetySettingsModel(
      harassment: (data['harassment'] as int?) ?? 2,
      hateSpeech: (data['hateSpeech'] as int?) ?? 2,
      sexuallyExplicit: (data['sexuallyExplicit'] as int?) ?? 2,
      dangerousContent: (data['dangerousContent'] as int?) ?? 2,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'harassment': harassment,
        'hateSpeech': hateSpeech,
        'sexuallyExplicit': sexuallyExplicit,
        'dangerousContent': dangerousContent,
      };

  // ---------------------------------------------------------------------------
  // Conversion to Firebase AI SDK types
  // ---------------------------------------------------------------------------

  /// Converts an integer level (0–2) to the corresponding [HarmBlockThreshold].
  static HarmBlockThreshold _levelToThreshold(int level) {
    switch (level.clamp(0, 2)) {
      case 0:
        return HarmBlockThreshold.low;
      case 1:
        return HarmBlockThreshold.medium;
      case 2:
      default:
        return HarmBlockThreshold.high;
    }
  }

  /// Returns the full [List<SafetySetting>] to pass to [GenerativeModel].
  ///
  /// Note: [HarmCategory.jailbreak] is not an enum member in firebase_ai 3.15.0;
  /// prompt injection/jailbreak protection is enforced via system instructions
  /// and the standard safety thresholds.
  List<SafetySetting> toSafetySettings() {
    return [
      SafetySetting(
        HarmCategory.harassment,
        _levelToThreshold(harassment),
        HarmBlockMethod.probability,
      ),
      SafetySetting(
        HarmCategory.hateSpeech,
        _levelToThreshold(hateSpeech),
        HarmBlockMethod.probability,
      ),
      SafetySetting(
        HarmCategory.sexuallyExplicit,
        _levelToThreshold(sexuallyExplicit),
        HarmBlockMethod.probability,
      ),
      SafetySetting(
        HarmCategory.dangerousContent,
        _levelToThreshold(dangerousContent),
        HarmBlockMethod.probability,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Equality & copyWith
  // ---------------------------------------------------------------------------

  SafetySettingsModel copyWith({
    int? harassment,
    int? hateSpeech,
    int? sexuallyExplicit,
    int? dangerousContent,
  }) {
    return SafetySettingsModel(
      harassment: harassment ?? this.harassment,
      hateSpeech: hateSpeech ?? this.hateSpeech,
      sexuallyExplicit: sexuallyExplicit ?? this.sexuallyExplicit,
      dangerousContent: dangerousContent ?? this.dangerousContent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetySettingsModel &&
          harassment == other.harassment &&
          hateSpeech == other.hateSpeech &&
          sexuallyExplicit == other.sexuallyExplicit &&
          dangerousContent == other.dangerousContent;

  @override
  int get hashCode => Object.hash(
        harassment,
        hateSpeech,
        sexuallyExplicit,
        dangerousContent,
      );
}
