# Codex 新窗口上下文交接说明

当你开启新的 Codex 对话窗口时，优先把这份文档发给 Codex，并要求它继续读取项目真实文件后再动手。

## 当前协作决策

- 从 `2026-04-27` 起，PaceKit 不再采用 Codex/Gemini 分工。
- Gemini/Antigravity 的 UI 效果未达到预期，后续由 Codex 全权接手。
- 旧文档 `docs/gemini_ui_handoff_prompt.md` 和 `docs/codex_gemini_handoff.md` 只保留为历史记录，不再作为执行路线。

## 项目目标

PaceKit 是一款 Flutter 规划类 App，核心功能是：

- 每日计划 Plan
- DDL 备忘 Memo
- 习惯 Habit
- 日/周/月完成回看 View
- 像素宠物 Pet 情绪反馈

产品风格目标：

- 轻量、可爱、有陪伴感，但不要幼稚。
- 浅色玻璃质感、柔和大圆角卡片、绿色主焦点、紫/蓝/橙功能色。
- Pet 图片必须使用 `pet/` 中的真实素材。
- `ui_reference/` 只作为视觉参考，不能当页面背景。

## 关键文档

新窗口 Codex 应先阅读：

- `docs/project_update_log.md`
- `docs/planning_app_product_spec_v_0_1.md`
- `docs/App UI 与 Pet 图片资源使用说明 v0.1.md`
- `README.md`

如果任务涉及 UI，还需要查看：

- `ui_reference/plan/plan_view_reference.png`
- `ui_reference/memo/memo_view_reference.png`
- `ui_reference/view/day_view_reference.png`
- `ui_reference/view/week_view_reference.png`
- `ui_reference/view/month_view_reference.png`
- `ui_reference/setting/setting_view_reference.png`

## 当前技术状态

- Flutter + Riverpod + Drift SQLite。
- Android 平台文件已生成。
- Drift 代码已通过 `build_runner` 生成。
- 当前字体策略：
  - 全局主字体引用系统字体 `SimHei`，不再打包 `MiSans`。
  - `SmileySans` 仍用于宠物状态、空状态标题、Plan 编辑按钮、底部导航文字和 Plan 编辑弹窗标题。
  - `LXGWWenKaiScreen` 用于 Plan 卡标题“昨天 / 今天 / 明天”和 Habit 卡标题“习惯”，Memo 内容也保持该字体。
  - `assets/fonts/` 目前只包含 `LXGWWenKaiScreen.ttf` 和 `SmileySans-Oblique.ttf`，约 `27M`。
- 当前 Plan 页第一轮视觉重构已做：
  - Pet 使用 `pet/leafbuds_transparent/` 透明背景素材。
  - Plan 页有宠物头部、三日 Plan 卡、Habit 卡、自定义底部导航和中文文案。
  - 已完成多轮尺寸、进度条、Habit、底部导航和 Plan 日期锁定规则微调。
- 当前 Memo 页第一轮视觉重构已做：
  - 顶部使用液态玻璃紫色进度条。
  - 跑步小龙使用 `PetAssets.running`，已镜像为朝右奔跑。
  - Memo DDL 卡片已按截图做宽度、字体、间距、玻璃边框和状态图标微调。
  - 滑动操作区已改为 `Crush / Delete` 双按钮。
  - Delete 会弹确认窗口，删除不会写入 View 记录。
  - 完成 Memo 时先显示本地完成态和勾号路径动画，约 `820ms` 后再写入数据库，避免卡片立即跳到底部。
  - Memo 卡片使用 `ValueKey(memo.id)` 保持排序前后状态稳定。
