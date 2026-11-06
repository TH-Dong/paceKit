import 'app_database.dart';
import 'app_storage.dart';
import 'repositories.dart';

class AppResetService {
  AppResetService(this._db, this._profileRepository, this._habitRepository);

  final AppDatabase _db;
  final ProfileRepository _profileRepository;
  final HabitRepository _habitRepository;

  Future<void> clearAllLocalData() async {
    await _db.transaction(() async {
      await _db.delete(_db.completionEvents).go();
      await _db.delete(_db.habitRecords).go();
      await _db.delete(_db.memoTasks).go();
      await _db.delete(_db.planTasks).go();
      await _db.delete(_db.habitTemplates).go();
      await _db.delete(_db.userProfiles).go();
    });

    final avatarDirectory = await getAvatarStorageDirectory();
    if (await avatarDirectory.exists()) {
      await avatarDirectory.delete(recursive: true);
    }

    await _profileRepository.seedProfile();
    await _habitRepository.seedDefaultHabits();
  }
}
