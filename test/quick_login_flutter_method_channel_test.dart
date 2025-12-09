import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_login_flutter/quick_login_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelQuickLoginFlutter platform =
      MethodChannelQuickLoginFlutter();
  const MethodChannel channel = MethodChannel('quick_login_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'init':
              return null;
            case 'login':
              return {'resultCode': 'ok', 'token': 't-123'};
            case 'prefetchNumber':
              return {'resultCode': 'prefetch'};
            case 'dismiss':
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('method channel calls', () async {
    await platform.initialize(appId: 'id', appKey: 'key');
    expect(await platform.login(), {'resultCode': 'ok', 'token': 't-123'});
    expect(await platform.prefetchNumber(), {'resultCode': 'prefetch'});
    await platform.dismiss();
  });
}
