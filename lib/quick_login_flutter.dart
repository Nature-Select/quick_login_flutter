export 'src/auth_ui_config.dart';
export 'src/quick_login_result.dart';
export 'src/uaf_sdk_error_code.dart';
export 'src/quick_login_event_keys.dart';

import 'package:quick_login_flutter/src/auth_ui_config.dart';
import 'package:quick_login_flutter/src/quick_login_result.dart';

import 'quick_login_flutter_platform_interface.dart';

class QuickLoginFlutter {
  QuickLoginFlutter._();

  static final QuickLoginFlutter instance = QuickLoginFlutter._();
  factory QuickLoginFlutter() => instance;

  /// 初始化原生 SDK（传入运营商分配的 appId、appKey，支持可选调试/超时时间）
  /// [appId] 运营商分配的应用 ID
  /// [appKey] 运营商分配的密钥
  /// [enableDebug] 是否开启原生日志
  /// [timeoutMs] 超时时间（毫秒）
  Future<void> initialize({
    required String appId,
    required String appKey,
    bool enableDebug = false,
    int? timeoutMs,
  }) {
    return QuickLoginFlutterPlatform.instance.initialize(
      appId: appId,
      appKey: appKey,
      enableDebug: enableDebug,
      timeoutMs: timeoutMs,
    );
  }

  /// 预取号，加速后续弹窗授权
  /// [timeoutMs] 超时时间（毫秒，可选）
  Future<QuickLoginResult> prefetchNumber({int? timeoutMs}) async {
    final payload = await QuickLoginFlutterPlatform.instance.prefetchNumber(
      timeoutMs: timeoutMs,
    );
    return QuickLoginResult(raw: payload);
  }

  /// 弹出原生授权页并获取 token
  /// [timeoutMs] 超时时间（毫秒，可选）
  /// [uiConfig] 授权页 UI 配置（全屏/半屏/弹窗、按钮文案等）
  Future<QuickLoginResult> login({
    int? timeoutMs,
    AuthUIConfig? uiConfig,
  }) async {
    final payload = await QuickLoginFlutterPlatform.instance.login(
      timeoutMs: timeoutMs,
      uiConfig: uiConfig,
    );
    return QuickLoginResult(raw: payload);
  }

  /// 关闭授权页
  Future<void> dismiss() {
    return QuickLoginFlutterPlatform.instance.dismiss();
  }

  /// 获取事件流，用于监听授权页相关事件
  /// 
  /// 返回的事件 Map 包含以下字段：
  /// - [QuickLoginEventKeys.event]: 事件类型，可能的值：
  ///   - [QuickLoginEventKeys.eventTypeSwitchToSmsLogin]: 用户点击了切换到验证码登录按钮
  ///   - [QuickLoginEventKeys.eventTypeLoginCallback]: 登录回调事件
  ///   - [QuickLoginEventKeys.eventTypeCheckboxNotChecked]: 用户点击登录但未勾选隐私协议
  ///   - [QuickLoginEventKeys.eventTypeAuthPageShown]: 原生授权页已弹出
  ///   - [QuickLoginEventKeys.eventTypeAuthPageClosed]: 原生授权页已关闭
  /// - [QuickLoginEventKeys.payload]: 事件携带的数据（对于某些事件类型）
  /// 
  /// 使用示例：
  /// ```dart
  /// QuickLoginFlutter.instance.getEventStream().listen((event) {
  ///   final eventType = event[QuickLoginEventKeys.event];
  ///   if (eventType == QuickLoginEventKeys.eventTypeSwitchToSmsLogin) {
  ///     // 处理切换到验证码登录
  ///   }
  /// });
  /// ```
  Stream<Map<String, dynamic>> getEventStream() {
    return QuickLoginFlutterPlatform.instance.getEventStream();
  }
}
