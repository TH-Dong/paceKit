# PaceKit 项目更新日志

本文件保留项目关键决策、当前状态和阶段性变更。细碎 UI 微调已合并为阶段摘要，后续只记录会影响交接、验证、功能边界或较大视觉方向的变更。

时间默认使用本机时区 `CST`。

## 当前最新决策

- 从 `2026-04-27 16:24 CST` 起，PaceKit 不再继续使用 Gemini / Antigravity 负责 UI。
- 后续由 Codex 全权接手 UI、业务逻辑、数据层、测试和集成。
- 旧文档 `docs/codex_gemini_handoff.md` 和 `docs/gemini_ui_handoff_prompt.md` 只保留为历史，不再作为执行路线。
- 新窗口继续项目时，先读取：
  - `docs/codex_context_brief.md`
  - `docs/project_update_log.md`
  - `docs/planning_app_product_spec_v_0_1.md`
  - `docs/App UI 与 Pet 图片资源使用说明 v0.1.md`

## 当前项目状态

- 技术栈：Flutter + Riverpod + Drift SQLite。
- Android 平台文件已生成，本机 Android 构建环境可用。
- 已安装并使用过：
  - Android NDK `28.2.13676358`
  - CMake `3.22.1`
- 常用真机：
  - Android 15 真机 `ab94f74d` / `2410DPN6CC`
- 当前字体策略：
  - 全局主字体引用系统字体 `SimHei`，不打包 MiSans。
  - `LXGWWenKaiScreen` 用于 Plan 日期标题、Habit 标题、Plan/Habit 列表项、顶部每日句子。
  - `SmileySans` 用于部分 UI 装饰文字，例如编辑按钮、底部导航、空状态等。
  - 当前 `assets/fonts/` 仅保留：
    - `assets/fonts/LXGWWenKaiScreen.ttf`
    - `assets/fonts/SmileySans-Oblique.ttf`
- 当前验证状态：
  - `flutter analyze` 通过。
  - `flutter test` 通过：13 个测试。
  - `flutter build apk --debug` 通过。
  - 最近一次 release 构建曾通过，release APK 约 `104.7MB`。
- 当前 Android 应用图标已替换为 `planner_pet_icon.ico` 生成的 `mipmap-* / ic_launcher.png`。

## 当前业务规则边界

这些规则需要继续保护：

- View 页历史数据主要读取 `CompletionEvent`，不要从当前任务状态反推历史。
- Plan/Memo/Habit 完成时必须写入 `CompletionEvent`。
- 完成后 5 分钟内允许撤销，超过 5 分钟不能直接撤销。
- Memo 删除使用软删除，不写入 View 记录；完成后的“粉碎”是归档。
- 早睡在 `00:00-05:00` 点击时归属前一天。
- Plan 日期补记规则：
  - 昨天 Plan 在次日 `06:00` 前仍可补勾。
  - 次日 `06:00` 后昨天 Plan 锁定。
  - 锁定后未完成 Plan/Habit 显示红色 missed 状态：红色文字、红色叉号圆圈，并禁用点击。
  - 明天任务不可点击，但不显示 missed 红色状态。
- 同步字段 `syncStatus / remoteId / revision` 需要保留。

## 当前 Plan 页视觉状态

截至 `2026-04-27 21:13 CST`，Plan 页已完成阶段性高保真微调，当前实现重点如下：

- 顶部 Pet：
  - 使用 `pet/leafbuds_transparent/` 静态 Pet 素材。
  - 时间胶囊使用 `_GlassTimeBadge`，液态玻璃质感，位于 Pet 右侧偏下。
  - 顶部每日句子共 100 条，按本地日期每天轮换一句。
- 三日 Plan/Habit 卡：
  - 左侧 Plan 卡与右侧 Habit 卡横向并排，比例约 `62:38`。
  - Plan/Habit 卡横向间距当前为 `6`。
  - Plan/Habit 卡启用更明显的柔和阴影：
    - `shadowAlpha: 0.12`
    - `shadowBlur: 34`
    - `shadowOffset: Offset(0, 14)`
  - Plan 进度条为液态玻璃风格，填充从最左侧开始，计数显示在进度槽内。
  - Plan 列表勾选圆放大，列表项字体为 `LXGWWenKaiScreen`。
  - Habit 左侧图标使用 `_HabitGlassIcon`，带径向玻璃渐变、反光条、小高光点和投影。
  - Habit 列表项字体为 `LXGWWenKaiScreen`。
- 底部导航：
  - 选中态为绿色液态玻璃泡效果。

## 当前 Memo 页视觉状态

截至 `2026-04-28 15:20 CST`，Memo 页已按用户截图完成一轮集中高保真微调，当前实现重点如下：

- 顶部 Memo 进度：
  - 使用与 Plan 共用的 `LiquidProgressBar` 液态玻璃进度条。
  - 进度条包含紫色渐变、内侧高光、星点和柔和尾部过渡。
  - 小龙使用 `PetAssets.running`，在 Memo 进度条上已水平镜像，朝右侧奔跑。
  - 点击 Memo 完成后的待提交状态会临时计入进度，避免进度和卡片反馈脱节。
