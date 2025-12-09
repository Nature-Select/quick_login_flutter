import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'quick_login_flutter_method_channel.dart';
import 'src/auth_ui_config.dart';

abstract class QuickLoginFlutterPlatform extends PlatformInterface {
  QuickLoginFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static QuickLoginFlutterPlatform _instance = MethodChannelQuickLoginFlutter();

  static QuickLoginFlutterPlatform get instance => _instance;

  static set instance(QuickLoginFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 初始化原生 SDK
  /// [appId] 运营商分配的应用 ID
  /// [appKey] 运营商分配的密钥
  /// [enableDebug] 是否开启原生日志
  /// [timeoutMs] 超时时间（毫秒，可选）
  Future<void> initialize({
    required String appId,
    required String appKey,
    bool enableDebug = false,
    int? timeoutMs,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// 预取号
  /// [timeoutMs] 超时时间（毫秒，可选）
  Future<Map<String, dynamic>> prefetchNumber({int? timeoutMs}) {
    throw UnimplementedError('prefetchNumber() has not been implemented.');
  }

  /// 弹出授权页并获取 token
  /// [timeoutMs] 超时时间（毫秒，可选）
  /// [uiConfig] 授权页 UI 配置
  Future<Map<String, dynamic>> login({int? timeoutMs, AuthUIConfig? uiConfig}) {
    throw UnimplementedError('login() has not been implemented.');
  }

  /// 关闭授权页
  Future<void> dismiss() {
    throw UnimplementedError('dismiss() has not been implemented.');
  }

  /// 获取事件流，用于监听切换到验证码登录等事件
  Stream<Map<String, dynamic>> getEventStream() {
    throw UnimplementedError('getEventStream() has not been implemented.');
  }
}
