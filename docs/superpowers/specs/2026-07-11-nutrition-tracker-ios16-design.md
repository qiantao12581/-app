# NutritionTracker iOS 16 设计说明

## 1. 目标与边界

NutritionTracker 是一款面向中文用户的原生 iPhone 营养与减脂记录 App。用户可以记录每餐食物、每日运动和体重，查看当天热量与三大营养素，并根据每日目标获得后续餐次的离线食物组合建议。App 同时提供基础代谢估算、日常活动消耗、运动消耗、热量缺口、减脂目标日期和倒计时。

项目使用 Swift、SwiftUI 和 Core Data，不使用第三方库。最低部署版本为 iOS 16.0，目标设备包括运行 iOS 16.5.1 的 iPhone 14 Pro。项目应能由最新版 Xcode 直接打开、签名和运行。

本 App 提供的是一般性的记录和估算，不替代医生或注册营养师的诊断与建议。自动减脂计算仅面向 18 岁及以上成年人，不适用于孕期、哺乳期、未成年人或需要临床营养治疗的人群。

## 2. 技术选型

- UI：SwiftUI。
- 本地持久化：Core Data。SwiftData 最低要求 iOS 17，不能用于目标设备。
- 图片：相册使用 `PhotosPicker`，相机使用 `UIImagePickerController` 的 SwiftUI 包装。
- 并发：Swift `async/await`。
- 营养与建议：本地 JSON 数据库和确定性计算，不调用远程 AI。
- 测试：XCTest，计算逻辑优先采用纯值类型和纯函数测试。
- 导航：根视图使用 `TabView`，保留“今日”“添加”“历史”三个标签；个人资料和减脂目标使用页面内导航或 sheet。

## 3. 项目目录

```text
NutritionTracker.xcodeproj
NutritionTracker/
├─ App/
│  ├─ NutritionTrackerApp.swift
│  ├─ RootTabView.swift
│  └─ AppTab.swift
├─ Persistence/
│  ├─ PersistenceController.swift
│  ├─ NutritionTracker.xcdatamodeld/
│  ├─ FoodRecord+CoreDataClass.swift
│  ├─ FoodRecord+CoreDataProperties.swift
│  ├─ DailyNutritionGoal+CoreDataClass.swift
│  ├─ DailyNutritionGoal+CoreDataProperties.swift
│  ├─ NutritionSettings+CoreDataClass.swift
│  ├─ NutritionSettings+CoreDataProperties.swift
│  ├─ UserProfile+CoreDataClass.swift
│  ├─ UserProfile+CoreDataProperties.swift
│  ├─ WeightGoal+CoreDataClass.swift
│  ├─ WeightGoal+CoreDataProperties.swift
│  ├─ WeightEntry+CoreDataClass.swift
│  ├─ WeightEntry+CoreDataProperties.swift
│  ├─ ExerciseRecord+CoreDataClass.swift
│  └─ ExerciseRecord+CoreDataProperties.swift
├─ Models/
│  ├─ NutritionValues.swift
│  ├─ FoodReference.swift
│  ├─ FoodCategory.swift
│  ├─ MealType.swift
│  ├─ InputMethod.swift
│  ├─ BiologicalSex.swift
│  ├─ ActivityLevel.swift
│  ├─ DailyNutritionBalance.swift
│  ├─ DailyEnergyBalance.swift
│  └─ MealSuggestion.swift
├─ Services/
│  ├─ FoodDatabaseService.swift
│  ├─ FoodRecognitionService.swift
│  ├─ MockFoodRecognitionService.swift
│  ├─ MealRecommendationService.swift
│  └─ HealthDataService.swift
├─ Utilities/
│  ├─ NutritionCalculator.swift
│  ├─ DailySummaryCalculator.swift
│  ├─ MetabolismCalculator.swift
│  ├─ EnergyBalanceCalculator.swift
│  ├─ WeightGoalProjectionCalculator.swift
│  ├─ InputValidator.swift
│  ├─ NutritionFormatters.swift
│  └─ Date+DayBounds.swift
├─ Features/
│  ├─ Today/
│  │  ├─ TodayView.swift
│  │  ├─ DailySummaryCard.swift
│  │  ├─ MacroProgressRow.swift
│  │  ├─ EnergyBalanceCard.swift
│  │  ├─ WeightGoalCard.swift
│  │  ├─ MealSuggestionView.swift
│  │  └─ FoodRecordRow.swift
│  ├─ Add/
│  │  ├─ AddView.swift
│  │  ├─ AddFoodView.swift
│  │  ├─ AddExerciseView.swift
│  │  ├─ AddWeightView.swift
│  │  ├─ FoodSearchView.swift
│  │  ├─ PhotoFoodView.swift
│  │  └─ CameraPicker.swift
│  ├─ History/
│  │  ├─ HistoryView.swift
│  │  ├─ HistoryDayRow.swift
│  │  └─ HistoryDetailView.swift
│  ├─ Goals/
│  │  ├─ DailyGoalEditorView.swift
│  │  └─ WeightGoalEditorView.swift
│  └─ Profile/
│     └─ UserProfileEditorView.swift
├─ Resources/
│  ├─ foods.json
│  └─ Assets.xcassets/
└─ Supporting/
   └─ Info.plist

NutritionTrackerTests/
├─ NutritionCalculatorTests.swift
├─ DailySummaryCalculatorTests.swift
├─ FoodDatabaseServiceTests.swift
├─ MealRecommendationServiceTests.swift
├─ MetabolismCalculatorTests.swift
├─ EnergyBalanceCalculatorTests.swift
├─ WeightGoalProjectionCalculatorTests.swift
└─ PersistenceControllerTests.swift
```

