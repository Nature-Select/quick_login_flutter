import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:quick_login_flutter/quick_login_flutter.dart';
import 'package:quick_login_flutter/quick_login_flutter_platform_interface.dart';

import 'package:quick_login_flutter_example/main.dart';

class FakeQuickLoginPlatform extends QuickLoginFlutterPlatform {
  final events = StreamController<Map<String, dynamic>>.broadcast();
  AuthUIConfig? lastUiConfig;

  @override
  Future<void> initialize({
    required String appId,
    required String appKey,
    bool enableDebug = false,
    int? timeoutMs,
  }) async {}

  @override
  Future<Map<String, dynamic>> prefetchNumber({int? timeoutMs}) async {
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> login({
    int? timeoutMs,
    AuthUIConfig? uiConfig,
  }) async {
    lastUiConfig = uiConfig;
    return <String, dynamic>{};
  }

  @override
  Future<void> dismiss() async {}

  @override
  Stream<Map<String, dynamic>> getEventStream() => events.stream;
}

void main() {
  late FakeQuickLoginPlatform fakePlatform;
  late QuickLoginFlutterPlatform originalPlatform;

  setUpAll(() async {
    originalPlatform = QuickLoginFlutterPlatform.instance;
    await dotenv.load(fileName: '.env', isOptional: true);
  });

  setUp(() {
    fakePlatform = FakeQuickLoginPlatform();
    QuickLoginFlutterPlatform.instance = fakePlatform;
  });

  tearDown(() {
    QuickLoginFlutterPlatform.instance = originalPlatform;
  });

  testWidgets('login config enables native privacy agreement alert', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('初始化 SDK'));
    await tester.pump();
    await tester.tap(find.text('弹出授权页'));
    await tester.pump();

    final uiConfig = fakePlatform.lastUiConfig;
    expect(uiConfig, isNotNull);
    expect(uiConfig!.showPrivacyAgreementAlert, isTrue);
    expect(uiConfig.showNativeToast, isFalse);
    expect(uiConfig.privacyAgreementAlertTitle, '运营商服务协议');
    expect(
      uiConfig.privacyAgreementAlertMessage,
      '点击同意并继续视为您已同意运营商服务协议，并使用本机号码一键登录',
    );
    expect(uiConfig.privacyAgreementAlertCancelText, '取消');
    expect(uiConfig.privacyAgreementAlertContinueText, '同意并继续');

    await tester.pumpWidget(const SizedBox());
    await fakePlatform.events.close();
  });

  testWidgets(
    'checkbox event is handled by native sdk instead of Flutter dialog',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      fakePlatform.events.add({
        QuickLoginEventKeys.event:
            QuickLoginEventKeys.eventTypeCheckboxNotChecked,
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('未勾选隐私协议'), findsOneWidget);
      expect(find.text('运营商服务协议'), findsNothing);
      expect(find.text('同意并继续'), findsNothing);
      expect(find.text('取消'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await fakePlatform.events.close();
    },
  );
}
