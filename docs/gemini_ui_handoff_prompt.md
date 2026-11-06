# Gemini / Antigravity UI 交接 Prompt

> 状态：已废弃，仅作为历史记录保留。
> 从 `2026-04-27` 起，PaceKit 不再继续交给 Gemini / Antigravity 做 UI，高保真前端润色改由 Codex 全权负责。
> 新窗口交接请使用 `docs/codex_context_brief.md`。

本文件用于把 PaceKit 的 UI 高保真优化任务交给 Gemini / Antigravity。建议直接复制下面的 Prompt 使用。

## 第一轮总 Prompt

```text
你现在接手一个 Flutter 项目的 UI 高保真优化任务。项目名是 PaceKit，是一款个人规划类 App，核心是每日计划、DDL 备忘、习惯养成、历史回看和像素宠物反馈。

请先阅读这些文件：

1. planning_app_product_spec_v_0_1.md
2. App UI 与 Pet 图片资源使用说明 v0.1.md
3. docs/codex_gemini_handoff.md
4. docs/project_update_log.md
5. ui_reference/plan/plan_view_reference.png
6. ui_reference/memo/memo_view_reference.png
7. ui_reference/view/day_view_reference.png
8. ui_reference/view/week_view_reference.png
9. ui_reference/view/month_view_reference.png
10. ui_reference/setting/setting_view_reference.png

当前代码已经可以通过：

- flutter analyze
- flutter test

你的任务是：只优化 Flutter UI 的视觉、布局、组件结构和交互细节，让它更接近 ui_reference 中的目标效果。不要重写业务逻辑。

你可以修改的范围：

- lib/src/features/home/home_shell.dart
- lib/src/features/plan/plan_screen.dart
- lib/src/features/memo/memo_screen.dart
- lib/src/features/view/view_screen.dart
- lib/src/features/settings/settings_screen.dart
- lib/src/features/pet/pet_image.dart
- lib/src/shared/empty_state.dart
- lib/src/shared/glass_card.dart
- lib/src/shared/liquid_progress_bar.dart
- lib/src/app/theme.dart

你不能修改的范围：

- lib/src/data/
- lib/src/core/
- lib/src/app/providers.dart
- pubspec.yaml 中的依赖版本
- Drift schema / repository / provider 方法签名
- test/ 中的业务规则测试

如果你发现必须改业务接口，请先停止并说明原因，不要直接修改。

设计目标：

- 参考图是视觉方向，不允许把参考图当页面背景。
- 真实 UI 必须由 Flutter 组件实现。
- 整体风格：浅色玻璃质感、柔和大圆角卡片、绿色主焦点、紫/蓝/橙功能色、像素宠物作为视觉中心。
- 轻量、可爱、有陪伴感，但不要做成幼稚儿童风。
- 中文界面文案。
- 移动端优先，必须适配常规 Android 竖屏。
- 文本不能溢出或互相遮挡。
- 底部导航要保持四个入口：计划、备忘、回看、设置。

优先级：

1. 先优化 Plan 页：顶部宠物、三日计划卡、Habit 卡、液态进度条、底部编辑面板。
2. 再优化 Memo 页：顶部奔跑宠物进度条、DDL 卡片、紧迫色、完成态、粉碎/删除操作。
3. 再优化 View 页：Day/Week/Month 三个视图的信息密度、卡片层级、图表和 timeline。
4. 最后优化 Setting 页：头像区域、宠物设置入口、设置项卡片、深色模式开关。

验收标准：

- flutter analyze 必须无错误。
- flutter test 必须通过。
- 不破坏现有 provider/repository 调用。
- App 启动后四个底部模块可切换。
- Plan/Memo/View/Setting 页面在小屏 Android 竖屏下不出现明显溢出。
- Pet 图片来自 pet/ 目录，不使用 ui_reference 图片作为实际页面资源。

请先做一轮 UI 优化，不要做大规模重构。完成后请列出你修改了哪些文件、每个页面做了什么视觉变化、还有哪些风险需要 Codex 回收验证。
```

## 第二轮 Prompt：让 Gemini 修视觉问题

当 Gemini 第一轮改完后，如果你发现 UI 不够像参考图，可以继续发：

```text
请继续做第二轮视觉还原，但仍然只改 UI 层。

重点对比 ui_reference 中的页面：

- Plan 页需要更接近参考图的双列卡片比例、柔和玻璃背景、宠物顶部空间和三种日期功能色。
- Memo 页需要更强的 DDL 紧迫感，但不要使用粗暴红色大面积背景。
- View 页需要提高信息层级：图表、timeline、周视图、月历格要更容易扫读。
- Setting 页需要更接近参考图的个人资料顶部视觉和大卡片列表。

请不要改变业务逻辑，不要新增第三方依赖。完成后再次确保 flutter analyze 和 flutter test 可以通过。
```

## 第三轮 Prompt：让 Gemini 专门做响应式

```text
请专门检查移动端响应式和文字溢出问题。

目标设备：

- 小屏 Android：360 x 800
- 常规 Android：393 x 873
- 大屏 Android：412 x 915

请检查并修复：

- Plan 三日卡片在窄屏是否需要从左右布局切换为上下布局。
- Memo 卡片长文本是否正确换行。
- View Week 和 Month 页面是否能纵向/横向滚动，不遮挡底部导航。
- Setting 页设置项长文案是否溢出。
- 所有按钮、勾选圆圈、编辑入口是否有足够触控区域。

只改 UI 层，不改数据层和业务规则。
```

## 第四轮 Prompt：让 Gemini 做动效和微交互

```text
请在不改变业务逻辑的前提下，为当前 Flutter UI 增加克制的动效和微交互。

允许加入：

- 页面切换的轻微淡入/位移。
- Plan/Memo 完成时的短动画反馈。
- 液态进度条的进度变化动画。
- 底部导航选中态的柔和过渡。
- Pet 图片的轻微浮动或缩放，但不能影响操作效率。

限制：

- 不要引入新的第三方动画库。
- 动画时长控制在 200ms-500ms。
- 不要做夸张弹跳、闪烁或大面积发光。
- 不要改 repository/provider/data/core。
```

## Codex 回收 Prompt

Gemini 修改完后，把代码交回 Codex 时可以这样说：

```text
Gemini 已经完成 UI 修改。请你作为 Codex 回收集成：

1. 运行 flutter analyze。
2. 运行 flutter test。
3. 检查 Gemini 是否误改 lib/src/data/、lib/src/core/、lib/src/app/providers.dart。
4. 检查 Plan/Memo/View/Setting 是否仍然调用 repository/provider，而不是自己维护假的业务状态。
5. 如果有编译错误、测试失败或业务边界被破坏，请直接修复。
6. 修复后更新 docs/project_update_log.md。
```

## 给 Gemini 的硬性边界

- 不要把 `ui_reference/*.png` 当页面背景。
- 不要绕过 repository 直接写数据库。
- 不要把 `CompletionEvent` 改成从当前任务状态推导。
- 不要删除 5 分钟撤销规则。
- 不要引入账号、云同步、通知、小组件、宠物成长系统。
- 不要为了视觉效果牺牲中文文本可读性。
- 不要新增依赖，除非先明确说明必要性。
