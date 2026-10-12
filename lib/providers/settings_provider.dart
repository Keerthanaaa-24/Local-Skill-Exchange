import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/token_storage.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool sessionReminders;
  final bool bookingUpdates;
  final bool chatNotifications;
  final bool learningReminders;
  final bool achievementAlerts;
  final bool profileVisibility;
  final bool locationSharing;
  final bool nearbyMentorVisibility;
  final int dailyLearningGoalMinutes;
  final String preferredDifficulty;
  final String preferredContentType;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.sessionReminders = true,
    this.bookingUpdates = true,
    this.chatNotifications = true,
    this.learningReminders = true,
    this.achievementAlerts = true,
    this.profileVisibility = true,
    this.locationSharing = true,
    this.nearbyMentorVisibility = true,
    this.dailyLearningGoalMinutes = 30,
    this.preferredDifficulty = 'Intermediate',
    this.preferredContentType = 'All',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? sessionReminders,
    bool? bookingUpdates,
    bool? chatNotifications,
    bool? learningReminders,
    bool? achievementAlerts,
    bool? profileVisibility,
    bool? locationSharing,
    bool? nearbyMentorVisibility,
    int? dailyLearningGoalMinutes,
    String? preferredDifficulty,
    String? preferredContentType,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      sessionReminders: sessionReminders ?? this.sessionReminders,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      chatNotifications: chatNotifications ?? this.chatNotifications,
      learningReminders: learningReminders ?? this.learningReminders,
      achievementAlerts: achievementAlerts ?? this.achievementAlerts,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      locationSharing: locationSharing ?? this.locationSharing,
      nearbyMentorVisibility: nearbyMentorVisibility ?? this.nearbyMentorVisibility,
      dailyLearningGoalMinutes: dailyLearningGoalMinutes ?? this.dailyLearningGoalMinutes,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      preferredContentType: preferredContentType ?? this.preferredContentType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'sessionReminders': sessionReminders,
      'bookingUpdates': bookingUpdates,
      'chatNotifications': chatNotifications,
      'learningReminders': learningReminders,
      'achievementAlerts': achievementAlerts,
      'profileVisibility': profileVisibility,
      'locationSharing': locationSharing,
      'nearbyMentorVisibility': nearbyMentorVisibility,
      'dailyLearningGoalMinutes': dailyLearningGoalMinutes,
      'preferredDifficulty': preferredDifficulty,
      'preferredContentType': preferredContentType,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    ThemeMode mode = ThemeMode.light;
    final modeStr = json['themeMode']?.toString().toLowerCase();
    if (modeStr == 'dark') {
      mode = ThemeMode.dark;
    } else if (modeStr == 'system') {
      mode = ThemeMode.system;
    } else if (modeStr == 'light') {
      mode = ThemeMode.light;
    }

    return SettingsState(
      themeMode: mode,
      sessionReminders: json['sessionReminders'] as bool? ?? true,
      bookingUpdates: json['bookingUpdates'] as bool? ?? true,
      chatNotifications: json['chatNotifications'] as bool? ?? true,
      learningReminders: json['learningReminders'] as bool? ?? true,
      achievementAlerts: json['achievementAlerts'] as bool? ?? true,
      profileVisibility: json['profileVisibility'] as bool? ?? true,
      locationSharing: json['locationSharing'] as bool? ?? true,
      nearbyMentorVisibility: json['nearbyMentorVisibility'] as bool? ?? true,
      dailyLearningGoalMinutes: json['dailyLearningGoalMinutes'] as int? ?? 30,
      preferredDifficulty: json['preferredDifficulty'] as String? ?? 'Intermediate',
      preferredContentType: json['preferredContentType'] as String? ?? 'All',
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _storageKey = 'lse_user_settings_v1';

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final raw = await TokenStorage.read(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        state = SettingsState.fromJson(data);
      }
    } catch (_) {
      // Use defaults on parse error
    }
  }

  Future<void> _saveSettings(SettingsState newState) async {
    state = newState;
    try {
      await TokenStorage.write(_storageKey, jsonEncode(newState.toJson()));
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    _saveSettings(state.copyWith(themeMode: mode));
  }

  void toggleSessionReminders(bool value) {
    _saveSettings(state.copyWith(sessionReminders: value));
  }

  void toggleBookingUpdates(bool value) {
    _saveSettings(state.copyWith(bookingUpdates: value));
  }

  void toggleChatNotifications(bool value) {
    _saveSettings(state.copyWith(chatNotifications: value));
  }

  void toggleLearningReminders(bool value) {
    _saveSettings(state.copyWith(learningReminders: value));
  }

  void toggleAchievementAlerts(bool value) {
    _saveSettings(state.copyWith(achievementAlerts: value));
  }

  void toggleProfileVisibility(bool value) {
    _saveSettings(state.copyWith(profileVisibility: value));
  }

  void toggleLocationSharing(bool value) {
    _saveSettings(state.copyWith(locationSharing: value));
  }

  void toggleNearbyMentorVisibility(bool value) {
    _saveSettings(state.copyWith(nearbyMentorVisibility: value));
  }

  void setDailyLearningGoal(int minutes) {
    _saveSettings(state.copyWith(dailyLearningGoalMinutes: minutes));
  }

  void setPreferredDifficulty(String difficulty) {
    _saveSettings(state.copyWith(preferredDifficulty: difficulty));
  }

  void setPreferredContentType(String type) {
    _saveSettings(state.copyWith(preferredContentType: type));
  }

  Future<void> resetToDefaults() async {
    const defaultState = SettingsState();
    await _saveSettings(defaultState);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider.select((s) => s.themeMode));
});
