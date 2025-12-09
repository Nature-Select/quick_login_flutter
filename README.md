# quick_login_flutter

Flutter 插件，基于当前仓库提供的中国移动一键登录 SDK (`quick_login_android_5.9.15.aar`、`TYRZUISDK.xcframework`) 封装，帮助在 iOS/Android 弹出原生授权页并获取 token。

## 功能概览

- SDK 初始化：设置 `appId`/`appKey`、可选调试开关与超时时间。
- 预取号：在弹窗前提前取号，加快后续授权。
- 弹出原生授权页获取 token。
- 关闭授权页。
- 支持自定义授权页样式（全屏/半屏/中心弹窗、按钮文案/颜色/偏移等）。
- **支持在授权页面添加"切换到验证码登录"按钮（iOS/Android）**：用户可以在原生授权页面点击按钮，切换到自定义的验证码登录页面。

## 使用示例

```dart
import 'package:quick_login_flutter/quick_login_flutter.dart';

final quickLogin = QuickLoginFlutter.instance;

Future<void> init() async {
  await quickLogin.initialize(
    appId: '你的AppId',
    appKey: '你的AppKey',
    enableDebug: true,
  );
}

Future<void> login() async {
  final result = await quickLogin.login(
    uiConfig: const AuthUIConfig(
      presentationStyle: AuthPresentationStyle.bottomSheet,
      windowHeightPercent: 0.55,
      loginButtonText: '本机号一键登录',
      loginButtonTextColor: 0xffffffff,
      loginButtonTextSize: 16,
      loginButtonTextBold: true,
      loginButtonOffsetY: 220,
      numberOffsetY: 120,
      privacyOffsetY: 160,
      privacyRequired: true,
    ),
  );
  // result.raw 包含原生返回的完整字典，例如 resultCode、token 等
  if (result.hasToken) {
    // 将 token 传给服务端换取手机号
  }
}
```

运行 `example/` 可查看完整交互示例（需填入真实 `appId`/`appKey`）。

## 切换到验证码登录功能（iOS/Android）

如果用户不想使用一键登录，可以在授权页面添加"切换登录方式"按钮，点击后切换到自定义的其他登录页面（如验证码登录、账号密码登录等）。

### 使用步骤

1. **在 `AuthUIConfig` 中启用切换登录方式按钮**（Android 通过叠加自定义按钮实现，按钮默认位于号码区域右侧，可用 `numberOffsetY`/`switchButtonSpacing` 微调）：

```dart
final result = await quickLogin.login(
  uiConfig: AuthUIConfig(
    // ... 其他配置 ...
    // 启用切换登录方式按钮
    showSwitchButton: true,
    switchButtonText: '切换到验证码登录',  // 可选，默认文案
    switchButtonTextColor: 0xff666666,      // 可选，默认颜色
    switchButtonTextSize: 14,                // 可选，默认字号
    switchButtonBackgroundColor: 0xFF333333, // 可选，默认背景色
    switchButtonWidth: 36,                   // 可选，默认宽度（dp）
    switchButtonHeight: 20,                  // 可选，默认高度（dp）
    switchButtonCornerRadius: 10,            // 可选，默认圆角（dp）
    switchButtonSpacing: 8,                  // 可选，与号码框间距（dp）
  ),
);
```

2. **监听事件流，处理切换到验证码登录的事件**：

```dart
import 'dart:async';
import 'package:quick_login_flutter/quick_login_flutter.dart';

// 在 initState 中监听事件
StreamSubscription<Map<String, dynamic>>? _eventSubscription;

@override
void initState() {
  super.initState();
  _eventSubscription = QuickLoginFlutter.instance.getEventStream().listen((event) {
    final eventType = event[QuickLoginEventKeys.event];
    if (eventType == QuickLoginEventKeys.eventTypeSwitchToSmsLogin) {
      // 用户点击了切换到验证码登录按钮
      _handleSwitchToSmsLogin();
    } else if (eventType == QuickLoginEventKeys.eventTypeCheckboxNotChecked) {
      // 用户未勾选隐私协议就点击了登录按钮
      _showCheckboxTip();
    } else if (eventType == QuickLoginEventKeys.eventTypeLoginCallback) {
      // 登录回调事件（包含 resultCode、token 等）
      final payload = event[QuickLoginEventKeys.payload];
      _handleLoginCallback(payload);
    }
  });
}

@override
void dispose() {
  _eventSubscription?.cancel();
  super.dispose();
}

Future<void> _handleSwitchToSmsLogin() async {
  // 1. 关闭原生授权页面
  await QuickLoginFlutter.instance.dismiss();
  
  // 2. 打开你的验证码登录页面
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => YourSmsCodeLoginPage(),
    ),
  );
}
```

