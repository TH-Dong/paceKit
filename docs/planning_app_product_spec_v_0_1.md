# 规划类 App 产品说明文档 v0.1

## 1. 产品定位

本 App 是一款以“每日计划 + DDL 备忘 + 习惯养成 + 像素宠物反馈”为核心的个人规划工具。

它不是复杂的日程管理软件，而是一个更偏向“完成感”和“持续养成”的轻量计划系统。用户每天主要关注三件事：

1. 今天要做什么。
2. 近期有哪些 DDL 任务。
3. 自己这一天、一周、一个月到底完成了什么。

像素宠物不是单纯装饰，而是用户完成状态的情绪化反馈。完成得多，宠物开心、成长、向前跑；完成得少，宠物低落或静止。这样可以把冷冰冰的 ToDo List 转化为具有陪伴感的计划系统。

---

## 2. 平台规划与 MVP 边界

### 2.1 总体平台目标

长期目标：

- Android 端
- iOS 端
- Mac 端
- 多端数据同步
- 统一账号系统
- 桌面小组件 / 手机桌面小组件

### 2.2 当前 MVP 目标

当前优先完成 Android 端。第一版不建议一开始就做完整多端同步，因为同步、账号、安全、冲突处理会显著增加复杂度。

v0.1 建议范围：

- Android 单端可用。
- 本地数据持久化。
- 完成 Plan / Memo / View / Setting 四个底部模块。
- 数据表设计预留同步字段。
- UI 先完成核心交互，不急着做复杂宠物养成系统。
- 登录、云同步、iOS、Mac、小组件放到后续版本。



## 3. 产品核心结构

底部导航栏包含四个模块：

1. **Plan**：昨天、今天、明天的计划和习惯。
2. **Memo**：带 DDL 的备忘任务。
3. **View**：日 / 周 / 月完成情况视图。
4. **Setting**：个人资料、宠物设置、账号安全、语言、深色模式等。

信息架构如下：

```text
App
├── Plan
│   ├── Pixel Pet Header
│   ├── Yesterday Card
│   ├── Today Card
│   └── Tomorrow Card
│
├── Memo
│   ├── Running Pet Progress Bar
│   ├── Add Memo
│   └── Memo Task Cards
│
├── View
│   ├── Day View
│   ├── Week View
│   └── Month View
│
└── Setting
    ├── Profile
    ├── Pet Setting
    ├── Account Security
    ├── Widget
    ├── Language
    ├── Dark Mode
    └── Logout
```

---

## 4. 模块一：Plan 规划页

## 4.1 页面目标

Plan 页是用户每天打开 App 最常看的页面。它负责回答：

- 昨天完成得怎么样。
- 今天要做什么。
- 明天要提前安排什么。
- 今天的习惯有没有完成。

该页面应该有强烈的“每日陪伴感”，所以像素宠物放在页面顶部中心位置。

---

## 4.2 页面结构

### 顶部区域

顶部包含：

1. 中心位置的动态像素宠物。
2. 宠物右下角的圆角矩形时钟。
3. 可选的简短状态文字。

示例：

```text
        [ Pixel Pet ]
              [ 22:41 ]

     今天完成得不错，宠物很开心
```

宠物状态由当天完成情况决定：

- 完成率高：开心、跳跃、闪星星。
- 完成率中等：普通待机。
- 完成率低：低落、坐下、慢速眨眼。

建议先做 3 种状态即可：

1. Happy
2. Normal
3. Sad

后续再扩展成长、等级、装扮、宠物皮肤。

---

## 4.3 三张日期卡片

Plan 页面包含三张主卡片：

1. Yesterday
2. Today
3. Tomorrow

三张卡片建议使用不同的柔和背景色，保证区分度：

- Yesterday：低饱和蓝紫色，表示回顾。
- Today：清爽绿色或青色，表示当前行动。
- Tomorrow：浅橙色或浅黄色，表示提前准备。

每张卡片内部横向分成两部分：