`HealthDataService` 第一版只定义未来接入 HealthKit 所需的接口，不读取或写入健康数据。运动消耗由用户手动记录。

## 4. Core Data 模型

### 4.1 FoodRecord

每条食物记录包含：

- `id: UUID`
- `foodName: String`
- `weightGrams: Double`
- `calories: Double`
- `carbohydrates: Double`
- `protein: Double`
- `fat: Double`
- `createdAt: Date`
- `mealTypeRawValue: String`
- `inputMethodRawValue: String`

营养值保存实际摄入量，而不是每 100 克数据。这样历史统计不受以后修改内置食物库的影响。

### 4.2 NutritionSettings

这是单例配置，保存默认每日目标：

- `id: UUID`
- `defaultCarbohydrates: Double`
- `defaultProtein: Double`
- `defaultFat: Double`
- `updatedAt: Date`

### 4.3 DailyNutritionGoal

每天保存独立目标快照：

- `id: UUID`
- `date: Date`，归一化为用户当前日历的当天零点
- `carbohydrates: Double`
- `protein: Double`
- `fat: Double`
- `createdAt: Date`
- `updatedAt: Date`

新的一天第一次打开时，从 `NutritionSettings` 复制目标。修改默认值不回写过去日期。

### 4.4 UserProfile

- `id: UUID`
- `biologicalSexRawValue: String?`，男、女或未填写
- `birthDate: Date`
- `heightCentimeters: Double`
- `activityLevelRawValue: String`
- `customActivityFactor: Double`，零表示使用所选活动类型默认值
- `usesManualBMR: Bool`
- `manualBMR: Double`
- `updatedAt: Date`

不愿提供生理性别时，必须启用手动基础代谢；App 不使用臆测常数代替。

### 4.5 WeightGoal

- `id: UUID`
- `startWeightKilograms: Double`
- `targetWeightKilograms: Double`
- `startDate: Date`
- `monthlyLossRate: Double`，取值 0.03 到 0.05
- `targetDate: Date`
- `targetDateModeRawValue: String`，自动估算或手动指定
- `isActive: Bool`
- `createdAt: Date`
- `updatedAt: Date`

