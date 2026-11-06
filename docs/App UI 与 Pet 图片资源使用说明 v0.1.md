1. App Icon 资源
2. UI 设计参考图
3. Pet 静态状态图
4. Pet 动态序列帧(还没有做) 动态准备后面再跟进

App Icon 资源
/Users/tinghaodong/Code/Projects/paceKit/planner_pet_icon.ico

UI 设计参考图
```
ui_reference/
├── plan/
│   └── plan_view_reference.png
│
├── memo/
│   └── memo_view_reference.png
│
├── view/
│   ├── day_view_reference.png
│   ├── week_view_reference.png
│   └── month_view_reference.png
│
└── setting/
    └── setting_view_reference.png
```
UI 参考图只作为视觉参考，真正开发时应该拆成组件：不要把参考图当成页面背景

Pet 静态状态图
/Users/tinghaodong/Code/Projects/paceKit/pet

状态	中文含义	主要场景
normal	普通 / 待机	默认状态、完成率中等
happy	开心	今日完成率高、完成关键任务
sad	低落	今日完成率低、任务逾期较多
sleep	睡眠	睡眠总结、夜间状态、早睡记录
run	奔跑	Memo 顶部进度条、任务推进过程
empty	发呆	白天随机出现 宠物发呆

Pet 状态切换规则
今日完成分数

Plan 页顶部 Pet 状态由今日完成分数决定
推荐公式：
TodayScore = 0.65 × Plan完成率+0.25 × Habit完成率+0.10 × Memo完成率

其中：
Plan完成率 = 今日已完成Plan数 / 今日Plan总数
Habit完成率 = 今日已完成普通Habit数 / 今日普通Habit总数
Memo完成率 = 今日已完成Memo数 / 今日相关Memo总数
注意：Habit 完成率不建议把 Wake Up / Sleep Early 算入普通习惯完成率。它们更适合作为睡眠记录。

状态映射
TodayScore >= 0.75 -> happy
0.35 <= TodayScore < 0.75 -> normal
TodayScore < 0.35 -> sad