- Android 应用图标已从 `planner_pet_icon.ico` 生成并替换 `mipmap-* / ic_launcher.png`。
- `flutter analyze` 通过。
- `flutter test` 通过，当前 13 个测试。
- `flutter build apk --debug` 通过。
- `flutter build apk --release` 通过，release APK 约 `104.7MB`。
- Debug APK 曾成功构建并安装到 Android 模拟器 `emulator-5554`。
- 当前连接过 Android 15 真机 `ab94f74d` / `2410DPN6CC`。
- 本地 Android 环境已安装 NDK `28.2.13676358` 和 CMake `3.22.1`。
- 注意：`2026-04-27 19:42 CST` 曾出现 Flutter 红屏：
  - 报错为 `package:flutter/src/painting/text_style.dart` 断言：`fontSize != null || (fontSizeFactor == 1.0 && fontSizeDelta == 0.0)`。
  - 原因是 `ThemeData.textTheme.apply(fontSizeFactor: 0.96)` 对部分没有显式 `fontSize` 的默认样式触发断言。
  - 已改为在 `lib/src/app/theme.dart` 中逐个 `TextStyle` 判断 `fontSize != null` 后手动乘 `0.96`。
  - 修复后 `analyze/test/debug build/release build` 均通过，release APK 已重新构建并安装到真机；最后一次启动截图验证被用户中断，新窗口可先重新跑一次真机截图确认。

常用验证命令：

```sh
flutter analyze
flutter test
flutter build apk --debug
```

如果连接真机：

```sh
flutter devices
flutter run -d <device-id>
```

当前真机常用命令：

```sh
flutter run -d ab94f74d
flutter install -d ab94f74d
```

## 代码边界

Codex 可以全权修改代码，但必须保护这些业务规则：

- View 页历史数据主要读取 `CompletionEvent`，不要从当前任务状态反推历史。
- Plan/Memo/Habit 完成时必须写入 `CompletionEvent`。
- 5 分钟内允许撤销，超过 5 分钟不能直接撤销。
- Memo 删除使用软删除，不写入 View 记录；完成后的“粉碎”是归档。
- 早睡在 00:00-05:00 点击时归属前一天。
- 同步字段 `syncStatus / remoteId / revision` 需要保留。

## 下一阶段主线

### 1. 先继续润色前端

前端润色优先级：

1. View 页：Day/Week/Month 三个视图的信息密度、日历格、timeline、睡眠总结。
2. Setting 页：个人资料、宠物设置、设置项、深色模式。
3. 全局：底部导航、主题色、卡片质感、响应式、文字溢出、触控区域。
4. Plan/Memo：当前已完成阶段性重构，后续按用户截图反馈做局部修补。

润色要求：

- 先运行/截图/观察当前 UI，再改。
- 优先做真实 Flutter 组件，不引入无必要依赖。
- 不要为视觉效果破坏业务状态流。
- 每轮改完必须运行 `flutter analyze` 和 `flutter test`。
- 有条件时运行 `flutter run` 做模拟器或真机手动检查。

### 2. 前端稳定后再补功能

功能推进顺序：

1. 补齐 Plan/Memo/Habit 的编辑体验和空状态。
2. 补齐 View 页统计逻辑和历史详情。
3. 加入 Pet 动态效果。
4. 完善 widget tests 和关键 repository tests。
5. 再考虑提醒通知、桌面小组件、账号/同步等 v0.2+ 功能。

## Pet 动态方向

用户计划生成 6 张透明背景 sprite sheet：

- normal
- happy
- sad
- running
- sleep
- empty

每张图包含 20 帧。Codex 后续需要：

- 检查图片尺寸和透明背景。
- 自动切割或直接按 sprite sheet 播放。
- 新增 `AnimatedPet` 组件。
- 让 Plan/Memo/View/Setting 根据状态播放对应动画。

## 新窗口推荐开场 Prompt

```text
请读取 docs/codex_context_brief.md 和 docs/project_update_log.md，继续接手 PaceKit。现在不再使用 Gemini，后续由 Codex 全权负责。Plan 和 Memo 已完成阶段性 UI 重构，Memo 最近还补了完成动画、删除确认、小龙朝右和 Android 图标。请先检查当前项目状态和运行结果，再按我最新指定的页面继续执行下一步。
```