同一时间仅允许一个有效目标，旧目标保留用于历史展示。

### 4.6 WeightEntry

- `id: UUID`
- `weightKilograms: Double`
- `recordedAt: Date`

最新记录作为当前体重；没有体重记录时使用目标的起始体重。

### 4.7 ExerciseRecord

- `id: UUID`
- `name: String`
- `activeCalories: Double`
- `durationMinutes: Double`
- `createdAt: Date`

`activeCalories` 只表示运动产生的主动能量，不包含运动期间本来就会消耗的静息能量。

## 5. 内置食物数据库

`foods.json` 是 `[FoodReference]` 数组，每种食物包含：

- `id`
- `name`
- `aliases`
- `category`
- `suitableMeals`
- `caloriesPer100Grams`
- `carbohydratesPer100Grams`
- `proteinPer100Grams`
- `fatPer100Grams`
- `minimumSuggestedGrams`
- `maximumSuggestedGrams`
- `suggestionStepGrams`

首批食物包括熟米饭、鸡蛋、鸡胸肉、鸡腿肉、牛肉、猪肉、牛奶、香蕉、苹果、面条、馒头、红薯、土豆，以及西兰花、菠菜、生菜、番茄、黄瓜、胡萝卜等常见蔬菜。为了让加餐更实用，还加入无糖酸奶、燕麦和原味坚果。

搜索同时匹配名称和别名，忽略首尾空格及英文大小写。选择结果后自动填充每 100 克营养值，用户可以继续修改。

## 6. 核心计算

### 6.1 食物营养

对热量、碳水、蛋白质和脂肪分别计算：

```text
实际营养 = 每 100 克营养 × 实际重量 ÷ 100
```

内部保留 `Double` 精度，界面统一显示一位小数。

### 6.2 每日营养余额

```text
余额 = 每日目标 - 当天已摄入
```

- 正数显示“还需摄入”。
- 负数显示“已超出”的绝对值。
- 不把负数截断为零，避免隐藏超量。

### 6.3 基础代谢

默认使用 Mifflin–St Jeor 公式，体重单位为 kg，身高单位为 cm：

```text
男性 BMR = 10 × 体重 + 6.25 × 身高 - 5 × 年龄 + 5
女性 BMR = 10 × 体重 + 6.25 × 身高 - 5 × 年龄 - 161
```

年龄由出生日期和计算日期得到。用户也可以启用手动基础代谢，手动值优先。

### 6.4 日常活动系数

活动类型只描述不含专项运动的日常生活和工作：

| 类型 | 默认系数 | 含义 |
|---|---:|---|
| 久坐 | 1.20 | 办公、日常走动较少 |
| 轻度活动 | 1.30 | 经常站立、日常走动较多 |
| 中度活动 | 1.45 | 持续走动或中等体力工作 |
| 重度活动 | 1.60 | 长时间体力劳动 |

用户可以在 1.0 到 2.0 之间手动调整系数。专项锻炼单独记录，不能再次包含在活动类型判断中。

### 6.5 每日热量缺口

```text
日常基础消耗 = BMR × 日常活动系数
今日运动消耗 = 当天 ExerciseRecord.activeCalories 之和
今日预计总消耗 = 日常基础消耗 + 今日运动消耗
今日热量缺口 = 今日预计总消耗 - 今日食物摄入热量
```

结果为正数时显示热量缺口，为负数时显示热量盈余。所有结果标注为估算值。由于活动系数不包含专项运动，手动运动消耗不会被重复计算。

### 6.6 减脂目标日期与倒计时

自动日期采用按当前体重逐月复合下降的模型：

```text
下一月预计体重 = 当前预计体重 × (1 - 每月减重比例)
预计月数 = ln(目标体重 / 当前体重) ÷ ln(1 - 每月减重比例)
```

预计天数使用 `预计月数 × 30.4375` 并向上取整。目标日期等于计算日加预计天数。

