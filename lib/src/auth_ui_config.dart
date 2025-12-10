enum AuthPresentationStyle {
  /// 全屏授权页
  fullScreen,

  /// 底部半屏/弹窗
  bottomSheet,

  /// 中心弹窗
  centerDialog,
}

enum CheckboxLocation {
  /// 复选框相对协议文案靠上
  top,

  /// 复选框居中
  center,
}

enum AppLanguageType {
  /// 中文简体
  simplifiedChinese,

  /// 中文繁体
  traditionalChinese,

  /// 英文
  english,
}

class PrivacyClause {
  const PrivacyClause({required this.name, required this.url});

  final String name;
  final String url;

  Map<String, String> toMap() => {'name': name, 'url': url};
}

class AuthUIConfig {
  const AuthUIConfig({
    this.presentationStyle = AuthPresentationStyle.fullScreen,
    this.windowWidthPercent,
    this.windowHeightPercent,
    this.windowWidth,
    this.windowHeight,
    this.windowCornerRadius,
    this.windowCornerRadiusTopLeft,
    this.windowCornerRadiusTopRight,
    this.windowCornerRadiusBottomLeft,
    this.windowCornerRadiusBottomRight,
    this.presentAnimated = true,
    this.fitsSystemWindows,
    this.statusBarColor,
    this.statusBarDarkText,
    this.navHidden,
    this.navColor,
    this.navTextColor,
    this.navTextSize,
    this.navTextFromWebTitle,
    this.clauseLayoutResId,
    this.clauseLayoutReturnId,
    this.clauseStatusBarColor,
    this.clauseDialogTheme,
    this.authLayoutResId,
    this.backgroundImage,
    this.backgroundColor,
    this.loginButtonText,
    this.loginButtonTextColor,
    this.loginButtonTextSize,
    this.loginButtonTextBold = false,
    this.loginButtonImageName,
    this.loginButtonBackgroundColor,
    this.loginButtonCornerRadius,
    this.loginButtonOffsetY,
    this.loginButtonOffsetYBottom,
    this.loginButtonWidth,
    this.loginButtonHeight,
    this.loginButtonMarginLeft,
    this.loginButtonMarginRight,
    this.numberOffsetY,
    this.numberOffsetYBottom,
    this.numberOffsetX,
    this.numberColor,
    this.numberSize,
    this.numberBold,
    this.privacyOffsetY,
    this.privacyOffsetYBottom,
    this.privacyMarginLeft,
    this.privacyMarginRight,
    this.privacyText,
    this.privacyClauses = const <PrivacyClause>[],
    this.privacyTextSize,
    this.privacyTextBold,
    this.privacyTextCenter,
    this.privacyBaseTextColor,
    this.privacyClauseTextColor,
    this.checkboxLocation,
    this.checkboxCheckedImageName,
    this.checkboxUncheckedImageName,
    this.checkboxImageWidth,
    this.checkboxImageHeight,
    this.checkboxAccurateClick,
    this.checkboxOffsetX,
    this.checkboxOffsetY,
    this.privacyPageFullScreen,
    this.privacyAnimation,
    this.checkTipText,
    this.showNativeToast = true,
    this.nativeToastCenterYOffset,
    this.webDomStorage,
    this.privacyDefaultCheck,
    this.privacyRequired = true,
    this.privacyBookSymbol,
    this.provideTextSize,
    this.provideTextBold,
    this.provideTextColor,
    this.provideTextOffsetX,
    this.provideTextOffsetY,
    this.provideTextOffsetYBottom,
    this.displayLogo,
    this.logoWidth,
    this.logoHeight,
    this.logoOffsetX,
    this.logoOffsetY,
    this.logoOffsetYBottom,
    this.authPageInAnimation,
    this.activityOutAnimation,
    this.authPageOutAnimation,
    this.activityInAnimation,
    this.windowOffsetX,
    this.windowOffsetY,
    this.windowBottom,
    this.themeId,
    this.backButtonEnabled,
    this.appLanguageType,
    this.showSwitchButton = false,
    this.switchButtonText,
    this.switchButtonTextColor,
    this.switchButtonTextSize,
    this.switchButtonBackgroundColor,
    this.switchButtonWidth,
    this.switchButtonHeight,
    this.switchButtonCornerRadius,
    this.switchButtonSpacing,
    this.showCloseButton = true,
    this.closeButtonTopSpacing,
    this.closeButtonRightSpacing,
    this.closeButtonImageName,
  });

