import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../app/app_strings.dart';
import '../../app/providers.dart';
import '../../core/planning_rules.dart';
import '../../data/app_storage.dart';
import '../../features/pet/pet_assets.dart';
import '../../features/pet/pet_image.dart';

const _settingGreen = Color(0xFF36B96A);
const _settingPurple = Color(0xFF8A63E8);
const _settingRed = Color(0xFFE44A4A);

const _avatarOptions = <_AvatarOption>[
  _AvatarOption('绿芽开心', PetAssets.happy),
  _AvatarOption('绿芽日常', PetAssets.normal),
  _AvatarOption('绿芽奔跑', PetAssets.running),
  _AvatarOption('绿芽睡觉', PetAssets.sleep),
  _AvatarOption('云朵伙伴', PetAssets.cloudsHappy),
  _AvatarOption('草莓伙伴', PetAssets.strawberryHappy),
];

class _AvatarOption {
  const _AvatarOption(this.label, this.asset);

  final String label;
  final String asset;
}

class _SettingsPalette {
  const _SettingsPalette({
    required this.isDark,
    required this.ink,
    required this.muted,
    required this.line,
    required this.surface,
    required this.softSurface,
    required this.glassSurface,
    required this.glassBorder,
    required this.background,
    required this.shadow,
    required this.switchOffStart,
    required this.switchOffEnd,
  });

  final bool isDark;
  final Color ink;
  final Color muted;
  final Color line;
  final Color surface;
  final Color softSurface;
  final Color glassSurface;
  final Color glassBorder;
  final List<Color> background;
  final Color shadow;
  final Color switchOffStart;
  final Color switchOffEnd;