- 左侧 70%：有序计划列表。
- 右侧 30%：Habit 习惯列表。

在手机竖屏上，如果横向空间不足，仍然可以保持 7:3，但需要控制文字长度；极窄屏幕可以自动改成上下结构。

---

## 4.4 左侧：有序 Plan List

### 4.4.1 基本内容

左侧用于显示当天有明确顺序的 ToDo List。

结构：

```text
Yesterday / Today / Tomorrow     [液态玻璃进度条]

1. [ ] 完成算法作业
2. [x] 阅读论文 20 分钟
3. [ ] 整理项目文档

                              Edit
```

第一行包含：

- 日期标题：Yesterday / Today / Tomorrow。
- 液态玻璃进度条。
- 进度条右端随机奖励 icon，例如星星、花朵、笑脸、勾勾。

进度条规则：

```text
完成进度 = 已完成 Plan 数量 / 当天 Plan 总数量
```

如果当天没有计划，进度显示为空状态，不显示 0% 的挫败感，可以显示：

```text
No plans yet
```

### 4.4.2 列表交互

每条任务前有一个圆角框：

- 点击后打勾。
- 文字变灰。
- 添加删除线。
- 生成一条完成记录 CompletionEvent。

完成后 5 分钟内再次点击，可以撤销勾选。

5 分钟后不建议直接撤销，因为 View 页依赖完成记录。如果确实要修改，可以在后续版本加入“历史纠错”入口。

### 4.4.3 Yesterday / Today / Tomorrow 的行为差异

为了避免数据混乱，三种日期卡片的行为应该不同：

#### Yesterday

主要用于回顾。

- 默认允许查看。
- 可以允许“补记完成”，但建议限制在 24 小时内。
- 不建议频繁编辑昨天的计划内容。

#### Today

主要用于执行。

- 可以添加任务。
- 可以完成任务。
- 可以排序。
- 可以删除未完成任务。

#### Tomorrow

主要用于提前规划。

- 可以添加任务。
- 可以排序。
- 可以删除任务。
- 默认不允许提前打勾完成。

这样可以让时间语义更清晰：

- Yesterday = 回顾
- Today = 执行
- Tomorrow = 规划

---

## 4.5 Plan 编辑弹窗

点击 Plan 区域右上角的 Edit 后，弹出编辑层。

移动端更推荐使用底部弹窗 Modal Bottom Sheet，而不是居中弹窗。原因是：

- 手机屏幕较窄。
- 底部弹窗更适合长列表编辑。
- 可以自然支持拖拽排序。

视觉上可以设计成“纸面背景”：

- 米白色纸张质感。
- 轻微阴影。
- 圆角。
- 顶部有拖拽 handle。

功能：

1. 显示当前日期的 Plan List。
2. 底部或列表下方有加号按钮。
3. 点击加号添加任务。
4. 长按任务进入拖拽排序。
5. 拖拽到垃圾桶区域删除。
6. 删除前可以短暂显示 Undo。

建议交互：

```text
[ Edit Today Plans ]

≡  完成算法题
≡  阅读论文
≡  整理项目文档

+ Add Plan

拖拽时底部出现：
[ Trash ]
```

---

## 4.6 右侧：Habit 习惯列表

### 4.6.1 基本内容

右侧用于显示无序习惯列表。

默认习惯：

1. 早起
2. 早睡

可选习惯：

- Reading
- Exercise
- Drink Water
- Meditation
- Coding

结构：

```text
Habits        Edit

早起       ( )
早睡       ( )
Reading    (✓)
Exercise   ( )
```

每个 Habit 右侧有一个圆圈：

- 默认空心圆。
- 点击后出现勾勾。
- 完成后写入 HabitRecord。
- 同时生成 CompletionEvent。

### 4.6.2 早起 / 早睡的特殊规则

早起和早睡不是普通 Habit，而是带时间记录的特殊 Habit。

#### 早起

点击后记录当前时间：

```text
wakeTime = 当前时间
```

#### 早睡

点击后记录当前时间：

```text
sleepTime = 当前时间
```

