/// UAF SDK 错误码常量
/// 
/// 对应 iOS 框架中的 UAFSDKErrorCode.h 文件定义
class UAFSDKErrorCode {
  UAFSDKErrorCode._();

  /// 成功
  static const String success = '103000';

  /// 无网络
  static const String noNetworkLegacy = '102101';

  /// 网络异常
  static const String networkExceptionLegacy = '102102';

  /// 未开启数据网络
  static const String dataNetworkDisabledLegacy = '102103';

  /// 输入参数错误
  static const String inputParamErrorLegacy = '102203';

  /// 数据解析异常（一般是卡欠费）
  static const String parseErrorLegacy = '102223';

  /// 登录超时（授权页点登录按钮时）
  static const String loginTimeoutLegacy = '102507';

  /// 请求签名错误
  static const String requestSignError = '103101';

  /// 包签名错误
  static const String bundleIdError = '103102';

  /// 网关 IP 错误
  static const String gatewayIpError = '103111';

  /// appid 不存在
  static const String appIdNotFound = '103119';

  /// 其他错误（报文格式不对等）
  static const String otherRequestError = '103211';

  /// 预取号联通重定向
  static const String cuccRedirect = '103273';

  /// 无效的请求
  static const String invalidRequest = '103412';

  /// 参数校验异常
  static const String paramCheckError = '103414';

  /// 服务器 ip 白名单校验失败
  static const String ipWhiteListError = '103511';

  /// token 为空
  static const String tokenEmpty = '103811';

  /// scrip 失效（客户端高频调用请求 token 接口）
  static const String scripInvalid = '103902';

  /// token 请求过于频繁
  static const String tokenRequestTooFrequently = '103911';

  /// token 已失效或不存在
  static const String tokenInvalid = '104201';

  /// 联通取号失败
  static const String cuccGetPhoneFailed = '105001';

  /// 移动取号失败（一般是物联网卡）
  static const String cmccGetPhoneFailed = '105002';

  /// 电信取号失败
  static const String ctccGetPhoneFailed = '105003';

  /// 中国移动香港取号失败
  static const String cmhkGetPhoneFailed = '105004';

  /// 不支持电信取号
  static const String ctccUnsupported = '105012';

  /// 不支持联通取号
  static const String cuccUnsupported = '105013';

  /// token 权限不足
  static const String tokenNoPermission = '105018';

  /// 应用未授权
  static const String appUnauthorized = '105019';

  /// 已达当天取号限额
  static const String dailyLimitReached = '105021';

  /// appid 不在白名单
  static const String appIdNotInWhiteList = '105302';

  /// 移动能力余量不足
  static const String cmccQuotaInsufficient = '105312';

  /// 非法请求
  static const String illegalRequest = '105313';

  /// 不支持的运营商类型
  static const String unsupportedCarrier = '105315';

  /// 受限用户
  static const String restrictedUser = '105317';

  /// 电信能力余量不足
  static const String ctccQuotaInsufficient = '105422';

  /// 联通能力余量不足
  static const String cuccQuotaInsufficient = '105423';

  /// 中国移动香港能力余量不足
  static const String cmhkQuotaInsufficient = '105424';

  /// 中国移动香港能力余量不足
  static const String cmhkQuotaInsufficientLegacy = '105024';

  /// 用户未安装 sim 卡
  static const String phoneWithoutSIMLegacy = '200002';

  /// 用户未授权（READ_PHONE_STATE）
  static const String readPhoneStateUnauthorized = '200005';

  /// 数据解析异常
  static const String processException = '200021';

  /// 无网络
  static const String noNetwork = '200022';

  /// 请求超时
  static const String requestTimeout = '200023';

  /// 数据网络切换失败
  static const String dataNetworkSwitchFailed = '200024';

  /// 其他错误（socket、系统未授权数据蜂窝权限等）
  static const String unknownError = '200025';

  /// 输入参数错误
  static const String inputParamError = '200026';

