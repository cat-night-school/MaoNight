# 猫夜 · iOS 原生版（无 HTML）

这是猫夜 iOS 的**原生 Swift 工程**：界面全部由 UIKit + CoreGraphics 绘制，
不包含 WKWebView、不加载任何 html，和 Windows 原生版是同一套视觉与流程。

## 已原生接入

| 页面 | 状态 |
|---|---|
| 登录（账号/密码，连猫夜后端） | ✅ 原生输入框 + 按钮 |
| 首页（用户卡、头衔、猫币/小鱼干/连胜、31 项功能菜单） | ✅ 原生自绘 |
| 棋类训练五步流程（棋种/模式/难度/先后手/房间） | ✅ |
| 五子棋对局（15×15 棋盘、人机/双人、悔棋、重开） | ✅ CoreGraphics 绘制 |
| 其余页面 | 原生过渡页，逐批补上（不加载网页） |

## 怎么出 IPA（Windows 上不用 Mac）

1. 在 GitHub 新建一个空仓库（Public，Actions 免费）
2. 把这个目录里的**全部内容**（包括 `.github`）上传到仓库根目录
3. 仓库 → Actions → 「Build Maonight Native IPA」→ Run workflow
4. 等 5~10 分钟，在运行页底部 Artifacts 下载 `MaonightNative-IPA.zip`，解压得到 `MaonightNative.ipa`
5. 装到 iPhone：已越狱 / TrollStore 直接装；未越狱用 Sideloadly 自签（7 天）

## 结构

```
project.yml                        XcodeGen 工程描述
Info.plist                         应用信息（显示名「猫夜」）
Sources/
  AppDelegate.swift                启动 + 根导航
  Theme.swift                      配色、玻璃卡片、按钮、页头
  Api.swift                        登录 / 拉资料（猫夜后端）
  LoginViewController.swift        登录页
  HomeViewController.swift         首页 + 31 项菜单
  ChessFlowViewController.swift    棋类训练五步流程
  GomokuViewController.swift       五子棋棋盘 + 本地 AI
  ComingSoonViewController.swift   未接入页面的原生过渡页
.github/workflows/build-native-ipa.yml  macOS CI 出 unsigned IPA
```