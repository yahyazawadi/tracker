import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tracker/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tracker/l10n/app_localizations.dart';
import 'package:tracker/providers/cycle_provider.dart';
import 'package:tracker/models/entry_model.dart';

class EntryScreen extends StatefulWidget {
  final DateTime selectedDate;
  final CycleEntry? existingEntry;

  const EntryScreen({
    super.key,
    required this.selectedDate,
    this.existingEntry,
  });

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  late CycleProvider _provider;
  late AppLocalizations t;
  late AppSettingsProvider _settingsProvider;

  // Form state
  String? _phase;
  String? _flowIntensity;
  int? _moodRating; // 1-5
  int? _energyLevel; // 1-5
  int? _painLevel; // 0-5
  final Map<String, bool> _symptoms = {};
  List<String> _photoPaths = [];
  bool _isPickingPhoto = false;

  CycleEntry? _existingEntry; // ← NEW: always loaded from Provider

  final _notesController = TextEditingController();
  final _flowDescController = TextEditingController();

  bool get _isEditing => _existingEntry != null;

  // Common symptoms (add to .arb later)
  final List<String> _symptomList = [
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    t = AppLocalizations.of(context)!;
    _provider = Provider.of<CycleProvider>(context, listen: false);
    _settingsProvider = Provider.of<AppSettingsProvider>(
      context,
      listen: false,
    );

    // Always load from Provider (most reliable way)
    _existingEntry = _provider.getEntry(widget.selectedDate);

    if (_existingEntry != null) {
      _phase = _existingEntry!.phase;
      _flowIntensity = _existingEntry!.flowIntensity;
      _flowDescController.text = _existingEntry!.flowDescription ?? '';

      _moodRating = _existingEntry!.moodRating;
      _energyLevel = _existingEntry!.energyLevel;
      _painLevel = _existingEntry!.painLevel;
      _notesController.text = _existingEntry!.notes ?? '';
      _photoPaths = List.from(_existingEntry!.photoPaths);

      _symptoms.clear();
      _symptoms.addAll(_existingEntry!.symptoms);

      // Force emoji selectors + chips to show selected state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      // New entry → reset everything
      _phase = null;
      _flowIntensity = null;
      _moodRating = null;
      _energyLevel = null;
      _painLevel = null;
      _flowDescController.clear();
      _notesController.clear();
      _photoPaths.clear();
      _symptoms.clear();

      // Auto-select phase from calendar ranges
      final ranges = _provider.getDateRanges();
      for (final range in ranges) {
        if (!widget.selectedDate.isBefore(range.start) &&
            !widget.selectedDate.isAfter(range.end)) {
          _phase = range.phase;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _flowDescController.dispose();
    super.dispose();
  }

  // ==================== SAVE ====================
  void _saveEntry() {
    HapticFeedback.mediumImpact();

    final entry = CycleEntry(
      date: widget.selectedDate,
      phase: _phase,
      flowIntensity: _flowIntensity,
      flowDescription: _flowDescController.text.trim().isEmpty
          ? null
          : _flowDescController.text.trim(),
      moodRating: _moodRating,
      energyLevel: _energyLevel,
      painLevel: _painLevel,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      symptoms: Map.from(_symptoms),
      photoPaths: List.from(_photoPaths),
      overallFeeling: null,
    );

    _provider.addOrUpdateEntry(widget.selectedDate, entry);

    _maybeAutoPredictAfterSave(entry);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? t.entryUpdated : t.entrySaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _maybeAutoPredictAfterSave(CycleEntry entry) {
    if (entry.phase == 'menstruation' || entry.flowIntensity != null) {
      final settings = context.read<AppSettingsProvider>();
      final autoPredictPref = settings.autoPredictAfterSave;

      if (autoPredictPref == null) {
        // Ask the user once
        bool rememberChoice = true; // default checked

        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              title: const Text("Update future predictions?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Want me to automatically update your cycle predictions when you log a period?",
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: rememberChoice,
                    onChanged: (v) => setDialogState(() => rememberChoice = v!),
                    title: const Text("Remember my choice"),
                    dense: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (rememberChoice) {
                      settings.autoPredictAfterSave = false;
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () {
                    if (rememberChoice) {
                      settings.autoPredictAfterSave = true;
                    }
                    _provider.predictAndApplyPhases(
                      futureMonths: 6,
                      pastMonths: 6,
                      protectMenstruation: true,
                      learnFromBody: settings.phasesMakerOpensCount >= 3,
                      settings: settings,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text("Yes"),
                ),
              ],
            ),
          ),
        );
      } else if (autoPredictPref == true) {
        // User previously said yes → auto-predict silently
        final settings = context.read<AppSettingsProvider>();
        _provider.predictAndApplyPhases(
          futureMonths: 6,
          pastMonths: 6,
          protectMenstruation: true,
          learnFromBody: settings.phasesMakerOpensCount >= 3,
          settings: settings,
        );
      }
      // If autoPredictPref == false, user said no → do nothing
    }
  }

  // ==================== PHOTOS ====================
  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPickingPhoto) return;

    setState(() => _isPickingPhoto = true);

    HapticFeedback.lightImpact();

    try {
      final permission = source == ImageSource.camera
          ? Permission.camera
          : Permission.photos;
      if (!await permission.request().isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.permissionDenied)));
        }
        return;
      }

      final XFile? file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (file == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(dir.path, 'photos'));
      await photosDir.create(recursive: true);

      final newName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
      final newPath = p.join(photosDir.path, newName);

      await File(file.path).copy(newPath);

      if (mounted) {
        setState(() => _photoPaths.add(newPath));
      }
    } catch (e) {
      print('Photo error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save photo')));
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  void _deletePhoto(int index) async {
    HapticFeedback.mediumImpact();
    final path = _photoPaths[index];
    try {
      await File(path).delete();
    } catch (e) {
      print('Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete photo')));
      }
      return;
    }
    if (mounted) setState(() => _photoPaths.removeAt(index));
  }

  void _showFullPhoto(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.file(File(path), fit: BoxFit.contain)),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Beautiful emoji selector (smaller emojis now!)
  Widget _buildEmojiSelector({
    required List<(String emoji, String label, int value)> options,
    required int? selectedValue,
    required Function(int) onSelected,
    bool usePainTheme = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = usePainTheme ? colorScheme.error : colorScheme.primary;
    final bgColor = usePainTheme
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;

    return Wrap(
      spacing: 20,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: options.map((option) {
        final isSelected = selectedValue == option.$3;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onSelected(option.$3);
          },
          child: AnimatedScale(
            scale: isSelected ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8), // tighter padding
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? bgColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : Colors.grey.withOpacity(0.35),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accentColor.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    option.$1,
                    style: TextStyle(
                      fontSize: isSelected
                          ? 37
                          : 33, // ← slightly smaller emojis
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 74,
                  child: Text(
                    option.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? accentColor : colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? t.editEntry : t.newEntry),
        actions: _isEditing
            ? [
                TextButton(
                  onPressed: _showDeleteConfirmation,
                  child: Text(
                    t.delete,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(),
            const SizedBox(height: 12),
            Text(
              t.everythingOptional,
              style: theme.textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            _buildLivePhasePreview(),
            const SizedBox(height: 40),
            _buildSectionTitle(t.phase),
            _buildPhaseSelector(),
            const SizedBox(height: 40),
            _buildSectionTitle(t.flow),
            _buildFlowChips(),
            const SizedBox(height: 12),
            TextField(
              controller: _flowDescController,
              decoration: InputDecoration(
                labelText: t.flowDescription,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 40),
            _buildSectionTitle(t.mood), // ← restored
            _buildMoodSelector(),
            const SizedBox(height: 40),
            _buildSectionTitle(t.energy), // ← restored
            _buildEnergySelector(),
            const SizedBox(height: 40),
            _buildSectionTitle(t.pain), // ← restored
            _buildPainSelector(),
            const SizedBox(height: 40),
            _buildSectionTitle(t.symptoms),
            _buildSymptomsChips(),
            const SizedBox(height: 40),
            _buildSectionTitle('${t.photos} (${_photoPaths.length})'),
            _buildPhotoSection(),
            const SizedBox(height: 40),
            _buildSectionTitle(t.notes),
            TextField(
              controller: _notesController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: t.notesHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 60),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isEditing ? t.update : t.save,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final dateStr = DateFormat(
      'EEEE, d MMMM yyyy',
      t.localeName,
    ).format(widget.selectedDate);
    final isToday = isSameDay(widget.selectedDate, DateTime.now());

    return Row(
      children: [
        Expanded(
          child: Text(
            dateStr,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
        ),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              t.today,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLivePhasePreview() {
    final color = _provider.getPhaseColor(_phase);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      height: 14,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(
      bottom: 16,
    ), // ← increased for breathing room
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
  );

  // Phase Selector (colored cards)
  Widget _buildPhaseSelector() {
    final phases = ['menstruation', 'follicular', 'ovulation', 'luteal'];
    final labels = [t.menstruation, t.follicular, t.ovulation, t.luteal];

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: [
        for (int i = 0; i < phases.length; i++)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _phase = phases[i]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _phase == phases[i]
                    ? _provider.getPhaseColor(phases[i])
                    : Colors.transparent,
                border: Border.all(
                  color: _provider.getPhaseColor(phases[i]),
                  width: _phase == phases[i] ? 0 : 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _phase == phases[i]
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        // None
        GestureDetector(
          onTap: () => setState(() => _phase = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _phase == null ? Colors.grey[400] : Colors.transparent,
              border: Border.all(
                color: Colors.grey[400]!,
                width: _phase == null ? 0 : 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(t.none, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // Flow Chips
  Widget _buildFlowChips() {
    final flows = ['light', 'medium', 'heavy', 'spotting'];
    final labels = [t.flowLight, t.flowMedium, t.flowHeavy, t.flowSpotting];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (int i = 0; i < flows.length; i++)
          FilterChip(
            label: Text(labels[i]),
            selected: _flowIntensity == flows[i],
            onSelected: (_) => setState(() => _flowIntensity = flows[i]),
            selectedColor: Colors.pink.withOpacity(0.2),
          ),
        FilterChip(
          label: Text(t.none),
          selected: _flowIntensity == null,
          onSelected: (_) => setState(() => _flowIntensity = null),
        ),
      ],
    );
  }

  // Mood Selector (single with labels)
  Widget _buildMoodSelector() {
    return _buildEmojiSelector(
      options: [
        ('😢', t.moodSad, 1),
        ('😐', t.moodNeutral, 2),
        ('🙂', t.moodOkay, 3),
        ('😊', t.moodHappy, 4),
        ('🥰', t.moodAmazing, 5),
      ],
      selectedValue: _moodRating,
      onSelected: (v) => setState(() => _moodRating = v),
    );
  }

  Widget _buildEnergySelector() {
    return _buildEmojiSelector(
      options: [
        ('😴', t.energyVeryLow, 1),
        ('🥱', t.energyLow, 2),
        ('😐', t.energyMedium, 3),
        ('⚡', t.energyHigh, 4),
        ('🔥', t.energyVeryHigh, 5),
      ],
      selectedValue: _energyLevel,
      onSelected: (v) => setState(() => _energyLevel = v),
    );
  }

  Widget _buildPainSelector() {
    return _buildEmojiSelector(
      options: [
        ('😊', t.noPain, 0),
        ('🙂', '1', 1),
        ('😐', '2', 2),
        ('😣', '3', 3),
        ('😖', '4', 4),
        ('😭', '5', 5),
      ],
      selectedValue: _painLevel,
      onSelected: (v) => setState(() => _painLevel = v),
      usePainTheme: true,
    );
  }

  // Symptoms Chips (multi)
  Widget _buildSymptomsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _symptomList.map((key) {
        final selected = _symptoms[key] ?? false;
        return FilterChip(
          label: Text(key), // Replace with t.symptomCramps etc. later
          selected: selected,
          onSelected: (val) => setState(() => _symptoms[key] = val),
        );
      }).toList(),
    );
  }

  // Photos Section
  Widget _buildPhotoSection() {
    return Column(
      children: [
        if (_photoPaths.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photoPaths.length,
              itemBuilder: (context, index) {
                final path = _photoPaths[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showFullPhoto(path),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(path),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _deletePhoto(index),
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isPickingPhoto
                  ? null
                  : () => _pickPhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: Text(t.camera),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isPickingPhoto
                  ? null
                  : () => _pickPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: Text(t.gallery),
            ),
          ],
        ),
        if (_isPickingPhoto)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Saving photo...',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        if (_photoPaths.isEmpty && !_isPickingPhoto)
          Center(
            child: Text(
              t.addPhotosHint,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteEntry),
        content: Text(t.deleteEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              _provider.deleteEntry(widget.selectedDate);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(t.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