  /// 蜂窝未开启或不稳定
  static const String nonCellularNetwork = '200027';

  /// 网络请求出错(HTTP Code 非200)
  static const String requestError = '200028';

  /// 非移动网关重定向失败
  static const String wapRedirectFailed = '200038';

  /// 异网取号网关取号失败
  static const String wapGatewayFailed = '200039';

  /// UI 资源加载异常
  static const String uiResourceLoadError = '200040';

  /// 无SIM卡
  static const String phoneWithoutSIM = '200048';

  /// 无法识别sim卡或没有sim卡
  static const String unrecognizedSIM = '200010';

  /// 蜂窝未开启或不稳定 (operatortype: 0)
  static const String nonCellularNetworkDetail = '200027';

  /// EOF 异常
  static const String socketError = '200050';

  /// 授权页关闭
  static const String authPageClosed = '200020';

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

  /// 授权页成功调起
  static const String successGetAuthVCCode = '200087';

  /// 当前网络不支持取号
  static const String unsupportedNetwork = '200096';

  /// 错误码到中文含义映射
  static const Map<String, String> errorMessages = {
    '103000': '成功',
    '102101': '无网络',
    '102102': '网络异常',
    '102103': '未开启数据网络',
    '102203': '输入参数错误',
    '102223': '数据解析异常（一般是卡欠费）',
    '102507': '登录超时（授权页点登录按钮时）',
    '103101': '请求签名错误',
    '103102': '包签名错误',
    '103111': '网关 IP 错误',
    '103119': 'appid 不存在',
    '103211': '其他错误（报文格式不对等）',
    '103273': '预取号联通重定向',
    '103412': '无效的请求',
    '103414': '参数校验异常',
    '103511': '服务器 ip 白名单校验失败',
    '103811': 'token 为空',
    '103902': 'scrip 失效（客户端高频调用请求 token 接口）',
    '103911': 'token 请求过于频繁',
    '104201': 'token 已失效或不存在',
    '105001': '联通取号失败',
    '105002': '移动取号失败（一般是物联网卡）',
    '105003': '电信取号失败',
    '105004': '中国移动香港取号失败',
    '105012': '不支持电信取号',
    '105013': '不支持联通取号',
    '105018': 'token 权限不足',
    '105019': '应用未授权',
    '105021': '已达当天取号限额',
    '105302': 'appid 不在白名单',
    '105312': '移动能力余量不足',
    '105313': '非法请求',
    '105315': '不支持的运营商类型',
    '105317': '受限用户',
    '105422': '电信能力余量不足',
    '105423': '联通能力余量不足',
    '105424': '中国移动香港能力余量不足',
    '105024': '中国移动香港能力余量不足',
    '200002': '用户未安装 sim 卡',
    '200005': '用户未授权（READ_PHONE_STATE）',
    '200021': '数据解析异常',
    '200022': '无网络',
    '200023': '请求超时',
    '200024': '数据网络切换失败',
    '200025': '其他错误（socket、系统未授权数据蜂窝权限等）',
    '200026': '输入参数错误',
    '200027': '蜂窝未开启或不稳定',
    '200028': '网络请求出错(HTTP Code 非200)',
    '200038': '非移动网关重定向失败',
    '200039': '异网取号网关取号失败',
    '200040': 'UI 资源加载异常',
    '200048': '无SIM卡',
    '200010': '无法识别sim卡或没有sim卡',
    '200050': 'EOF 异常',
    '200020': '授权页关闭',
    '200060': '用户点击了"账号切换"按钮（自定义短信页面customSMS为YES才会返回）',
    '200061': '显示登录"授权页面"被拦截（hooked）',
    '200062': '连续授权超过限制',
    '200064': '服务端返回数据异常',
    '200072': 'CA 根证书校验失败',
    '200080': '本机号码校验仅支持移动手机号',
    '200082': '服务器繁忙',
    '200086': 'ppLocation 为空',
    '200087': '授权页成功调起',
    '200096': '当前网络不支持取号',
  };
}
