import Flutter
import UIKit
import TYRZUISDK
import ObjectiveC

/// 辅助类：用于保存原生按钮引用，以便在自定义按钮点击时触发原生按钮事件
private class LoginButtonActionTarget: NSObject {
  weak var nativeButton: UIButton?
  weak var customView: UIView?
  var checkBoxFrame: CGRect = .zero
  var eventSink: FlutterEventSink?
  var findCheckboxFunc: ((UIView, CGRect) -> UIView?)?
  weak var plugin: QuickLoginFlutterPlugin?

  @objc func triggerNativeButton(_ sender: UIButton) {
    // 检查复选框是否勾选
    if let customView = customView,
       let checkboxView = findCheckboxFunc?(customView, checkBoxFrame),
       let checkboxButton = checkboxView as? UIButton {
      // 检测复选框是否被选中（通过 isSelected 属性）
      if !checkboxButton.isSelected {
        DispatchQueue.main.async { [weak self] in
          // 原生弹出提示，避免 Flutter 侧被覆盖
          self?.plugin?.showCheckboxNotSelectedToast(in: customView)
          // 继续发送事件，保持 Dart 侧兼容
          self?.eventSink?(["event": "checkboxNotChecked"])
        }
        return
      }
    }
    nativeButton?.sendActions(for: .touchUpInside)
  }
}

/// 扩大勾选框点击区域的透明按钮
private class CheckboxHitAreaButton: UIButton {
  weak var targetCheckbox: UIControl?
  
  @objc func forwardTap() {
    targetCheckbox?.sendActions(for: .touchUpInside)
  }
}

