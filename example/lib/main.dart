import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quick_login_flutter/quick_login_flutter.dart';
import 'package:quick_login_flutter/src/quick_login_event_keys.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = QuickLoginFlutter.instance;
  final _appIdController = TextEditingController(
    text: Platform.isIOS
        ? (dotenv.env['IOS_APP_ID'] ?? '')
        : (dotenv.env['ANDROID_APP_ID'] ?? ''),
  );
  final _appKeyController = TextEditingController(
    text: Platform.isIOS
        ? (dotenv.env['IOS_APP_KEY'] ?? '')
        : (dotenv.env['ANDROID_APP_KEY'] ?? ''),
  );

  String _status = '未初始化';
  bool _initialised = false;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  String? _quickLoginToken;

  @override
  void initState() {
    super.initState();
    // 监听事件流，处理各类登录事件
    _eventSubscription = _plugin.getEventStream().listen((event) {
      final eventType = event[QuickLoginEventKeys.event];
      if (eventType == QuickLoginEventKeys.eventTypeSwitchToSmsLogin) {
        // 收到更换按钮点击事件，关闭授权页面
        _dismiss();
      } else if (eventType == QuickLoginEventKeys.eventTypeCheckboxNotChecked) {
        // 收到复选框未勾选事件，弹出 Toast 提示
        BotToast.showText(text: '请先阅读并勾选隐私协议', align: Alignment.center);
      } else if (eventType == QuickLoginEventKeys.eventTypeLoginCallback) {
        // 收到登录回调事件
        final payload = event[QuickLoginEventKeys.payload];
        if (payload is Map) {
          _handleLoginCallback(Map<String, dynamic>.from(payload));
        }
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _appIdController.dispose();
    _appKeyController.dispose();
    super.dispose();
  }

  Future<void> _initSdk() async {
    try {
      await _plugin.initialize(
        appId: _appIdController.text.trim(),
        appKey: _appKeyController.text.trim(),
        enableDebug: true,
        // timeoutMs: 8000,
      );
      setState(() {
        _initialised = true;
        _status = 'SDK 初始化完成';
        print('SDK 初始化完成');
      });
    } catch (e) {
      setState(() {
        _status = '初始化失败: $e';
        print('初始化失败: $e');
      });
    }
  }

  Future<void> _prefetch() async {
    try {
      final result = await _plugin.prefetchNumber(timeoutMs: 6000);
      setState(() {
        _status = '预取号: ${result.raw}';
      });
    } catch (e) {
      setState(() {
        _status = '预取号失败: $e';
      });
    }
  }

  Future<void> _login() async {
    try {
      final result = await _plugin.login(
        uiConfig: Platform.isIOS 
        ? const AuthUIConfig(
          presentationStyle: AuthPresentationStyle.bottomSheet,
          backgroundColor: 0xFFFFFFFF,
          windowCornerRadiusTopLeft: 40,
          windowCornerRadiusTopRight: 40,
          windowHeightPercent: 0.65,
          windowHeight: 294,
          statusBarDarkText: true,
          displayLogo: false,
          loginButtonText: '本机号码一键登录',
          loginButtonBackgroundColor: 0xFF333333,
          loginButtonCornerRadius: 56 * 0.5,
          loginButtonTextColor: 0xFFFFFFFF,
          loginButtonTextSize: 16,
          loginButtonTextBold: true,
          loginButtonHeight: 56,
          loginButtonWidth: 320,
          loginButtonOffsetY: 124,
          numberOffsetY: 74,
          numberColor: 0xFF333333,
          numberSize: 24,
          numberBold: true,
          privacyTextCenter: false,
          privacyOffsetY: 236,
          privacyText: '我已阅读并同意 我已阅读并同意 我已阅读并同意',
          privacyTextSize: 12,
          privacyBaseTextColor: 0x7F333333,
          privacyClauseTextColor: 0xFF333333,
          privacyRequired: true,
          privacyBookSymbol: true,
          // privacyMarginLeft: 0,
          // checkboxOffsetX: -40,
          // checkboxOffsetY: 8,
          // checkboxLocation: CheckboxLocation.top,
          showSwitchButton: true,
          switchButtonText: '更换',
          switchButtonTextColor: 0xffffffff,
          switchButtonTextSize: 14,
          switchButtonBackgroundColor: 0xFF333333,
          switchButtonWidth: 36,
          switchButtonHeight: 20,
          switchButtonCornerRadius: 20 * 0.5,
          switchButtonSpacing: 2,
        ) 
        : AuthUIConfig(
          presentationStyle: AuthPresentationStyle.bottomSheet,
          backgroundColor: 0xFFFFFFFF,
          windowCornerRadiusTopLeft: 40,
          windowCornerRadiusTopRight: 40,
          windowHeightPercent: 0.65,
          windowHeight: 294,
          statusBarDarkText: true,
          displayLogo: false,
          loginButtonText: '本机号码一键登录',
          loginButtonBackgroundColor: 0xFF333333,
          loginButtonCornerRadius: 56 * 0.5,
          loginButtonTextColor: 0xFFFFFFFF,
          loginButtonTextSize: 16,
          loginButtonTextBold: true,
          loginButtonHeight: 56,
          loginButtonWidth: 320,
          loginButtonOffsetY: 124,
          numberOffsetY: 74,
          numberColor: 0xFF333333,
          numberSize: 24,
          numberBold: true,
          privacyTextCenter: false,
          privacyOffsetY: 236,
          privacyText: '我已阅读并同意 我已阅读并同意 我已阅读并同意',
          privacyTextSize: 12,
          privacyBaseTextColor: 0x7F333333,
          privacyClauseTextColor: 0xFF333333,
          privacyRequired: true,
          privacyBookSymbol: true,
          checkboxOffsetY: 8,
          showSwitchButton: true,
          switchButtonText: '更换',
          switchButtonTextColor: 0xffffffff,
          switchButtonTextSize: 13.sp.toInt(),
          switchButtonBackgroundColor: 0xFF333333,
          switchButtonWidth: 36,
          switchButtonHeight: 20,
          switchButtonCornerRadius: 20 * 0.5,
          switchButtonSpacing: 2,
        ),
      );
      setState(() {
        _status = '授权结果: ${result.raw}';
        print('授权结果: ${result.raw}');
      });
    } catch (e) {
      setState(() {
        _status = '授权失败: $e';
        print('授权失败: $e');
      });
    }
  }

  Future<void> _dismiss() async {
    await _plugin.dismiss();
    setState(() {
      _status = '授权页关闭';
    });
  }

  void _handleLoginCallback(Map<String, dynamic> payload) {
    developer.log('一键登录回调: $payload', name: 'QuickLogin');

    final resultCode = payload[QuickLoginEventKeys.resultCode];
    if (resultCode != UAFSDKErrorCode.successGetAuthVCCode) {
      // 非授权页弹起事件，需要关闭授权页
      _plugin.dismiss().catchError((e) {
        developer.log('关闭授权页失败: $e', name: 'QuickLogin');
      });

      if (resultCode == UAFSDKErrorCode.success) {
        // 登录成功，获取 token
        final token = payload[QuickLoginEventKeys.token];
        _quickLoginToken = token;
        setState(() {
          _status = '一键登录成功，token: $token';
        });
        developer.log('一键登录成功，token: $token', name: 'QuickLogin');
      } else {
        // 登录失败
        setState(() {
          _status = '一键登录失败，resultCode: $resultCode';
        });
        developer.log('一键登录失败，resultCode: $resultCode', name: 'QuickLogin');
      }
    }
  }

  Future<void> _testNetworkRequest() async {
    setState(() {
      _status = '正在请求百度官网...';
    });
    
    try {
      developer.log('开始请求百度官网: https://www.baidu.com', name: 'NetworkTest');
      final response = await http.get(Uri.parse('https://www.baidu.com'));
      
      developer.log('请求状态码: ${response.statusCode}', name: 'NetworkTest');
      developer.log('响应头: ${response.headers}', name: 'NetworkTest');
      developer.log('响应体长度: ${response.body.length} 字符', name: 'NetworkTest');
      developer.log('响应体前500字符: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}', name: 'NetworkTest');
      
      setState(() {
        _status = '请求成功！状态码: ${response.statusCode}, 响应长度: ${response.body.length} 字符';
      });
    } catch (e, stackTrace) {
      developer.log('请求失败: $e', name: 'NetworkTest', error: e, stackTrace: stackTrace);
      setState(() {
        _status = '请求失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          builder: (context, widget) {
            return BotToastInit()(context, widget);
          },
          navigatorObservers: [BotToastNavigatorObserver()],
          home: Scaffold(
            appBar: AppBar(title: const Text('一键登录示例')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  TextField(
                    controller: _appIdController,
                    decoration: const InputDecoration(labelText: 'APP ID'),
                  ),
                  TextField(
                    controller: _appKeyController,
                    decoration: const InputDecoration(labelText: 'APP Key'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: _initSdk,
                        child: const Text('初始化 SDK'),
                      ),
                      ElevatedButton(
                        onPressed: _initialised ? _prefetch : null,
                        child: const Text('预取号'),
                      ),
                      ElevatedButton(
                        onPressed: _initialised ? _login : null,
                        child: const Text('弹出授权页'),
                      ),
                      OutlinedButton(
                        onPressed: _dismiss,
                        child: const Text('关闭授权页'),
                      ),
                      ElevatedButton(
                        onPressed: _testNetworkRequest,
                        child: const Text('网络请求测试'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_status, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        );
      },
      child: const SizedBox(),
    );
  }
}