如果用户在凌晨 0:00 到 5:00 之间点击“早睡”，建议把这次记录归属到前一天。原因是多数用户会把凌晨 1 点睡觉理解为“前一天晚上睡觉”。

默认日界线：

```text
dayBoundary = 05:00
```

后续可以在设置中开放修改。

### 4.6.3 Habit 编辑规则

Habit 编辑不同于 Plan 编辑。

Plan 是某一天的任务；Habit 是长期模板。

所以 Habit 编辑应该遵循：

- 添加 Habit：从明天或今天开始显示。
- 修改 Habit 名称：影响未来显示。
- 历史完成记录不被修改。
- 删除 Habit：默认只是停用，不删除历史记录。

数据上应区分：

```text
HabitTemplate：习惯模板
HabitRecord：某一天是否完成该习惯
```

这样 View 页才能正确回看过去的数据。

---

## 4.7 Plan 页宠物状态计算

建议用综合得分控制宠物状态。

第一版可以使用简单公式：

```text
TodayScore = 0.65 × Plan完成率
           + 0.25 × Habit完成率
           + 0.10 × 今日Memo完成率
```

宠物状态：

```text
TodayScore >= 0.75：Happy
0.35 <= TodayScore < 0.75：Normal
TodayScore < 0.35：Sad
```

不要一开始做太复杂的成长数值系统。先把情绪反馈做稳定，再扩展等级、经验、装扮。

---

# 5. 模块二：Memo 备忘页

## 5.1 页面目标

Memo 页用于管理有 DDL 的任务。它和 Plan 的区别是：

- Plan 更像“某一天我要做什么”。
- Memo 更像“某件事必须在某个截止日期前完成”。

Memo 页应该强调紧迫程度、截止日期和完成后的释放感。

---

## 5.2 顶部进度条

页面顶部是一条横向进度条，宠物在进度条上向右跑。

右侧有加号按钮，用于添加 Memo。

```text
[ Pet ] ━━━━━━━━━━━━━━━          +
```

进度条建议表示“近期 DDL 完成进度”。

推荐范围：

```text
近期 Memo = 已过期 + 未来 7 天内截止的 Memo
```

进度计算：

```text
MemoProgress = 近期已完成 Memo 数量 / 近期 Memo 总数量
```

这样比统计所有 Memo 更合理，因为很远的任务不应该影响当前紧迫感。

---

## 5.3 添加 Memo

点击右上角加号，打开添加弹窗。

字段：

1. Memo 内容。
2. 截止日期。
3. 可选提醒时间。
4. 可选优先级。

v0.1 可以只做前两个字段：

```text
内容 + 截止日期
```

提醒时间可以放到 v0.2。

---

## 5.4 Memo 卡片结构

每个 Memo 是一张独立卡片。

结构：

```text
DDL 04月30日                         [Edit]

完成数学建模论文第三问模型整理

○                                  Edited 04月26日
```

字段说明：

- 左上角：截止日期。
- 右上角：编辑图标。
- 中间：任务内容。
- 左下角或左侧：完成圆圈。
- 右下角：最近编辑日期。

点击圆圈：

- 圆圈变成勾勾。
- 文字变灰。
- 生成完成记录。
- 卡片进入“已完成但未归档”状态。

右上角编辑图标：

- 可以修改内容。
- 可以修改 DDL。
- 修改后更新 editedAt。

---

## 5.5 Memo 滑动操作

支持向右滑动卡片。

滑出两个操作：

1. 粉碎按钮。
2. 删除按钮。

### 粉碎按钮

粉碎按钮只对已完成 Memo 生效。

点击后：

- 播放粉碎动画。
- 卡片消失。
- Memo 进入 archived 状态。
- 历史完成记录仍保留。

语义：

```text
我完成了它，并把它归档了。
```

### 删除按钮

删除按钮无论是否完成都可以点击。

点击后：

- Memo 标记为 deleted。
- 不建议物理删除数据库记录。
- 可保留短暂 Undo。