public class QuickLoginFlutterPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private var eventSink: FlutterEventSink?
  private var pendingResult: FlutterResult?
  private var appId: String?
  private var appKey: String?
  private var toastView: UIView?
  private var toastHideWorkItem: DispatchWorkItem?
  private var checkboxTipText: String = "请先阅读并勾选隐私协议"
  private var nativeToastEnabled: Bool = true
  private var nativeToastOffsetY: CGFloat = 0
  private let checkboxHitAreaTag = 98765001

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "quick_login_flutter", binaryMessenger: registrar.messenger())
    let instance = QuickLoginFlutterPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // 注册事件通道，用于发送切换到验证码登录的事件
    let eventChannel = FlutterEventChannel(name: "quick_login_flutter/events", binaryMessenger: registrar.messenger())
    instance.eventChannel = eventChannel
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "init":
      handleInit(call: call, result: result)
    case "prefetchNumber":
      handlePrefetch(call: call, result: result)
    case "login":
      handleLogin(call: call, result: result)
    case "dismiss":
      UAFSDKLogin.share.ua_dismissViewController(animated: true, completion: nil)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInit(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let appId = args["appId"] as? String,
          let appKey = args["appKey"] as? String else {
      result(FlutterError(code: "invalid_args", message: "appId and appKey are required", details: nil))
      return
    }

    self.appId = appId
    self.appKey = appKey

    let debug = args["debug"] as? Bool ?? false
    let timeoutMs = args["timeoutMs"] as? Int

    DispatchQueue.main.async {
      UAFSDKLogin.share.registerAppId(appId, appKey: appKey)
      UAFSDKLogin.share.printConsoleEnable(debug)
      if let timeoutMs = timeoutMs {
        let seconds = TimeInterval(Double(timeoutMs) / 1000.0)
        UAFSDKLogin.share.setTimeoutInterval(seconds)
      }
      result(nil)
    }
  }

  private func handlePrefetch(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "in_progress", message: "Another request is in progress", details: nil))
      return
    }
    guard appId != nil, appKey != nil else {
      result(FlutterError(code: "not_initialized", message: "Call initialize() with appId and appKey first", details: nil))
      return
    }
    pendingResult = result

    let timeoutMs = (call.arguments as? [String: Any])?["timeoutMs"] as? Int
    if let timeoutMs = timeoutMs {
      let seconds = TimeInterval(Double(timeoutMs) / 1000.0)
      UAFSDKLogin.share.setTimeoutInterval(seconds)
    }

    UAFSDKLogin.share.getPhoneNumberCompletion { [weak self] response in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.pendingResult?(response)
        self.pendingResult = nil
      }
    }
  }

  private func handleLogin(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "in_progress", message: "Another request is in progress", details: nil))
      return
    }
    guard appId != nil, appKey != nil else {
      result(FlutterError(code: "not_initialized", message: "Call initialize() with appId and appKey first", details: nil))
      return
    }
    let uiConfig = (call.arguments as? [String: Any])?["uiConfig"] as? [String: Any]
    guard let presentingVC = topViewController() else {
      result(FlutterError(code: "no_view_controller", message: "Unable to find a view controller to present the authorization page", details: nil))
      return
    }

    pendingResult = result
    let timeoutMs = (call.arguments as? [String: Any])?["timeoutMs"] as? Int
    if let timeoutMs = timeoutMs {
      let seconds = TimeInterval(Double(timeoutMs) / 1000.0)
      UAFSDKLogin.share.setTimeoutInterval(seconds)
    }

    DispatchQueue.main.async {
      let model = UAFCustomModel()
      model.currentVC = presentingVC
      self.applyUiConfig(uiConfig, model: model)

      let selector = NSSelectorFromString("getAuthorizationWithModel:complete:")
      if let imp = UAFSDKLogin.share.method(for: selector) {
        typealias AuthFunc = @convention(c) (AnyObject, Selector, UAFCustomModel, @escaping (Any?) -> Void) -> Void
        let function = unsafeBitCast(imp, to: AuthFunc.self)
        function(UAFSDKLogin.share, selector, model) { [weak self] payload in
          guard let self = self else { return }
          DispatchQueue.main.async {
            // 1) 事件通道透传每一次原生回调，便于 Dart 层监听
            if let sink = self.eventSink {
              sink(["event": "loginCallback", "payload": payload ?? [:]])
            }
            // 2) 首次回调用于完成当前 methodChannel 调用
            if let result = self.pendingResult {
              result(payload)
              self.pendingResult = nil
            }
          }
        }
      } else {
        self.pendingResult?(FlutterError(code: "missing_method", message: "getAuthorizationWithModel:complete: not found", details: nil))
        self.pendingResult = nil
      }
    }
  }

  private func topViewController(from providedRoot: UIViewController? = nil) -> UIViewController? {
    let root: UIViewController?
    if let providedRoot = providedRoot {
      root = providedRoot
    } else if #available(iOS 13.0, *) {
      root = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?.rootViewController
    } else {
      root = UIApplication.shared.keyWindow?.rootViewController ?? UIApplication.shared.windows.first?.rootViewController
    }

    if let nav = root as? UINavigationController {
      return topViewController(from: nav.visibleViewController)
    }
    if let tab = root as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    return root
  }

  private func applyUiConfig(_ config: [String: Any]?, model: UAFCustomModel) {
    let config = config ?? [:]
    // 每次配置时刷新勾选提示文案，避免复用旧值
    checkboxTipText = "请先阅读并勾选隐私协议"
    nativeToastEnabled = (config["showNativeToast"] as? Bool) ?? true
    nativeToastOffsetY = CGFloat((config["nativeToastCenterYOffset"] as? Double) ?? 0.0)
    let presentation = (config["presentationStyle"] as? String) ?? "fullScreen"
    let widthPercent = config["windowWidthPercent"] as? Double
    let heightPercent = config["windowHeightPercent"] as? Double
    let windowWidth = config["windowWidth"] as? Double
    let windowHeight = config["windowHeight"] as? Double
    let windowCornerRadius = config["windowCornerRadius"] as? Double
    let windowCornerRadiusTopLeft = config["windowCornerRadiusTopLeft"] as? Double
    let windowCornerRadiusTopRight = config["windowCornerRadiusTopRight"] as? Double
    let checkboxOffsetX = config["checkboxOffsetX"] as? Double
    let checkboxOffsetY = config["checkboxOffsetY"] as? Double
    let defaultCheckedImageName = "check_box_selected"
    let defaultUncheckedImageName = "check_box_unselected"
    let presentAnimated = config["presentAnimated"] as? Bool ?? true
    model.presentAnimated = presentAnimated
    
    // 检查是否需要显示切换登录方式按钮
    let showSwitchButton = config["showSwitchButton"] as? Bool ?? false
    let switchButtonText = config["switchButtonText"] as? String ?? "更换"
    let switchButtonTextColor = config["switchButtonTextColor"] as? Int ?? 0xffffffff
    let switchButtonTextSize = config["switchButtonTextSize"] as? Int ?? 14
    let switchButtonBackgroundColor = config["switchButtonBackgroundColor"] as? Int ?? 0xFF333333 // 默认 0xFF333333
    let switchButtonWidth = config["switchButtonWidth"] as? Double ?? 36.0 // 默认宽度 36
    let switchButtonHeight = config["switchButtonHeight"] as? Double ?? 20.0 // 默认高度 20
    let switchButtonCornerRadius = config["switchButtonCornerRadius"] as? Double ?? 100.0 // 默认圆角 100（完全圆形）
    let switchButtonSpacing = config["switchButtonSpacing"] as? Double ?? 8.0 // 默认间距 8
    
    // 检查是否需要显示关闭按钮
    let showCloseButton = config["showCloseButton"] as? Bool ?? true // 默认显示
    let closeButtonTopSpacing = config["closeButtonTopSpacing"] as? Double ?? 12.0 // 默认顶部间距 12
    let closeButtonRightSpacing = config["closeButtonRightSpacing"] as? Double ?? 12.0 // 默认右边间距 12
    let closeButtonImageName = config["closeButtonImageName"] as? String ?? "close.png" // 默认图片名称
    
    // 创建统一的 authViewBlock，先处理关闭按钮，再处理 SmsLoginButton
    let originalAuthViewBlock = model.authViewBlock
    model.authViewBlock = { [weak self] customView, numberFrame, loginBtnFrame, checkBoxFrame, privacyFrame in
      // 先执行原有的 authViewBlock（如果有）
      originalAuthViewBlock?(customView, numberFrame, loginBtnFrame, checkBoxFrame, privacyFrame)
      
      guard let self = self else { return }
      guard let customView = customView else { return }
      
      // 添加关闭按钮
      if showCloseButton {
        let closeButton = UIButton(type: .custom)
        let closeButtonSize: CGFloat = 26.0 // 默认大小 26*26
        let topSpacing = CGFloat(closeButtonTopSpacing)
        let rightSpacing = CGFloat(closeButtonRightSpacing)
        
        // 设置按钮位置：右上角
        let buttonX = customView.bounds.width - closeButtonSize - rightSpacing
        let buttonY = topSpacing
        
        closeButton.frame = CGRect(x: buttonX, y: buttonY, width: closeButtonSize, height: closeButtonSize)
        
        // 加载关闭按钮图片
        if let closeImage = self.loadImage(named: closeButtonImageName) {
          closeButton.setImage(closeImage, for: .normal)
        } else {
          // 如果图片加载失败，使用系统图标作为后备
          if #available(iOS 13.0, *) {
            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            closeButton.tintColor = UIColor.black
          }
        }
        
        // 添加点击事件：关闭授权页
        closeButton.addTarget(self, action: #selector(self.onCloseButtonTapped), for: .touchUpInside)
        
        // 确保按钮在最上层显示
        customView.addSubview(closeButton)
        customView.bringSubviewToFront(closeButton)
      }
      
      // 添加切换登录方式按钮
      if showSwitchButton {
        // 创建切换登录方式按钮
        let button = UIButton(type: .custom)
        button.setTitle(switchButtonText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: CGFloat(switchButtonTextSize))
        button.setTitleColor(self.colorFromInt(switchButtonTextColor), for: .normal)
        
        // 设置背景色
        button.backgroundColor = self.colorFromInt(switchButtonBackgroundColor)
        
        // 计算按钮尺寸
        let buttonWidth: CGFloat = CGFloat(switchButtonWidth)
        let buttonHeight: CGFloat = CGFloat(switchButtonHeight)
        
        // 设置圆角：如果圆角半径大于按钮高度的一半，则使用按钮高度的一半（形成完全圆形）
        let maxCornerRadius = min(buttonHeight / 2, CGFloat(switchButtonCornerRadius))
        button.layer.cornerRadius = maxCornerRadius
        button.layer.masksToBounds = true
        
        // 计算按钮位置：
        // y轴中心点与号码框的y轴中心点对齐
        let buttonY = numberFrame.midY - buttonHeight / 2
        // 横轴方向左侧与号码框的右侧间距（可配置）
        let buttonX = numberFrame.maxX + CGFloat(switchButtonSpacing)
        
        button.frame = CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight)
        
        // 确保按钮在可见区域内
        if buttonY < 0 {
            button.frame.origin.y = 0 // 如果位置太靠上，放在顶部
        }
        if buttonY + buttonHeight > customView.bounds.height {
            button.frame.origin.y = customView.bounds.height - buttonHeight // 如果超出底部，放在底部
        }
        // 确保按钮不超出右边界
        if buttonX + buttonWidth > customView.bounds.width {
            button.frame.origin.x = customView.bounds.width - buttonWidth - CGFloat(switchButtonSpacing) // 如果超出右边界，放在右边界内侧间距的位置
        }
        
        // 设置内容边距，确保文字不被裁剪
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        
        // 添加点击事件
        button.addTarget(self, action: #selector(self.onSmsLoginButtonTapped), for: .touchUpInside)
        
        // 确保按钮在最上层显示
        customView.addSubview(button)
        customView.bringSubviewToFront(button)
      }

      // 扩大复选框点击区域（四周各 20，保持中心不变）
      if checkBoxFrame != .zero {
        self.ensureCheckboxHitArea(in: customView, checkboxFrame: checkBoxFrame)
      }
    }

    if let statusBarDarkText = config["statusBarDarkText"] as? Bool {
      if #available(iOS 13.0, *) {
        model.statusBarStyle = statusBarDarkText ? .darkContent : .lightContent
      } else {
        model.statusBarStyle = statusBarDarkText ? .default : .lightContent
      }
    }

    switch presentation {
    case "bottomSheet":
      model.presentType = .bottom
      model.modalPresentationStyle = .custom
      let height: CGFloat
      if let windowHeight = windowHeight {
        // 如果设置了具体高度值，优先使用具体值（dp 转 pt，iOS 中 1 pt = 1 dp）
        height = CGFloat(windowHeight)
      } else {
        // 否则使用百分比
        height = UIScreen.main.bounds.height * CGFloat(heightPercent ?? 0.5)
      }
      model.controllerSize = CGSize(width: UIScreen.main.bounds.width, height: height)
      model.authWindow = false
      if let cornerRadius = windowCornerRadius {
        model.cornerRadius = CGFloat(cornerRadius)
      }
    case "centerDialog":
      model.authWindow = true
      model.modalTransitionStyle = .crossDissolve
      model.presentType = .bottom
      // 如果设置了具体宽高值，优先使用具体值；否则使用百分比
      let screenWidth = UIScreen.main.bounds.width
      let screenHeight = UIScreen.main.bounds.height
      if let windowWidth = windowWidth {
        // 如果设置了具体宽度值，优先使用具体值（dp 转 pt）
        model.scaleW = CGFloat(windowWidth) / screenWidth
      } else {
        // 否则使用百分比
        model.scaleW = CGFloat(widthPercent ?? 0.8)
      }
      if let windowHeight = windowHeight {
        // 如果设置了具体高度值，优先使用具体值（dp 转 pt）
        model.scaleH = CGFloat(windowHeight) / screenHeight
      } else {
        // 否则使用百分比
        model.scaleH = CGFloat(heightPercent ?? 0.5)
      }
    default:
      model.authWindow = false
      model.modalPresentationStyle = .fullScreen
      model.presentType = .bottom
    }

    if let loginText = config["loginButtonText"] as? String {
      let colorValue = config["loginButtonTextColor"] as? Int ?? 0xffffffff
      let size = config["loginButtonTextSize"] as? Int ?? 15
      let color = colorFromInt(colorValue)
      let attrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: color,
        .font: UIFont.systemFont(ofSize: CGFloat(size), weight: (config["loginButtonTextBold"] as? Bool ?? false) ? .semibold : .regular)
      ]
      model.logBtnText = NSAttributedString(string: loginText, attributes: attrs)
    }

    // 检查是否需要自定义登录按钮（背景颜色和圆角）
    let loginButtonBackgroundColor = config["loginButtonBackgroundColor"] as? Int
    let loginButtonCornerRadius = config["loginButtonCornerRadius"] as? Double
    
    // 如果设置了背景颜色，则忽略背景图片配置（因为会使用自定义按钮）
    if loginButtonBackgroundColor == nil {
      if let loginImgName = config["loginButtonImageName"] as? String,
         let image = UIImage(named: loginImgName) {
        model.logBtnImgs = [image, image, image]
      }
    }
    
    if let bgColor = loginButtonBackgroundColor {
      // 如果设置了背景颜色，使用自定义按钮覆盖原生按钮
      let originalAuthViewBlock = model.authViewBlock
      model.authViewBlock = { [weak self] customView, numberFrame, loginBtnFrame, checkBoxFrame, privacyFrame in
        // 先执行原有的 authViewBlock（如果有）
        originalAuthViewBlock?(customView, numberFrame, loginBtnFrame, checkBoxFrame, privacyFrame)
        
        guard let self = self else { return }
        guard let customView = customView else { return }
        
        // 查找原生登录按钮
        let nativeLoginButton = self.findLoginButton(in: customView, frame: loginBtnFrame)
        
        if let nativeButton = nativeLoginButton {
          // 隐藏原生按钮
          nativeButton.isHidden = true
          
          // 创建背景视图（用于显示背景颜色和圆角）
          let backgroundView = UIView(frame: loginBtnFrame)
          let bgUIColor = self.colorFromInt(bgColor)
          backgroundView.backgroundColor = bgUIColor
          
          // 设置圆角
          if let cornerRadius = loginButtonCornerRadius {
            backgroundView.layer.cornerRadius = CGFloat(cornerRadius)
          } else {
            // 默认圆角为高度的一半
            backgroundView.layer.cornerRadius = loginBtnFrame.height / 2
          }
          backgroundView.layer.masksToBounds = true
          
          // 创建自定义登录按钮（透明背景，只用于显示文本和处理点击）
          let customLoginButton = UIButton(type: .custom)
          customLoginButton.frame = CGRect(x: 0, y: 0, width: loginBtnFrame.width, height: loginBtnFrame.height)
          customLoginButton.backgroundColor = UIColor.clear
          
          // 复制原生按钮的文本和样式
          if let nativeTitle = nativeButton.title(for: .normal) {
            customLoginButton.setTitle(nativeTitle, for: .normal)
          } else if let nativeAttributedTitle = nativeButton.attributedTitle(for: .normal) {
            customLoginButton.setAttributedTitle(nativeAttributedTitle, for: .normal)
          }
          
          // 复制文本颜色
          if let nativeTitleColor = nativeButton.titleColor(for: .normal) {
            customLoginButton.setTitleColor(nativeTitleColor, for: .normal)
          }
          
          // 复制字体
          if let nativeFont = nativeButton.titleLabel?.font {
            customLoginButton.titleLabel?.font = nativeFont
          }
          
          // 创建辅助对象来保存原生按钮引用
          let actionTarget = LoginButtonActionTarget()
          actionTarget.nativeButton = nativeButton
          actionTarget.customView = customView
          actionTarget.checkBoxFrame = checkBoxFrame
          actionTarget.eventSink = self.eventSink
          actionTarget.findCheckboxFunc = self.findCheckbox
          actionTarget.plugin = self

          // 使用关联对象保存 actionTarget，防止被释放
          objc_setAssociatedObject(customLoginButton, "actionTarget", actionTarget, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
          objc_setAssociatedObject(backgroundView, "actionTarget", actionTarget, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

          // 点击自定义按钮时，触发原生按钮的点击事件
          customLoginButton.addTarget(actionTarget, action: #selector(LoginButtonActionTarget.triggerNativeButton(_:)), for: .touchUpInside)
          
          // 将按钮添加到背景视图
          backgroundView.addSubview(customLoginButton)
          
          // 添加背景视图到自定义视图
          customView.addSubview(backgroundView)
          customView.bringSubviewToFront(backgroundView)
        }
      }
    }

    if presentation == "bottomSheet" {
      let resolvedTopLeft = windowCornerRadiusTopLeft ?? windowCornerRadius
      let resolvedTopRight = windowCornerRadiusTopRight ?? windowCornerRadius
      if let tl = resolvedTopLeft ?? resolvedTopRight, tl > 0 || (resolvedTopRight ?? 0) > 0 {
        let topLeftRadius = CGFloat(resolvedTopLeft ?? 0)
        let topRightRadius = CGFloat(resolvedTopRight ?? 0)
        let previousAuthViewBlock = model.authViewBlock
        model.authViewBlock = { [weak self] customView, numberFrame, loginBtnFrame, checkBoxFrame, privacyFrame in
          previousAuthViewBlock?(customView, numberFrame, loginBtnFrame, checkBoxFrame, privacyFrame)
          guard let self = self, let containerView = customView else { return }
          self.applyTopCornerMask(to: containerView, topLeft: topLeftRadius, topRight: topRightRadius)
          DispatchQueue.main.async { [weak self, weak containerView] in
            guard let self = self, let containerView = containerView else { return }
            self.applyTopCornerMask(to: containerView, topLeft: topLeftRadius, topRight: topRightRadius)
          }
        }
      }
    }

    if let loginOffset = config["loginButtonOffsetY"] as? Double {
      model.logBtnOffsetY = NSNumber(value: loginOffset)
    }

    if let loginOffsetBottom = config["loginButtonOffsetYBottom"] as? Double {
      model.logBtnOffsetY_B = NSNumber(value: loginOffsetBottom)
    }

    if let loginHeight = config["loginButtonHeight"] as? Double {
      model.logBtnHeight = CGFloat(loginHeight)
    }

    let marginLeft = config["loginButtonMarginLeft"] as? Double
    let marginRight = config["loginButtonMarginRight"] as? Double
    if marginLeft != nil || marginRight != nil {
      model.logBtnOriginLR = [NSNumber(value: marginLeft ?? 0), NSNumber(value: marginRight ?? 0)]
    }

    var numberAttributes: [NSAttributedString.Key: Any] = [:]
    if let numberColor = config["numberColor"] as? Int {
      numberAttributes[.foregroundColor] = colorFromInt(numberColor)
    }
    if let numberSize = config["numberSize"] as? Int {
      numberAttributes[.font] = UIFont.systemFont(ofSize: CGFloat(numberSize), weight: (config["numberBold"] as? Bool ?? false) ? .semibold : .regular)
    }
    if !numberAttributes.isEmpty {
      model.numberTextAttributes = numberAttributes
    }
    if let numberOffset = config["numberOffsetY"] as? Double {
      model.numberOffsetY = NSNumber(value: numberOffset)
    }
    if let numberOffsetBottom = config["numberOffsetYBottom"] as? Double {
      model.numberOffsetY_B = NSNumber(value: numberOffsetBottom)
    }
    if let numberOffsetX = config["numberOffsetX"] as? Double {
      model.numberOffsetX = NSNumber(value: numberOffsetX)
    }

    if let privacyOffset = config["privacyOffsetY"] as? Double {
      model.privacyOffsetY = NSNumber(value: privacyOffset)
    }
    if let privacyOffsetBottom = config["privacyOffsetYBottom"] as? Double {
      model.privacyOffsetY_B = NSNumber(value: privacyOffsetBottom)
    }

    let privacyMarginLeft = config["privacyMarginLeft"] as? Double
    let privacyMarginRight = config["privacyMarginRight"] as? Double
    if privacyMarginLeft != nil || privacyMarginRight != nil {
      model.appPrivacyOriginLR = [NSNumber(value: privacyMarginLeft ?? 0), NSNumber(value: privacyMarginRight ?? 0)]
    }

    if let privacyText = config["privacyText"] as? String {
      // SDK 要求模板中必须包含 &&默认&&，并建议自定义协议名以 &&协议名&& 形式出现在模板中
      var template = privacyText
      let clauseNamesForTemplate = (config["privacyClauses"] as? [[String: Any]] ?? [])
        .compactMap { $0["name"] as? String }
      if !template.contains("&&默认&&") {
        template += "&&默认&&"
      }
      let missingClauseNames = clauseNamesForTemplate.filter { !template.contains("&&\($0)&&") }
      if !missingClauseNames.isEmpty {
        // 将未包含的协议名追加到模板中，保持与示例一致的“和/、”分隔
        let placeholders = missingClauseNames.map { "&&\($0)&&" }
        template += "和" + placeholders.joined(separator: "、")
      }
      let baseColor = (config["privacyBaseTextColor"] as? Int).map { colorFromInt($0) } ?? UIColor.gray
      let fontSize = CGFloat(config["privacyTextSize"] as? Int ?? 12)
      let weight: UIFont.Weight = (config["privacyTextBold"] as? Bool ?? false) ? .semibold : .regular
      var attrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: baseColor,
        .font: UIFont.systemFont(ofSize: fontSize, weight: weight)
      ]
      if config["privacyTextCenter"] as? Bool == true {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        attrs[.paragraphStyle] = style
      }
      model.appPrivacyDemo = NSAttributedString(string: template, attributes: attrs)
    }

    if let clauseColorValue = config["privacyClauseTextColor"] as? Int {
      model.privacyColor = colorFromInt(clauseColorValue)
    }

    if let clauses = config["privacyClauses"] as? [[String: Any]] {
      var items: [NSAttributedString] = []
      let clauseFontSize = CGFloat(config["privacyTextSize"] as? Int ?? 12)
      let clauseWeight: UIFont.Weight = (config["privacyTextBold"] as? Bool ?? false) ? .semibold : .regular
      let clauseColor = (config["privacyClauseTextColor"] as? Int).map { colorFromInt($0) }

      for clause in clauses.prefix(4) {
        if let name = clause["name"] as? String,
           let url = clause["url"] as? String {
          var attrs: [NSAttributedString.Key: Any] = [
            .link: url,
            .font: UIFont.systemFont(ofSize: clauseFontSize, weight: clauseWeight)
          ]
          if let clauseColor = clauseColor {
            attrs[.foregroundColor] = clauseColor
          }
          items.append(NSAttributedString(string: name, attributes: attrs))
        }
      }
      if !items.isEmpty {
        model.appPrivacy = items
      }
    }

    if let bookSymbol = config["privacyBookSymbol"] as? Bool {
      model.privacySymbol = bookSymbol
    }

    if let animation = config["privacyAnimation"] as? String {
      model.privacyUncheckAnimation = !animation.isEmpty
    }

    if let tipText = config["checkTipText"] as? String {
      model.checkTipText = tipText
      checkboxTipText = tipText
    } else {
      checkboxTipText = "请先阅读并勾选隐私协议"
    }

    let checkedName = (config["checkboxCheckedImageName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = checkedName, let image = loadImage(named: name) {
      model.checkedImg = image
    } else if let image = loadImage(named: defaultCheckedImageName) {
      model.checkedImg = image
    }

    let uncheckedName = (config["checkboxUncheckedImageName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let name = uncheckedName, let image = loadImage(named: name) {
      model.uncheckedImg = image
    } else if let image = loadImage(named: defaultUncheckedImageName) {
      model.uncheckedImg = image
    }

    if let checkboxSize = (config["checkboxImageWidth"] as? Int) ?? (config["checkboxImageHeight"] as? Int) {
      model.checkboxWH = NSNumber(value: checkboxSize)
    }

    if let displayLogo = config["displayLogo"] as? Bool {
      model.brandImageHidden = !displayLogo
    }
    if let logoWidth = config["logoWidth"] as? Double {
      model.brandImageWidth = NSNumber(value: logoWidth)
    }
    if let logoHeight = config["logoHeight"] as? Double {
      model.brandImageHeight = NSNumber(value: logoHeight)
    }
    if let logoOffsetX = config["logoOffsetX"] as? Double {
      model.brandImageOffsetX = NSNumber(value: logoOffsetX)
    }
    if let logoOffsetY = config["logoOffsetY"] as? Double {
      model.brandImageOffsetY = NSNumber(value: logoOffsetY)
    }

    let privacyRequired = config["privacyRequired"] as? Bool ?? true
    let defaultCheck = config["privacyDefaultCheck"] as? Bool
    model.privacyState = defaultCheck ?? false
    model.ignorePrivacyState = !privacyRequired

    if let bgName = config["backgroundImage"] as? String,
       let bg = UIImage(named: bgName) {
      model.authPageBackgroundImage = bg
    }

    if (checkboxOffsetX != nil || checkboxOffsetY != nil) {
      let previousAuthViewBlock = model.authViewBlock
      model.authViewBlock = { [weak self] customView, numberFrame, loginBtnFrame, checkBoxFrame, privacyFrame in
        previousAuthViewBlock?(customView, numberFrame, loginBtnFrame, checkBoxFrame, privacyFrame)
        guard let self = self, let customView = customView else { return }
        // 以隐私文本左侧为基准，保持勾选框右侧与隐私文本之间的间距
        let baseLeft: CGFloat
        if privacyFrame != .zero {
          baseLeft = privacyFrame.origin.x - checkBoxFrame.width
        } else {
          baseLeft = checkBoxFrame.origin.x
        }
        let baseTop = checkBoxFrame.origin.y
        let offsetX = CGFloat(checkboxOffsetX ?? 0)
        let offsetY = CGFloat(checkboxOffsetY ?? 0)
        let targetFrame = CGRect(
          x: baseLeft + offsetX,
          y: baseTop + offsetY,
          width: checkBoxFrame.width,
          height: checkBoxFrame.height
        )
        if let checkboxView = self.findCheckbox(in: customView, frame: checkBoxFrame) {
          checkboxView.frame = targetFrame
        }
        self.ensureCheckboxHitArea(in: customView, checkboxFrame: targetFrame)
      }
    }

    if let languageIndex = config["appLanguageType"] as? Int,
       let language = UALanguageType(rawValue: UInt(languageIndex + 1)) {
      model.appLanguageType = language
    }
  }

  @objc private func onSmsLoginButtonTapped() {
    // 发送事件到 Flutter 层
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(["event": "switchToSmsLogin"])
    }
  }
  
  @objc private func onCloseButtonTapped() {
    // 关闭授权页
    DispatchQueue.main.async {
      UAFSDKLogin.share.ua_dismissViewController(animated: true, completion: nil)
    }
  }
  
  /// 在视图层次结构中查找位于指定 frame 的登录按钮
  private func findLoginButton(in view: UIView, frame: CGRect) -> UIButton? {
    // 遍历所有子视图查找按钮
    for subview in view.subviews {
      // 如果找到 UIButton 且 frame 匹配（允许小范围误差）
      if let button = subview as? UIButton {
        let frameDiff = abs(button.frame.origin.x - frame.origin.x) +
                       abs(button.frame.origin.y - frame.origin.y) +
                       abs(button.frame.width - frame.width) +
                       abs(button.frame.height - frame.height)
        // 如果 frame 差异小于 5 像素，认为是同一个按钮
        if frameDiff < 5.0 {
          return button
        }
      }
      // 递归查找子视图
      if let foundButton = findLoginButton(in: subview, frame: frame) {
        return foundButton
      }
    }
    return nil
  }

  /// 在视图层次结构中查找位于指定 frame 的勾选框视图（通常是 UIButton）
  private func findCheckbox(in view: UIView, frame: CGRect) -> UIView? {
    for subview in view.subviews {
      let frameDiff = abs(subview.frame.origin.x - frame.origin.x) +
                     abs(subview.frame.origin.y - frame.origin.y) +
                     abs(subview.frame.width - frame.width) +
                    abs(subview.frame.height - frame.height)
      if frameDiff < 5.0 {
        return subview
      }
      if let found = findCheckbox(in: subview, frame: frame) {
        return found
      }
    }
    return nil
  }
  
  private func ensureCheckboxHitArea(in customView: UIView, checkboxFrame: CGRect) {
    guard checkboxFrame != .zero else { return }
    guard let checkboxView = findCheckbox(in: customView, frame: checkboxFrame) else { return }

    let targetSize = CGSize(width: checkboxFrame.width + 40, height: checkboxFrame.height + 40)
    let center = CGPoint(x: checkboxFrame.midX, y: checkboxFrame.midY)
    let targetFrame = CGRect(
      x: center.x - targetSize.width / 2,
      y: center.y - targetSize.height / 2,
      width: targetSize.width,
      height: targetSize.height
    )

    if let overlay = customView.viewWithTag(checkboxHitAreaTag) as? CheckboxHitAreaButton {
      overlay.frame = targetFrame
      overlay.targetCheckbox = checkboxView as? UIControl
    } else {
      let overlay = CheckboxHitAreaButton(type: .custom)
      overlay.tag = checkboxHitAreaTag
      overlay.backgroundColor = .clear
      overlay.frame = targetFrame
      overlay.targetCheckbox = checkboxView as? UIControl
      overlay.addTarget(overlay, action: #selector(CheckboxHitAreaButton.forwardTap), for: .touchUpInside)
      customView.addSubview(overlay)
      customView.bringSubviewToFront(overlay)
    }
  }
  
  private func applyTopCornerMask(to view: UIView, topLeft: CGFloat, topRight: CGFloat) {
    let tl = max(0, topLeft)
    let tr = max(0, topRight)
    if tl == 0 && tr == 0 {
      view.layer.mask = nil
      view.clipsToBounds = false
      return
    }
    view.layoutIfNeeded()
    let path = topCornersPath(for: view.bounds, topLeft: tl, topRight: tr)
    let maskLayer = CAShapeLayer()
    maskLayer.frame = view.bounds
    maskLayer.path = path.cgPath
    view.layer.mask = maskLayer
    view.clipsToBounds = true
  }

  private func topCornersPath(for rect: CGRect, topLeft: CGFloat, topRight: CGFloat) -> UIBezierPath {
    let maxRadius = min(rect.width, rect.height) / 2
    let tl = min(topLeft, maxRadius)
    let tr = min(topRight, maxRadius)

    let path = UIBezierPath()
    let minX = rect.minX
    let maxX = rect.maxX
    let minY = rect.minY
    let maxY = rect.maxY

    // 起点：左下角
    path.move(to: CGPoint(x: minX, y: maxY))
    // 左边直线到左上圆角起点
    path.addLine(to: CGPoint(x: minX, y: minY + tl))
    // 左上角圆弧
    if tl > 0 {
      path.addQuadCurve(to: CGPoint(x: minX + tl, y: minY), controlPoint: CGPoint(x: minX, y: minY))
    } else {
      path.addLine(to: CGPoint(x: minX, y: minY))
    }
    // 顶部直线到右上圆角起点
    path.addLine(to: CGPoint(x: maxX - tr, y: minY))
    // 右上角圆弧
    if tr > 0 {
      path.addQuadCurve(to: CGPoint(x: maxX, y: minY + tr), controlPoint: CGPoint(x: maxX, y: minY))
    } else {
      path.addLine(to: CGPoint(x: maxX, y: minY))
    }
    // 右边直线到右下角
    path.addLine(to: CGPoint(x: maxX, y: maxY))
    // 回到起点
    path.close()
    return path
  }
  
  private func loadImage(named name: String) -> UIImage? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let pluginBundle = Bundle(for: QuickLoginFlutterPlugin.self)
    let resourceBundle: Bundle? = {
      if let path = Bundle.main.path(forResource: "TYRZResource", ofType: "bundle") {
        return Bundle(path: path)
      }
      return nil
    }()

    if let image = UIImage(named: trimmed) {
      return image
    }
    if let image = UIImage(named: trimmed, in: pluginBundle, compatibleWith: nil) {
      return image
    }
    if let bundle = resourceBundle, let image = UIImage(named: trimmed, in: bundle, compatibleWith: nil) {
      return image
    }
    if !trimmed.lowercased().hasSuffix(".png") {
      let nameWithExtension = "\(trimmed).png"
      if let image = UIImage(named: nameWithExtension) {
        return image
      }
      if let image = UIImage(named: nameWithExtension, in: pluginBundle, compatibleWith: nil) {
        return image
      }
      if let bundle = resourceBundle, let image = UIImage(named: nameWithExtension, in: bundle, compatibleWith: nil) {
        return image
      }
    }
    return nil
  }
  
  private func colorFromInt(_ value: Int) -> UIColor {
    let a = CGFloat((value >> 24) & 0xff) / 255.0
    let r = CGFloat((value >> 16) & 0xff) / 255.0
    let g = CGFloat((value >> 8) & 0xff) / 255.0
    let b = CGFloat(value & 0xff) / 255.0
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }

  fileprivate func showCheckboxNotSelectedToast(in view: UIView?) {
    guard nativeToastEnabled else { return }
    let text = checkboxTipText.trimmingCharacters(in: .whitespacesAndNewlines)
    let message = text.isEmpty ? "请先阅读并勾选隐私协议" : text
    showNativeToast(message: message, in: view)
  }

  private func showNativeToast(message: String, in containerView: UIView?, duration: TimeInterval = 3.0) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.toastHideWorkItem?.cancel()
      self.toastView?.removeFromSuperview()

      // 优先在传入的容器所在的 window 层展示，保持与全屏 window 中心对齐
      let fallbackHost = containerView ?? self.topViewController()?.view
      guard let hostView = fallbackHost else { return }
      let anchorView = hostView.window ?? self.keyWindow() ?? hostView

      let toast = UIView()
      toast.translatesAutoresizingMaskIntoConstraints = false
      toast.isUserInteractionEnabled = false

      let bgImage = self.loadImage(named: "common_toast_background")
      let backgroundView = UIImageView(image: bgImage)
      backgroundView.translatesAutoresizingMaskIntoConstraints = false
      backgroundView.contentMode = .scaleToFill
      backgroundView.clipsToBounds = true
      toast.addSubview(backgroundView)

      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.text = message
      label.textAlignment = .center
      label.textColor = .white
      label.numberOfLines = 2
      label.font = UIFont.systemFont(ofSize: 14, weight: .light)
      toast.addSubview(label)

      anchorView.addSubview(toast)

      let width = anchorView.bounds.width > 0 ? anchorView.bounds.width : UIScreen.main.bounds.width
      let height: CGFloat
      if let size = bgImage?.size, size.width > 0 {
        height = width * (size.height / size.width)
      } else {
        height = 66
      }

      NSLayoutConstraint.activate([
        toast.leadingAnchor.constraint(equalTo: anchorView.leadingAnchor),
        toast.trailingAnchor.constraint(equalTo: anchorView.trailingAnchor),
        toast.centerYAnchor.constraint(equalTo: anchorView.centerYAnchor, constant: nativeToastOffsetY),
        toast.heightAnchor.constraint(equalToConstant: height),

        backgroundView.leadingAnchor.constraint(equalTo: toast.leadingAnchor),
        backgroundView.trailingAnchor.constraint(equalTo: toast.trailingAnchor),
        backgroundView.topAnchor.constraint(equalTo: toast.topAnchor),
        backgroundView.bottomAnchor.constraint(equalTo: toast.bottomAnchor),

        label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 57),
        label.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -57),
        label.centerYAnchor.constraint(equalTo: toast.centerYAnchor)
      ])

      hostView.layoutIfNeeded()

      toast.alpha = 0
      UIView.animate(withDuration: 0.2) {
        toast.alpha = 1
      }

      let workItem = DispatchWorkItem { [weak toast] in
        UIView.animate(withDuration: 0.2, animations: {
          toast?.alpha = 0
        }, completion: { _ in
          toast?.removeFromSuperview()
        })
      }
      self.toastHideWorkItem = workItem
      DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
      self.toastView = toast
    }
  }

  private func keyWindow() -> UIWindow? {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
    } else {
      return UIApplication.shared.keyWindow ?? UIApplication.shared.windows.first
    }
  }
}

// 实现 FlutterStreamHandler 协议，用于事件通道
extension QuickLoginFlutterPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