  /// 授权页展示形式
  final AuthPresentationStyle presentationStyle;

  /// 弹窗宽度百分比（0~1，centerDialog/bottomSheet 时可用）
  /// 如果同时设置了 windowWidth，则以 windowWidth 为准
  final double? windowWidthPercent;

  /// 弹窗高度百分比（0~1，centerDialog/bottomSheet 时可用）
  /// 如果同时设置了 windowHeight，则以 windowHeight 为准
  final double? windowHeightPercent;

  /// 弹窗宽度具体值（dp，centerDialog/bottomSheet 时可用）
  /// 如果同时设置了 windowWidthPercent，则以 windowWidth 为准
  final double? windowWidth;

  /// 弹窗高度具体值（dp，centerDialog/bottomSheet 时可用）
  /// 如果同时设置了 windowHeightPercent，则以 windowHeight 为准
  final double? windowHeight;

  /// 弹窗顶部圆角半径（dp，centerDialog/bottomSheet；iOS 支持 centerDialog/bottomSheet，Android 仅 bottomSheet）
  final double? windowCornerRadius;

  /// 左上圆角半径（dp，centerDialog/bottomSheet）
  final double? windowCornerRadiusTopLeft;

  /// 右上圆角半径（dp，centerDialog/bottomSheet）
  final double? windowCornerRadiusTopRight;

  /// 左下圆角半径（dp，centerDialog/bottomSheet）
  final double? windowCornerRadiusBottomLeft;

  /// 右下圆角半径（dp，centerDialog/bottomSheet）
  final double? windowCornerRadiusBottomRight;

  /// 是否展示弹出动画
  final bool presentAnimated;

  /// 是否开启安卓底部导航栏自适应
  final bool? fitsSystemWindows;

  /// 状态栏背景色（仅安卓）
  final int? statusBarColor;

  /// 状态栏字体是否深色（仅安卓）
  final bool? statusBarDarkText;

  /// 隐藏服务条款导航栏（仅安卓）
  final bool? navHidden;

  /// 服务条款导航栏背景色（仅安卓）
  final int? navColor;

  /// 服务条款导航栏标题颜色（仅安卓）
  final int? navTextColor;

  /// 服务条款导航栏标题字号（仅安卓）
  final int? navTextSize;

  /// 服务条款标题是否读取网页标题（仅安卓）
  final bool? navTextFromWebTitle;

  /// 服务条款标题布局资源 ID（含返回按钮，安卓）
  final int? clauseLayoutResId;

  /// 服务条款返回按钮 ID 字符串（安卓）
  final String? clauseLayoutReturnId;

  /// 服务条款页状态栏颜色（安卓）
  final int? clauseStatusBarColor;

  /// 服务条款弹窗主题（安卓）
  final int? clauseDialogTheme;

  /// 授权页布局资源 ID（安卓）
  final int? authLayoutResId;

  /// 背景图资源名（宿主需提供）
  final String? backgroundImage;

  /// 背景色（安卓，传入 0xAARRGGBB 整数值）
  final int? backgroundColor;

  /// 登录按钮文案
  final String? loginButtonText;

  /// 登录按钮文字颜色（0xAARRGGBB）
  final int? loginButtonTextColor;

  /// 登录按钮文字大小（sp）
  final int? loginButtonTextSize;

  /// 登录按钮文字是否加粗
  final bool loginButtonTextBold;

  /// 登录按钮背景图资源名
  final String? loginButtonImageName;

  /// 登录按钮背景颜色（0xAARRGGBB，iOS，当设置此属性时，会使用自定义按钮覆盖原生按钮）
  final int? loginButtonBackgroundColor;

  /// 登录按钮圆角半径（dp，iOS，当设置 loginButtonBackgroundColor 时生效）
  final double? loginButtonCornerRadius;

