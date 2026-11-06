import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/planning_rules.dart';
import 'pet_assets.dart';

class PetImage extends ConsumerWidget {
  const PetImage({
    this.mood = PetMood.normal,
    this.asset,
    this.size = 132,
    super.key,
  });

  final PetMood mood;
  final String? asset;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petKind = PetAssets.kindFromName(ref.watch(petKindProvider));
    return Image.asset(
      asset ?? PetAssets.moodForKind(petKind, mood),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.cruelty_free, size: size * 0.55);
      },
    );
  }
}
