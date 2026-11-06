# PaceKit

一款带有像素宠物陪伴的轻量规划 App，帮助你安排每日任务、管理截止日期、养成习惯并回顾进度。

## 功能

- **每日计划**：查看相邻日期的计划，管理任务与完成进度。
- **DDL 备忘**：按截止日期和紧急程度整理事项，支持完成、归档与删除。
- **习惯与作息**：记录习惯打卡、入睡和起床时间。
- **历史回顾**：通过日、周、月视图查看完成记录和统计。
- **宠物陪伴**：提供绿芽、云朵、草莓三种伙伴，根据完成情况显示不同心情。
- **个性设置**：支持个人资料、头像、中英文切换及浅色/深色主题。

## 技术栈

Flutter / Dart · Riverpod · Drift / SQLite。数据保存在本地，当前为 Android MVP，暂未接入账号与云同步。

## 本地运行

准备 Flutter stable（按当前依赖锁定版本，需 Flutter ≥ 3.38.4、Dart ≥ 3.10.3）、Android SDK、JDK 17，以及 Android 模拟器或真机。

```bash
git clone https://github.com/TH-Dong/paceKit.git
cd paceKit
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Drift 的 `*.g.dart` 文件不纳入版本管理，首次运行前需执行上面的代码生成命令。

## 检查与构建

```bash
flutter analyze
flutter test
flutter build apk --release
```

APK 输出位置：`build/app/outputs/flutter-apk/app-release.apk`。当前 release 使用调试签名，正式发布前需配置自己的签名。

## 目录

```text
lib/           页面、状态管理、业务规则与数据库
test/          业务规则、数据仓库与组件测试
android/       Android 平台工程
assets/        字体资源
pet/           宠物图片素材
ui_reference/  UI 设计参考图
scripts/       宠物素材处理脚本
docs/          产品说明与开发记录
```

更多说明见 [产品设计](docs/planning_app_product_spec_v_0_1.md)、[开发记录](docs/project_update_log.md) 和 [宠物动画工作流](docs/pet_animation_workflow.md)。
