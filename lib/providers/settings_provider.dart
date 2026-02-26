import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import '../l10n/app_localizations.dart';

class AppSettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  double _textScale = 1.0;
  bool _hasTextScaleOverride = false;
  set hasTextScaleOverride(bool value) {
    _hasTextScaleOverride = value;
    notifyListeners();
  }

  FlexScheme _selectedScheme = FlexScheme.mandyRed;

  Set<int> _weekendDays = {DateTime.friday, DateTime.saturday};

  static const Map<String, bool> _defaultExpansionStates = {
    'themeStyle': true,
    'appearanceMode': false,
    'language': false,
    'weekendDays': false,
  };
  Map<String, bool> _expansionStates = Map<String, bool>.from(
    _defaultExpansionStates,
  );

  AppSettingsProvider(this._prefs) {
    _loadSettings();
  }

  // ── Theme display names map ────────────────────────────────────────────────
  static String getThemeDisplayName(BuildContext context, FlexScheme scheme) {
    final t = AppLocalizations.of(context)!;
    switch (scheme) {
      case FlexScheme.mandyRed:
        return t.themeMandyRed;
      case FlexScheme.redWine:
        return t.themeRedWine;
      case FlexScheme.deepPurple:
        return t.themeDeepPurple;
      case FlexScheme.sakura:
        return t.themeSakura;
      case FlexScheme.purpleBrown:
        return t.themePurpleBrown;
      case FlexScheme.jungle:
        return t.themeJungle;
      case FlexScheme.shadBlue:
        return t.themeShadBlue;
      case FlexScheme.sanJuanBlue:
        return t.themeSanJuanBlue;
      case FlexScheme.indigo:
        return t.themeIndigo;
      case FlexScheme.brandBlue:
        return t.themeBrandBlue;
      case FlexScheme.purpleM3:
        return t.themePurpleM3;
      default:
        return scheme.name;
    }
  }

  void _loadSettings() {
    // Theme mode
    final modeIndex = _prefs.getInt('themeMode') ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[modeIndex];

    // Locale
    final lang = _prefs.getString('language') ?? 'en';
    _locale = Locale(lang);

    // Text scale
    _hasTextScaleOverride = _prefs.containsKey('textScale');
    if (_hasTextScaleOverride) {
      _textScale = _prefs.getDouble('textScale') ?? 1.0;
    }

    // Selected theme scheme
    final schemeName = _prefs.getString('themeScheme') ?? 'mandyRed';
    _selectedScheme = _schemeFromName(schemeName) ?? FlexScheme.mandyRed;

    final savedDays = _prefs.getString('weekendDays');
    if (savedDays == null) {
      _weekendDays = _locale.languageCode == 'ar'
          ? {DateTime.friday, DateTime.saturday}
          : {DateTime.saturday, DateTime.sunday};
    } else {
      _weekendDays = savedDays
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toSet();
    }

    final savedExpansion = _prefs.getString('expansion_states');
    if (savedExpansion != null) {
      try {
        final decoded = jsonDecode(savedExpansion);
        if (decoded is Map) {
          final map = decoded.map(
            (key, value) => MapEntry(key.toString(), value == true),
          );
          _expansionStates = {..._defaultExpansionStates, ...map};
        }
      } catch (_) {
        _expansionStates = Map<String, bool>.from(_defaultExpansionStates);
      }
    } else {
      _expansionStates = Map<String, bool>.from(_defaultExpansionStates);
    }

    notifyListeners();
  }

  // ── Getters ────────────────────────────────────────────────────────────────
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  double get textScale => _textScale;
  bool get hasTextScaleOverride => _hasTextScaleOverride;
  FlexScheme get selectedScheme => _selectedScheme;
  Set<int> get weekendDays => _weekendDays;
  List<int> get weekendDaysList => _weekendDays.toList();
  bool isSectionExpanded(String key) => _expansionStates[key] ?? false;

  // ── Setters ────────────────────────────────────────────────────────────────
  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  set locale(Locale loc) {
    _locale = loc;
    _prefs.setString('language', loc.languageCode);
    notifyListeners();
  }

  set textScale(double scale) {
    _textScale = scale.clamp(0.8, 2.0);
    _hasTextScaleOverride = true;
    _prefs.setDouble('textScale', _textScale);
    notifyListeners();
  }

  void resetTextScale() {
    _hasTextScaleOverride = false;
    _textScale = 1.0;
    _prefs.remove('textScale');
    notifyListeners();
  }

  void setScheme(FlexScheme scheme) {
    _selectedScheme = scheme;
    _prefs.setString('themeScheme', _nameFromScheme(scheme));
    notifyListeners();
  }

  void toggleWeekendDay(int day) {
    if (_weekendDays.contains(day)) {
      _weekendDays.remove(day);
    } else {
      _weekendDays.add(day);
    }
    _saveWeekendDays();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    await Future.wait([
      _prefs.remove('themeMode'),
      _prefs.remove('language'),
      _prefs.remove('textScale'),
      _prefs.remove('themeScheme'),
      _prefs.remove('weekendDays'),
      _prefs.remove('expansion_states'),
    ]);
    _loadSettings();
  }

  void setSectionExpanded(String key, bool expanded) {
    if (_expansionStates[key] == expanded) return;
    _expansionStates[key] = expanded;
    _saveExpansionStates();
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  FlexScheme? _schemeFromName(String name) {
    const map = {
      'mandyRed': FlexScheme.mandyRed,
      'redWine': FlexScheme.redWine,
      'deepPurple': FlexScheme.deepPurple,
      'sakura': FlexScheme.sakura,
      'purpleBrown': FlexScheme.purpleBrown,
      'jungle': FlexScheme.jungle,
      'shadBlue': FlexScheme.shadBlue,
      'sanJuanBlue': FlexScheme.sanJuanBlue,
      'indigo': FlexScheme.indigo,
      'brandBlue': FlexScheme.brandBlue,
      'purpleM3': FlexScheme.purpleM3,
    };
    return map[name];
  }

  String _nameFromScheme(FlexScheme scheme) {
    const reverseMap = {
      FlexScheme.mandyRed: 'mandyRed',
      FlexScheme.redWine: 'redWine',
      FlexScheme.deepPurple: 'deepPurple',
      FlexScheme.sakura: 'sakura',
      FlexScheme.purpleBrown: 'purpleBrown',
      FlexScheme.jungle: 'jungle',
      FlexScheme.shadBlue: 'shadBlue',
      FlexScheme.sanJuanBlue: 'sanJuanBlue',
      FlexScheme.indigo: 'indigo',
      FlexScheme.brandBlue: 'brandBlue',
      FlexScheme.purpleM3: 'purpleM3',
    };
    return reverseMap[scheme] ?? 'mandyRed';
  }

  void _saveWeekendDays() {
    final saved = _weekendDays.join(',');
    _prefs.setString('weekendDays', saved);
  }

  void _saveExpansionStates() {
    _prefs.setString('expansion_states', jsonEncode(_expansionStates));
  }

  // ── Flow Options (ديناميكي) ───────────────────────────────────────────────
  List<String> _flowOptions = ['light', 'medium', 'heavy', 'spotting'];

  List<String> get flowOptions => List.unmodifiable(_flowOptions);

  void addFlowOption(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty || _flowOptions.contains(trimmed)) return;
    _flowOptions.add(trimmed);
    _prefs.setString('flowOptions', jsonEncode(_flowOptions));
    notifyListeners();
  }

  void removeFlowOption(String value) {
    _flowOptions.remove(value);
    _prefs.setString('flowOptions', jsonEncode(_flowOptions));
    notifyListeners();
  }

  // ── Symptoms (ديناميكي) ───────────────────────────────────────────────────
  List<String> _symptomOptions = [
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

  List<String> get symptomOptions => List.unmodifiable(_symptomOptions);

  void addSymptomOption(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _symptomOptions.contains(trimmed)) return;
    _symptomOptions.add(trimmed);
    _prefs.setString('symptomOptions', jsonEncode(_symptomOptions));
    notifyListeners();
  }

  void removeSymptomOption(String value) {
    _symptomOptions.remove(value);
    _prefs.setString('symptomOptions', jsonEncode(_symptomOptions));
    notifyListeners();
  }
}