完整示例请参考 `example/lib/sms_login_example.dart`。

### 事件类型说明

插件提供了事件流监听机制，可以通过 `QuickLoginFlutter.instance.getEventStream()` 获取事件流。事件 Map 包含以下字段：

- `QuickLoginEventKeys.event`：事件类型，可能的值：
  - `QuickLoginEventKeys.eventTypeSwitchToSmsLogin`：用户点击了切换到验证码登录按钮
  - `QuickLoginEventKeys.eventTypeCheckboxNotChecked`：用户点击登录但未勾选隐私协议（需要设置 `privacyRequired: true`）
  - `QuickLoginEventKeys.eventTypeLoginCallback`：登录回调事件（包含 resultCode、token 等数据）
- `QuickLoginEventKeys.payload`：事件携带的数据（某些事件类型会包含此字段）

## 平台说明

### Android
- 已内置 `android/libs/quick_login_android_5.9.15.aar`，`minSdk` 设为 21。
- SDK 清单中已包含网络相关权限；如需自定义其他权限，可在宿主应用清单中声明。
- 授权页依赖当前 `Activity`，请确保调用时插件已附着到 Activity。

### iOS
- 已内置 `Frameworks/TYRZUISDK.xcframework` 与 `Resources/TYRZResource.bundle`，平台最低 iOS 12。
- 默认使用 SDK 内置 UI；如需深度自定义，可在原生层扩展 `UAFCustomModel`。
- 返回的 `resultCode` 为 `103000` 即表示获取 token 成功，`token` 字段可用于服务端换取手机号。

