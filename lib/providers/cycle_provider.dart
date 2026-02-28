import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tracker/models/entry_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tracker/providers/settings_provider.dart';
import 'dart:async'; // for Timer

// Extension for color blending/mixing
extension ColorMix on Color {
  Color mix(Color other, double amount) => Color.lerp(this, other, amount)!;
}

// Extension for Color.lerp functionality
extension on Color {
  static Color lerp(Color a, Color b, double t) => Color.lerp(a, b, t)!;
}

// Make sure you have this DateRange class somewhere
// If not, see the end of this answer for a simple version.

class CycleProvider extends ChangeNotifier {
  late Box<CycleEntry> _cyclesBox;
  Map<DateTime, CycleEntry> _entries = {};
  Map<DateTime, CycleEntry> get entries => Map.unmodifiable(_entries);

  // Store last applied state for undo
  Map<DateTime, CycleEntry>? _lastAppliedState;
  Timer? _undoTimer;
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

  // ====================== PERIOD LENGTH ======================

  int getAveragePeriodLength() {
    int totalDays = 0;
    int count = 0;
    final sorted = entries.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].phase == 'menstruation' ||
          sorted[i].flowIntensity != null) {
        int length = 1;
        while (i + 1 < sorted.length &&
            sorted[i + 1].date.difference(sorted[i].date).inDays == 1 &&
            (sorted[i + 1].phase == 'menstruation' ||
                sorted[i + 1].flowIntensity != null)) {
          length++;
          i++;
        }
        totalDays += length;
        count++;
      }
    }
    return count > 0 ? (totalDays / count).round() : 5;
  }

  double get currentCycleDay => getPeriodStarts().isNotEmpty
      ? DateTime.now().difference(getPeriodStarts().last).inDays + 1
      : 0;

  // ====================== DATE RANGES (with isPredicted and opacity) ======================

  List<DateRange> getDateRanges() {
    var ranges = <DateRange>[];
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
    ranges = _fillSmallGaps(ranges); // call new helper
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
    _lastAppliedState = Map.from(_entries); // for 90-second undo

    final starts = getPeriodStarts();
    if (starts.isEmpty && manualLastPeriod == null) return;

    final lastPeriod = starts.isNotEmpty ? starts.last : manualLastPeriod!;
    final avgCycle = starts.isNotEmpty
        ? getAverageCycleLength()
        : (manualCycleLength ?? 28).toDouble();
    final periodDays = starts.isNotEmpty
        ? getAveragePeriodLength()
        : (manualPeriodLength ?? 5);

    final avgCycleRounded = avgCycle.round();
    final lutealDays = 14;
    final now = DateTime.now();

    final pastLimit = pastMonths == 999
        ? DateTime(2000, 1, 1)
        : now.subtract(Duration(days: pastMonths * 30));

    final futureLimit = now.add(Duration(days: futureMonths * 30));

    final generated = <DateRange>[];

    // Forward for future
    DateTime current = lastPeriod;
    while (current.isBefore(futureLimit)) {
      _generateOneCycleBackward(
        current,
        avgCycleRounded,
        periodDays,
        lutealDays,
        generated,
        pastLimit,
        futureLimit,
      );
      current = current.add(Duration(days: avgCycleRounded));
    }

    // Backward for past gaps
    if (pastMonths > 0) {
      current = starts.isNotEmpty ? starts.first : lastPeriod;
      for (int i = 0; i < (pastMonths * 2); i++) {
        final prevPeriod = current.subtract(Duration(days: avgCycleRounded));
        _generateOneCycleBackward(
          prevPeriod,
          avgCycleRounded,
          periodDays,
          lutealDays,
          generated,
          pastLimit,
          futureLimit,
        );
        current = prevPeriod;
        if (prevPeriod.isBefore(pastLimit)) break;
      }
    }

    if (learnFromBody) {
      final adjustments = detectPhaseAdjustments();
      _applyGentleAdjustments(generated, adjustments);
    }

    // Fill small gaps post-generation
    final filled = _fillSmallGaps(generated);

    // Apply with safety rules
    for (var range in filled) {
      for (
        var d = range.start;
        !d.isAfter(range.end);
        d = d.add(const Duration(days: 1))
      ) {
        if (d.isBefore(pastLimit) || d.isAfter(futureLimit)) continue;

        final existing = getEntry(d);
        final isFuture = d.isAfter(now);

        if (existing == null) {
          addOrUpdateEntry(
            d,
            CycleEntry(date: d, phase: range.phase, isPredicted: true),
          );
        } else if (isFuture && existing.isPredictedValue) {
          existing.phase = range.phase;
          existing.isPredicted = true;
          addOrUpdateEntry(d, existing);
        } else if (!protectMenstruation &&
            existing.phase != 'menstruation' &&
            existing.isPredictedValue) {
          existing.phase = range.phase;
          existing.isPredicted = true;
          addOrUpdateEntry(d, existing);
        }
      }
    }

    _startUndoTimer();
    notifyListeners();
  }

  /// Returns a map of suggested phase shifts based on symptom patterns
  /// e.g., {'follicular': -2} means move follicular start 2 days earlier
  Map<String, int> detectPhaseAdjustments() {
    final adjustments = <String, int>{};
    final userEntries = _entries.values
        .where((e) => !e.isPredictedValue)
        .toList();
    if (userEntries.length < 10) return adjustments; // not enough data

    // Personal baselines (relative to her max)
    final maxEnergy = userEntries.map((e) => e.energyLevel ?? 0).reduce(max) > 0
        ? userEntries.map((e) => e.energyLevel ?? 0).reduce(max)
        : 5; // fallback if no data
    final maxMood = userEntries.map((e) => e.moodRating ?? 0).reduce(max) > 0
        ? userEntries.map((e) => e.moodRating ?? 0).reduce(max)
        : 5;
    final maxPain = userEntries.map((e) => e.painLevel ?? 0).reduce(max) > 0
        ? userEntries.map((e) => e.painLevel ?? 0).reduce(max)
        : 5;

    // Symptom clusters (fixed + custom if consistent in 3+ cycles)
    final symptomPhaseCount = <String, Map<String, int>>{};
    final fixedSymptoms = [
      'cramps',
      'bloating',
      'headache',
      'breastTenderness',
      'fatigue',
      'nausea',
      'moodSwings',
      'acne',
      'backPain',
      'cravings',
    ];

    for (var entry in userEntries) {
      if (entry.phase == null) continue;
      for (var symptom in entry.symptoms.keys.where(
        (k) => entry.symptoms[k] == true,
      )) {
        // Allow custom if it appears in 3+ entries
        if (fixedSymptoms.contains(symptom) ||
            userEntries.where((e) => e.symptoms[symptom] == true).length >= 3) {
          symptomPhaseCount.putIfAbsent(symptom, () => {});
          symptomPhaseCount[symptom]![entry.phase!] =
              (symptomPhaseCount[symptom]![entry.phase!] ?? 0) + 1;
        }
      }
    }

    // Find preferred phase for each symptom (if consistent in 3+)
    final symptomPreferredPhase = <String, String>{};
    symptomPhaseCount.forEach((symptom, phaseMap) {
      final best = phaseMap.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (best.value >= 3) symptomPreferredPhase[symptom] = best.key;
    });

    // Gentle shifts based on patterns (max ±3 days)
    if (symptomPreferredPhase.containsKey('acne') &&
        symptomPreferredPhase['acne'] == 'luteal') {
      adjustments['luteal'] = 1; // extend luteal slightly
    }
    if (symptomPreferredPhase.containsKey('breastTenderness') &&
        symptomPreferredPhase['breastTenderness'] == 'luteal') {
      adjustments['luteal'] = 2;
    }

    // Energy/mood/pain shifts (relative)
    // Example: High energy in "luteal" → shift ovulation earlier
    final energyLutealList = userEntries
        .where((e) => e.phase == 'luteal' && e.energyLevel != null)
        .map((e) => e.energyLevel!)
        .toList();
    final avgEnergyLuteal = energyLutealList.isNotEmpty
        ? energyLutealList.reduce((a, b) => a + b) / energyLutealList.length
        : 0.0;
    if (avgEnergyLuteal > maxEnergy * 0.8) {
      adjustments['ovulation'] = -2; // shift earlier
    }

    // Pain spike pattern (extends luteal for PMS)
    final painLutealList = userEntries
        .where((e) => e.phase == 'luteal' && e.painLevel != null)
        .map((e) => e.painLevel!)
        .toList();
    if (painLutealList.isNotEmpty) {
      final avgPainLuteal =
          painLutealList.reduce((a, b) => a + b) / painLutealList.length;
      if (avgPainLuteal > maxPain * 0.7) {
        adjustments['luteal'] = 2; // extend luteal for PMS discomfort
      }
    }

    return adjustments;
  }

  void _generateOneCycleBackward(
    DateTime periodStart,
    int avgCycle,
    int periodDays,
    int lutealDays,
    List<DateRange> generated,
    DateTime pastLimit,
    DateTime futureLimit,
  ) {
    final nextPeriod = periodStart.add(Duration(days: avgCycle));
    final ovu = nextPeriod.subtract(Duration(days: lutealDays));
    final mentEnd = periodStart.add(Duration(days: periodDays - 1));

    // Luteal (stable, backward from period)
    generated.add(
      DateRange(
        start: ovu.add(const Duration(days: 1)),
        end: nextPeriod.subtract(const Duration(days: 1)),
        color: Colors.purple[300]!,
        phase: 'luteal',
        isPredicted: true,
        opacity: 0.45,
      ),
    );

    // Ovulation
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

    // Follicular (fills gap + handles small gaps with gradient)
    final follicStart = mentEnd.add(const Duration(days: 1));
    final follicEnd = ovu.subtract(const Duration(days: 1));
    if (follicStart.isBefore(follicEnd)) {
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
    } else if (follicStart.isAfter(follicEnd) &&
        follicStart.difference(follicEnd).inDays.abs() <= 4) {
      // Small gap - fill with extended follicular or gradient mix
      generated.add(
        DateRange(
          start: mentEnd.add(const Duration(days: 1)),
          end: ovu.subtract(const Duration(days: 1)),
          color: Colors
              .pink[200]!, // or blend with next (e.g., Colors.pink[200]!.mix(Colors.yellow[300]!, 0.5))
          phase: 'follicular', // or 'transition'
          isPredicted: true,
          opacity: 0.3, // lower for "mix"
        ),
      );
    }

    // Menstruation (anchored)
    generated.add(
      DateRange(
        start: periodStart,
        end: mentEnd,
        color: Colors.red[300]!,
        phase: 'menstruation',
        isPredicted: true,
        opacity: 0.45,
      ),
    );
  }

  void _applyGentleAdjustments(
    List<DateRange> ranges,
    Map<String, int> adjustments,
  ) {
    for (var adjustment in adjustments.entries) {
      final phase = adjustment.key;
      final shift = adjustment.value.clamp(-3, 3); // max 3 days
      for (var i = 0; i < ranges.length; i++) {
        if (ranges[i].phase == phase) {
          ranges[i] = DateRange(
            start: ranges[i].start.add(Duration(days: shift)),
            end: ranges[i].end.add(Duration(days: shift)),
            color: ranges[i].color,
            phase: phase,
            isPredicted: true,
            opacity: 0.45,
          );
        }
      }
    }
  }

  void _startUndoTimer() {
    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 90), () {
      _lastAppliedState = null;
      notifyListeners(); // optional refresh
    });
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

  String? getIrregularNote() {
    final lengths = [];
    final starts = getPeriodStarts();
    for (int i = 1; i < starts.length; i++) {
      lengths.add(starts[i].difference(starts[i - 1]).inDays);
    }
    if (lengths.length >= 2 &&
        (lengths.reduce((a, b) => max(a, b)) -
                lengths.reduce((a, b) => min(a, b)) >
            8)) {
      return "Your cycles are a bit irregular lately. This prediction is just a guide. You can always change anything.";
    }
    return null;
  }

  List<DateRange> _fillSmallGaps(List<DateRange> ranges) {
    ranges.sort((a, b) => a.start.compareTo(b.start));
    final filled = <DateRange>[];
    for (int i = 0; i < ranges.length; i++) {
      filled.add(ranges[i]);
      if (i + 1 < ranges.length) {
        final gapStart = ranges[i].end.add(const Duration(days: 1));
        final gapEnd = ranges[i + 1].start.subtract(const Duration(days: 1));
        if (gapStart.isBefore(gapEnd) &&
            gapEnd.difference(gapStart).inDays <= 4) {
          // Mix color for gap
          final mixColor = Color.lerp(
            ranges[i].color,
            ranges[i + 1].color,
            0.5,
          )!;
          filled.add(
            DateRange(
              start: gapStart,
              end: gapEnd,
              color: mixColor,
              phase: 'transition',
              isPredicted: true,
              opacity: 0.3, // less for "estimated"
            ),
          );
        }
      }
    }
    return filled;
  }
}
