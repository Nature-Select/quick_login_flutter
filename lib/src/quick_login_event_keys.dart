/// 一键登录事件流中的键名和事件类型常量
class QuickLoginEventKeys {
  QuickLoginEventKeys._();

  /// 事件类型键名
  static const String event = 'event';

  /// 载荷数据键名
  static const String payload = 'payload';

  /// 结果码键名
  static const String resultCode = 'resultCode';

  /// Token 键名
  static const String token = 'token';

  /// 事件类型：切换到短信登录
  static const String eventTypeSwitchToSmsLogin = 'switchToSmsLogin';

  /// 事件类型：登录回调
  static const String eventTypeLoginCallback = 'loginCallback';

  /// 事件类型：复选框未勾选（用户点击登录但未勾选隐私协议）
  static const String eventTypeCheckboxNotChecked = 'checkboxNotChecked';
}