  /// 登录按钮 Y 偏移（dp）
  final double? loginButtonOffsetY;

  /// 登录按钮距底部偏移（dp）
  final double? loginButtonOffsetYBottom;

  /// 登录按钮宽度（dp）
  final double? loginButtonWidth;

  /// 登录按钮高度（dp）
  final double? loginButtonHeight;

  /// 登录按钮左边距（dp）
  final double? loginButtonMarginLeft;

  /// 登录按钮右边距（dp）
  final double? loginButtonMarginRight;

  /// 号码展示 Y 偏移（dp）
  final double? numberOffsetY;

  /// 号码展示距底部偏移（dp）
  final double? numberOffsetYBottom;

  /// 号码展示 X 偏移（dp）
  final double? numberOffsetX;

  /// 号码字体颜色
  final int? numberColor;

  /// 号码字体大小
  final int? numberSize;

  /// 号码是否加粗
  final bool? numberBold;

  /// 隐私区 Y 偏移（dp）
  final double? privacyOffsetY;

  /// 隐私区距底部偏移（dp）
  final double? privacyOffsetYBottom;

  /// 隐私区左右边距（dp）
  final double? privacyMarginLeft;
  final double? privacyMarginRight;

  /// 隐私条款展示模板，需包含 SDK 默认协议标记
  final String? privacyText;

  /// 自定义协议（最多 4 个）
  final List<PrivacyClause> privacyClauses;

  /// 隐私条款字体大小
  final int? privacyTextSize;

  /// 隐私条款字体是否加粗
  final bool? privacyTextBold;

  /// 隐私条款是否居中
  final bool? privacyTextCenter;

  /// 隐私条款基础文案颜色
  final int? privacyBaseTextColor;

  /// 隐私协议名称颜色
  final int? privacyClauseTextColor;

  /// 复选框位置（靠上/居中，安卓）
  final CheckboxLocation? checkboxLocation;

  /// 复选框选中图
  final String? checkboxCheckedImageName;

  /// 复选框未选中图
  final String? checkboxUncheckedImageName;

  /// 复选框宽度（dp，安卓）
  final int? checkboxImageWidth;

  /// 复选框高度（dp，安卓）
  final int? checkboxImageHeight;

  /// 复选框精确点击（安卓）
  final bool? checkboxAccurateClick;

  /// 复选框 X 偏移（dp，iOS/Android，用于调整与协议文案的间距）
  final double? checkboxOffsetX;

  /// 复选框 Y 偏移（dp，iOS/Android）
  final double? checkboxOffsetY;

  /// 协议页是否全屏（安卓）
  final bool? privacyPageFullScreen;

  /// 协议区域动画配置（安卓）
  final String? privacyAnimation;

  /// 未勾选提示文案
  final String? checkTipText;

  /// 是否展示原生 toast（复选框未勾选时）
  final bool showNativeToast;

  /// toast 相对 window 中心的 Y 轴偏移（dp，正数向下）
  final double? nativeToastCenterYOffset;

  /// WebView domStorage 开关（安卓）
  final bool? webDomStorage;

  /// 复选框默认是否勾选（安卓）
  final bool? privacyDefaultCheck;

  /// 是否强制勾选隐私（false 则忽略勾选）
  final bool privacyRequired;

  /// 隐私条款书名号开关
  final bool? privacyBookSymbol;

  /// 底部说明文字字号/加粗（香港号码场景）
  final int? provideTextSize;
  final bool? provideTextBold;

  /// 底部说明文字颜色
  final int? provideTextColor;

  /// 底部说明文字 X 偏移（dp）
  final double? provideTextOffsetX;

  /// 底部说明文字 Y 偏移（dp）
  final double? provideTextOffsetY;

  /// 底部说明文字距底部偏移（dp）
  final double? provideTextOffsetYBottom;

  /// 品牌 logo 是否显示
  final bool? displayLogo;

  /// 品牌 logo 宽高（dp）
  final double? logoWidth;
  final double? logoHeight;

  /// 品牌 logo X 偏移（dp）
  final double? logoOffsetX;

  /// 品牌 logo Y 偏移（dp）
  final double? logoOffsetY;

