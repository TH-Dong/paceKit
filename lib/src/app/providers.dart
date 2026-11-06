import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../core/planning_rules.dart';
import '../data/app_database.dart';
import '../data/app_reset_service.dart';
import '../data/repositories.dart';
import 'app_preferences.dart';

final clockProvider = Provider<AppClock>((ref) => const SystemClock());
final uuidProvider = Provider<Uuid>((ref) => const Uuid());

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    ref.watch(uuidProvider),
  );
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    ref.watch(uuidProvider),
  );
});

final memoRepositoryProvider = Provider<MemoRepository>((ref) {
  return MemoRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    ref.watch(uuidProvider),
  );
});

final completionRepositoryProvider = Provider<CompletionRepository>((ref) {
  return CompletionRepository(ref.watch(databaseProvider));
});

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
      ref.watch(databaseProvider), ref.watch(clockProvider));
});

final appResetServiceProvider = Provider<AppResetService>((ref) {
  return AppResetService(
    ref.watch(databaseProvider),
    ref.watch(profileRepositoryProvider),
    ref.watch(habitRepositoryProvider),
  );
});

final bootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(profileRepositoryProvider).seedProfile();
  await ref.watch(habitRepositoryProvider).seedDefaultHabits();
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._preferences) : super(ThemeMode.light) {
    unawaited(_load());
  }

  final AppPreferences _preferences;

  Future<void> _load() async {
    state = await _preferences.loadThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _preferences.saveThemeMode(mode);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(appPreferencesProvider));
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._preferences) : super(const Locale('zh')) {
    unawaited(_load());
  }

  final AppPreferences _preferences;

  Future<void> _load() async {
    state = await _preferences.loadLocale();
  }

  Future<void> setLocale(Locale locale) async {
    if (state.languageCode == locale.languageCode) return;
    state = locale;
    await _preferences.saveLocale(locale);
  }
}

final appLocaleProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController(ref.watch(appPreferencesProvider));
});

class PetKindController extends StateNotifier<String> {
  PetKindController(this._preferences) : super('leafbuds') {
    unawaited(_load());
  }

  final AppPreferences _preferences;

  Future<void> _load() async {
    state = await _preferences.loadPetKind();
  }

  Future<void> setPetKind(String petKind) async {
    if (state == petKind) return;
    state = petKind;
    await _preferences.savePetKind(petKind);
  }
}

final petKindProvider = StateNotifierProvider<PetKindController, String>((ref) {
  return PetKindController(ref.watch(appPreferencesProvider));
});

final planTasksProvider =
    StreamProvider.family<List<PlanTask>, DateTime>((ref, date) {
  return ref.watch(planRepositoryProvider).watchPlans(dateOnly(date));
});

final planTasksInRangeProvider =
    StreamProvider.family<List<PlanTask>, DateRange>((ref, range) {
  return ref.watch(planRepositoryProvider).watchPlansInRange(range);
});

final habitEntriesProvider =
    StreamProvider.family<List<HabitEntry>, DateTime>((ref, date) {
  return ref.watch(habitRepositoryProvider).watchHabitEntries(dateOnly(date));
});

final activeHabitTemplatesProvider = StreamProvider<List<HabitTemplate>>((ref) {
  return ref.watch(habitRepositoryProvider).watchActiveTemplates();
});

final habitRecordsInRangeProvider =
    StreamProvider.family<List<HabitRecord>, DateRange>((ref, range) {
  return ref.watch(habitRepositoryProvider).watchRecordsInRange(range);
});

final memoTasksProvider = StreamProvider<List<MemoTask>>((ref) {
  return ref.watch(memoRepositoryProvider).watchActiveMemos();
});

final memoTasksInRangeProvider =
    StreamProvider.family<List<MemoTask>, DateRange>((ref, range) {
  return ref.watch(memoRepositoryProvider).watchMemosInRange(range);
});

final completionEventsProvider =
    StreamProvider.family<List<CompletionEvent>, DateRange>((ref, range) {
  return ref.watch(completionRepositoryProvider).watchEvents(range);
});

final profileProvider = StreamProvider<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
});