- Memo 卡片：
  - 使用浅色玻璃卡片、柔和边框、顶部高光、底部反光和左侧同色强调条。
  - 卡片宽度已调回接近满屏，仅保留少量左右边距。
  - 字体改回 normal 视觉重量，DDL、剩余天数、内容、编辑时间和勾选圆都已按截图缩小。
  - 状态图标包含 alert / clock / clipboard / party 四类自绘图标；alert 图标仍是后续可继续精修的视觉点。
- 滑动操作：
  - 右滑操作区按截图拆成紫色 `Crush` 与红色 `Delete` 两块。
  - `Crush` 只允许已完成 Memo 归档。
  - `Delete` 会弹确认窗口，防止误删。
  - Memo 删除使用软删除，不会生成 View 页删除记录；已新增 repository 测试保护。
- 完成交互：
  - 点击未完成 Memo 后，先在原位显示完成态和勾号动画。
  - 完成写入延迟约 `820ms`，让勾号可见后再触发数据库更新和列表重排。
  - 勾号使用路径绘制动画，配合轻微缩放和阴影反馈。
  - Memo 卡片使用 `ValueKey(memo.id)`，避免排序后 Flutter 按位置错误复用状态。

## 2026-04-27 阶段摘要

### MVP 初始化与基础功能

- 创建 Flutter 项目源码骨架：`lib/`、`test/`、`docs/`、`pubspec.yaml`、`analysis_options.yaml`、`.gitignore`。
- 接入 Riverpod 状态层、Drift SQLite 数据层和本地 repository 合同。
- 实现 `Plan / Memo / View / Setting` 四个底部模块首版页面。
- 实现 Plan 完成、Habit 勾选、Memo DDL、CompletionEvent 历史记录、5 分钟撤销、软删除、Memo 归档、TodayScore 宠物状态规则。
- 注册 `pet/leafbuds/`、`pet/Clouds/`、`pet/Strawberry/` 等 Flutter assets。
- 新增核心业务规则测试：`test/planning_rules_test.dart`。

### 测试、Analyzer 与 Android 环境

- 修复默认 widget test，替换为当前项目可用的 `EmptyState` 测试。
- 将 Flutter 3.41 中弃用的 `Color.withOpacity(...)` 迁移为 `Color.withValues(alpha: ...)`。
- Drift 代码生成已成功执行。
- 修复 Android 本地构建环境，补齐 NDK/CMake 后 Debug APK 可构建并安装。
- 常用验证命令：

```sh
flutter analyze
flutter test
flutter build apk --debug
```

### 协作路线调整

- Gemini / Antigravity 曾尝试进行 UI 高保真优化，但效果未达到预期。
- `2026-04-27 16:24 CST` 起停止使用 Gemini / Antigravity，后续由 Codex 负责全部 UI、业务、数据、测试和集成。
- 新增 `docs/codex_context_brief.md` 作为新窗口交接入口。
- `README.md` 已提示新窗口优先读取 `docs/codex_context_brief.md`。

### Pet 动画素材工作流

- 新增 `scripts/make_pet_gif.sh`，用于把 sprite sheet 切成帧并生成预览 GIF。
- 新增 `docs/pet_animation_workflow.md`，记录 Pet 动画素材测试流程。
- 处理 `pet/leafbuds/1777280828806.mp4`：
  - 新增 `scripts/process_pet_video.sh`。
  - 支持视频抽帧、去浅色背景、清理角落水印、提亮并生成 GIF / sprite sheet。
  - 输出完整 16fps / 512px 透明 PNG 帧序列、预览 GIF 和 sprite sheet。
  - 额外生成 32 帧和 48 帧轻量循环候选。
- 重要产物：
  - `pet/leafbuds/generated/leafbuds_happy_from_video/`
  - `pet/leafbuds/generated/leafbuds_happy_from_video_v2/`
  - `pet/leafbuds/generated/leafbuds_happy_loop32/`
  - `pet/leafbuds/generated/leafbuds_happy_loop48/`

### 字体、体积与红屏修复

- 按用户要求删除 `MiSans` 字体文件和 `pubspec.yaml` 中的 `MiSans` 注册。
- 全局主题主字体改为系统字体名 `SimHei`，不再把主字体打包进 APK。
- 保留 `LXGWWenKaiScreen` 与 `SmileySans`。
- 当前 `assets/fonts/` 约 `27M`。
- 修复一次真机红屏：
  - 报错：`package:flutter/src/painting/text_style.dart` 断言失败，`fontSize != null || (fontSizeFactor == 1.0 && fontSizeDelta == 0.0)`。
  - 原因：`ThemeData.textTheme.apply(fontSizeFactor: 0.96)` 会作用到部分没有显式 `fontSize` 的默认样式。
  - 修复：在 `lib/src/app/theme.dart` 中逐个 `TextStyle` 判断 `fontSize != null` 后手动乘 `0.96`，同时统一默认字重为 `FontWeight.w400`、`letterSpacing: 0`。

### Plan 页 UI 集中优化

本阶段合并了 `19:46-21:13 CST` 的多轮细节微调：

