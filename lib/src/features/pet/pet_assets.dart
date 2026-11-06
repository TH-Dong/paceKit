import '../../core/planning_rules.dart';

enum PetKind { leafbuds, clouds, strawberry }

class PetAssets {
  const PetAssets._();

  static const normal = 'pet/leafbuds_transparent/leafbuds_normal.png';
  static const happy = 'pet/leafbuds_transparent/leafbuds_happy.png';
  static const sad = 'pet/leafbuds_transparent/leafbuds_sad.png';
  static const running = 'pet/leafbuds_transparent/leafbuds_running.png';
  static const sleep = 'pet/leafbuds_transparent/leafbuds_sleeping.png';
  static const empty = 'pet/leafbuds_transparent/leafbuds_empty.png';

  static const cloudsNormal = 'pet/Clouds_transparent/clouds_normal.png';
  static const cloudsHappy = 'pet/Clouds_transparent/clouds_happy.png';
  static const cloudsSad = 'pet/Clouds_transparent/clouds_sad.png';
  static const cloudsRunning = 'pet/Clouds_transparent/clouds_running.png';
  static const cloudsSleep = 'pet/Clouds_transparent/clouds_sleep.png';
  static const cloudsEmpty = 'pet/Clouds_transparent/clouds_empty.png';

  static const strawberryNormal =
      'pet/Strawberry_transparent/strawberry_normal.png';
  static const strawberryHappy =
      'pet/Strawberry_transparent/strawberry_happy.png';
  static const strawberrySad = 'pet/Strawberry_transparent/strawberry_sad.png';
  static const strawberryRunning =
      'pet/Strawberry_transparent/strawberry_runing.png';
  static const strawberrySleep =
      'pet/Strawberry_transparent/strawberry_sleep.png';
  static const strawberryEmpty =
      'pet/Strawberry_transparent/strawberry_empty.png';

  static String mood(PetMood mood) {
    return moodForKind(PetKind.leafbuds, mood);
  }

  static String moodForKind(PetKind kind, PetMood mood) {
    return switch (mood) {
      PetMood.happy => _family(kind).happy,
      PetMood.normal => _family(kind).normal,
      PetMood.sad => _family(kind).sad,
    };
  }

  static String runningForKind(PetKind kind) => _family(kind).running;

  static String sleepForKind(PetKind kind) => _family(kind).sleep;

  static String emptyForKind(PetKind kind) => _family(kind).empty;

  static PetKind kindFromName(String value) {
    return switch (value) {
      'clouds' => PetKind.clouds,
      'strawberry' => PetKind.strawberry,
      _ => PetKind.leafbuds,
    };
  }

  static String nameOf(PetKind kind) => kind.name;

  static _PetAssetFamily _family(PetKind kind) {
    return switch (kind) {
      PetKind.leafbuds => const _PetAssetFamily(
          normal: normal,
          happy: happy,
          sad: sad,
          running: running,
          sleep: sleep,
          empty: empty,
        ),
      PetKind.clouds => const _PetAssetFamily(
          normal: cloudsNormal,
          happy: cloudsHappy,
          sad: cloudsSad,
          running: cloudsRunning,
          sleep: cloudsSleep,
          empty: cloudsEmpty,
        ),
      PetKind.strawberry => const _PetAssetFamily(
          normal: strawberryNormal,
          happy: strawberryHappy,
          sad: strawberrySad,
          running: strawberryRunning,
          sleep: strawberrySleep,
          empty: strawberryEmpty,
        ),
    };
  }
}

class _PetAssetFamily {
  const _PetAssetFamily({
    required this.normal,
    required this.happy,
    required this.sad,
    required this.running,
    required this.sleep,
    required this.empty,
  });

  final String normal;
  final String happy;
  final String sad;
  final String running;
  final String sleep;
  final String empty;
}