  /// 品牌 logo 距底部偏移（dp）
  final double? logoOffsetYBottom;

  /// 授权页进场动画（安卓 overridePendingTransition 动画资源名）
  final String? authPageInAnimation;

  /// 宿主退出动画（安卓）
  final String? activityOutAnimation;

  /// 授权页退场动画（安卓）
  final String? authPageOutAnimation;

  /// 宿主进入动画（安卓）
  final String? activityInAnimation;

  /// 弹窗 X/Y 轴偏移（dp，安卓）
  final double? windowOffsetX;
  final double? windowOffsetY;

  /// 弹窗是否底部对齐（安卓）
  final bool? windowBottom;

  /// 弹窗主题 id（安卓）
  final int? themeId;

  /// 实体返回键是否可用（安卓）
  final bool? backButtonEnabled;

  /// 授权页语言（安卓）
  final AppLanguageType? appLanguageType;

  /// 是否显示切换登录方式按钮（iOS/Android）
  final bool showSwitchButton;

  /// 切换登录方式按钮文案（iOS/Android）
  final String? switchButtonText;

  /// 切换登录方式按钮文字颜色（0xAARRGGBB，iOS/Android）
  final int? switchButtonTextColor;

  /// 切换登录方式按钮文字大小（iOS/Android）
  final int? switchButtonTextSize;

  /// 切换登录方式按钮背景颜色（0xAARRGGBB，iOS/Android，默认 0xFF333333）
  final int? switchButtonBackgroundColor;

  /// 切换登录方式按钮宽度（dp，iOS/Android，默认 36）
  final double? switchButtonWidth;

  /// 切换登录方式按钮高度（dp，iOS/Android，默认 20）
  final double? switchButtonHeight;

  /// 切换登录方式按钮圆角半径（dp，iOS/Android，默认 100 完全圆形）
  final double? switchButtonCornerRadius;

  /// 切换登录方式按钮与号码框的间距（dp，iOS/Android，默认 8）
  final double? switchButtonSpacing;

  /// 是否显示关闭按钮（iOS/Android，默认 true）
  final bool showCloseButton;

  /// 关闭按钮顶部间距（dp，iOS/Android，默认 12）
  final double? closeButtonTopSpacing;

  /// 关闭按钮右边间距（dp，iOS/Android，默认 12）
  final double? closeButtonRightSpacing;

  /// 关闭按钮图片名称（iOS/Android，默认 "close.png"）
  final String? closeButtonImageName;