手动目标日期模式反算所需月减重率：

```text
所需月减重率 = 1 - (目标体重 / 当前体重) ^ (30.4375 / 剩余天数)
```

若反算结果超过 5%，显示风险警告，并且不根据该速度生成扩大热量缺口的提示。更新体重记录后，自动模式重新估算目标日期；手动模式保留用户日期并更新所需速度提示。

进度按以下公式显示并限制在 0% 到 100%：

```text
进度 = (起始体重 - 当前体重) ÷ (起始体重 - 目标体重)
```

倒计时显示目标日期与当前日期之间的完整自然日数量，过期后显示“已超过目标日期”。达到或低于目标体重时显示“目标已完成”。

## 7. 离线餐次推荐

推荐服务不持久化结果。每次食物、目标或日期变化时重新计算。

### 7.1 尚未完成的餐次

- 当天没有主餐记录：推荐早餐、午餐、晚餐和加餐。
- 已记录早餐：推荐午餐、晚餐和加餐。
- 已记录早餐与午餐：推荐晚餐和加餐。
- 已记录晚餐：只在仍有明显营养缺口时推荐加餐。
- 加餐可以记录多次；推荐系统把它视为平衡营养素的最后手段，而不是必须完成的餐次。

### 7.2 缺口分配

如果仍有主餐，先为加餐预留当前正缺口的 15%，其余 85% 平均分给尚未完成的主餐。每次保存实际记录后使用真实摄入重新计算，不假设用户完全照推荐执行。

### 7.3 候选组合

- 主餐：一份主食、一份蛋白质来源和一份蔬菜。
- 加餐：一到两种适合加餐的水果、奶类、蛋、薯类、燕麦或坚果。
- 在每种食物允许的最小、最大重量之间，按建议步长枚举候选。
- 对每个候选计算碳水、蛋白质和脂肪与该餐目标的归一化误差。
- 对超过当天剩余额度的营养素增加双倍惩罚。
- 返回得分最低且主食或蛋白质来源互不相同的前三个方案。

如果三项均已达到或超出目标，显示“今天三大营养素已达标，无需额外加餐”。如果某项已经超出而其他项不足，优先选择对已超出项影响较小的食物，并明确显示无法完全补齐时的取舍。

选择“使用此方案”后进入确认页，用户可以修改各食物重量，再把组合中的食物分别保存为同一餐次的 `FoodRecord`。

## 8. 拍照流程

用户可以从相机或相册选择一张图片。图片只在当前添加流程中显示，不写入 Core Data，避免数据库膨胀。

`FoodRecognitionService` 接口接收图片数据并异步返回食物候选。第一版 `MockFoodRecognitionService` 返回固定模拟候选，并明确标注“模拟识别，请手动确认”。用户必须确认食物名称、重量和每 100 克营养后才能保存。

相机不可用、用户拒绝权限、图片读取失败或模拟识别失败时显示中文错误信息，并保留手动输入路径。

## 9. 页面设计与数据流

### 9.1 今日

按顺序显示：

1. 今日热量和三大营养素汇总。
2. 三大营养素目标、已摄入、还需或超出量。
3. 基础代谢、活动估算、运动消耗、总消耗和热量缺口／盈余。
4. 当前体重、目标体重、减脂进度、预计完成日期和倒计时。
5. 下一餐与加餐建议。
6. 今日食物记录，可滑动删除。

缺少每日目标、个人资料或减脂目标时，相应卡片显示明确的设置入口，不使用虚假默认值代替用户数据。

### 9.2 添加

顶部使用分段选择器切换：

- 食物：手动搜索、输入或拍照添加。
- 运动：输入运动名称、主动消耗热量和可选时长。
- 体重：输入当天体重。

食物表单包含食物名称、重量、每 100 克热量、碳水、蛋白质、脂肪、餐次和输入方式。营养预览随重量与每 100 克数值实时更新。

### 9.3 历史