语义：

```text
这个任务不需要了。
```

---

## 5.6 Memo 排序规则

Memo 按截止日期排序。

推荐排序顺序：

1. 已过期未完成。
2. 今天截止。
3. 1 天内截止。
4. 2 天内截止。
5. 3 天内截止。
6. 更晚截止。
7. 已完成但未归档。

预警颜色：

```text
已过期：深红
剩余 0-1 天：红色
剩余 2 天：橙色
剩余 3 天：黄色
剩余 4 天及以上：普通颜色
已完成：灰色 / 低饱和绿色
```

注意：

DDL 判断建议按“日期”计算，而不是按精确小时计算。否则用户会遇到“明明是明天截止却被算成 23 小时”的混乱情况。

---

# 6. 模块三：View 视图页

## 6.1 页面目标

View 页不是用来编辑任务，而是用来回看完成记录。

它应该回答：

- 我今天完成了什么。
- 我这一周每天状态如何。
- 我这个月的完成节奏如何。
- 我的睡眠时间大概怎样。

核心原则：

```text
View 页读取完成记录 CompletionEvent，而不是直接读取当前任务状态。
```

原因：

如果用户后来修改了任务标题、删除了任务，历史视图仍然应该能保留当时的完成记录。

---

## 6.2 顶部切换

View 页顶部是三个选项：

```text
Day | Week | Month
```

点击后切换视图。

建议使用 Segmented Control，而不是普通 Tab，因为这个模块内部就是三种视图切换。

---

## 6.3 日视图 Day View

### 6.3.1 顶部环形图

日视图顶部用一个环形图表示当天完成内容。

环形中间放像素宠物。

环形切片按照任务完成顺序排列。

不同类型使用不同颜色：

```text
Plan：蓝色
Memo：橙色
Habit：绿色
Sleep / Wake：紫色
```

环形图表达的不是时间长度，而是完成事件顺序和类型分布。

### 6.3.2 下方完成列表

环形图下方显示当天完成内容：

```text
睡眠时间：23:48 - 07:12，共 7h24m

1.  7:12 早起
2. 9:30 完成算法题
3.  11:20 Reading
4.  15:10 完成 Memo：提交表格
5.  23:48 早睡
```

我们可以获得我们完成相应任务时候的精确时间，按完成顺序显示。

睡眠时间计算：

```text
睡眠时长 = wakeTime - sleepTime
```

如果缺少早睡或早起记录，则显示：

```text
睡眠记录不完整
```

---

## 6.4 周视图 Week View

周视图参考 iOS 日历的布局感觉，但不做精确时间轴。

原因：你的 App 不是时间块日程管理，而是完成顺序记录。

推荐结构：

```text
Mon      Tue      Wed      Thu      Fri      Sat      Sun
07:10    07:42    --       08:01    07:20    09:10    --
Plan xxx     Habit xxx    Memo     Plan     Plan     Habit    Memo
Memo xxx    Plan xxx             Habit    Memo
23:40    00:20    --       23:55    00:10    --       --
```

每一天显示：

1. 起床时间。
2. 中间显示完成的 Plan / Memo / Habit 要具体写出完成的任务
3. 底部显示睡觉时间。
4. 用颜色区分类型。

点击某一天，可以展开该天详情，复用 Day View 的列表。

可能week表会比较长 所以这一页大概率需要滑动
---

## 6.5 月视图 Month View

月视图使用日历网格。

每个日期格子中显示：

- 日期数字。
- 每天的格子应该是能够显示 plan 完成率的小圆环 圆环中间是plan 对应的符号 然后下方是相应的完成百分比 然后比较显眼 然后是memo和habbit的符号 完成了ddl 就显示memo图标 没完成就不显示 然后图标下面显示完成的ddl数量 然后habbits 的图标 下面有几个小正方形框框 完成了多少正方形框框就打了多少勾勾（不包括起床和睡眠的完成） 然后睡眠异常记录 用红色小月亮右上角加一个小感叹号的图标来表示
- 睡眠记录异常时显示小月亮警告。

