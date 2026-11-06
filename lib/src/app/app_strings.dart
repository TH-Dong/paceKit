import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings._(this.languageCode);

  final String languageCode;

  static AppStrings of(BuildContext context) {
    return AppStrings._(Localizations.localeOf(context).languageCode);
  }

  bool get isEnglish => languageCode == 'en';

  String get plans => isEnglish ? 'Plans' : '计划';
  String get memos => isEnglish ? 'Memos' : '备忘';
  String get review => isEnglish ? 'Review' : '回看';
  String get settings => isEnglish ? 'Settings' : '设置';
  String get petSettings => isEnglish ? 'Pet Settings' : '宠物设置';
  String get petSettingsSubtitle =>
      isEnglish ? 'Choose your active pet' : '选择当前陪伴你的宠物';
  String get language => isEnglish ? 'Language' : '语言';
  String get languageSubtitle => isEnglish ? 'Choose app language' : '选择应用语言';
  String get accountSecurity => isEnglish ? 'Account Security' : '账号安全';
  String get accountSecuritySubtitle =>
      isEnglish ? 'Manage password and safety' : '管理密码和安全设置';
  String get widgets => isEnglish ? 'Widgets' : '桌面小组件';
  String get widgetsSubtitle =>
      isEnglish ? 'Manage home screen widgets' : '管理主屏幕小组件';
  String get darkMode => isEnglish ? 'Dark Mode' : '深色模式';
  String get darkModeSubtitle =>
      isEnglish ? 'Switch between light and dark' : '切换浅色与深色主题';
  String get logout => isEnglish ? 'Log Out' : '退出登录';
  String get clearLocalData => isEnglish ? 'Clear Local Data' : '清空本地数据';
  String get selectAvatar => isEnglish ? 'Choose Avatar' : '选择头像';
  String get avatarSaved => isEnglish
      ? 'Changes save to your profile automatically'
      : '更换后会自动保存到个人资料';
  String get pickFromGallery => isEnglish ? 'Choose from Photos' : '从相册选择';
  String get appAvatars => isEnglish ? 'Or choose an app avatar' : '或选择应用头像';
  String get resetDefaultAvatar =>
      isEnglish ? 'Restore default avatar' : '恢复默认头像';
  String get changeAvatar => isEnglish ? 'Change Avatar' : '更换头像';
  String get editNickname => isEnglish ? 'Edit Nickname' : '修改昵称';
  String get nickname => isEnglish ? 'Nickname' : '昵称';
  String get cancel => isEnglish ? 'Cancel' : '取消';
  String get save => isEnglish ? 'Save' : '保存';
  String get clearLocalDataTitle => isEnglish ? 'Clear local data' : '清空本地数据';
  String get clearLocalDataBody => isEnglish
      ? 'This removes plans, memos, habits, and custom avatars stored on this device, then restores the default profile. This cannot be undone.'
      : '这会删除当前设备上的计划、备忘、习惯记录和自定义头像，并恢复默认资料。这个操作不能撤销。';
  String get confirmClear => isEnglish ? 'Clear Data' : '确认清空';
  String get clearedSuccess => isEnglish
      ? 'Local data cleared. The app is back to its initial state.'
      : '本地数据已清空，应用已恢复到初始状态';
  String get clearFailed =>
      isEnglish ? 'Failed to clear data. Please try again.' : '清空失败，请稍后重试';
  String get petPickerTitle => isEnglish ? 'Choose Pet' : '选择宠物';
  String get petPickerBody =>
      isEnglish ? 'Pick which pet appears across the app.' : '选择在整个应用中出现的宠物形象。';
  String get languagePickerTitle => isEnglish ? 'Choose Language' : '选择语言';
  String get languagePickerBody => isEnglish
      ? 'Apply the preferred language for navigation and settings.'
      : '为导航与设置选择显示语言。';
  String get chinese => isEnglish ? 'Chinese' : '中文';
  String get english => 'English';
  String get featureLater => isEnglish
      ? 'This setting will arrive in a later version'
      : '这个设置会在后续版本开放';
  String get imagePickFailed => isEnglish
      ? 'Failed to read the avatar image. Try another image.'
      : '头像图片读取失败，请换一张图片再试';
}