  factory _SettingsPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _SettingsPalette(
      isDark: isDark,
      ink: isDark ? const Color(0xFFF1F5F1) : const Color(0xFF26364B),
      muted: isDark ? const Color(0xFF9AA8A0) : const Color(0xFF7B8AA1),
      line: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE3E9E6),
      surface: isDark
          ? const Color(0xFF1D211F).withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.86),
      softSurface: isDark
          ? const Color(0xFF232824).withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.96),
      glassSurface: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.white.withValues(alpha: 0.96),
      glassBorder: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : const Color(0xFFEAF0ED),
      background: isDark
          ? const [
              Color(0xFF0D110F),
              Color(0xFF111614),
              Color(0xFF151917),
            ]
          : const [
              Color(0xFFFAFBFD),
              Color(0xFFF5F8F6),
              Color(0xFFF7F6FB),
            ],
      shadow: isDark
          ? Colors.black.withValues(alpha: 0.34)
          : const Color(0xFF8E9891).withValues(alpha: 0.11),
      switchOffStart:
          isDark ? const Color(0xFF2E3532) : const Color(0xFFE2E8EE),
      switchOffEnd: isDark
          ? const Color(0xFF3A433F).withValues(alpha: 0.94)
          : const Color(0xFFF6F7F8).withValues(alpha: 0.94),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final palette = _SettingsPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.background,
        ),
      ),
      child: profile.when(
        data: (value) => _SettingsContent(
          nickname: value.nickname,
          username: value.username,
          avatarUri: value.avatarUri,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _SettingsErrorView(error: error),
      ),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  const _SettingsContent({
    required this.nickname,
    required this.username,
    required this.avatarUri,
  });

  final String nickname;
  final String username;
  final String? avatarUri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).height < 760;
    final palette = _SettingsPalette.of(context);
    final strings = AppStrings.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(0, compact ? 2 : 12, 0, 124),
      physics: const BouncingScrollPhysics(),
      children: [
        Center(
          child: FractionallySizedBox(
            widthFactor: compact ? 0.94 : 0.93,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  _SettingsProfileHero(
                    nickname: nickname,
                    username: username,
                    avatarUri: avatarUri,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 18 : 22),
                  _SettingActionTile(
                    icon: Icons.pets_rounded,
                    title: strings.petSettings,
                    subtitle: strings.petSettingsSubtitle,
                    color: _settingGreen,
                    value: _petLabel(context, ref.watch(petKindProvider)),
                    compact: compact,
                    onTap: () => _showPetSettings(context, ref),
                  ),
                  _SettingActionTile(
                    icon: Icons.lock_rounded,
                    title: strings.accountSecurity,
                    subtitle: strings.accountSecuritySubtitle,
                    color: _settingPurple,
                    compact: compact,
                    onTap: () => _showComingSoon(context),
                  ),
                  _SettingActionTile(
                    icon: Icons.grid_view_rounded,
                    title: strings.widgets,
                    subtitle: strings.widgetsSubtitle,
                    color: _settingPurple,
                    compact: compact,
                    onTap: () => _showComingSoon(context),
                  ),
                  _SettingActionTile(
                    icon: Icons.language_rounded,
                    title: strings.language,
                    subtitle: strings.languageSubtitle,
                    color: _settingPurple,
                    value: _languageLabel(context),
                    compact: compact,
                    onTap: () => _showLanguageSettings(context, ref),
                  ),
                  _DarkModeTile(compact: compact),
                  SizedBox(height: compact ? 5 : 8),
                  _LogoutButton(compact: compact),
                  SizedBox(height: compact ? 16 : 18),
                  Text(
                    '版本 1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.muted.withValues(alpha: 0.55),
                      fontFamily: 'LXGWWenKaiScreen',
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 14),
                  _ResetDataButton(compact: compact),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsProfileHero extends ConsumerWidget {
  const _SettingsProfileHero({
    required this.nickname,
    required this.username,
    required this.avatarUri,
    required this.compact,
  });

  final String nickname;
  final String username;
  final String? avatarUri;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _SettingsPalette.of(context);
    return Column(
      children: [
        SizedBox(
          height: compact ? 144 : 170,
          child: _ProfileAvatarStage(
            avatarUri: avatarUri,
            compact: compact,
            onEditAvatar: () => _showAvatarPicker(context, ref, avatarUri),
          ),
        ),
        Transform.translate(
          offset: Offset(0, compact ? -8 : -11),
          child: _ChangeAvatarButton(
            compact: compact,
            onTap: () => _showAvatarPicker(context, ref, avatarUri),
          ),
        ),
        SizedBox(height: compact ? 15 : 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: compact ? 27 : 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showNicknameEditor(context, ref, nickname),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.edit_square,
                    color: _settingPurple,
                    size: compact ? 20 : 23,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _emailFor(nickname, username),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.muted.withValues(alpha: 0.92),
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatarStage extends StatelessWidget {
  const _ProfileAvatarStage({
    required this.avatarUri,
    required this.compact,
    required this.onEditAvatar,
  });

  final String? avatarUri;
  final bool compact;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final frame = compact ? 124.0 : 146.0;
    final innerFrame = compact ? 105.0 : 124.0;
    final petSize = compact ? 104.0 : 122.0;
    final editSize = compact ? 40.0 : 44.0;

    return Center(
      child: SizedBox(
        width: compact ? 276 : 320,
        height: compact ? 144 : 170,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ProfileSparklePainter()),
            ),
            Container(
              width: frame,
              height: frame,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.softSurface
                    .withValues(alpha: palette.isDark ? 0.78 : 0.84),
                border: Border.all(
                  color: palette.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE8DFFC).withValues(alpha: 0.86),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _settingPurple.withValues(
                        alpha: palette.isDark ? 0.20 : 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                  if (!palette.isDark)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.88),
                      blurRadius: 10,
                      offset: const Offset(-2, -4),
                    ),
                ],
              ),
              child: Center(
                child: Container(
                  width: innerFrame,
                  height: innerFrame,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.26, -0.35),
                      radius: 0.92,
                      colors: [
                        palette.isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.98),
                        palette.isDark
                            ? const Color(0xFF34294A).withValues(alpha: 0.52)
                            : const Color(0xFFF5F1FF).withValues(alpha: 0.82),
                        _settingPurple.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _AvatarImage(
              avatarUri: avatarUri,
              size: petSize,
              fallbackMood: PetMood.happy,
            ),
            Positioned(
              right: compact ? 75 : 86,
              bottom: compact ? 12 : 13,
              child: _AvatarEditButton(
                size: editSize,
                onTap: onEditAvatar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarEditButton extends StatelessWidget {
  const _AvatarEditButton({
    required this.size,
    required this.onTap,
  });

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.glassSurface,
            border: Border.all(
              color: palette.isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFECE6FA),
            ),
            boxShadow: [
              BoxShadow(
                color: _settingPurple.withValues(
                    alpha: palette.isDark ? 0.22 : 0.17),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.edit_rounded,
            color: _settingPurple,
            size: size * 0.50,
          ),
        ),
      ),
    );
  }
}

class _ChangeAvatarButton extends StatelessWidget {
  const _ChangeAvatarButton({
    required this.compact,
    required this.onTap,
  });

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final strings = AppStrings.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 17,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: palette.softSurface
                .withValues(alpha: palette.isDark ? 0.74 : 0.90),
            border: Border.all(
              color: palette.isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFE8E0F8),
            ),
            boxShadow: [
              BoxShadow(
                color: _settingPurple.withValues(
                    alpha: palette.isDark ? 0.18 : 0.13),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
              if (!palette.isDark)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.70),
                  blurRadius: 6,
                  offset: const Offset(-2, -3),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_size_select_actual_outlined,
                color: _settingPurple,
                size: compact ? 16 : 18,
              ),
              const SizedBox(width: 8),
              Text(
                strings.changeAvatar,
                style: TextStyle(
                  color: _settingPurple,
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingActionTile extends StatelessWidget {
  const _SettingActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.compact,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool compact;
  final VoidCallback onTap;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final tileHeight = compact ? 64.0 : 74.0;
    final iconSize = compact ? 44.0 : 52.0;
    final titleSize = compact ? 16.5 : 18.0;
    final subtitleSize = compact ? 11.6 : 12.6;

    return _SettingCardShell(
      margin: EdgeInsets.only(bottom: compact ? 10 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: tileHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 12 : 18,
                    compact ? 8 : 9,
                    compact ? 11 : 18,
                    compact ? 8 : 9,
                  ),
                  child: Row(
                    children: [
                      _SettingGlassIcon(
                        icon: icon,
                        color: color,
                        size: iconSize,
                      ),
                      SizedBox(width: compact ? 12 : 15),
                      Expanded(
                        child: _SettingTileCopy(
                          title: title,
                          subtitle: subtitle,
                          color: color,
                          titleSize: titleSize,
                          subtitleSize: subtitleSize,
                        ),
                      ),
                      if (value != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          value!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _settingPurple,
                            fontFamily: 'LXGWWenKaiScreen',
                            fontSize: compact ? 13 : 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: palette.muted.withValues(alpha: 0.64),
                        size: compact ? 24 : 28,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingTileCopy extends StatelessWidget {
  const _SettingTileCopy({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.titleSize,
    required this.subtitleSize,
  });

  final String title;
  final String subtitle;
  final Color color;
  final double titleSize;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontFamily: 'LXGWWenKaiScreen',
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.muted.withValues(alpha: 0.92),
            fontSize: subtitleSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.avatarUri,
    required this.size,
    required this.fallbackMood,
  });

  final String? avatarUri;
  final double size;
  final PetMood fallbackMood;

  @override
  Widget build(BuildContext context) {
    final filePath = _avatarFilePath(avatarUri);
    if (filePath != null) {
      return ClipOval(
        child: Image.file(
          File(filePath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return PetImage(mood: fallbackMood, size: size);
          },
        ),
      );
    }

    final asset = _avatarAssetPath(avatarUri);
    if (asset == null) {
      return PetImage(mood: fallbackMood, size: size);
    }

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (context, error, stackTrace) {
        return PetImage(mood: fallbackMood, size: size);
      },
    );
  }
}

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({
    required this.currentUri,
    required this.onPickImage,
    required this.onSelected,
  });

  final String? currentUri;
  final Future<void> Function() onPickImage;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final strings = AppStrings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.selectAvatar,
              style: TextStyle(
                color: palette.ink,
                fontFamily: 'LXGWWenKaiScreen',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.avatarSaved,
              style: TextStyle(
                color: palette.muted.withValues(alpha: 0.86),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(strings.pickFromGallery),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.appAvatars,
              style: TextStyle(
                color: palette.muted.withValues(alpha: 0.82),
                fontFamily: 'LXGWWenKaiScreen',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _avatarOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final option = _avatarOptions[index];
                final uri = _avatarAssetUri(option.asset);
                return _AvatarChoiceTile(
                  option: option,
                  selected: currentUri == uri ||
                      (currentUri == null && option.asset == PetAssets.happy),
                  onTap: () => onSelected(uri),
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => onSelected(null),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.resetDefaultAvatar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarChoiceTile extends StatelessWidget {
  const _AvatarChoiceTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _AvatarOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
          decoration: BoxDecoration(
            color: palette.softSurface
                .withValues(alpha: palette.isDark ? 0.86 : 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? _settingPurple.withValues(alpha: 0.70)
                  : palette.line,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? _settingPurple : palette.muted).withValues(
                  alpha: selected ? 0.16 : (palette.isDark ? 0.14 : 0.08),
                ),
                blurRadius: selected ? 16 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        option.asset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontFamily: 'LXGWWenKaiScreen',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: _settingPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkModeTile extends ConsumerWidget {
  const _DarkModeTile({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final mode = ref.watch(themeModeProvider);
    final enabled = mode == ThemeMode.dark;
    final tileHeight = compact ? 66.0 : 78.0;
    final iconSize = compact ? 48.0 : 56.0;

    return _SettingCardShell(
      margin: EdgeInsets.only(bottom: compact ? 10 : 12),
      child: SizedBox(
        height: tileHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            compact ? 8 : 10,
            compact ? 14 : 18,
            compact ? 8 : 10,
          ),
          child: Row(
            children: [
              _SettingGlassIcon(
                icon: Icons.nightlight_round,
                color: _settingPurple,
                size: iconSize,
              ),
              SizedBox(width: compact ? 12 : 15),
              Expanded(
                child: _SettingTileCopy(
                  title: strings.darkMode,
                  subtitle: strings.darkModeSubtitle,
                  color: _settingPurple,
                  titleSize: compact ? 18 : 20,
                  subtitleSize: compact ? 12.2 : 13.5,
                ),
              ),
              _PaceSwitch(
                value: enabled,
                compact: compact,
                onChanged: (value) async {
                  await ref.read(themeModeProvider.notifier).setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingCardShell extends StatelessWidget {
  const _SettingCardShell({
    required this.child,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: palette.surface,
        border: Border.all(
          color: palette.line.withValues(alpha: 0.95),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          if (!palette.isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.76),
              blurRadius: 8,
              offset: const Offset(-2, -3),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

class _SettingGlassIcon extends StatelessWidget {
  const _SettingGlassIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.glassSurface,
        border: Border.all(color: palette.glassBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          if (!palette.isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.86),
              blurRadius: 6,
              offset: const Offset(-2, -3),
            ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class _PaceSwitch extends StatelessWidget {
  const _PaceSwitch({
    required this.value,
    required this.compact,
    required this.onChanged,
  });

  final bool value;
  final bool compact;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final width = compact ? 58.0 : 66.0;
    final height = compact ? 34.0 : 38.0;
    final knob = compact ? 26.0 : 30.0;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: value
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF9367EF), Color(0xFF7B55D8)],
                )
              : LinearGradient(
                  colors: [
                    palette.switchOffStart,
                    palette.switchOffEnd,
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: (value ? _settingPurple : palette.muted)
                  .withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: knob,
            height: knob,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.glassSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: palette.isDark ? 0.24 : 0.11),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    final strings = AppStrings.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showComingSoon(context),
        borderRadius: BorderRadius.circular(23),
        child: Container(
          height: compact ? 58 : 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.softSurface
                .withValues(alpha: palette.isDark ? 0.58 : 0.52),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: _settingRed.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: _settingRed,
                size: compact ? 25 : 29,
              ),
              SizedBox(width: compact ? 12 : 15),
              Text(
                strings.logout,
                style: TextStyle(
                  color: _settingRed,
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: compact ? 20 : 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsErrorView extends StatelessWidget {
  const _SettingsErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _SettingCardShell(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '加载失败：$error',
              style: TextStyle(
                color: palette.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetDataButton extends ConsumerWidget {
  const _ResetDataButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _SettingsPalette.of(context);
    final strings = AppStrings.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _confirmResetData(context, ref),
        borderRadius: BorderRadius.circular(23),
        child: Container(
          height: compact ? 54 : 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.softSurface
                .withValues(alpha: palette.isDark ? 0.68 : 0.62),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: _settingRed.withValues(alpha: 0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_sweep_rounded,
                color: _settingRed,
                size: compact ? 22 : 25,
              ),
              SizedBox(width: compact ? 10 : 12),
              Text(
                strings.clearLocalData,
                style: TextStyle(
                  color: _settingRed,
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: compact ? 17 : 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSparklePainter extends CustomPainter {
  const _ProfileSparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    _drawSparkle(
      canvas,
      Offset(size.width * 0.06, size.height * 0.50),
      _settingGreen,
      5.0,
      paint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.13, size.height * 0.73),
      const Color(0xFF5FC9AC),
      4.2,
      paint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.19, size.height * 0.61),
      const Color(0xFFEBCB3A),
      4.5,
      paint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.82, size.height * 0.49),
      _settingGreen,
      5.0,
      paint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.78, size.height * 0.72),
      const Color(0xFFEBCB3A),
      4.2,
      paint,
    );
    _drawSparkle(
      canvas,
      Offset(size.width * 0.91, size.height * 0.67),
      const Color(0xFF5FC9AC),
      4.2,
      paint,
    );
  }

  void _drawSparkle(
    Canvas canvas,
    Offset center,
    Color color,
    double radius,
    Paint paint,
  ) {
    paint.color = color.withValues(alpha: 0.72);
    canvas.drawLine(
      center.translate(-radius, 0),
      center.translate(radius, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -radius),
      center.translate(0, radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileSparklePainter oldDelegate) => false;
}

String _emailFor(String nickname, String username) {
  if (username.contains('@')) return username;
  final nicknameHandle = _toEmailHandle(nickname);
  final usernameHandle = _toEmailHandle(username);
  final handle = nicknameHandle.isNotEmpty
      ? nicknameHandle
      : usernameHandle.isNotEmpty
          ? usernameHandle
          : 'greensprout';
  return '$handle@email.com';
}

String _toEmailHandle(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String _avatarAssetUri(String asset) => 'asset:$asset';

String _avatarFileUri(String filePath) => 'file:$filePath';

String? _avatarAssetPath(String? avatarUri) {
  final clean = avatarUri?.trim();
  if (clean == null || clean.isEmpty) return null;
  if (clean.startsWith('asset:')) return clean.substring('asset:'.length);
  if (clean.startsWith('pet/')) return clean;
  return null;
}

String? _avatarFilePath(String? avatarUri) {
  final clean = avatarUri?.trim();
  if (clean == null || clean.isEmpty) return null;
  if (clean.startsWith('file:')) return clean.substring('file:'.length);
  if (clean.startsWith('/')) return clean;
  return null;
}

void _showAvatarPicker(
  BuildContext context,
  WidgetRef ref,
  String? currentUri,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      return _AvatarPickerSheet(
        currentUri: currentUri,
        onPickImage: () => _pickProfileImage(context, sheetContext, ref),
        onSelected: (avatarUri) async {
          await ref.read(profileRepositoryProvider).updateAvatarUri(avatarUri);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      );
    },
  );
}

Future<void> _pickProfileImage(
  BuildContext parentContext,
  BuildContext sheetContext,
  WidgetRef ref,
) async {
  try {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 88,
    );
    if (picked == null) return;

    final savedPath = await _persistPickedAvatar(picked);
    await ref
        .read(profileRepositoryProvider)
        .updateAvatarUri(_avatarFileUri(savedPath));

    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
  } catch (_) {
    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text(AppStrings.of(parentContext).imagePickFailed)),
    );
  }
}

Future<String> _persistPickedAvatar(XFile picked) async {
  final avatarDir = await getAvatarStorageDirectory();
  if (!await avatarDir.exists()) {
    await avatarDir.create(recursive: true);
  }

  final extension = p.extension(picked.path).toLowerCase();
  final safeExtension = switch (extension) {
    '.png' || '.jpg' || '.jpeg' || '.webp' => extension,
    _ => '.jpg',
  };
  final fileName =
      'profile_${DateTime.now().millisecondsSinceEpoch}$safeExtension';
  final savedPath = p.join(avatarDir.path, fileName);
  await File(picked.path).copy(savedPath);
  return savedPath;
}

Future<void> _confirmResetData(BuildContext context, WidgetRef ref) async {
  final strings = AppStrings.of(context);
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(strings.clearLocalDataTitle),
            content: Text(strings.clearLocalDataBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.confirmClear),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!confirmed || !context.mounted) return;

  try {
    await ref.read(appResetServiceProvider).clearAllLocalData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.clearedSuccess)),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.clearFailed)),
    );
  }
}

void _showNicknameEditor(
  BuildContext context,
  WidgetRef ref,
  String nickname,
) {
  final strings = AppStrings.of(context);
  final controller = TextEditingController(text: nickname);
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(strings.editNickname),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.nickname),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(profileRepositoryProvider)
                  .updateNickname(controller.text);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(strings.save),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

void _showPetSettings(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _PetSettingsSheet(
      selectedKind: ref.watch(petKindProvider),
      onSelected: (value) async {
        await ref.read(petKindProvider.notifier).setPetKind(value);
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      },
    ),
  );
}

void _showLanguageSettings(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _LanguageSettingsSheet(
      selectedLocale: ref.watch(appLocaleProvider),
      onSelected: (locale) async {
        await ref.read(appLocaleProvider.notifier).setLocale(locale);
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      },
    ),
  );
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppStrings.of(context).featureLater)),
  );
}

String _petLabel(BuildContext context, String petKindName) {
  final strings = AppStrings.of(context);
  final kind = PetAssets.kindFromName(petKindName);
  return switch (kind) {
    PetKind.leafbuds => strings.isEnglish ? 'Leafbuds' : '绿芽',
    PetKind.clouds => strings.isEnglish ? 'Clouds' : '云朵',
    PetKind.strawberry => strings.isEnglish ? 'Strawberry' : '草莓',
  };
}

String _languageLabel(BuildContext context) {
  final strings = AppStrings.of(context);
  return Localizations.localeOf(context).languageCode == 'en'
      ? strings.english
      : strings.chinese;
}

class _PetSettingsSheet extends StatelessWidget {
  const _PetSettingsSheet({
    required this.selectedKind,
    required this.onSelected,
  });

  final String selectedKind;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final options = <PetKind>[
      PetKind.leafbuds,
      PetKind.clouds,
      PetKind.strawberry,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.petPickerTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'LXGWWenKaiScreen',
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(strings.petPickerBody),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final kind = options[index];
                final name = PetAssets.nameOf(kind);
                return _PetOptionTile(
                  label: _petLabel(context, name),
                  asset: PetAssets.moodForKind(kind, PetMood.happy),
                  selected: selectedKind == name,
                  onTap: () => onSelected(name),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PetOptionTile extends StatelessWidget {
  const _PetOptionTile({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            color: palette.softSurface
                .withValues(alpha: palette.isDark ? 0.86 : 0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? _settingGreen.withValues(alpha: 0.70)
                  : palette.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: Image.asset(asset, fit: BoxFit.contain)),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.ink,
                  fontFamily: 'LXGWWenKaiScreen',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSettingsSheet extends StatelessWidget {
  const _LanguageSettingsSheet({
    required this.selectedLocale,
    required this.onSelected,
  });

  final Locale selectedLocale;
  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.languagePickerTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'LXGWWenKaiScreen',
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(strings.languagePickerBody),
            const SizedBox(height: 14),
            _LanguageOptionTile(
              label: strings.chinese,
              selected: selectedLocale.languageCode == 'zh',
              onTap: () => onSelected(const Locale('zh')),
            ),
            const SizedBox(height: 10),
            _LanguageOptionTile(
              label: strings.english,
              selected: selectedLocale.languageCode == 'en',
              onTap: () => onSelected(const Locale('en')),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _SettingsPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: palette.softSurface
                .withValues(alpha: palette.isDark ? 0.82 : 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? _settingPurple.withValues(alpha: 0.70)
                  : palette.line,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: palette.ink,
                    fontFamily: 'LXGWWenKaiScreen',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? _settingPurple : palette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
