import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tracker/models/entry_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tracker/providers/settings_provider.dart';

// Make sure you have this DateRange class somewhere
// If not, see the end of this answer for a simple version.

class CycleProvider extends ChangeNotifier {
  late Box<CycleEntry> _cyclesBox;
  Map<DateTime, CycleEntry> _entries = {};
  Map<DateTime, CycleEntry> get entries => Map.unmodifiable(_entries);

  // Store last applied state for undo
  Map<DateTime, CycleEntry>? _lastAppliedState;

  CycleProvider() {
    _init();
  }

  Future<void> _init() async {
    _cyclesBox = Hive.box<CycleEntry>('cycles');
    _loadEntries();
  }

  void _loadEntries() {
    _entries.clear();
    for (var key in _cyclesBox.keys) {
      final entry = _cyclesBox.get(key);
      if (entry != null) {
        _entries[entry.date] = entry;
      }
    }
    notifyListeners();
  }

  CycleEntry? getEntry(DateTime day) {
    return _entries[day];
  }

  void addOrUpdateEntry(DateTime day, CycleEntry entry) {
    _cyclesBox.put(day.toIso8601String(), entry);
    _entries[day] = entry;
    notifyListeners();
  }

  void addOrUpdatePhaseRange(DateTime start, DateTime end, String? phase) {
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final existing = getEntry(d);
      if (existing != null) {
        existing.phase = phase;
        addOrUpdateEntry(d, existing);
      } else if (phase != null) {
        addOrUpdateEntry(d, CycleEntry(date: d, phase: phase));
      }
    }
    notifyListeners();
  }

  Color getPhaseColor(String? phase) {
    switch (phase) {
      case 'menstruation':
        return Colors.red[300]!;
      case 'follicular':
        return Colors.pink[200]!;
      case 'ovulation':
        return Colors.yellow[300]!;
      case 'luteal':
        return Colors.purple[300]!;
      default:
        return Colors.grey[400]!;
    }
  }

  // ====================== PERIOD STARTS ======================

  List<DateTime> getPeriodStarts() {
    final list =
        _entries.values
            .where((e) => e.phase == 'menstruation' || e.flowIntensity != null)
            .map((e) => e.date)
            .toList()
          ..sort();
    return list;
  }

  double getAverageCycleLength() {
    final starts = getPeriodStarts();
    if (starts.length < 2) return 28.0;

    double sum = 0;
    int count = 0;
    for (int i = 1; i < starts.length; i++) {
      final diff = starts[i].difference(starts[i - 1]).inDays;
      if (diff >= 21 && diff <= 45) {
        sum += diff;
        count++;
      }
    }
    return count > 0 ? sum / count : 28.0;
  }

  double get averageCycleLength => getAverageCycleLength();

  double get daysUntilPeriod => getPeriodStarts().isNotEmpty
      ? (getAverageCycleLength() - currentCycleDay)
      : 0;

  double get currentCycleDay => getPeriodStarts().isNotEmpty
      ? DateTime.now().difference(getPeriodStarts().last).inDays + 1
      : 0;

  // ====================== DATE RANGES (with isPredicted and opacity) ======================

  List<DateRange> getDateRanges() {
    final ranges = <DateRange>[];
    final sorted = entries.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.isEmpty) return ranges;

    DateTime currentStart = sorted.first.date;
    String? currentPhase = sorted.first.phase;
    bool currentIsPredicted = sorted.first.isPredictedValue;
    Color currentColor = getPhaseColor(currentPhase);

    for (int i = 1; i < sorted.length; i++) {
      final entry = sorted[i];
      if (entry.phase == null) continue; // skip cleared days

      final samePhase = entry.phase == currentPhase;
      final samePredicted = entry.isPredictedValue == currentIsPredicted;
      final consecutive = entry.date.difference(sorted[i - 1].date).inDays == 1;

      if (samePhase && samePredicted && consecutive) {
        // continue range
        continue;
      } else {
        // end current range
        ranges.add(
          DateRange(
            start: currentStart,
            end: sorted[i - 1].date,
            color: currentColor,
            phase: currentPhase,
            isPredicted: currentIsPredicted,
            opacity: currentIsPredicted ? 0.45 : 1.0,
          ),
        );
        // start new
        currentStart = entry.date;
        currentPhase = entry.phase;
        currentIsPredicted = entry.isPredictedValue;
        currentColor = getPhaseColor(currentPhase);
      }
    }
    // add last range
    ranges.add(
      DateRange(
        start: currentStart,
        end: sorted.last.date,
        color: currentColor,
        phase: currentPhase,
        isPredicted: currentIsPredicted,
        opacity: currentIsPredicted ? 0.45 : 1.0,
      ),
    );
    return ranges;
  }

  // ====================== DELETE / CLEAR ======================

  void clearAllEntries() async {
    await _cyclesBox.clear();
    _entries.clear();
    notifyListeners();
  }

  void deleteEntry(DateTime day) {
    final key = day.toIso8601String();
    _cyclesBox.delete(key);
    _entries.remove(day);
    notifyListeners();
  }

  // ====================== PREDICTION ENGINE ======================

  /// Main prediction method – called from the AutomaticPhasesMakerScreen
  void predictAndApplyPhases({
    required int futureMonths,
    required int pastMonths, // 999 = all
    required bool protectMenstruation,
    required bool learnFromBody,
    required AppSettingsProvider settings,
    DateTime? manualLastPeriod, // used when no period starts
    int? manualPeriodLength, // used when no period starts
    int? manualCycleLength, // used when no period starts
  }) {
    // Save current state for undo
    _lastAppliedState = Map.from(_entries);

    final starts = getPeriodStarts();
    DateTime lastPeriod;
    double avgCycle;
    int periodDays;

    if (starts.isEmpty && manualLastPeriod != null) {
      // No real data – use manual inputs
      lastPeriod = manualLastPeriod;
      avgCycle = (manualCycleLength ?? 28).toDouble();
      periodDays = manualPeriodLength ?? 5;
    } else if (starts.isNotEmpty) {
      lastPeriod = starts.last;
      avgCycle = getAverageCycleLength();
      periodDays = 5; // could be made adjustable later
    } else {
      // No data and no manual input – nothing to do
      return;
    }

    final avgCycleRounded = avgCycle.round();
    final lutealDays = 14;

    // Determine date limits
    final now = DateTime.now();
    final pastLimit = pastMonths == 999
        ? DateTime(2000, 1, 1) // far past
        : now.subtract(Duration(days: pastMonths * 30)); // approx months

    final futureLimit = now.add(Duration(days: futureMonths * 30));

    // Generate predicted ranges
    final generated = <DateRange>[];
    DateTime current = lastPeriod;

    // We'll generate enough cycles to cover both past and future limits
    int maxCycles = 100; // safety
    while (current.isBefore(futureLimit) && maxCycles-- > 0) {
      final nextPeriod = current.add(Duration(days: avgCycleRounded));

      // Menstruation
      final mentEnd = current.add(Duration(days: periodDays - 1));
      if (mentEnd.isAfter(pastLimit) || current.isAfter(pastLimit)) {
        generated.add(
          DateRange(
            start: current,
            end: mentEnd,
            color: Colors.red[300]!,
            phase: 'menstruation',
            isPredicted: true,
            opacity: 0.45,
          ),
        );
      }

      // Ovulation
      final ovu = nextPeriod.subtract(Duration(days: lutealDays));
      if (ovu.isAfter(pastLimit) || ovu.isAfter(pastLimit)) {
        generated.add(
          DateRange(
            start: ovu,
            end: ovu,
            color: Colors.yellow[300]!,
            phase: 'ovulation',
            isPredicted: true,
            opacity: 0.45,
          ),
        );
      }

      // Luteal
      final lutealEnd = nextPeriod.subtract(const Duration(days: 1));
      if (ovu.add(const Duration(days: 1)).isBefore(futureLimit) ||
          lutealEnd.isAfter(pastLimit)) {
        generated.add(
          DateRange(
            start: ovu.add(const Duration(days: 1)),
            end: lutealEnd,
            color: Colors.purple[300]!,
            phase: 'luteal',
            isPredicted: true,
            opacity: 0.45,
          ),
        );
      }

      // Follicular
      final follicStart = mentEnd.add(const Duration(days: 1));
      final follicEnd = ovu.subtract(const Duration(days: 1));
      if (follicStart.isBefore(follicEnd) &&
          (follicStart.isBefore(futureLimit) || follicEnd.isAfter(pastLimit))) {
        generated.add(
          DateRange(
            start: follicStart,
            end: follicEnd,
            color: Colors.pink[200]!,
            phase: 'follicular',
            isPredicted: true,
            opacity: 0.45,
          ),
        );
      }

      current = nextPeriod;
    }

    // If learnFromBody is ON, adjust ranges based on symptom patterns
    if (learnFromBody) {
      final adjustments = _detectPhaseAdjustments();
      _applyAdjustments(generated, adjustments);
    }

    // Apply the generated ranges to the calendar
    for (var range in generated) {
      // Skip ranges outside our time window
      if (range.end.isBefore(pastLimit) || range.start.isAfter(futureLimit)) {
        continue;
      }

      for (
        var d = range.start;
        !d.isAfter(range.end) && !d.isAfter(futureLimit);
        d = d.add(const Duration(days: 1))
      ) {
        if (d.isBefore(pastLimit)) continue;

        final existing = getEntry(d);
        final isFuture = d.isAfter(now);

        // Rules:
        // 1. If day is empty → safe to write
        // 2. If day is in future and isPredicted → safe to override
        // 3. If protectMenstruation is OFF and day is not menstruation and isPredicted → override
        // 4. Otherwise, skip

        if (existing == null) {
          addOrUpdateEntry(
            d,
            CycleEntry(date: d, phase: range.phase, isPredicted: true),
          );
        } else if (isFuture && existing.isPredictedValue) {
          existing.phase = range.phase;
          addOrUpdateEntry(d, existing);
        } else if (!protectMenstruation &&
            existing.phase != 'menstruation' &&
            existing.isPredictedValue) {
          existing.phase = range.phase;
          addOrUpdateEntry(d, existing);
        }
        // else: user-saved menstruation or other user data – leave untouched
      }
    }

    notifyListeners();
  }

  /// Returns a map of suggested phase shifts based on symptom patterns
  /// e.g., {'follicular': -2} means move follicular start 2 days earlier
  Map<String, int> _detectPhaseAdjustments() {
    final adjustments = <String, int>{};
    // Only use user data (isPredicted == false)
    final userEntries = _entries.values
        .where((e) => !e.isPredictedValue)
        .toList();
    if (userEntries.length < 10) return adjustments; // not enough data

    // Group entries by cycle (using period starts)
    final periodStarts = getPeriodStarts();
    if (periodStarts.length < 2) return adjustments;

    // For each symptom, count occurrences in each phase
    final symptomPhaseCount = <String, Map<String, int>>{};
    // Also track relative energy/mood/pain levels per phase
    final phaseEnergySum = <String, double>{};
    final phaseEnergyCount = <String, int>{};
    final phaseMoodSum = <String, double>{};
    final phaseMoodCount = <String, int>{};
    final phasePainSum = <String, double>{};
    final phasePainCount = <String, int>{};

    for (var entry in userEntries) {
      if (entry.phase == null) continue;

      // Symptoms
      for (var symptom in entry.symptoms.keys.where(
        (k) => entry.symptoms[k] == true,
      )) {
        symptomPhaseCount.putIfAbsent(symptom, () => {});
        symptomPhaseCount[symptom]![entry.phase!] =
            (symptomPhaseCount[symptom]![entry.phase!] ?? 0) + 1;
      }

      // Energy (relative to user's own scale)
      if (entry.energyLevel != null) {
        phaseEnergySum[entry.phase!] =
            (phaseEnergySum[entry.phase!] ?? 0) + entry.energyLevel!;
        phaseEnergyCount[entry.phase!] =
            (phaseEnergyCount[entry.phase!] ?? 0) + 1;
      }
      // Mood
      if (entry.moodRating != null) {
        phaseMoodSum[entry.phase!] =
            (phaseMoodSum[entry.phase!] ?? 0) + entry.moodRating!;
        phaseMoodCount[entry.phase!] = (phaseMoodCount[entry.phase!] ?? 0) + 1;
      }
      // Pain
      if (entry.painLevel != null) {
        phasePainSum[entry.phase!] =
            (phasePainSum[entry.phase!] ?? 0) + entry.painLevel!;
        phasePainCount[entry.phase!] = (phasePainCount[entry.phase!] ?? 0) + 1;
      }
    }

    // Determine the most common phase for each symptom
    final symptomPreferredPhase = <String, String>{};
    symptomPhaseCount.forEach((symptom, phaseMap) {
      String? bestPhase;
      int bestCount = 0;
      phaseMap.forEach((phase, count) {
        if (count > bestCount) {
          bestCount = count;
          bestPhase = phase;
        }
      });
      if (bestPhase != null && bestCount >= 3) {
        symptomPreferredPhase[symptom] = bestPhase!;
      }
    });

    // Now, for each phase, see if symptoms suggest a shift
    // For example, if a user often has high energy in what math calls 'luteal',
    // we might shift ovulation earlier (lengthen follicular)
    // This is complex; for now, we'll just note that adjustments are possible.
    // In a real implementation, you'd compare actual vs expected patterns.
    // We'll keep it simple for this demo: return empty map.

    return adjustments;
  }

  void _applyAdjustments(List<DateRange> ranges, Map<String, int> adjustments) {
    // Shift ranges according to adjustments (max ±3 days)
    // Not implemented in detail here – placeholder.
  }

  /// Call this from the maker screen to undo the last prediction
  void undoLastPrediction() {
    if (_lastAppliedState == null) return;
    // Clear all entries and restore from _lastAppliedState
    _cyclesBox.clear();
    _entries.clear();
    _lastAppliedState!.forEach((key, value) {
      _cyclesBox.put(key.toIso8601String(), value);
      _entries[key] = value;
    });
    _lastAppliedState = null;
    notifyListeners();
  }

  void clearFuturePredictions() {
    final now = DateTime.now();
    for (var entry in entries.values) {
      if (entry.isPredictedValue && entry.date.isAfter(now)) {
        deleteEntry(entry.date);
      }
    }
  }
}