  Map<String, dynamic> toMap() {
    return {
      'presentationStyle': presentationStyle.name,
      'windowWidthPercent': windowWidthPercent,
      'windowHeightPercent': windowHeightPercent,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'windowCornerRadius': windowCornerRadius,
      'windowCornerRadiusTopLeft': windowCornerRadiusTopLeft,
      'windowCornerRadiusTopRight': windowCornerRadiusTopRight,
      'windowCornerRadiusBottomLeft': windowCornerRadiusBottomLeft,
      'windowCornerRadiusBottomRight': windowCornerRadiusBottomRight,
      'presentAnimated': presentAnimated,
      'fitsSystemWindows': fitsSystemWindows,
      'statusBarColor': statusBarColor,
      'statusBarDarkText': statusBarDarkText,
      'navHidden': navHidden,
      'navColor': navColor,
      'navTextColor': navTextColor,
      'navTextSize': navTextSize,
      'navTextFromWebTitle': navTextFromWebTitle,
      'clauseLayoutResId': clauseLayoutResId,
      'clauseLayoutReturnId': clauseLayoutReturnId,
      'clauseStatusBarColor': clauseStatusBarColor,
      'clauseDialogTheme': clauseDialogTheme,
      'authLayoutResId': authLayoutResId,
      'backgroundImage': backgroundImage,
      'backgroundColor': backgroundColor,
      'loginButtonText': loginButtonText,
      'loginButtonTextColor': loginButtonTextColor,
      'loginButtonTextSize': loginButtonTextSize,
      'loginButtonTextBold': loginButtonTextBold,
      'loginButtonImageName': loginButtonImageName,
      'loginButtonBackgroundColor': loginButtonBackgroundColor,
      'loginButtonCornerRadius': loginButtonCornerRadius,
      'loginButtonOffsetY': loginButtonOffsetY,
      'loginButtonOffsetYBottom': loginButtonOffsetYBottom,
      'loginButtonWidth': loginButtonWidth,
      'loginButtonHeight': loginButtonHeight,
      'loginButtonMarginLeft': loginButtonMarginLeft,
      'loginButtonMarginRight': loginButtonMarginRight,
      'numberOffsetY': numberOffsetY,
      'numberOffsetYBottom': numberOffsetYBottom,
      'numberOffsetX': numberOffsetX,
      'numberColor': numberColor,
      'numberSize': numberSize,
      'numberBold': numberBold,
      'privacyOffsetY': privacyOffsetY,
      'privacyOffsetYBottom': privacyOffsetYBottom,
      'privacyMarginLeft': privacyMarginLeft,
      'privacyMarginRight': privacyMarginRight,
      'privacyText': privacyText,
      'privacyClauses': privacyClauses.map((e) => e.toMap()).toList(),
      'privacyTextSize': privacyTextSize,
      'privacyTextBold': privacyTextBold,
      'privacyTextCenter': privacyTextCenter,
      'privacyBaseTextColor': privacyBaseTextColor,
      'privacyClauseTextColor': privacyClauseTextColor,
      'checkboxLocation': checkboxLocation?.name,
      'checkboxCheckedImageName': checkboxCheckedImageName,
      'checkboxUncheckedImageName': checkboxUncheckedImageName,
      'checkboxImageWidth': checkboxImageWidth,
      'checkboxImageHeight': checkboxImageHeight,
      'checkboxAccurateClick': checkboxAccurateClick,
      'checkboxOffsetX': checkboxOffsetX,
      'checkboxOffsetY': checkboxOffsetY,
      'privacyPageFullScreen': privacyPageFullScreen,
      'privacyAnimation': privacyAnimation,
      'checkTipText': checkTipText,
      'showNativeToast': showNativeToast,
      'nativeToastCenterYOffset': nativeToastCenterYOffset,
      'webDomStorage': webDomStorage,
      'privacyDefaultCheck': privacyDefaultCheck,
      'privacyRequired': privacyRequired,
      'privacyBookSymbol': privacyBookSymbol,
      'provideTextSize': provideTextSize,
      'provideTextBold': provideTextBold,
      'provideTextColor': provideTextColor,
      'provideTextOffsetX': provideTextOffsetX,
      'provideTextOffsetY': provideTextOffsetY,
      'provideTextOffsetYBottom': provideTextOffsetYBottom,
      'displayLogo': displayLogo,
      'logoWidth': logoWidth,
      'logoHeight': logoHeight,
      'logoOffsetX': logoOffsetX,
      'logoOffsetY': logoOffsetY,
      'logoOffsetYBottom': logoOffsetYBottom,
      'authPageInAnimation': authPageInAnimation,
      'activityOutAnimation': activityOutAnimation,
      'authPageOutAnimation': authPageOutAnimation,
      'activityInAnimation': activityInAnimation,
      'windowOffsetX': windowOffsetX,
      'windowOffsetY': windowOffsetY,
      'windowBottom': windowBottom,
      'themeId': themeId,
      'backButtonEnabled': backButtonEnabled,
      'appLanguageType': appLanguageType?.index,
      'showSwitchButton': showSwitchButton,
      'switchButtonText': switchButtonText,
      'switchButtonTextColor': switchButtonTextColor,
      'switchButtonTextSize': switchButtonTextSize,
      'switchButtonBackgroundColor': switchButtonBackgroundColor,
      'switchButtonWidth': switchButtonWidth,
      'switchButtonHeight': switchButtonHeight,
      'switchButtonCornerRadius': switchButtonCornerRadius,
      'switchButtonSpacing': switchButtonSpacing,
      'showCloseButton': showCloseButton,
      'closeButtonTopSpacing': closeButtonTopSpacing,
      'closeButtonRightSpacing': closeButtonRightSpacing,
      'closeButtonImageName': closeButtonImageName,
    };
  }
}