- Plan 标题、进度条、任务行、勾选圆、编辑按钮、底部弹窗和底部导航做尺寸级微调。
- Habit 卡按参考图调整图标圆、右侧完成圆、文字字号、行高和间距比例。
- 曾出现一次 Habit 内部 `LayoutBuilder` 与父级 `IntrinsicHeight` 组合导致 Plan 内容卡整块不显示的问题：
  - 已移除 Habit 卡内层 `LayoutBuilder`。
  - 改为固定 `_HabitMetrics`。
  - 真机截图确认 Plan/Habit 卡恢复显示。
- `LiquidProgressBar` 扩展为液态玻璃视觉：
  - 支持可选 `label`。
  - 计数显示在进度槽内。
  - 填充层从最左侧开始延展。
- Plan 任务行：
  - 勾选圆放大。
  - 列表项字体改为 `LXGWWenKaiScreen`。
  - missed 状态显示红色文字、红色叉号圆圈。
- Habit 行：
  - 阅读/运动图标改为书本/哑铃。
  - 左侧图标圆改为玻璃图标组件 `_HabitGlassIcon`。
  - 列表项字体改为 `LXGWWenKaiScreen`。
  - missed 状态与 Plan 一致。
- 顶部 Pet Header：
  - 时间胶囊改为 `_GlassTimeBadge` 液态玻璃视觉。
  - 每日陪伴文案扩展为 100 条并按日期轮换。
- Plan 日期锁定规则：
  - 新增 `canEditPlanDate` 与 `isPlanDateExpired`。
  - 测试覆盖 `06:00` 截止前后和未来日期。
- Plan/Habit 卡：
  - 横向间距缩小。
  - 阴影增强。
- 底部导航：
  - 选中态改为绿色液态玻璃泡。

## 2026-04-28 阶段摘要

### Memo 页 UI 集中优化

- 读取 `docs/project_update_log.md` 和 `docs/codex_context_brief.md` 后，按用户提供的 Memo 截图逐阶段实现。
- 顶部 Memo 进度条已强化为液态玻璃紫色进度条，并同步应用到 Plan/Memo 共用组件。
- Memo 顶部跑步小龙已镜像，当前朝右侧奔跑。
- Memo DDL 卡片完成多轮尺寸、字体、宽度、间距、圆角、阴影、渐变和边框微调。
- 自绘了 Memo 状态图标：
  - 紧急 alert
  - 时钟 clock
  - 剪贴板 clipboard
  - 完成 party
- 滑动操作区按截图调整为 `Crush / Delete` 双按钮视觉。
- 删除操作新增确认弹窗，并明确删除不会生成 View 记录。
- 数据层新增/调整 `softDeleteMemo` 相关测试，保护“删除不写入 CompletionEvent”的关系。
- Memo 完成操作增加本地过渡态：
  - 点击后先显示完成态。
  - 勾号路径绘制动画可见。
  - 延迟约 `820ms` 后再提交数据库，避免卡片立即跳到底部。

### Android 应用图标

- 使用 `/Users/tinghaodong/Code/Projects/paceKit/planner_pet_icon.ico` 作为源图标。
- 从 `.ico` 的 256px 图层生成 Android 各密度启动图标：
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`：48x48
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`：72x72
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`：96x96
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`：144x144
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`：192x192
- `AndroidManifest.xml` 原本已指向 `@mipmap/ic_launcher`，因此无需改 manifest。

## 当前验证记录

最近几轮修改后已反复执行：

```sh
flutter analyze
flutter test
flutter build apk --debug
```

当前结果：

- `flutter analyze`：通过。
- `flutter test`：通过，13 个测试。
- `flutter build apk --debug`：通过。

## 接下来的任务

### P0：新窗口先同步当前状态

- 新对话开始时先读取：
  - `docs/codex_context_brief.md`
  - `docs/project_update_log.md`
- 然后检查当前代码状态，不要重新从旧 Plan 阶段开始。
- Memo 当前轮次已经完成；如果继续 Memo，只做真机细节复核或局部修补。

### P1：继续润色前端

- 下一轮建议从 View 或 Setting 页继续，而不是重复 Memo 已完成的基础重构。
- 可选顺序：
  - View：Day/Week/Month 图表、timeline、月历格、睡眠总结。
  - Setting：个人资料、宠物设置入口、设置项卡片、深色模式。
  - 全局：响应式、文字溢出、触控区域、主题一致性。
  - Memo：仅在用户继续指出截图差异时做局部修补。

### P2：前端稳定后补功能

- 补齐 Plan/Memo/Habit 的编辑体验和空状态。
- 补齐 View 页统计逻辑和历史详情。
- 接入 Pet 动态效果：
  - 接收 6 张透明背景 sprite sheet：`normal / happy / sad / running / sleep / empty`。
  - 检查尺寸和透明背景。
  - 新增 `AnimatedPet` 组件。
- 完善 widget tests 和关键 repository tests。

### P3：v0.2 之前暂不做

- 云同步、账号登录、提醒通知、桌面小组件、复杂宠物成长/换装系统。
- Pet 动态先做本地 sprite sheet 播放，不做复杂成长系统。
