import 'package:hive/hive.dart';

part 'entry_model.g.dart';

@HiveType(typeId: 0)
class CycleEntry {
  @HiveField(0)
  final DateTime date; // The day this entry belongs to (required)

  @HiveField(1)
  String? notes; // Any free text notes for the day

  @HiveField(2)
  List<String> photoPaths; // Paths to photos (unencrypted files in private dir)

  @HiveField(3)
  String? flowIntensity; // 'light', 'medium', 'heavy', 'spotting', 'none'

  @HiveField(4)
  String? flowDescription; // "bright red", "brown", "clots", "stringy", etc.

  @HiveField(5)
  String? phase; // 'menstruation', 'follicular', 'ovulation', 'luteal' — now optional

  @HiveField(6)
  Map<String, bool> symptoms; // e.g. {'cramps': true, 'headache': false}

  @HiveField(7)
  int? moodRating; // Optional 1–5 scale

  @HiveField(8)
  int? energyLevel; // Optional 1–5 or null (as is)

  @HiveField(9)
  int? painLevel; // Optional 1–10 scale, focused on cramps/pain

  @HiveField(10)
  String? overallFeeling; // "exhausted", "anxious", "okay", "euphoric", etc.
  @HiveField(11)
  bool? isPredicted;

  CycleEntry({
    required this.date,
    this.notes,
    this.photoPaths = const [],
    this.flowIntensity,
    this.flowDescription,
    this.phase,
    this.symptoms = const {},
    this.moodRating,
    this.energyLevel,
    this.painLevel,
    this.overallFeeling,
    this.isPredicted = false, // default = user created/edited it
  });
  CycleEntry copyWith({String? phase, bool? isPredicted}) {
    return CycleEntry(
      date: date,
      phase: phase ?? this.phase,
      flowIntensity: flowIntensity,
      flowDescription: flowDescription,
      moodRating: moodRating,
      energyLevel: energyLevel,
      painLevel: painLevel,
      notes: notes,
      symptoms: symptoms,
      photoPaths: photoPaths,
      isPredicted: isPredicted ?? this.isPredicted,
    );
  }

  // Helper getter to always return a non-null boolean
  bool get isPredictedValue => isPredicted ?? false;
}
