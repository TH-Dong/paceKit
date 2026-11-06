import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pacekit/src/core/clock.dart';
import 'package:pacekit/src/data/app_database.dart';
import 'package:pacekit/src/data/repositories.dart';

void main() {
  group('ProfileRepository', () {
    late AppDatabase db;
    late ProfileRepository profiles;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      profiles = ProfileRepository(
        db,
        FixedClock(DateTime(2026, 5, 4, 22)),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('updates nickname and avatar uri for local profile', () async {
      await profiles.seedProfile();

      await profiles.updateNickname('  小绿芽  ');
      await profiles.updateAvatarUri(
        'asset:pet/Strawberry/strawberry_happy.png',
      );

      final profile = await db.select(db.userProfiles).getSingle();

      expect(profile.nickname, '小绿芽');
      expect(profile.avatarUri, 'asset:pet/Strawberry/strawberry_happy.png');
      expect(profile.updatedAt, DateTime(2026, 5, 4, 22));
    });
  });
}
