import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'quick_login_flutter_platform_interface.dart';
import 'src/auth_ui_config.dart';

/// An implementation of [QuickLoginFlutterPlatform] that uses method channels.
class MethodChannelQuickLoginFlutter extends QuickLoginFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('quick_login_flutter');
  @visibleForTesting
  final eventChannel = const EventChannel('quick_login_flutter/events');
  
  Stream<Map<String, dynamic>>? _eventStream;

  @override
  /// 调用原生 init
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
    return methodChannel.invokeMethod<void>('init', {
      'appId': appId,
      'appKey': appKey,
      'debug': enableDebug,
      'timeoutMs': timeoutMs,
    });
  }

  @override
  /// 调用原生预取号
  /// [timeoutMs] 超时时间（毫秒，可选）
  Future<Map<String, dynamic>> prefetchNumber({int? timeoutMs}) async {
    final response = await methodChannel.invokeMapMethod<String, dynamic>(
      'prefetchNumber',
      {'timeoutMs': timeoutMs},
    );
    return response?.map((key, value) => MapEntry(key, value)) ??
        <String, dynamic>{};
  }

  @override
  /// 调用原生授权页登录
  /// [timeoutMs] 超时时间（毫秒，可选）
  /// [uiConfig] 授权页 UI 配置
  Future<Map<String, dynamic>> login({
    int? timeoutMs,
    AuthUIConfig? uiConfig,
  }) async {
    final response = await methodChannel.invokeMapMethod<String, dynamic>(
      'login',
      {'timeoutMs': timeoutMs, 'uiConfig': uiConfig?.toMap()},
    );
    return response?.map((key, value) => MapEntry(key, value)) ??
        <String, dynamic>{};
  }

  @override
  /// 关闭授权页
  Future<void> dismiss() {
    return methodChannel.invokeMethod<void>('dismiss');
  }

  /// 获取事件流，用于监听切换到验证码登录等事件
  @override
  Stream<Map<String, dynamic>> getEventStream() {
    _eventStream ??= eventChannel.receiveBroadcastStream().cast<Map<dynamic, dynamic>>().map((event) {
      return Map<String, dynamic>.from(event.map((key, value) => MapEntry(key.toString(), value)));
    });
    return _eventStream!;
  }
}