点击某一天：

- 下方出现当天摘要。
- 可以进入 Day View。

月视图的目标不是显示所有任务文字，而是帮助用户感知长期节奏。

---

# 7. 模块四：Setting 设置页

## 7.1 个人资料区域

顶部显示：

- 头像。
- 昵称。
- 账号名。

点击头像：

- 打开头像大图。
- 下方显示修改头像按钮。
- 支持从图库选择或拍照。

点击昵称：

- 弹出编辑昵称输入框。

v0.1 如果没有账号系统，可以把账号名显示为本地用户名：

```text
local_user
```

---

## 7.2 宠物设置

- 更换宠物。（目前准备了三种）

- 查看宠物成长值。
- 查看宠物心情规则。
- 开启 / 关闭宠物动画。

v0.1 建议只做：

```text
宠物显示开关 + 宠物状态说明
```

---

## 7.3 其他设置项

设置页包含：

1. 账号安全。
2. 桌面小部件。
3. 语言。
4. 深色模式。
5. 退出登录。

v0.1 建议处理方式：

| 设置项   | v0.1 建议       |
| ----- | ------------- |
| 账号安全  | 占位，提示未来支持同步账号 |
| 桌面小部件 | 占位            |
| 语言    | 先固定中文，预留设置项   |
| 深色模式  | 可以实现          |
| 退出登录  | 如果没有账号系统，先隐藏  |

---

# 8. 数据模型设计

## 8.1 设计原则

数据模型必须支持：

1. Plan 的每日任务。
2. Habit 的长期模板和每日记录。
3. Memo 的 DDL 管理。
4. View 页的历史完成记录。
5. 5 分钟撤销。
6. 未来多端同步。

关键原则：

```text
任务状态和完成历史分离。
```

也就是说：

- PlanTask / MemoTask / HabitRecord 表示当前任务状态。
- CompletionEvent 表示历史完成事件。

---

## 8.2 UserProfile

```text
UserProfile
- id
- nickname
- username
- avatarUri
- createdAt
- updatedAt
```

v0.1 可以只有一个本地用户。

---

## 8.3 PlanTask

```text
PlanTask
- id
- date
- title
- sortOrder
- isDone
- completedAt
- createdAt
- updatedAt
- deletedAt
- syncStatus
- remoteId
- revision
```

说明：

- date 表示任务属于哪一天。
- sortOrder 表示有序列表顺序。
- deletedAt 用于软删除。
- syncStatus / remoteId / revision 为未来同步预留。

---

## 8.4 HabitTemplate

```text
HabitTemplate
- id
- title
- type
- sortOrder
- isEnabled
- createdAt
- updatedAt
- deletedAt
- syncStatus
- remoteId
- revision
```

Habit 类型：

```text
NORMAL
WAKE_UP
SLEEP
```

---

## 8.5 HabitRecord

```text
HabitRecord
- id
- habitTemplateId
- date
- isDone
- checkedAt
- valueTime
- createdAt
- updatedAt
- syncStatus
- remoteId
- revision
```

说明：

- checkedAt 表示点击完成的时间。
- valueTime 用于早起 / 早睡记录具体时间。
- 普通 Habit 可以不使用 valueTime。

---

## 8.6 MemoTask

```text
MemoTask
- id
- content
- dueDate
- isDone
- completedAt
- isArchived
- createdAt
- updatedAt
- deletedAt
- syncStatus
- remoteId
- revision
```

说明：

- isArchived 表示完成后粉碎归档。
- deletedAt 表示用户删除。
- 完成和删除是两种不同语义。

---

## 8.7 CompletionEvent

```text
CompletionEvent
- id
- targetType
- targetId
- targetTitleSnapshot
- date
- completedAt
- undoDeadlineAt
- color
- isCanceled
- createdAt
- syncStatus
- remoteId
- revision
```

字段说明：