### UI 可配字段（Dart -> 原生）
- 窗口/弹窗：`presentationStyle`、`windowWidthPercent`、`windowHeightPercent`、`windowWidth`、`windowHeight`、`windowCornerRadius`、`windowCornerRadiusTopLeft`、`windowCornerRadiusTopRight`、`windowCornerRadiusBottomLeft`、`windowCornerRadiusBottomRight`、`windowOffsetX`、`windowOffsetY`、`windowBottom`、`themeId`、`presentAnimated`、`fitsSystemWindows`、`windowBackgroundAlpha`（iOS centerDialog 蒙层透明度，0~1）、`backgroundColor`、`backgroundImage`、`backButtonEnabled`
- 状态栏/导航：`statusBarColor`、`statusBarDarkText`、`navHidden`、`navColor`、`navTextColor`、`navTextSize`、`navTextFromWebTitle`、`clauseLayoutResId`/`clauseLayoutReturnId`、`clauseDialogTheme`、`clauseStatusBarColor`、`authLayoutResId`
- 登录按钮：`loginButtonText`、`loginButtonTextColor`、`loginButtonTextSize`、`loginButtonTextBold`、`loginButtonImageName`、`loginButtonBackgroundColor`、`loginButtonCornerRadius`、`loginButtonWidth`/`loginButtonHeight`、`loginButtonMarginLeft`/`loginButtonMarginRight`、`loginButtonOffsetY`/`loginButtonOffsetYBottom`
- 号码栏：`numberColor`、`numberSize`、`numberBold`、`numberOffsetX`、`numberOffsetY`、`numberOffsetYBottom`
- 品牌 logo：`displayLogo`、`logoWidth`/`logoHeight`、`logoOffsetX`/`logoOffsetY`/`logoOffsetYBottom`
- 隐私区：`privacyText` + `privacyClauses`（使用 `PrivacyClause`）、`privacyBaseTextColor`、`privacyClauseTextColor`、`privacyTextSize`、`privacyTextBold`、`privacyTextCenter`、`privacyMarginLeft`/`privacyMarginRight`、`privacyOffsetY`/`privacyOffsetYBottom`、`privacyBookSymbol`、`checkboxCheckedImageName`/`checkboxUncheckedImageName`/`checkboxImageWidth`/`checkboxImageHeight`、`checkboxLocation`、`checkboxOffsetX`/`checkboxOffsetY`、`checkboxAccurateClick`、`privacyPageFullScreen`、`privacyAnimation`、`checkTipText`、`webDomStorage`、`privacyDefaultCheck`、`privacyRequired`
- **切换登录方式按钮（iOS/Android）**：`showSwitchButton`（是否显示）、`switchButtonText`（按钮文案）、`switchButtonTextColor`（文字颜色）、`switchButtonTextSize`（文字大小）、`switchButtonBackgroundColor`（背景颜色，默认 0xFF333333）、`switchButtonWidth`（宽度，默认 36dp）、`switchButtonHeight`（高度，默认 20dp）、`switchButtonCornerRadius`（圆角半径，默认 100）、`switchButtonSpacing`（与号码框间距，默认 8dp）
- **关闭按钮（iOS/Android）**：`showCloseButton`（是否显示，默认 true）、`closeButtonTopSpacing`（顶部间距，默认 12dp）、`closeButtonRightSpacing`（右边间距，默认 12dp）、`closeButtonImageName`（图片名称，默认 "close.png"）
- 其他：`provideTextSize`/`provideTextBold`/`provideTextColor`/`provideTextOffsetX`/`provideTextOffsetY`/`provideTextOffsetYBottom`、`authPageInAnimation`/`activityOutAnimation`/`authPageOutAnimation`/`activityInAnimation`、`appLanguageType`
- 说明：自定义协议使用 `PrivacyClause(name: ..., url: ...)` 传入；`checkboxLocation` 对应 `CheckboxLocation.top/center`；`appLanguageType` 对应 `AppLanguageType` 枚举。

## 配置说明

### 开发环境配置

运行示例项目前，需要先配置凭证信息：

1. **创建环境变量文件**

```bash
cd example
cp .env.example .env
```

编辑 `.env` 文件，填入你的真实凭证：

```env
IOS_APP_ID=your_ios_app_id
IOS_APP_KEY=your_ios_app_key
ANDROID_APP_ID=your_android_app_id
ANDROID_APP_KEY=your_android_app_key
```

2. **配置 Android 签名**（可选，仅需打包发布时）

```bash
cd example/android
cp key.properties.example key.properties
```

编辑 `key.properties`，填入你的签名信息。详细说明请参考 [SECURITY.md](SECURITY.md)。

### 获取凭证

- `appId` 和 `appKey` 需在[中国移动能力开放平台](https://dev.10086.cn/)注册获取
- iOS 和 Android 平台需要分别申请

## 🔒 安全提示

**⚠️ 重要：切勿将以下文件提交到版本控制系统！**

- `.env` 文件（包含 appId/appKey）
- `key.properties` 文件（包含签名密钥）
- `*.keystore` 或 `*.jks` 文件

本项目已配置 git pre-commit hook 自动检测并阻止敏感文件提交。详细的安全配置指南请查看 [SECURITY.md](SECURITY.md)。

## 注意事项

- `timeoutMs` 统一使用毫秒（可选参数）；Android 对应 `setOverTime`，iOS 对应 `setTimeoutInterval`。
- SDK 会弹出原生授权界面，确保宿主 App 隐私合规与必要的权限申请。
- 登录返回的 `QuickLoginResult` 包含以下字段：
  - `raw`：原生返回的完整字典
  - `resultCode`：结果码，使用 `UAFSDKErrorCode.success`（值为 '103000'）判断登录成功
  - `token`：登录成功时返回的 token，用于服务端换取手机号
  - `hasToken`：便捷属性，判断是否有有效 token
  - `operatorType`：运营商类型
  - `message`：结果描述信息
- 更多错误码常量请参考 `UAFSDKErrorCode` 类。