按日期倒序显示每天的食物、运动、摄入热量、三大营养素、预计总消耗和热量缺口。进入某天可查看食物及运动明细。体重记录和目标进度在历史页提供独立区块。

## 10. 输入校验与错误处理

- 食物、运动名称去除首尾空格后不能为空。
- 重量必须大于零，所有营养和热量字段必须为有限的非负数。
- 每日碳水、蛋白质和脂肪目标必须大于零。
- 出生日期必须对应 18 岁及以上；否则禁用自动减脂与代谢建议。
- 身高、体重、BMR、活动系数和目标日期必须为有效正值并处于界面说明的合理范围。
- 减脂目标体重必须小于起始或当前体重；每月比例只能在 3% 到 5% 之间。
- 手动目标日期必须晚于今天。
- 保存 Core Data 失败时显示错误，不清空当前表单。
- `foods.json` 解码失败时允许完整手动输入，并显示数据库加载错误。
- 删除使用系统滑动删除；删除后立即重新计算当天余额、建议和热量缺口。
- 所有营养、体重和热量界面值显示一位小数；倒计时显示整数天。

## 11. 测试策略

实施遵循测试驱动开发。先写会因功能缺失而失败的测试，再实现最小代码。

### 11.1 纯计算测试

- 100 克、非 100 克和小数重量的营养换算。
- 三大营养素剩余、达标和超出。
- 男女 Mifflin–St Jeor 公式、手动 BMR 优先级和年龄计算。
- 四档活动系数、自定义系数和运动热量不重复计算。
- 热量缺口与盈余的正负号。
- 自动目标日期、手动日期反算、5% 边界、目标完成和过期状态。
- 餐次缺口分配、超量惩罚、前三个方案去重和全部达标时不推荐加餐。

### 11.2 数据与持久化测试

- 解码完整食物 JSON，验证所有营养值非负且建议重量范围有效。
- 使用内存 Core Data store 测试食物、运动、体重、每日目标的保存、读取和删除。
- 验证过去日期的每日目标不会因修改默认目标而改变。

### 11.3 构建与人工验收

- 使用最新版 Xcode 对 iOS 16 模拟器运行 `xcodebuild test`。
- 使用 App scheme 对 iOS 16 模拟器或 iPhone 14 Pro 构建。
- 检查三个标签、空状态、中文表单、负数输入、相册、相机、删除、跨日历史和 App 重启后的数据。
- 在没有 HealthKit 权限和没有 Apple Watch 的情况下，手动运动记录仍能完整工作。

## 12. 实施阶段

### 阶段一：项目与模型

创建 Xcode 项目、Core Data 模型、食物 JSON、枚举和值类型，并加入计算单元测试。

### 阶段二：最小可运行版本

完成食物搜索、手动输入、重量换算、保存、删除、今日汇总、每日三大营养素目标和余额。

### 阶段三：计划与推荐

完成个人资料、基础代谢、活动系数、运动记录、热量缺口、体重记录、减脂目标、倒计时和离线餐次推荐。

### 阶段四：照片与历史

完成相机、相册、模拟识别、按日历史和日期详情。

### 阶段五：验证与修复

运行全部测试与构建，修复编译错误和明显交互问题，最后提供 Xcode 运行、真机签名和测试步骤。

## 13. 参考依据

- Apple Core Data `NSPersistentContainer`：<https://developer.apple.com/documentation/coredata/nspersistentcontainer>
- Apple SwiftUI `PhotosPicker`：<https://developer.apple.com/documentation/photosui/photospicker>
- Apple HealthKit 主动能量定义：<https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/activeenergyburned>
- Mifflin–St Jeor 原始研究：<https://pubmed.ncbi.nlm.nih.gov/2305711/>
- CDC 渐进减重说明：<https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html>
- 国家卫生健康委《肥胖症诊疗指南（2024 年版）》：<https://www.gov.cn/zhengce/zhengceku/202410/P020241020715873679737.pdf>
