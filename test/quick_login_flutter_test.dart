import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:quick_login_flutter/quick_login_flutter.dart';
import 'package:quick_login_flutter/quick_login_flutter_method_channel.dart';
import 'package:quick_login_flutter/quick_login_flutter_platform_interface.dart';

class MockQuickLoginFlutterPlatform
    with MockPlatformInterfaceMixin
    implements QuickLoginFlutterPlatform {
  bool initialized = false;
  Map<String, dynamic>? lastInitArgs;

  @override
  Future<void> dismiss() async {}

  @override
  Future<void> initialize({
    required String appId,
    required String appKey,
    bool enableDebug = false,
    int? timeoutMs,
  }) async {
    initialized = true;
    lastInitArgs = {
      'appId': appId,
      'appKey': appKey,
      'enableDebug': enableDebug,
      'timeoutMs': timeoutMs,
    };
  }

  @override
  Future<Map<String, dynamic>> login({
    int? timeoutMs,
    AuthUIConfig? uiConfig,
  }) => Future.value({
    'resultCode': 'login',
    'token': 'abc',
    'timeoutMs': timeoutMs,
  });

  @override
  Future<Map<String, dynamic>> prefetchNumber({int? timeoutMs}) =>
      Future.value({'resultCode': 'prefetch', 'timeoutMs': timeoutMs});

  @override
  Stream<Map<String, dynamic>> getEventStream() => const Stream.empty();
}

void main() {
  final QuickLoginFlutterPlatform initialPlatform =
      QuickLoginFlutterPlatform.instance;

  test('$MethodChannelQuickLoginFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQuickLoginFlutter>());
  });

  test('delegates to platform interface', () async {
    final plugin = QuickLoginFlutter.instance;
    final mock = MockQuickLoginFlutterPlatform();
    QuickLoginFlutterPlatform.instance = mock;

    await plugin.initialize(
      appId: 'id',
      appKey: 'key',
      enableDebug: true,
      timeoutMs: 1000,
    );
    expect(mock.initialized, isTrue);
    expect(mock.lastInitArgs?['appId'], 'id');
    expect(mock.lastInitArgs?['enableDebug'], isTrue);

    final loginResult = await plugin.login(timeoutMs: 2000);
    expect(loginResult.token, 'abc');
    expect(loginResult.raw['timeoutMs'], 2000);

    final prefetchResult = await plugin.prefetchNumber();
    expect(prefetchResult.raw['resultCode'], 'prefetch');
  });
}
