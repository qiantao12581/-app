# 营养记录（iOS 16）

面向中文用户的原生 iPhone 食物营养与减脂记录 App，使用 Swift、SwiftUI 和 Core Data，无第三方依赖。最低支持 iOS 16.0，可在 iPhone 14 Pro / iOS 16.5.1 上通过 TrollStore 安装。

## 已实现功能

- 内置常见食物 JSON 数据库，支持名称和别名搜索。
- 手动填写食物、重量及每 100 克营养，自动计算实际热量和三大营养素。
- 相机拍照或相册选择图片；第一版使用明确标注的模拟识别结果，保存前必须手动确认。
- Core Data 本机持久化，今日汇总、滑动删除、按日期历史与当天详情。
- 自定义每日碳水、蛋白质和脂肪目标，分别显示还需或超出量。
- 根据已记录餐次和剩余三大营养素，离线生成午餐、晚餐和加餐建议。
- 个人资料、Mifflin–St Jeor 基础代谢、四档非锻炼活动系数和自定义系数。
- 手动记录运动主动消耗，计算预计总消耗、热量缺口或盈余。
- 体重记录、每月 3%–5% 复合减重目标、自动/手动目标日期、进度和倒计时。
- GitHub Actions 使用最新版稳定 Xcode 自动测试并生成无签名 TrollStore IPA。

## 目录

```text
NutritionTracker/
├─ App/           App 入口和三个标签页
├─ Features/      今日、添加、历史、资料和目标页面
├─ Models/        纯 Swift 值类型
├─ Persistence/   Core Data 模型、实体和存储服务
├─ Resources/     foods.json 和资源目录
├─ Services/      食物库、推荐和模拟识别服务
└─ Utilities/     营养、代谢、能量与目标日期计算
NutritionTrackerTests/   XCTest 测试
scripts/                  TrollStore IPA 打包脚本
docs/                     设计、测试与安装说明
```

## 构建与安装

没有 Mac 时，按照 [TrollStore 安装说明](docs/distribution/trollstore-install.md) 使用 GitHub Actions 生成并下载 IPA。覆盖升级时保持相同 Bundle ID；不要先删除旧版，否则本地记录可能一并丢失。

有 Mac 时，可在最新版 Xcode 中直接打开 `NutritionTracker.xcodeproj`，选择 `NutritionTracker` scheme 和 iOS 16 或更高版本的设备/模拟器运行。

## 重要说明

基础代谢、活动消耗、食物营养、热量缺口、减脂日期和餐次组合均为估算，仅用于一般记录与规划，不替代医生或注册营养师的诊断和建议。自动代谢与减脂计算仅面向 18 岁及以上成年人，不适用于孕期、哺乳期或需要临床营养治疗的人群。
