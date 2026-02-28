import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracker/providers/cycle_provider.dart';
import 'package:tracker/providers/settings_provider.dart';
import 'package:tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // for mini preview
import 'dart:async'; // for undo Timer

class AutomaticPhasesMakerScreen extends StatefulWidget {
  const AutomaticPhasesMakerScreen({super.key});

  @override
  State<AutomaticPhasesMakerScreen> createState() =>
      _AutomaticPhasesMakerScreenState();
}

class _AutomaticPhasesMakerScreenState
    extends State<AutomaticPhasesMakerScreen> {
  int futureMonths = 6; // default 6 (1-12)
  int pastMonths = 6; // default 6 (0-999 for All)
  bool protectMenstruation = true; // default ON (sacred!)
  bool learnFromBody = false; // set based on opens count
  String? symptomMessage; // cute message if patterns found
  String?
  cycleStory; // "You’ve logged X periods • Average Y days • Longest Z • Shortest W"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<AppSettingsProvider>();
      settings.incrementPhasesMakerOpens();
      if (settings.phasesMakerOpensCount >= 3) {
        setState(() {
          learnFromBody = true; // default ON from 3rd open
        });
      }
    });
  }

  // Cycle story summary
  void _updateCycleStory(CycleProvider provider) {
    final starts = provider.getPeriodStarts();
    final avg = provider.averageCycleLength.toStringAsFixed(1);
    final lengths = [];
    for (int i = 1; i < starts.length; i++) {
      lengths.add(starts[i].difference(starts[i - 1]).inDays);
    }
    final longest = lengths.isNotEmpty
        ? lengths.reduce((a, b) => a > b ? a : b)
        : 0;
    final shortest = lengths.isNotEmpty
        ? lengths.reduce((a, b) => a < b ? a : b)
        : 0;
    cycleStory =
        "You’ve logged ${starts.length} periods • Average $avg days • Longest $longest • Shortest $shortest";
  }

  // Cute symptom message (based on detected patterns)
  void _updateSymptomMessage(CycleProvider provider) {
    final patterns = provider.detectPhaseAdjustments(); // from provider
    if (patterns.isNotEmpty) {
      final symptoms = patterns.keys.join(', ');
      symptomMessage =
          "I noticed you often get $symptoms around these days\nThat usually means luteal phase for you.\nWant me to adjust slightly?";
    } else {
      symptomMessage = null;
    }
  }

  // Mini preview calendar (shows 2–3 months with colors + dotted predicted)
  Widget _buildPreviewCalendar(CycleProvider provider) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.previewChanges,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200, // small preview
          child: SingleChildScrollView(
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              multiRanges: provider
                  .getDateRanges(), // shows colors + predicted dotted
              headerVisible: false,
              daysOfWeekVisible: false,
            ),
          ),
        ),
        if (symptomMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              symptomMessage!,
              style: TextStyle(
                color: Colors.pink[300],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (provider.getIrregularNote() != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              provider.getIrregularNote()!,
              style: TextStyle(color: Colors.pink[200]),
            ),
          ),
      ],
    );
  }

  // No-period manual dialog (asks last period, menstruation days, cycle length)
  Future<void> _showManualInputDialog(
    CycleProvider provider,
    AppSettingsProvider settings,
  ) async {
    final t = AppLocalizations.of(context)!;
    DateTime? lastPeriod = DateTime.now().subtract(const Duration(days: 14));
    int periodLength = 5; // how many days does menstruation last
    int cycleLength = 28; // average cycle

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.noPeriodDetected),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(t.lastPeriodStart),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: lastPeriod ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => lastPeriod = picked);
                    }
                  },
                  child: Text(DateFormat.yMd().format(lastPeriod!)),
                ),
              ),
              ListTile(
                title: Text(
                  t.periodLengthDays,
                ), // how many days does menstruation last
                trailing: DropdownButton<int>(
                  value: periodLength,
                  items: List.generate(10, (i) => i + 1)
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => periodLength = v!),
                ),
              ),
              ListTile(
                title: Text(
                  t.cycleLengthDays,
                ), // how many days does your cycle last
                trailing: DropdownButton<int>(
                  value: cycleLength,
                  items: List.generate(30, (i) => i + 21)
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => cycleLength = v!),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              provider.predictAndApplyPhases(
                futureMonths: futureMonths,
                pastMonths: pastMonths,
                protectMenstruation: protectMenstruation,
                learnFromBody: learnFromBody,
                settings: settings,
                manualLastPeriod: lastPeriod,
                manualPeriodLength: periodLength,
                manualCycleLength: cycleLength,
              );
            },
            child: Text(t.apply),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (mounted) {
        Navigator.pop(context); // close maker
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.predictionsApplied),
            action: SnackBarAction(
              label: t.undo,
              onPressed: provider.undoLastPrediction,
            ),
            duration: const Duration(seconds: 90), // 90s
          ),
        );
      }
    }
  }

  // Quick "Clear future predictions only" button
  Widget _buildClearFutureButton(CycleProvider provider) {
    final t = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () {
        provider.clearFuturePredictions();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.futureCleared)));
      },
      icon: const Icon(Icons.clear),
      label: Text(t.clearFuturePredictions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<CycleProvider>();
    final settings = context.watch<AppSettingsProvider>();

    // Update cycle story & cute message
    _updateCycleStory(provider);
    _updateSymptomMessage(provider);

    return Scaffold(
      appBar: AppBar(title: Text(t.autoPhases)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My cycle story summary
            if (cycleStory != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  cycleStory!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Compact sliders card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSliderRow(
                      title: t.futurePredictions,
                      value: futureMonths,
                      max: 12,
                      min: 1,
                      onChanged: (v) =>
                          setState(() => futureMonths = v.toInt()),
                      label: "$futureMonths ${t.months}",
                      helpText: t.futurePredictionsHelp,
                    ),
                    const Divider(height: 40),
                    _buildSliderRow(
                      title: t.fillPastGaps,
                      value: pastMonths == 999 ? 24 : pastMonths,
                      max: 24,
                      min: 0,
                      onChanged: (v) {
                        final newVal = v.toInt();
                        setState(
                          () => pastMonths = newVal == 24 ? 999 : newVal,
                        );
                      },
                      label: pastMonths == 999
                          ? t.allMonths
                          : "$pastMonths ${t.months}",
                      helpText: t.fillPastGapsHelp,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(t.protectPeriodDays),
              subtitle: Text(t.protectPeriodDaysDesc),
              value: protectMenstruation,
              onChanged: (v) => setState(() => protectMenstruation = v),
            ),
            if (settings.phasesMakerOpensCount >= 3) // hidden first 2 times
              SwitchListTile(
                title: Text(t.learnFromBodySignals),
                subtitle: Text(t.learnFromBodyDesc),
                value: learnFromBody,
                onChanged: (v) => setState(() => learnFromBody = v),
              ),
            const SizedBox(height: 24),
            _buildPreviewCalendar(provider), // mini preview with colors
            const SizedBox(height: 24),
            _buildClearFutureButton(provider), // clear future only
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (provider.getPeriodStarts().isEmpty) {
                    await _showManualInputDialog(provider, settings);
                  } else {
                    provider.predictAndApplyPhases(
                      futureMonths: futureMonths,
                      pastMonths: pastMonths,
                      protectMenstruation: protectMenstruation,
                      learnFromBody: learnFromBody,
                      settings: settings,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t.predictionsApplied),
                          action: SnackBarAction(
                            label: t.undo,
                            onPressed: provider.undoLastPrediction,
                          ),
                          duration: const Duration(seconds: 90), // 90s
                        ),
                      );
                    }
                  }
                },
                child: Text(t.applyPredictions),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String title,
    required int value,
    required int max,
    required int min,
    required ValueChanged<double> onChanged,
    required String label,
    required String helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.help_outline, size: 18),
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  content: Text(helpText),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: label,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
