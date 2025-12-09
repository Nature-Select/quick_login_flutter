import 'quick_login_event_keys.dart';

class QuickLoginResult {
  /// 封装原生返回结果，便于取出 token/resultCode 等字段
  /// [raw] 原生返回的完整字典
  QuickLoginResult({required Map<String, dynamic> raw})
    : raw = Map.unmodifiable(raw),
      resultCode = _stringValue(raw[QuickLoginEventKeys.resultCode]),
      token = _stringValue(raw[QuickLoginEventKeys.token]),
      operatorType =
          _stringValue(raw['operatortype']) ??
          _stringValue(raw['operatorType']),
      message =
          _stringValue(raw['resultDesc']) ??
          _stringValue(raw['desc']) ??
          _stringValue(raw['result']),
      requestCode = _intValue(raw['sdkRequestCode']);

  final Map<String, dynamic> raw;
  final String? resultCode;
  final String? token;
  final String? operatorType;
  final String? message;
  final int? requestCode;

  bool get hasToken => token?.isNotEmpty == true;

  static String? _stringValue(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int? _intValue(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
