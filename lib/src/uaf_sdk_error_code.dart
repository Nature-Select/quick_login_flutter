/// UAF SDK 错误码常量
/// 
/// 对应 iOS 框架中的 UAFSDKErrorCode.h 文件定义
class UAFSDKErrorCode {
  UAFSDKErrorCode._();

  /// 成功
  static const String success = '103000';

  /// 数据解析异常
  static const String processException = '200021';

  /// 无网络
  static const String noNetwork = '200022';

  /// 请求超时
  static const String requestTimeout = '200023';

  /// 未知错误
  static const String unknownError = '200025';

  /// 蜂窝未开启或不稳定
  static const String nonCellularNetwork = '200027';

  /// 网络请求出错(HTTP Code 非200)
  static const String requestError = '200028';

  /// 非移动网关重定向失败
  static const String wapRedirectFailed = '200038';

  /// 无SIM卡
  static const String phoneWithoutSIM = '200048';

  /// 无法识别sim卡或没有sim卡
  static const String unrecognizedSIM = '200010';

  /// 蜂窝未开启或不稳定 (operatortype: 0)
  static const String nonCellularNetworkDetail = '200027';

  /// Socket创建或发送接收数据失败
  static const String socketError = '200050';

  /// 用户点击了"账号切换"按钮（自定义短信页面customSMS为YES才会返回）
  static const String customSMSVC = '200060';

  /// 显示登录"授权页面"被拦截（hooked）
  static const String authVCisHooked = '200061';

  /// 连续授权超过限制
  static const String authFrequently = '200062';

  /// 服务端返回数据异常
  static const String exceptionData = '200064';

  /// CA根证书校验失败
  static const String caAuthFailed = '200072';

  /// 本机号码校验仅支持移动手机号
  static const String getMoblieOnlyCMCC = '200080';

  /// 服务器繁忙
  static const String serverBusy = '200082';

  /// ppLocation为空
  static const String locationError = '200086';

  /// 监听授权界面成功弹起
  static const String successGetAuthVCCode = '200087';

  /// 当前网络不支持取号
  static const String unsupportedNetwork = '200096';
}
