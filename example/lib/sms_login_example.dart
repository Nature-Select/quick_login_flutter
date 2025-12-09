import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quick_login_flutter/quick_login_flutter.dart';

/// 示例：如何在一键登录页面切换到验证码登录
class SmsLoginExample extends StatefulWidget {
  const SmsLoginExample({super.key});

  @override
  State<SmsLoginExample> createState() => _SmsLoginExampleState();
}

class _SmsLoginExampleState extends State<SmsLoginExample> {
  final _plugin = QuickLoginFlutter.instance;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  String _status = '未初始化';
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    // 监听事件流，处理切换到验证码登录的事件
    _eventSubscription = _plugin.getEventStream().listen((event) {
      final eventType = event[QuickLoginEventKeys.event];
      if (eventType == QuickLoginEventKeys.eventTypeSwitchToSmsLogin) {
        _handleSwitchToSmsLogin();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  /// 处理切换到验证码登录
  Future<void> _handleSwitchToSmsLogin() async {
    // 关闭原生授权页面
    await _plugin.dismiss();
    
    // 显示验证码登录页面（这里需要你自己实现验证码登录页面）
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SmsCodeLoginPage(),
        ),
      );
    }
  }

  Future<void> _initSdk() async {
    try {
      await _plugin.initialize(
        appId: 'YOUR_APP_ID',
        appKey: 'YOUR_APP_KEY',
        enableDebug: true,
      );
      setState(() {
        _initialised = true;
        _status = 'SDK 初始化完成';
      });
    } catch (e) {
      setState(() {
        _status = '初始化失败: $e';
      });
    }
  }

  Future<void> _login() async {
    try {
      final result = await _plugin.login(
        uiConfig: AuthUIConfig(
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
          // 启用切换到验证码登录按钮
          showSwitchButton: true,
          switchButtonText: '切换到验证码登录',
          switchButtonTextColor: 0xffffffff, // 白色文字，在黑色背景上可见
          switchButtonTextSize: 14,
          switchButtonBackgroundColor: 0xff000000, // 黑色背景
        ),
      );
      setState(() {
        _status = '授权结果: ${result.raw}';
      });
    } catch (e) {
      setState(() {
        _status = '授权失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('一键登录 - 切换到验证码登录示例')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _initSdk,
              child: const Text('初始化 SDK'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initialised ? _login : null,
              child: const Text('弹出授权页（带切换到验证码登录按钮）'),
            ),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// 验证码登录页面示例（需要你自己实现）
class SmsCodeLoginPage extends StatelessWidget {
  const SmsCodeLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('验证码登录')),
      body: const Center(
        child: Text('这里是验证码登录页面\n你需要自己实现验证码登录逻辑'),
      ),
    );
  }
}