- targetType：PLAN / MEMO / HABIT / WAKE\_UP / SLEEP。
- targetId：对应任务或习惯记录 ID。
- targetTitleSnapshot：完成时的标题快照。
- undoDeadlineAt：完成后 5 分钟。
- isCanceled：是否被撤销。

View 页主要读取 CompletionEvent。

---

# 9. 关键业务规则

## 9.1 完成任务规则

用户点击任务完成：

1. 更新任务 isDone = true。
2. 写入 completedAt。
3. 创建 CompletionEvent。
4. 设置 undoDeadlineAt = completedAt + 5 分钟。
5. 更新进度条。
6. 更新宠物状态。

---

## 9.2 5 分钟撤销规则

用户在 5 分钟内再次点击：

1. 更新任务 isDone = false。
2. 清空 completedAt。
3. 将 CompletionEvent 标记为 isCanceled = true。
4. 更新进度条和宠物状态。

超过 5 分钟后：

- 不允许直接撤销。
- 后续版本可以加入“历史纠错”。

---

## 9.3 Plan 日期滚动规则

Plan 页的三张卡片不是固定数据，而是根据当前日期动态查询：

```text
Yesterday = today - 1
Today = today
Tomorrow = today + 1
```

午夜后，Tomorrow 自动变为 Today。

---

## 9.4 Habit 模板规则

Habit 的编辑影响未来，不破坏历史。

规则：

- 删除 Habit = 停用 HabitTemplate。
- 历史 HabitRecord 保留。
- View 页仍然可以显示过去完成过的 Habit。

---

## 9.5 Memo DDL 规则

Memo 的紧迫程度按本地日期计算：

```text
daysLeft = dueDate - today
```

不要按小时差直接判断，否则用户体验容易混乱。

---

# 10. UI 风格规范

## 10.1 总体视觉方向

关键词：

- 像素宠物
- 玻璃质感
- 液态进度条
- 柔和卡片
- 高完成反馈
- 轻量、可爱但不幼稚

整体不建议做成强烈儿童风，而是“干净的效率工具 + 少量可爱陪伴”。

---

## 10.2 卡片规范

卡片建议：

- 大圆角。
- 柔和阴影。
- 低饱和背景色。
- 内部留白充足。
- 不要让装饰抢过任务文字。

---

## 10.3 进度条规范

液态进度条用于：

- Plan 卡片完成进度。
- Memo 顶部宠物奔跑进度。

完成后可以显示随机奖励 icon：

- 星星
- 花朵
- 笑脸
- 勾勾
- 小火花

动画要短，不要影响操作效率。

建议动画时长：

```text
200ms - 500ms
```

---

## 10.4 深色模式

深色模式不能只是把背景变黑。

建议：

- 背景使用深蓝灰。
- 卡片使用深色玻璃质感。
- 文字保持足够对比度。
- 进度条颜色降低饱和度。
- 宠物保持亮度，成为视觉中心。

---

##  未来多端同步扩展

未来要支持 Android / iOS / Mac，可以考虑两条路线：

### 路线 A：Android 原生先做完整，再迁移共享逻辑

适合当前阶段。

优点：

- 开发快。
- 学习成本低。
- Android MVP 更容易完成。

缺点：

- 未来 iOS / Mac 需要迁移一部分逻辑。

### 路线 B：一开始使用 Kotlin Multiplatform

优点：

- 未来多端共享数据模型和业务逻辑。
- 可以减少重复代码。

缺点：

- 项目结构更复杂。
- 对初版开发不友好。

当前建议：

```text
v0.1 Android 原生优先。
v0.2 把 domain model / usecase 设计成可迁移结构。
v1.0 再考虑 Kotlin Multiplatform 共享逻辑。
```

---

#

---

# 15. 后续可扩展功能

后续可以逐步加入：

1. 本地通知提醒。
2. 桌面小组件。
3. 宠物成长等级。
4. 宠物装扮系统。
5. 每周总结报告。
6. 月度完成热力图。
7. 数据导出。
8. 云同步。
9. iOS / Mac 客户端。
10. 多语言支持。

---

#
