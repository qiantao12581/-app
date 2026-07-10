# 使用 GitHub Actions 构建并通过 TrollStore 安装

## 适用设备

本项目最低支持 iOS 16.0。目标设备为 iPhone 14 Pro、iOS 16.5.1，并已安装可正常使用的 TrollStore。

TrollStore 官方支持 iOS 14.0 beta 2 到 16.6.1、16.7 RC 和 iOS 17.0。不要为了安装本 App 更新系统。

## 云端生成 IPA

1. 在浏览器打开 GitHub 私有仓库。
2. 点击仓库顶部的 **Actions**。
3. 在左侧选择 **Build TrollStore IPA**。
4. 点击 **Run workflow**，选择需要构建的分支，再点击绿色按钮确认。
5. 等待任务显示绿色对勾。
6. 打开本次运行，在页面底部的 **Artifacts** 下载 `NutritionTracker-TrollStore`。
7. 解压下载的 ZIP，得到 `NutritionTracker-TrollStore.ipa`。
8. `NutritionTracker-build-info` 中包含 Bundle ID、最低 iOS、Xcode 版本和 IPA 的 SHA-256 校验值。

GitHub Actions 使用云端 macOS 和 Xcode。脚本构建的是 `iphoneos` 真机 Release 版本，并关闭 Apple 代码签名；TrollStore 在安装时处理应用签名。

## 把 IPA 传到 iPhone

推荐使用 iCloud Drive：

1. 在 Windows 浏览器打开 <https://www.icloud.com/iclouddrive/>。
2. 上传 `NutritionTracker-TrollStore.ipa`。
3. 在 iPhone 的“文件”App 中打开 iCloud Drive，等待文件下载完成。

也可以在 iPhone Safari 登录 GitHub，直接从 Actions 运行页面下载构建产物并在“文件”App 中解压。

## 使用 TrollStore 安装

1. 在“文件”App 中长按 `NutritionTracker-TrollStore.ipa`。
2. 点击“共享”。
3. 在共享菜单中选择 TrollStore；如果第一屏没有显示，点击“更多”。
4. TrollStore 打开后点击 **Install**。
5. 安装完成后，从主屏幕打开“营养记录”。

如果 IPA 直接点击没有出现 TrollStore，请先打开 TrollStore，再使用其安装入口选择该 IPA。

## 更新与数据安全

- 后续版本保持相同 Bundle ID，可以直接在 TrollStore 中覆盖安装。
- 覆盖安装前仍建议备份重要记录。
- 不要先卸载旧版本；卸载通常会同时删除 App 的本地 Core Data 数据。
- 重启后若图标暂时无法打开，使用 TrollStore 的 Persistence Helper 刷新 App Registrations。
- 只安装由自己的私有仓库工作流生成的 IPA，并对照 `build-info.txt` 的 SHA-256 值。

## 常见问题

### Actions 显示红色叉号

打开失败步骤并查看日志。项目尚未完整生成、Swift 编译错误或测试失败时，工作流不会上传 IPA。修复后重新运行。

### 安装时提示已存在同 Bundle ID 应用

如果设备上有 Xcode、TestFlight 或其他来源安装的同 Bundle ID 版本，先确认其中的数据是否需要保留，再移除冲突版本。不要在未备份时删除正在使用的版本。

### App 与 iOS 不兼容

打开 `build-info.txt`，确认“最低 iOS”为 16.0。如果不是 16.0，停止安装并修正 Xcode 项目的 Deployment Target。

## 参考

- TrollStore 官方仓库：<https://github.com/opa334/TrollStore>
- GitHub 托管运行器：<https://docs.github.com/en/actions/how-tos/manage-runners/github-hosted-runners/use-github-hosted-runners>
- GitHub Actions 构建产物：<https://docs.github.com/en/actions/tutorials/store-and-share-data>

