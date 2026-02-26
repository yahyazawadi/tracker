import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tracker/l10n/app_localizations.dart';
import 'package:tracker/providers/cycle_provider.dart';
import 'package:tracker/screens/automatic_phases_maker_screen.dart';
import 'package:tracker/screens/calendar/phase_calendar.dart';
import 'package:tracker/screens/entries/entry_screen.dart'; // Your entry form
import './stat_item.dart'; // Separate widget
import './legend_row.dart'; // Separate widget

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CycleProvider cycleProvider;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart; // Only used in range mode now
  bool _showStats = true;
  bool _showLegendTutorial = true;
  bool _isRangeMode = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    final settingsBox = Hive.box('settings');
    _showLegendTutorial =
        settingsBox.get('showLegendTutorial', defaultValue: true) as bool;
    cycleProvider = Provider.of<CycleProvider>(context, listen: false);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() => _focusedDay = focusedDay);

    if (_isRangeMode) {
      if (_rangeStart == null) {
        // First tap
        setState(() => _rangeStart = selectedDay);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      } else {
        // Second tap → create range (mode STAYS ON)
        final start = _rangeStart!;
        final end = selectedDay.isBefore(start) ? start : selectedDay;
        final realStart = selectedDay.isBefore(start) ? selectedDay : start;

        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        _promptPhaseForRange(realStart, end);

        // Clear temp highlight immediately (mode stays on for more ranges)
        setState(() => _rangeStart = null);
      }
    } else {
      // Normal mode
      setState(() => _selectedDay = selectedDay);
      _showDayDetails(selectedDay);
    }
  }

  void _promptPhaseForRange(DateTime start, DateTime end) {
    final t = AppLocalizations.of(context)!;
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        String? selectedPhase = 'menstruation'; // null = None/Clear

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewColor = selectedPhase == null
                ? Colors.grey[400]!
                : cycleProvider.getPhaseColor(selectedPhase);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              title: Text(
                '${t.selectPhase}\n${DateFormat.yMd().format(start)} – ${DateFormat.yMd().format(end)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, height: 1.3),
              ),
              contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // None / Clear (first option)
                  RadioListTile<String?>(
                    value: null,
                    groupValue: selectedPhase,
                    dense: true,
                    onChanged: (v) => setDialogState(() => selectedPhase = v),
                    title: Row(
                      children: [
                        Icon(
                          Icons.circle_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.outline, // theme-aware
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(t.noneClear, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                  const Divider(height: 4),
                  // 4 phases
                  ...['menstruation', 'follicular', 'ovulation', 'luteal'].map((
                    phase,
                  ) {
                    final color = cycleProvider.getPhaseColor(phase);
                    final label = switch (phase) {
                      'menstruation' => t.menstruation,
                      'follicular' => t.follicular,
                      'ovulation' => t.ovulation,
                      'luteal' => t.luteal,
                      _ => '',
                    };
                    return RadioListTile<String>(
                      value: phase,
                      groupValue: selectedPhase,
                      dense: true,
                      onChanged: (v) => setDialogState(() => selectedPhase = v),
                      title: Row(
                        children: [
                          Icon(Icons.circle, color: color, size: 20),
                          const SizedBox(width: 12),
                          Text(label, style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // Tiny preview bar (no big text, minimal space)
                  Container(
                    height: 8,
                    width: 120,
                    decoration: BoxDecoration(
                      color: previewColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.cancel, style: const TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () {
                    cycleProvider.addOrUpdatePhaseRange(
                      start,
                      end,
                      selectedPhase,
                    );
                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: previewColor,
                    foregroundColor: selectedPhase == null
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.white, // theme-aware
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: Text(selectedPhase == null ? t.clear : t.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDayDetails(DateTime day) {
    final t = AppLocalizations.of(context)!;
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
    final entry = cycleProvider.getEntry(day);
    showBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day} / ${day.month} / ${day.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (entry != null) ...[
                Text('${t.phase}: ${_translatePhase(entry.phase, t)}'),
                Text('${t.flow}: ${_flowLabel(entry.flowIntensity, t)}'),
                Text('${t.mood}: ${entry.moodRating ?? t.notAvailable}'),
                Text('${t.pain}: ${entry.painLevel ?? t.notAvailable}'),
                Text('${t.feeling}: ${entry.overallFeeling ?? t.notAvailable}'),
                if (entry.photoPaths.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: entry.photoPaths.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.file(
                            File(entry.photoPaths[index]),
                            height: 50,
                            width: 50,
                          ),
                        );
                      },
                    ),
                  ),
                Text('${t.notes}: ${entry.notes ?? t.noNotes}'),
              ] else
                Text(t.noEntry),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t.close),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EntryScreen(selectedDate: day),
                        ),
                      );
                    },
                    child: Text(t.editAdd),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper function (put it in the same file or in an extension)
  String _flowLabel(String? intensity, AppLocalizations t) {
    if (intensity == null) return t.notAvailable;

    return switch (intensity.toLowerCase()) {
      'light' => t.flowLight,
      'medium' => t.flowMedium,
      'heavy' => t.flowHeavy,
      'spotting' => t.flowSpotting,
      _ => t.notAvailable, // fallback: show raw value
    };
  }

  // Helper function (add it in the same file or in a utils file)
  String _translatePhase(String? phase, AppLocalizations t) {
    if (phase == null) return t.notAvailable;

    return switch (phase.toLowerCase()) {
      'menstruation' => t.menstruation,
      'follicular' => t.follicular,
      'ovulation' => t.ovulation,
      'luteal' => t.luteal,
      _ => phase, // fallback: show the raw value if unknown
    };
  }

  void _showLegend() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.legend),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LegendRow(Colors.red[300]!, t.menstruation),
              LegendRow(Colors.pink[200]!, t.follicular),
              LegendRow(Colors.yellow[300]!, t.ovulation),
              LegendRow(Colors.purple[300]!, t.luteal),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _showLegendTutorial = false);
                Hive.box('settings').put('showLegendTutorial', false);
                Navigator.pop(context);
              },
              child: Text(t.gotIt),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cycleProvider = Provider.of<CycleProvider>(context);
    if (_showLegendTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLegend());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.calendar),
        actions: [
          // Range mode toggle
          IconButton(
            icon: Icon(_isRangeMode ? Icons.check_circle : Icons.edit_calendar),
            color: _isRangeMode
                ? Theme.of(context).colorScheme.primary
                : null, // theme-aware
            tooltip: _isRangeMode ? t.exitEditMode : t.editModeRanges,
            onPressed: () => setState(() {
              _isRangeMode = !_isRangeMode;
              if (!_isRangeMode) _rangeStart = null; // Clear leftover highlight
            }),
          ),
          // Temp Clear button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: t.clearAllTest,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(t.clearCalendar),
                  content: Text(t.clearCalendarWarning),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(t.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        t.clear,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ), // theme-aware
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                cycleProvider.clearAllEntries();
                setState(() {
                  _selectedDay = _rangeStart = null;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showLegend,
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible stats bar
          ListTile(
            title: Text(t.cycleStats),
            trailing: Icon(_showStats ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _showStats = !_showStats),
          ),
          if (_showStats)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatItem(
                    t.currentCycleDay,
                    '${cycleProvider.currentCycleDay}',
                  ),
                  StatItem(
                    t.daysUntilPeriod,
                    '${cycleProvider.daysUntilPeriod}',
                  ),
                  StatItem(
                    t.averageCycleLength,
                    '${cycleProvider.averageCycleLength} ${t.days}',
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                PhaseCalendar(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  rangeStart: _rangeStart,
                  calendarFormat: _calendarFormat,
                  isRangeMode: _isRangeMode,
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() => _calendarFormat = format);
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                // Range mode banner
                if (_isRangeMode)
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: Material(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer, // theme-aware
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _rangeStart == null
                              ? t.editModeOnTapFirst
                              : t.tapEndingDay,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer, // theme-aware
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                if (cycleProvider.entries.isEmpty)
                  IgnorePointer(
                    child: Center(
                      child: Text(
                        t.emptyStateMessage,
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant, // theme-aware
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.auto_awesome), // magic wand icon
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => AutomaticPhasesMakerScreen()),
      //     );
      //   },
      // ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.add),
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) =>
      //             EntryScreen(selectedDate: _selectedDay ?? DateTime.now()),
      //       ),
      //     );
      //   },
      // ),
    );
  }
}
