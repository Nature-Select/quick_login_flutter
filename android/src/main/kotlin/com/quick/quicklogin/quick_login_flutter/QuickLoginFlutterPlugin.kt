package com.quick.quicklogin.quick_login_flutter

import android.app.Activity
import android.app.Application
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.content.res.ColorStateList
import android.graphics.drawable.StateListDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.widget.Button
import android.widget.CheckBox
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.RelativeLayout
import android.widget.TextView
import android.webkit.WebView
import android.webkit.WebSettings
import android.webkit.WebViewClient
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.quick.quicklogin.quick_login_flutter.R
import com.cmic.gen.sdk.auth.GenAuthnHelper
import com.cmic.gen.sdk.auth.GenTokenListener
import com.cmic.gen.sdk.view.GenAuthThemeConfig
import com.cmic.gen.sdk.view.GenLoginAuthActivity
import org.json.JSONObject
import java.util.ArrayDeque

/**
 * QuickLoginFlutterPlugin
 * 
 * 一键登录 Flutter 插件 Android 端实现
 * 
 * 功能说明:
 * - 初始化 SDK (registerAppId)
 * - 预取号 (getPhoneNumber)
 * - 显示授权页并登录 (getAuthorizationWithModel)
 * - 关闭授权页 (quitAuthActivity)
 * - 自定义授权页 UI 配置 (setAuthThemeConfig)
 */
class QuickLoginFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var context: Context? = null
    private var pendingResult: Result? = null
    private var appId: String? = null
    private var appKey: String? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var dialogCornerRadii: FloatArray? = null
    private var authBackgroundColor: Int? = null
    private var customLoginButtonConfig: CustomLoginButtonConfig? = null
    private var customCheckboxConfig: CustomCheckboxConfig? = null
    private var customSmsLoginButtonConfig: CustomSmsLoginButtonConfig? = null
    private var customCloseButtonConfig: CustomCloseButtonConfig? = null
    private var lifecycleRegistered = false
    private val debugTag = "QLCustomBtn"

    private val authActivityLifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityCreated(activity: Activity, savedInstanceState: android.os.Bundle?) {
            maybeApplyAuthBackground(activity)
            maybeConfigureWebView(activity)
        }

        override fun onActivityStarted(activity: Activity) {}

        override fun onActivityResumed(activity: Activity) {
            maybeApplyAuthBackground(activity)
            maybeConfigureWebView(activity)
        }

        override fun onActivityPaused(activity: Activity) {}
        override fun onActivityStopped(activity: Activity) {}
        override fun onActivitySaveInstanceState(activity: Activity, outState: android.os.Bundle) {}
        override fun onActivityDestroyed(activity: Activity) {}
    }

    private fun applyCustomCheckbox(container: ViewGroup, attempts: Int) {
        val config = customCheckboxConfig ?: return
        val nativeCb = findNativeCheckbox(container) ?: run {
            logDebug("cb_not_found", emptyMap())
            if (attempts > 0) {
                mainHandler.postDelayed({ applyCustomCheckbox(container, attempts - 1) }, 50)
            }
            return
        }
        if (nativeCb.width == 0 && nativeCb.height == 0 && attempts > 0) {
            logDebug("cb_size_zero", mapOf("w" to nativeCb.width, "h" to nativeCb.height))
            mainHandler.postDelayed({ applyCustomCheckbox(container, attempts - 1) }, 50)
            return
        }

        val dx = config.offsetX ?: 0f
        val dy = config.offsetY ?: 0f
        nativeCb.translationX = dx
        nativeCb.translationY = dy
        logDebug(
            "cb_applied",
            mapOf(
                "offsetX" to dx,
                "offsetY" to dy,
                "w" to nativeCb.width,
                "h" to nativeCb.height,
                "class" to nativeCb.javaClass.simpleName
            )
        )
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "quick_login_flutter")
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "quick_login_flutter/events")
        eventChannel.setStreamHandler(this)

        registerLifecycleCallbacks()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)

        unregisterLifecycleCallbacks()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "init" -> handleInit(call, result)
            "prefetchNumber" -> handlePrefetch(call, result)
            "login" -> handleLogin(call, result)
            "dismiss" -> handleDismiss(result)
            else -> result.notImplemented()
        }
    }

    /**
     * 初始化 SDK
     * 
     * 参数:
     * - appId: String - 运营商分配的应用 ID
     * - appKey: String - 运营商分配的密钥
     * - debug: Boolean - 是否开启调试模式
     * - timeoutMs: Int? - 超时时间(毫秒)
     */
    private fun handleInit(call: MethodCall, result: Result) {
        val appId = call.argument<String>("appId")
        val appKey = call.argument<String>("appKey")
        val debug = call.argument<Boolean>("debug") ?: false
        val timeoutMs = call.argument<Int>("timeoutMs")

        if (appId.isNullOrEmpty() || appKey.isNullOrEmpty()) {
            result.error("invalid_args", "appId and appKey are required", null)
            return
        }

        this.appId = appId
        this.appKey = appKey

        mainHandler.post {
            try {
                // SDK 初始化在首次调用 getInstance 时自动完成
                // 无需显式调用初始化方法
                result.success(null)
            } catch (e: Exception) {
                result.error("init_failed", e.message, null)
            }
        }
    }

    /**
     * 预取号
     * 
     * 参数:
     * - timeoutMs: Int? - 超时时间(毫秒)
     * 
     * 返回:
     * Map<String, Any> - 包含 resultCode、msg 等字段的结果
     */
    private fun handlePrefetch(call: MethodCall, result: Result) {
        if (pendingResult != null) {
            result.error("in_progress", "Another request is in progress", null)
            return
        }

        if (appId.isNullOrEmpty() || appKey.isNullOrEmpty()) {
            result.error("not_initialized", "Call initialize() with appId and appKey first", null)
            return
        }

        val ctx = context
        if (ctx == null) {
            result.error("no_context", "Context is null", null)
            return
        }

        pendingResult = result
        val timeoutMs = (call.argument<Number>("timeoutMs")?.toInt()) ?: 10000

        mainHandler.post {
            try {
                val helper = GenAuthnHelper.getInstance(ctx, appId)
                helper.getPhoneInfo(appId!!, appKey!!, object : GenTokenListener {
                    override fun onGetTokenComplete(code: Int, jsonObject: JSONObject?) {
                        mainHandler.post {
                            val response = jsonObjectToMap(jsonObject)
                            pendingResult?.success(response)
                            pendingResult = null
                        }
                    }
                }, timeoutMs)
            } catch (e: Exception) {
                pendingResult?.error("prefetch_failed", e.message, null)
                pendingResult = null
            }
        }
    }

    /**
     * 显示授权页并登录
     * 
     * 参数:
     * - timeoutMs: Int? - 超时时间(毫秒)
     * - uiConfig: Map<String, Any?>? - UI 配置参数
     * 
     * 返回:
     * Map<String, Any> - 包含 resultCode、msg、token 等字段的授权结果
     */
    private fun handleLogin(call: MethodCall, result: Result) {
        if (pendingResult != null) {
            result.error("in_progress", "Another request is in progress", null)
            return
        }

        if (appId.isNullOrEmpty() || appKey.isNullOrEmpty()) {
            result.error("not_initialized", "Call initialize() with appId and appKey first", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("no_activity", "Unable to find an activity to present the authorization page", null)
            return
        }

        val ctx = context
        if (ctx == null) {
            result.error("no_context", "Context is null", null)
            return
        }

        pendingResult = result
        val timeoutMs = (call.argument<Number>("timeoutMs")?.toInt()) ?: 10000
        val uiConfig = call.argument<Map<String, Any?>>("uiConfig")

        mainHandler.post {
            try {
                val helper = GenAuthnHelper.getInstance(ctx, appId)
                
                // 创建并设置主题配置
                val themeConfig = createThemeConfig(uiConfig, currentActivity)
                helper.setAuthThemeConfig(themeConfig)
                
                // 调用 SDK 显示授权页并登录
                helper.loginAuth(appId!!, appKey!!, object : GenTokenListener {
                    override fun onGetTokenComplete(code: Int, jsonObject: JSONObject?) {
                        mainHandler.post {
                            val response = jsonObjectToMap(jsonObject)
                            // 发送事件到 Flutter
                            eventSink?.success(mapOf("event" to "loginCallback", "payload" to response))
                            // 完成方法调用
                            pendingResult?.success(response)
                            pendingResult = null
                        }
                    }
                }, timeoutMs)
            } catch (e: Exception) {
                pendingResult?.error("login_failed", e.message, null)
                pendingResult = null
            }
        }
    }

    /**
     * 关闭授权页
     */
    private fun handleDismiss(result: Result) {
        mainHandler.post {
            try {
                val ctx = context
                if (ctx != null && appId != null) {
                    val helper = GenAuthnHelper.getInstance(ctx, appId)
                    helper.quitAuthActivity()
                }
                result.success(null)
            } catch (e: Exception) {
                result.error("dismiss_failed", e.message, null)
            }
        }
    }

    /**
     * 创建主题配置对象
     * 
     * 根据 Dart 层传入的 uiConfig 参数,创建 Android SDK 的 GenAuthThemeConfig 对象
     * 
     * 支持的配置项:
     * - 状态栏配置 (statusBarColor, statusBarDarkText)
     * - 导航栏配置 (navHidden, navColor, navTextColor, navTextSize, etc.)
     * - 服务条款对话框配置 (clauseLayoutResId, clauseStatusBarColor, clauseDialogTheme, etc.)
     * - 授权页布局配置 (authLayoutResId, fitsSystemWindows)
     * - 号码栏配置 (numberColor, numberSize, numberBold, numberOffsetY, etc.)
     * - 品牌 Logo 配置 (displayLogo, logoWidth, logoHeight, logoOffsetY, etc.)
     * - 登录按钮配置 (loginButtonText, loginButtonTextColor, loginButtonImageName, loginButtonHeight, etc.)
     * - 隐私条款配置 (privacyText, privacyClauses, privacyTextSize, checkboxCheckedImageName, etc.)
     * - 底部文字配置 (provideTextSize, provideTextColor, provideTextOffsetY, etc.)
     * - 转场动画配置 (authPageInAnimation, authPageOutAnimation, etc.)
     * - 弹窗模式配置 (windowWidthPercent, windowHeight, windowOffsetX, windowBottom, etc.)
     * - 语言配置 (appLanguageType)
     * - 自定义按钮配置 (showSwitchButton, showCloseButton, etc.)
     */
    private fun createThemeConfig(config: Map<String, Any?>?, activity: Activity): GenAuthThemeConfig {
        val builder = GenAuthThemeConfig.Builder()
        
        if (config == null) {
            dialogCornerRadii = null
            authBackgroundColor = null
            customLoginButtonConfig = null
            customCheckboxConfig = null
            customSmsLoginButtonConfig = null
            customCloseButtonConfig = null
            return builder.build()
        }

        val ctx = context ?: return builder.build()

        // ============ 1. 安卓底部导航栏自适应 ============
        config["fitsSystemWindows"]?.let {
            builder.setFitsSystemWindows(it as Boolean)
        }

        // ============ 2. 状态栏 ============
        val statusBarColor = safeToInt(config["statusBarColor"])
        val statusBarDarkText = config["statusBarDarkText"] as? Boolean
        if (statusBarColor != null || statusBarDarkText != null) {
            val color = statusBarColor ?: Color.WHITE
            val isDark = statusBarDarkText ?: false
            builder.setStatusBar(color, isDark)
        }

        // ============ 3. 导航栏 (服务条款页) ============
        // 对应 SDK API: setNavHidden(boolean)
        config["navHidden"]?.let {
            builder.setNavHidden(it as Boolean)
        }

        // ============ 4. 服务条款对话框 ============
        // 对应 SDK API: setNavTextColor(int), setNavColor(int), setNavTextSize(int)
        config["navColor"]?.let {
            safeToInt(it)?.let { color -> builder.setNavColor(color) }
        }
        config["navTextColor"]?.let {
            safeToInt(it)?.let { color -> builder.setNavTextColor(color) }
        }
        config["navTextSize"]?.let {
            safeToInt(it)?.let { size -> builder.setNavTextSize(size) }
        }
        
        // 对应 SDK API: setNavTextGetWebViewTittle(boolean)
        config["navTextFromWebTitle"]?.let {
            builder.setNavTextGetWebViewTittle(it as Boolean)
        }
        
        // 对应 SDK API: setClauseLayoutResID(int, String)
        val clauseLayoutResId = safeToInt(config["clauseLayoutResId"])
        val clauseLayoutReturnId = config["clauseLayoutReturnId"] as? String
        
        // 如果未设置自定义布局，自动查找默认的title_layout.xml（使用关闭图标）
        val finalLayoutResId = clauseLayoutResId ?: getLayoutResourceId(ctx, "title_layout")
        val finalReturnId = clauseLayoutReturnId ?: "returnId"
        
        if (finalLayoutResId != null && finalLayoutResId != 0 && finalReturnId.isNotEmpty()) {
            builder.setClauseLayoutResID(finalLayoutResId, finalReturnId)
        }
        
        // 对应 SDK API: setClauseStatusColor(int)
        config["clauseStatusBarColor"]?.let {
            safeToInt(it)?.let { color -> builder.setClauseStatusColor(color) }
        }
        
        // 对应 SDK API: setClauseTheme(int)
        config["clauseDialogTheme"]?.let {
            safeToInt(it)?.let { theme -> builder.setClauseTheme(theme) }
        }

        // ============ 5. 授权页布局 ============
        // 对应 SDK API: setAuthLayoutResID(int), setAuthContentView(View)
        config["authLayoutResId"]?.let {
            safeToInt(it)?.let { resId -> builder.setAuthLayoutResID(resId) }
        }
        val hasCustomAuthLayout = config["authLayoutResId"] != null

        // 背景图 - SDK 可能不支持此方法，需要检查
        // config["backgroundImage"]?.let { imageName ->
        //     builder.setAuthPageBackgroundImage(imageName as String)
        // }

        // ============ 6. 授权页号码栏 ============
        // 对应 SDK API: setNumberColor(int)
        config["numberColor"]?.let {
            safeToInt(it)?.let { color -> builder.setNumberColor(color) }
        }
        
        // 对应 SDK API: setNumberSize(int, boolean)
        val numberSize = safeToInt(config["numberSize"])
        val numberBold = config["numberBold"] as? Boolean
        if (numberSize != null || numberBold != null) {
            val size = numberSize ?: 18
            val bold = numberBold ?: false
            builder.setNumberSize(size, bold)
        }
        
        // 对应 SDK API: setNumFieldOffsetY(float)
        config["numberOffsetY"]?.let {
            builder.setNumFieldOffsetY((it as Number).toInt())
        }
        
        // 对应 SDK API: setNumFieldOffsetY_B(float)
        config["numberOffsetYBottom"]?.let {
            builder.setNumFieldOffsetY_B((it as Number).toInt())
        }
        
        // 对应 SDK API: setNumberOffsetX(float)
        config["numberOffsetX"]?.let {
            builder.setNumberOffsetX((it as Number).toInt())
        }

        // ============ 7. 品牌 Logo ============
        // 对应 SDK API: displayLogo(boolean)
        config["displayLogo"]?.let {
            builder.displayLogo(it as Boolean)
        }
        
        // 对应 SDK API: setLogo(int, int)
        // 注意：此方法接受的是 dp 值，不需要转换为 px
        val logoWidth = config["logoWidth"] as? Number
        val logoHeight = config["logoHeight"] as? Number
        if (logoWidth != null && logoHeight != null) {
            builder.setLogo(logoWidth.toInt(), logoHeight.toInt())
        }
        
        // 对应 SDK API: setLogoOffsetX(float)
        config["logoOffsetX"]?.let {
            builder.setLogoOffsetX((it as Number).toInt())
        }
        
        // 对应 SDK API: setLogoOffsetY(float)
        config["logoOffsetY"]?.let {
            builder.setLogoOffsetY((it as Number).toInt())
        }
        
        // 对应 SDK API: setLogoOffsetY_B(float)
        config["logoOffsetYBottom"]?.let {
            builder.setLogoOffsetY_B((it as Number).toInt())
        }

        // ============ 8. 授权页登录按钮 ============
        // 对应 SDK API: setLogBtnText(String, int, int, boolean)
        val loginButtonText = config["loginButtonText"] as? String
        val loginButtonTextColor = safeToInt(config["loginButtonTextColor"])
        val loginButtonTextSize = safeToInt(config["loginButtonTextSize"])
        val loginButtonTextBold = config["loginButtonTextBold"] as? Boolean
        val customLoginButtonBg = safeToInt(config["loginButtonBackgroundColor"])
        val customLoginButtonCornerRadius = (config["loginButtonCornerRadius"] as? Number)?.toFloat()
        
        if (loginButtonText != null || loginButtonTextColor != null || 
            loginButtonTextSize != null || loginButtonTextBold != null) {
            val text = loginButtonText ?: "登录"
            val color = loginButtonTextColor ?: Color.WHITE
            val size = loginButtonTextSize ?: 15
            val bold = loginButtonTextBold ?: false
            builder.setLogBtnText(text, color, size, bold)
        }

        // 对应 SDK API: setLogBtnImgPath(String)
        // loginButtonBackgroundColor 暂时不处理，后续单独实现
        // val loginButtonBackgroundColor = safeToInt(config["loginButtonBackgroundColor"])
        // val loginButtonCornerRadius = config["loginButtonCornerRadius"] as? Number
        
        // 使用背景图片
        config["loginButtonImageName"]?.let { imageName ->
            builder.setLogBtnImgPath(imageName as String)
        }

        // 对应 SDK API: setLogBtn(int, int)
        // 注意：此方法接受的是 dp 值，不需要转换为 px
        val loginButtonWidth = config["loginButtonWidth"] as? Number
        val loginButtonHeight = config["loginButtonHeight"] as? Number
        if (loginButtonWidth != null && loginButtonHeight != null) {
            builder.setLogBtn(loginButtonWidth.toInt(), loginButtonHeight.toInt())
        }

        // 对应 SDK API: setLogBtnMargin(int, int)
        val loginButtonMarginLeft = config["loginButtonMarginLeft"] as? Number
        val loginButtonMarginRight = config["loginButtonMarginRight"] as? Number
        if (loginButtonMarginLeft != null || loginButtonMarginRight != null) {
            val left = loginButtonMarginLeft?.toFloat() ?: 0f
            val right = loginButtonMarginRight?.toFloat() ?: 0f
            builder.setLogBtnMargin(left.toInt(), right.toInt())
        }

        // 对应 SDK API: setLogBtnOffsetY(float)
        config["loginButtonOffsetY"]?.let {
            builder.setLogBtnOffsetY((it as Number).toInt())
        }
        
        // 对应 SDK API: setLogBtnOffsetY_B(float)
        config["loginButtonOffsetYBottom"]?.let {
            builder.setLogBtnOffsetY_B((it as Number).toInt())
        }
        customLoginButtonConfig = if (customLoginButtonBg != null || customLoginButtonCornerRadius != null) {
            CustomLoginButtonConfig(
                text = loginButtonText,
                textColor = loginButtonTextColor,
                textSize = loginButtonTextSize,
                textBold = loginButtonTextBold,
                backgroundColor = customLoginButtonBg,
                cornerRadiusPx = customLoginButtonCornerRadius?.let { toPx(it, ctx) },
                width = loginButtonWidth?.toInt(),
                height = loginButtonHeight?.toInt()
            )
        } else {
            null
        }

        // ============ 9. 授权页隐私栏 ============
        // 对应 SDK API: setPrivacyAlignment(String x9), setPrivacyText(int, int, int, boolean, boolean)
        val privacyText = config["privacyText"] as? String
        val privacyClauses = config["privacyClauses"] as? List<Map<String, String>>
        val privacyTextSize = safeToInt(config["privacyTextSize"])
        val privacyBaseTextColor = safeToInt(config["privacyBaseTextColor"])
        val privacyClauseTextColor = safeToInt(config["privacyClauseTextColor"])
        val privacyTextCenter = config["privacyTextCenter"] as? Boolean
        val privacyTextBold = config["privacyTextBold"] as? Boolean
        
        if (privacyText != null || privacyClauses != null) {
            var text = privacyText ?: "登录即同意"
            if (!text.contains(GenAuthThemeConfig.PLACEHOLDER)) {
                text += GenAuthThemeConfig.PLACEHOLDER
            }
            val clauses = privacyClauses?.take(4) ?: emptyList()
            
            // 构建 9 个参数：text, name1, url1, name2, url2, name3, url3, name4, url4
            val name1 = clauses.getOrNull(0)?.get("name") ?: ""
            val url1 = clauses.getOrNull(0)?.get("url") ?: ""
            val name2 = clauses.getOrNull(1)?.get("name") ?: ""
            val url2 = clauses.getOrNull(1)?.get("url") ?: ""
            val name3 = clauses.getOrNull(2)?.get("name") ?: ""
            val url3 = clauses.getOrNull(2)?.get("url") ?: ""
            val name4 = clauses.getOrNull(3)?.get("name") ?: ""
            val url4 = clauses.getOrNull(3)?.get("url") ?: ""
            
            builder.setPrivacyAlignment(text, name1, url1, name2, url2, name3, url3, name4, url4)
            
            val size = privacyTextSize ?: 12
            val baseColor = privacyBaseTextColor ?: Color.GRAY
            val clauseColor = privacyClauseTextColor ?: Color.BLUE
            val center = privacyTextCenter ?: false
            val bold = privacyTextBold ?: false
            
            builder.setPrivacyText(size, baseColor, clauseColor, center, bold)
        }

        // 对应 SDK API: setCheckBoxImgPath(String, String, int, int)
        // 注意：宽高参数接受的是 dp 值，不需要转换
        val checkedImageName = config["checkboxCheckedImageName"] as? String
        val uncheckedImageName = config["checkboxUncheckedImageName"] as? String
        val checkboxWidth = safeToInt(config["checkboxImageWidth"])
        val checkboxHeight = safeToInt(config["checkboxImageHeight"])
        val checkboxOffsetX = config["checkboxOffsetX"] as? Number
        val checkboxOffsetY = config["checkboxOffsetY"] as? Number
        val width = checkboxWidth ?: 12
        val height = checkboxHeight ?: 12
        if (checkedImageName != null && uncheckedImageName != null) {
            builder.setCheckBoxImgPath(checkedImageName, uncheckedImageName, width, height)
        } else {
            // 默认使用内置资源（与 iOS 对齐）
            builder.setCheckBoxImgPath("check_box_selected", "check_box_unselected", width, height)
        }
        customCheckboxConfig = if (checkboxOffsetX != null || checkboxOffsetY != null) {
            CustomCheckboxConfig(
                offsetX = checkboxOffsetX?.toFloat(),
                offsetY = checkboxOffsetY?.toFloat()
            )
        } else {
            null
        }

        // 对应 SDK API: setCheckBoxAccurateClick(boolean)
        config["checkboxAccurateClick"]?.let {
            builder.setCheckBoxAccurateClick(it as Boolean)
        }

        // 对应 SDK API: setPrivacyOffsetY(float)
        config["privacyOffsetY"]?.let {
            builder.setPrivacyOffsetY((it as Number).toInt())
        }
        
        // 对应 SDK API: setPrivacyOffsetY_B(float)
        config["privacyOffsetYBottom"]?.let {
            builder.setPrivacyOffsetY_B((it as Number).toInt())
        }

        // 对应 SDK API: setPrivacyMargin(int, int)
        val privacyMarginLeft = config["privacyMarginLeft"] as? Number
        val privacyMarginRight = config["privacyMarginRight"] as? Number
        if (privacyMarginLeft != null || privacyMarginRight != null) {
            val left = privacyMarginLeft?.toFloat() ?: 0f
            val right = privacyMarginRight?.toFloat() ?: 0f
            builder.setPrivacyMargin(left.toInt(), right.toInt())
        }

        // 对应 SDK API: setPrivacyState(boolean)
        config["privacyDefaultCheck"]?.let {
            builder.setPrivacyState(it as Boolean)
        }

        // 对应 SDK API: setPrivacyBookSymbol(boolean)
        config["privacyBookSymbol"]?.let {
            builder.setPrivacyBookSymbol(it as Boolean)
        }

        // 对应 SDK API: setCheckBoxLocation(int) - 0-居上，1-居中
        config["checkboxLocation"]?.let {
            val location = if ((it as String) == "center") 1 else 0
            builder.setCheckBoxLocation(location)
        }

        // 对应 SDK API: setPrivacyPageFullScreen(boolean)
        config["privacyPageFullScreen"]?.let {
            builder.setPrivacyPageFullScreen(it as Boolean)
        }

        // 对应 SDK API: setWebDomStorage(boolean)
        config["webDomStorage"]?.let {
            builder.setWebDomStorage(it as Boolean)
        }

        // 对应 SDK API: setPrivacyAnimation(String)
        config["privacyAnimation"]?.let {
            builder.setPrivacyAnimation(it as String)
        }

        // 对应 SDK API: setCheckTipText(String)
        config["checkTipText"]?.let {
            builder.setCheckTipText(it as String)
        }

        // ============ 10. 授权页底部文字 ============
        // 对应 SDK API: setProvideTextSize(int, boolean)
        val provideTextSize = safeToInt(config["provideTextSize"])
        val provideTextBold = config["provideTextBold"] as? Boolean
        if (provideTextSize != null || provideTextBold != null) {
            val size = provideTextSize ?: 12
            val bold = provideTextBold ?: false
            builder.setProvideTextSize(size, bold)
        }

        // 对应 SDK API: setProvideTextColor(int)
        config["provideTextColor"]?.let {
            safeToInt(it)?.let { color -> builder.setProvideTextColor(color) }
        }
        
        // 对应 SDK API: setProvideTextOffsetX(float)
        config["provideTextOffsetX"]?.let {
            builder.setProvideTextOffsetX((it as Number).toInt())
        }
        
        // 对应 SDK API: setProvideTextOffsetY(float)
        config["provideTextOffsetY"]?.let {
            builder.setProvideTextOffsetY((it as Number).toInt())
        }
        
        // 对应 SDK API: setProvideTextOffsetY_B(float)
        config["provideTextOffsetYBottom"]?.let {
            builder.setProvideTextOffsetY_B((it as Number).toInt())
        }

        // ============ 11. 授权页转场动画 ============
        // 对应 SDK API: setAuthPageActIn(String, String), setAuthPageActOut(String, String)
        val authPageInAnimation = config["authPageInAnimation"] as? String
        val activityOutAnimation = config["activityOutAnimation"] as? String
        val authPageOutAnimation = config["authPageOutAnimation"] as? String
        val activityInAnimation = config["activityInAnimation"] as? String
        
        if (authPageInAnimation != null && activityOutAnimation != null) {
            builder.setAuthPageActIn(authPageInAnimation, activityOutAnimation)
        }
        
        if (authPageOutAnimation != null && activityInAnimation != null) {
            builder.setAuthPageActOut(authPageOutAnimation, activityInAnimation)
        }

        // ============ 12. 弹窗模式 ============
        val presentationStyle = (config["presentationStyle"] as? String) ?: "fullScreen"
        val windowWidthPercent = (config["windowWidthPercent"] as? Number)?.toFloat()
        val windowHeightPercent = (config["windowHeightPercent"] as? Number)?.toFloat()
        val windowWidth = config["windowWidth"] as? Number
        val windowHeight = config["windowHeight"] as? Number
        val windowOffsetX = config["windowOffsetX"] as? Number
        val windowOffsetY = config["windowOffsetY"] as? Number
        val windowBottom = config["windowBottom"] as? Boolean
        val themeId = config["themeId"] as? Int
        val windowCornerRadius = (config["windowCornerRadius"] as? Number)?.toFloat()
        val windowCornerRadiusTopLeft = (config["windowCornerRadiusTopLeft"] as? Number)?.toFloat()
        val windowCornerRadiusTopRight = (config["windowCornerRadiusTopRight"] as? Number)?.toFloat()
        val windowCornerRadiusBottomLeft = (config["windowCornerRadiusBottomLeft"] as? Number)?.toFloat()
        val windowCornerRadiusBottomRight = (config["windowCornerRadiusBottomRight"] as? Number)?.toFloat()

        val numberOffsetY = config["numberOffsetY"] as? Number
        val numberOffsetYBottom = config["numberOffsetYBottom"] as? Number
        val loginButtonOffsetY = config["loginButtonOffsetY"] as? Number
        val loginButtonOffsetYBottom = config["loginButtonOffsetYBottom"] as? Number
        val privacyOffsetY = config["privacyOffsetY"] as? Number
        val privacyOffsetYBottom = config["privacyOffsetYBottom"] as? Number
        val provideTextOffsetYBottom = config["provideTextOffsetYBottom"] as? Number

        val hasNumberOffset = numberOffsetY != null || numberOffsetYBottom != null
        val hasLoginBtnOffset = loginButtonOffsetY != null || loginButtonOffsetYBottom != null
        val hasPrivacyOffset = privacyOffsetY != null || privacyOffsetYBottom != null
        val hasProvideOffsetBottom = provideTextOffsetYBottom != null

        val screenWidth = ctx.resources.displayMetrics.widthPixels
        val screenHeight = ctx.resources.displayMetrics.heightPixels
        val shouldApplyCornerRadius = !hasCustomAuthLayout && presentationStyle != "fullScreen"

        when (presentationStyle) {
            "bottomSheet" -> {
                val width = when {
                    windowWidth != null -> windowWidth.toInt()
                    windowWidthPercent != null -> (screenWidth * windowWidthPercent).toInt()
                    else -> RelativeLayout.LayoutParams.MATCH_PARENT
                }
                val height = when {
                    windowHeight != null -> windowHeight.toInt()
                    windowHeightPercent != null -> (screenHeight * windowHeightPercent).toInt()
                    else -> 300
                }
                builder.setAuthPageWindowMode(width, height)

                if (windowOffsetX != null || windowOffsetY != null) {
                    val offsetX = (windowOffsetX ?: 0).toInt()
                    val offsetY = (windowOffsetY ?: 0).toInt()
                    builder.setAuthPageWindowOffset(offsetX, offsetY)
                }

                val bottom = windowBottom ?: true
                builder.setWindowBottom(if (bottom) 1 else 0)
                builder.setThemeId(themeId ?: R.style.loginDialog)

                if (!hasNumberOffset) {
                    builder.setNumFieldOffsetY(40)
                }
                if (!hasLoginBtnOffset) {
                    builder.setLogBtnOffsetY(100)
                }
                if (!hasPrivacyOffset) {
                    builder.setPrivacyOffsetY(160)
                }
                if (!hasProvideOffsetBottom) {
                    builder.setProvideTextOffsetY_B(15)
                }
            }
            "centerDialog" -> {
                val width = when {
                    windowWidth != null -> windowWidth.toInt()
                    windowWidthPercent != null -> (screenWidth * windowWidthPercent).toInt()
                    else -> 320
                }
                val height = when {
                    windowHeight != null -> windowHeight.toInt()
                    windowHeightPercent != null -> (screenHeight * windowHeightPercent).toInt()
                    else -> (width * 3) / 4
                }
                builder.setAuthPageWindowMode(width, height)

                if (windowOffsetX != null || windowOffsetY != null) {
                    val offsetX = (windowOffsetX ?: 0).toInt()
                    val offsetY = (windowOffsetY ?: 0).toInt()
                    builder.setAuthPageWindowOffset(offsetX, offsetY)
                }

                val bottom = windowBottom ?: false
                builder.setWindowBottom(if (bottom) 1 else 0)
                builder.setThemeId(themeId ?: R.style.loginDialog)

                if (!hasNumberOffset) {
                    builder.setNumFieldOffsetY(40)
                }
                if (!hasLoginBtnOffset) {
                    builder.setLogBtnOffsetY(100)
                }
                if (!hasPrivacyOffset) {
                    builder.setPrivacyOffsetY(160)
                }
                if (!hasProvideOffsetBottom) {
                    builder.setProvideTextOffsetY_B(15)
                }
            }
            else -> {
                builder.setAuthPageWindowMode(0, 0)
                builder.setThemeId(themeId ?: -1)

                if (!hasNumberOffset) {
                    builder.setNumFieldOffsetY(180)
                }
                if (!hasLoginBtnOffset) {
                    builder.setLogBtnOffsetY(250)
                }
                if (!hasPrivacyOffset) {
                    builder.setPrivacyOffsetY_B(150)
                }
                if (!hasProvideOffsetBottom) {
                    builder.setProvideTextOffsetY_B(30)
                }
            }
        }

        dialogCornerRadii = if (shouldApplyCornerRadius) {
            val defaultRadius = windowCornerRadius ?: 0f
            val tl = windowCornerRadiusTopLeft ?: defaultRadius
            val tr = windowCornerRadiusTopRight ?: defaultRadius
            val bl = windowCornerRadiusBottomLeft ?: defaultRadius
            val br = windowCornerRadiusBottomRight ?: defaultRadius
            floatArrayOf(
                tl, tl,
                tr, tr,
                br, br,
                bl, bl
            )
        } else {
            null
        }
        authBackgroundColor = safeToInt(config["backgroundColor"]) ?: Color.WHITE

        // 对应 SDK API: setBackButton(boolean)
        config["backButtonEnabled"]?.let {
            builder.setBackButton(it as Boolean)
        }

        // ============ 13. 授权页语言切换 ============
        // 对应 SDK API: setAppLanguageType(int) - 0.中文简体 1.中文繁体 2.英文
        config["appLanguageType"]?.let {
            safeToInt(it)?.let { type -> builder.setAppLanguageType(type) }
        }

        // ============ 14. 自定义视图 (切换登录方式按钮、关闭按钮) ============
        val showSwitchButton = config["showSwitchButton"] as? Boolean ?: false
        val showCloseButton = config["showCloseButton"] as? Boolean ?: true

        // 解析切换按钮配置
        customSmsLoginButtonConfig = if (showSwitchButton) {
            CustomSmsLoginButtonConfig(
                text = config["switchButtonText"] as? String ?: "更换",
                textColor = safeToInt(config["switchButtonTextColor"]) ?: 0xFFFFFFFF.toInt(),
                textSize = safeToInt(config["switchButtonTextSize"]) ?: 14,
                backgroundColor = safeToInt(config["switchButtonBackgroundColor"]) ?: 0xFF333333.toInt(),
                width = (config["switchButtonWidth"] as? Number)?.toFloat() ?: 36f,
                height = (config["switchButtonHeight"] as? Number)?.toFloat() ?: 20f,
                cornerRadius = (config["switchButtonCornerRadius"] as? Number)?.toFloat() ?: 100f,
                spacing = (config["switchButtonSpacing"] as? Number)?.toFloat() ?: 8f
            )
        } else {
            null
        }

        // 解析关闭按钮配置
        customCloseButtonConfig = if (showCloseButton) {
            CustomCloseButtonConfig(
                topSpacing = (config["closeButtonTopSpacing"] as? Number)?.toFloat() ?: 12f,
                rightSpacing = (config["closeButtonRightSpacing"] as? Number)?.toFloat() ?: 12f,
                imageName = config["closeButtonImageName"] as? String ?: "close"
            )
        } else {
            null
        }

        return builder.build()
    }

    /**
     * 获取 drawable 资源 ID
     */
    private fun getDrawableResourceId(context: Context, name: String): Int {
        var resName = name.trim()
        // 移除可能的扩展名
        if (resName.endsWith(".png") || resName.endsWith(".jpg") || resName.endsWith(".jpeg")) {
            resName = resName.substring(0, resName.lastIndexOf('.'))
        }
        return context.resources.getIdentifier(resName, "drawable", context.packageName)
    }

    /**
     * 获取动画资源 ID
     */
    private fun getAnimResourceId(context: Context, name: String): Int {
        return context.resources.getIdentifier(name, "anim", context.packageName)
    }

    /**
     * 获取布局资源 ID
     * Flutter插件的资源会被合并到宿主应用的资源中，所以使用应用包名查找即可
     */
    private fun getLayoutResourceId(context: Context, name: String): Int? {
        val resName = name.trim()
        val resId = context.resources.getIdentifier(resName, "layout", context.packageName)
        return if (resId != 0) resId else null
    }

    /**
     * 将 JSONObject 转换为 Map
     */
    private fun jsonObjectToMap(jsonObject: JSONObject?): Map<String, Any?> {
        if (jsonObject == null) {
            return emptyMap()
        }
        
        val map = mutableMapOf<String, Any?>()
        val keys = jsonObject.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = jsonObject.opt(key)
            map[key] = value
        }
        return map
    }

    /**
     * 安全地将 Any 转换为 Int（处理 Long、Double 等类型）
     */
    private fun safeToInt(value: Any?): Int? {
        return when (value) {
            is Int -> value
            is Long -> value.toInt()
            is Double -> value.toInt()
            is Float -> value.toInt()
            is Number -> value.toInt()
            else -> null
        }
    }

    /**
     * EventChannel.StreamHandler 实现
     */
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun registerLifecycleCallbacks() {
        if (lifecycleRegistered) return
        val app = context?.applicationContext as? Application ?: return
        app.registerActivityLifecycleCallbacks(authActivityLifecycleCallbacks)
        lifecycleRegistered = true
    }

    private fun unregisterLifecycleCallbacks() {
        if (!lifecycleRegistered) return
        val app = context?.applicationContext as? Application ?: return
        app.unregisterActivityLifecycleCallbacks(authActivityLifecycleCallbacks)
        lifecycleRegistered = false
    }

    private fun maybeApplyAuthBackground(activity: Activity) {
        if (activity !is GenLoginAuthActivity) return

        val radii = dialogCornerRadii
        val color = authBackgroundColor
        if (radii == null && color == null) return

        val root = activity.findViewById<ViewGroup?>(android.R.id.content) ?: return
        val target: View = if (root.childCount > 0) root.getChildAt(0) else root

        val background = GradientDrawable().apply {
            setColor(color ?: Color.WHITE)
            if (radii != null) {
                cornerRadii = radii
            }
        }
        target.background = background
        if (radii != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            target.clipToOutline = true
            target.outlineProvider = ViewOutlineProvider.BACKGROUND
        }

        maybeApplyCustomLoginButton(target as? ViewGroup ?: root)
        maybeApplyCustomCheckbox(target as? ViewGroup ?: root)
        maybeApplyCustomSmsLoginButton(target as? ViewGroup ?: root)
        maybeApplyCustomCloseButton(target as? ViewGroup ?: root)
    }

    /**
     * 配置WebView以确保H5页面的返回按钮可以正常工作
     * 查找授权页Activity中的WebView并确保JavaScript已启用
     */
    private fun maybeConfigureWebView(activity: Activity) {
        if (activity !is GenLoginAuthActivity) return
        
        // 延迟执行，确保WebView已经创建，多次尝试以确保找到WebView
        var attempts = 5
        val findWebView = object : Runnable {
            override fun run() {
                val root = activity.findViewById<ViewGroup?>(android.R.id.content) ?: activity.window.decorView as? ViewGroup
                if (root != null) {
                    val webViews = findAllWebViews(root)
                    if (webViews.isNotEmpty()) {
                        webViews.forEach { webView ->
                            configureWebView(webView)
                        }
                        logDebug("webview_found_and_configured", mapOf("count" to webViews.size))
                    } else if (attempts > 0) {
                        attempts--
                        mainHandler.postDelayed(this, 300)
                    }
                } else if (attempts > 0) {
                    attempts--
                    mainHandler.postDelayed(this, 300)
                }
            }
        }
        mainHandler.postDelayed(findWebView, 200)
    }

    /**
     * 递归查找所有WebView
     */
    private fun findAllWebViews(root: View): List<WebView> {
        val webViews = mutableListOf<WebView>()
        val queue = ArrayDeque<View>()
        queue.add(root)
        
        while (queue.isNotEmpty()) {
            val view = queue.removeFirst()
            if (view is WebView) {
                webViews.add(view)
            } else if (view is ViewGroup) {
                for (i in 0 until view.childCount) {
                    queue.add(view.getChildAt(i))
                }
            }
        }
        
        return webViews
    }

    /**
     * 配置WebView设置，确保JavaScript已启用，并添加JavaScript接口以支持返回按钮
     */
    private fun configureWebView(webView: WebView) {
        try {
            val settings = webView.settings
            // 确保JavaScript已启用
            if (!settings.javaScriptEnabled) {
                settings.javaScriptEnabled = true
                logDebug("webview_js_enabled", emptyMap())
            }
            
            // 设置其他必要的WebView设置
            settings.domStorageEnabled = true
            settings.databaseEnabled = true
            settings.setSupportZoom(false)
            settings.builtInZoomControls = false
            settings.displayZoomControls = false
            
            // 添加JavaScript接口，让H5页面可以调用原生方法关闭页面
            // SDK可能使用特定的接口名称，我们添加一个通用的接口
            try {
                // 尝试添加通用的JavaScript接口
                val jsInterface = object {
                    @android.webkit.JavascriptInterface
                    fun close() {
                        mainHandler.post {
                            val ctx = context
                            if (ctx != null && appId != null) {
                                try {
                                    val helper = GenAuthnHelper.getInstance(ctx, appId)
                                    helper.quitAuthActivity()
                                } catch (e: Exception) {
                                    logDebug("js_interface_close_error", mapOf("error" to e.message))
                                }
                            }
                        }
                    }
                    
                    @android.webkit.JavascriptInterface
                    fun goBack() {
                        mainHandler.post {
                            if (webView.canGoBack()) {
                                webView.goBack()
                            } else {
                                val ctx = context
                                if (ctx != null && appId != null) {
                                    try {
                                        val helper = GenAuthnHelper.getInstance(ctx, appId)
                                        helper.quitAuthActivity()
                                    } catch (e: Exception) {
                                        logDebug("js_interface_goback_error", mapOf("error" to e.message))
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 添加多个可能的接口名称，以兼容不同的SDK版本
                webView.addJavascriptInterface(jsInterface, "Android")
                webView.addJavascriptInterface(jsInterface, "Native")
                webView.addJavascriptInterface(jsInterface, "QuickLogin")
                
                logDebug("webview_js_interface_added", mapOf("interfaces" to "Android, Native, QuickLogin"))
            } catch (e: Exception) {
                logDebug("webview_js_interface_error", mapOf("error" to e.message))
            }
            
            // 设置WebViewClient以确保页面加载完成后注入JavaScript代码
            val originalClient = webView.webViewClient
            webView.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    // 先调用原始的WebViewClient
                    if (originalClient != null && originalClient != this) {
                        try {
                            val method = originalClient.javaClass.getMethod("onPageFinished", WebView::class.java, String::class.java)
                            method.invoke(originalClient, view, url)
                        } catch (e: Exception) {
                            // 忽略反射错误
                        }
                    }
                    
                    // 注入JavaScript代码，确保返回按钮可以工作
                    view?.evaluateJavascript("""
                        (function() {
                            // 查找返回按钮并添加点击事件
                            function setupBackButton() {
                                var selectors = [
                                    '.back-btn', '.nav-back', '.back-button', 
                                    '[class*="back"]', '[id*="back"]',
                                    'a[href="javascript:void(0)"]',
                                    'button[onclick*="back"]'
                                ];
                                
                                for (var i = 0; i < selectors.length; i++) {
                                    var elements = document.querySelectorAll(selectors[i]);
                                    for (var j = 0; j < elements.length; j++) {
                                        var elem = elements[j];
                                        if (elem.textContent && (elem.textContent.indexOf('返回') >= 0 || 
                                            elem.textContent.indexOf('关闭') >= 0 || 
                                            elem.textContent.indexOf('Back') >= 0)) {
                                            elem.addEventListener('click', function(e) {
                                                e.preventDefault();
                                                e.stopPropagation();
                                                // 尝试调用原生方法
                                                if (typeof Android !== 'undefined' && Android.close) {
                                                    Android.close();
                                                } else if (typeof Native !== 'undefined' && Native.close) {
                                                    Native.close();
                                                } else if (typeof QuickLogin !== 'undefined' && QuickLogin.close) {
                                                    QuickLogin.close();
                                                } else if (window.history.length > 1) {
                                                    window.history.back();
                                                } else {
                                                    window.close();
                                                }
                                            }, true);
                                        }
                                    }
                                }
                            }
                            
                            // 页面加载完成后设置
                            if (document.readyState === 'complete') {
                                setupBackButton();
                            } else {
                                window.addEventListener('load', setupBackButton);
                            }
                            
                            // 使用MutationObserver监听DOM变化
                            var observer = new MutationObserver(setupBackButton);
                            observer.observe(document.body, {
                                childList: true,
                                subtree: true
                            });
                        })();
                    """.trimIndent(), null)
                }
                
                override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                    // 允许原始的WebViewClient先处理
                    if (originalClient != null && originalClient != this) {
                        try {
                            val method = originalClient.javaClass.getMethod("shouldOverrideUrlLoading", WebView::class.java, String::class.java)
                            val result = method.invoke(originalClient, view, url) as? Boolean
                            if (result == true) return true
                        } catch (e: Exception) {
                            // 忽略反射错误
                        }
                    }
                    return super.shouldOverrideUrlLoading(view, url)
                }
            }
            
            logDebug("webview_configured", mapOf(
                "jsEnabled" to settings.javaScriptEnabled,
                "domStorageEnabled" to settings.domStorageEnabled,
                "hasWebViewClient" to (webView.webViewClient != null)
            ))
        } catch (e: Exception) {
            logDebug("webview_config_error", mapOf("error" to e.message))
        }
    }

    private fun maybeApplyCustomLoginButton(container: ViewGroup) {
        applyCustomLoginButton(container, 3)
    }

    private fun maybeApplyCustomCheckbox(container: ViewGroup) {
        applyCustomCheckbox(container, 3)
    }

    private fun maybeApplyCustomSmsLoginButton(container: ViewGroup) {
        applyCustomSmsLoginButton(container, 3)
    }

    private fun maybeApplyCustomCloseButton(container: ViewGroup) {
        applyCustomCloseButton(container, 3)
    }

    private fun applyCustomLoginButton(container: ViewGroup, attempts: Int) {
        val config = customLoginButtonConfig ?: return
        val tagKey = "quick_custom_login_button"
        val contentRoot = container.rootView.findViewById<ViewGroup?>(android.R.id.content) ?: container
        if (contentRoot.findViewWithTag<View?>(tagKey) != null) return

        logDebug("start_apply", mapOf("container" to container.javaClass.simpleName))
        val nativeBtn = findNativeLoginButton(container) ?: run {
            logDebug("native_not_found", emptyMap())
            logViewTree(container)
            if (attempts > 0) {
                mainHandler.postDelayed({ applyCustomLoginButton(container, attempts - 1) }, 50)
            }
            return
        }

        if (nativeBtn.width == 0 || nativeBtn.height == 0) {
            logDebug("native_size_zero", mapOf("w" to nativeBtn.width, "h" to nativeBtn.height))
            if (attempts > 0) {
                mainHandler.postDelayed({ applyCustomLoginButton(container, attempts - 1) }, 50)
            }
            return
        }

        logDebug(
            "native_found",
            mapOf(
                "class" to nativeBtn.javaClass.simpleName,
                "w" to nativeBtn.width,
                "h" to nativeBtn.height,
                "parent" to (nativeBtn.parent?.javaClass?.simpleName ?: "null")
            )
        )

        // 将原生按钮外观置空，但保留点击行为
        nativeBtn.alpha = 0f
        nativeBtn.background = null
        (nativeBtn as? Button)?.text = ""

        // 创建自定义按钮，尺寸/位置沿用原生按钮
        val newButton = Button(container.context).apply {
            this.tag = tagKey
            text = config.text ?: "登录"
            setTextColor(config.textColor ?: Color.WHITE)
            textSize = (config.textSize ?: 15).toFloat()
            typeface = if (config.textBold == true) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
            setOnClickListener {
                // 检查复选框是否勾选
                val checkbox = findNativeCheckbox(contentRoot)
                val isChecked = (checkbox as? CheckBox)?.isChecked ?: true
                if (isChecked) {
                    nativeBtn.performClick()
                } else {
                    // 发送复选框未勾选事件到 Flutter
                    mainHandler.post {
                        eventSink?.success(mapOf("event" to "checkboxNotChecked"))
                    }
                }
            }
        }

        // 以屏幕坐标定位到与原生按钮中心一致的位置
        val nativePos = IntArray(2)
        nativeBtn.getLocationOnScreen(nativePos)
        val rootPos = IntArray(2)
        contentRoot.getLocationOnScreen(rootPos)

        val targetW = resolveSize(config.width, nativeBtn.width, container.context)
        val targetH = resolveSize(config.height, nativeBtn.height, container.context)
        val left = nativePos[0] - rootPos[0] + (nativeBtn.width - targetW) / 2
        val top = nativePos[1] - rootPos[1] + (nativeBtn.height - targetH) / 2

        val newLp = FrameLayout.LayoutParams(targetW, targetH)
        newLp.leftMargin = left
        newLp.topMargin = top
        newButton.layoutParams = newLp

        val radius = config.cornerRadiusPx ?: (targetH / 2f)
        newButton.background = createStateDrawable(config.backgroundColor ?: Color.TRANSPARENT, radius)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            newButton.foreground = createRippleDrawable(radius)
        }
        newButton.elevation = 100f

        contentRoot.addView(newButton)
        newButton.bringToFront()
        newButton.requestLayout()
        logDebug(
            "custom_btn_added",
            mapOf(
                "native_w" to nativeBtn.width,
                "native_h" to nativeBtn.height,
                "cfg_w" to config.width,
                "cfg_h" to config.height,
                "cfg_radius" to config.cornerRadiusPx,
                "cfg_bg" to config.backgroundColor,
                "final_w" to targetW,
                "final_h" to targetH,
                "text" to (config.text ?: "")
            )
        )
    }

    private fun findNativeLoginButton(root: ViewGroup): View? {
        val queue = ArrayDeque<View>()
        queue.add(root)
        val buttonCandidates = mutableListOf<Button>()
        val clickableCandidates = mutableListOf<View>()
        while (queue.isNotEmpty()) {
            val v = queue.removeFirst()
            if (v is ViewGroup) {
                for (i in 0 until v.childCount) {
                    queue.add(v.getChildAt(i))
                }
            }
            if (v is CheckBox) continue
            if (v.isClickable && v.isFocusable) {
                if (v is Button) buttonCandidates.add(v) else clickableCandidates.add(v)
            }
        }
        val winnerButton = buttonCandidates.maxByOrNull { (it.width.takeIf { w -> w > 0 } ?: 0) * (it.height.takeIf { h -> h > 0 } ?: 0) }
        val winnerOther = clickableCandidates.maxByOrNull { (it.width.takeIf { w -> w > 0 } ?: 0) * (it.height.takeIf { h -> h > 0 } ?: 0) }
        val winner = winnerButton ?: winnerOther
        logDebug(
            "native_candidates",
            mapOf(
                "btn_count" to buttonCandidates.size,
                "other_count" to clickableCandidates.size,
                "winner_class" to (winner?.javaClass?.simpleName ?: "none"),
                "winner_w" to (winner?.width ?: -1),
                "winner_h" to (winner?.height ?: -1)
            )
        )
        return winner
    }

    private fun findNativeCheckbox(root: ViewGroup): View? {
        val queue = ArrayDeque<View>()
        queue.add(root)
        val candidates = mutableListOf<View>()
        while (queue.isNotEmpty()) {
            val v = queue.removeFirst()
            if (v is ViewGroup) {
                for (i in 0 until v.childCount) {
                    queue.add(v.getChildAt(i))
                }
            }
            if (v is CheckBox) {
                candidates.add(v)
            }
        }
        val winner = candidates.maxByOrNull { (it.width.takeIf { w -> w > 0 } ?: 0) * (it.height.takeIf { h -> h > 0 } ?: 0) }
        logDebug(
            "cb_candidates",
            mapOf(
                "count" to candidates.size,
                "winner_w" to (winner?.width ?: -1),
                "winner_h" to (winner?.height ?: -1)
            )
        )
        return winner
    }

    /**
     * 查找号码展示 TextView
     * 号码通常是一个包含手机号（如 138****1234）格式文本的 TextView
     */
    private fun findNumberTextView(root: ViewGroup): TextView? {
        val queue = ArrayDeque<View>()
        queue.add(root)
        val candidates = mutableListOf<TextView>()
        val phonePattern = Regex("\\d{3}\\*{4}\\d{4}")

        while (queue.isNotEmpty()) {
            val v = queue.removeFirst()
            if (v is ViewGroup) {
                for (i in 0 until v.childCount) {
                    queue.add(v.getChildAt(i))
                }
            }
            if (v is TextView && v !is Button && v !is CheckBox) {
                val text = v.text?.toString() ?: ""
                if (phonePattern.containsMatchIn(text)) {
                    candidates.add(v)
                }
            }
        }
        val winner = candidates.maxByOrNull { it.textSize }
        logDebug(
            "number_tv_candidates",
            mapOf(
                "count" to candidates.size,
                "winner_text" to (winner?.text?.toString() ?: "none"),
                "winner_w" to (winner?.width ?: -1),
                "winner_h" to (winner?.height ?: -1)
            )
        )
        return winner
    }

    /**
     * 添加更换按钮（与号码 Y 轴中心对齐）
     */
    private fun applyCustomSmsLoginButton(container: ViewGroup, attempts: Int) {
        val config = customSmsLoginButtonConfig ?: return
        val tagKey = "quick_custom_sms_login_button"
        val contentRoot = container.rootView.findViewById<ViewGroup?>(android.R.id.content) ?: container
        if (contentRoot.findViewWithTag<View?>(tagKey) != null) return

        logDebug("start_apply_sms_btn", mapOf("container" to container.javaClass.simpleName))
        val numberTv = findNumberTextView(container) ?: run {
            logDebug("number_tv_not_found", emptyMap())
            if (attempts > 0) {
                mainHandler.postDelayed({ applyCustomSmsLoginButton(container, attempts - 1) }, 50)
            }
            return
        }

        if (numberTv.width == 0 || numberTv.height == 0) {
            logDebug("number_tv_size_zero", mapOf("w" to numberTv.width, "h" to numberTv.height))
            if (attempts > 0) {
                mainHandler.postDelayed({ applyCustomSmsLoginButton(container, attempts - 1) }, 50)
            }
            return
        }

        val ctx = container.context
        val density = ctx.resources.displayMetrics.density

        // 创建更换按钮
        val smsButton = Button(ctx).apply {
            this.tag = tagKey
            text = config.text ?: "更换"
            setTextColor(config.textColor ?: Color.WHITE)
            textSize = (config.textSize ?: 14).toFloat()
            isAllCaps = false
            setPadding(0, 0, 0, 0)

            setOnClickListener {
                // 发送切换到验证码登录事件到 Flutter
                mainHandler.post {
                    eventSink?.success(mapOf("event" to "switchToSmsLogin"))
                }
            }
        }

        // 计算按钮尺寸（dp 转 px）
        val buttonWidth = ((config.width ?: 36f) * density).toInt()
        val buttonHeight = ((config.height ?: 20f) * density).toInt()
        val spacing = ((config.spacing ?: 8f) * density).toInt()
        val cornerRadius = (config.cornerRadius ?: 100f) * density
        val actualRadius = minOf(cornerRadius, buttonHeight / 2f)

        // 设置按钮背景
        smsButton.background = createStateDrawable(config.backgroundColor ?: 0xFF333333.toInt(), actualRadius)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            smsButton.foreground = createRippleDrawable(actualRadius)
        }

        // 获取号码 TextView 的屏幕位置
        val numberPos = IntArray(2)
        numberTv.getLocationOnScreen(numberPos)
        val rootPos = IntArray(2)
        contentRoot.getLocationOnScreen(rootPos)

        // 计算按钮位置：
        // X: 号码右侧 + 间距
        // Y: 与号码 Y 轴中心对齐
        val buttonLeft = numberPos[0] - rootPos[0] + numberTv.width + spacing
        val numberCenterY = numberPos[1] - rootPos[1] + numberTv.height / 2
        val buttonTop = numberCenterY - buttonHeight / 2

        val lp = FrameLayout.LayoutParams(buttonWidth, buttonHeight)
        lp.leftMargin = buttonLeft
        lp.topMargin = buttonTop
        smsButton.layoutParams = lp

        contentRoot.addView(smsButton)
        smsButton.bringToFront()
        smsButton.requestLayout()

        logDebug(
            "sms_btn_added",
            mapOf(
                "number_x" to numberPos[0],
                "number_y" to numberPos[1],
                "number_w" to numberTv.width,
                "number_h" to numberTv.height,
                "btn_left" to buttonLeft,
                "btn_top" to buttonTop,
                "btn_w" to buttonWidth,
                "btn_h" to buttonHeight
            )
        )
    }

    /**
     * 添加关闭按钮（右上角）
     */
    private fun applyCustomCloseButton(container: ViewGroup, attempts: Int) {
        val config = customCloseButtonConfig ?: return
        val tagKey = "quick_custom_close_button"
        val contentRoot = container.rootView.findViewById<ViewGroup?>(android.R.id.content) ?: container
        if (contentRoot.findViewWithTag<View?>(tagKey) != null) return

        logDebug("start_apply_close_btn", mapOf("container" to container.javaClass.simpleName, "contentRoot_w" to contentRoot.width, "contentRoot_h" to contentRoot.height))

        // 如果容器宽度还是 0，延迟重试
        if (contentRoot.width == 0) {
            logDebug("close_btn_container_zero", mapOf("attempts" to attempts))
            if (attempts > 0) {
                mainHandler.postDelayed({ applyCustomCloseButton(container, attempts - 1) }, 100)
            }
            return
        }

        val ctx = container.context
        val density = ctx.resources.displayMetrics.density

        // 创建关闭按钮
        val closeButton = ImageView(ctx).apply {
            this.tag = tagKey
            scaleType = ImageView.ScaleType.CENTER_INSIDE

            // 加载关闭按钮图片
            val imageName = config.imageName ?: "close"
            // 先尝试从 drawable 加载
            val resId = getDrawableResourceId(ctx, imageName)
            logDebug("close_btn_resId", mapOf("imageName" to imageName, "resId" to resId))
            if (resId != 0) {
                setImageResource(resId)
            } else {
                // 尝试从 assets 加载
                try {
                    val assetFileName = if (imageName.endsWith(".png")) imageName else "$imageName.png"
                    val inputStream = ctx.assets.open(assetFileName)
                    val bitmap = android.graphics.BitmapFactory.decodeStream(inputStream)
                    inputStream.close()
                    setImageBitmap(bitmap)
                    logDebug("close_btn_loaded_from_assets", mapOf("fileName" to assetFileName))
                } catch (e: Exception) {
                    // 使用默认的 X 图标
                    setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
                    logDebug("close_btn_use_default", mapOf("error" to e.message))
                }
            }

            setOnClickListener {
                // 关闭授权页
                mainHandler.post {
                    val appCtx = context
                    if (appCtx != null && appId != null) {
                        try {
                            val helper = GenAuthnHelper.getInstance(appCtx, appId)
                            helper.quitAuthActivity()
                        } catch (e: Exception) {
                            logDebug("close_btn_error", mapOf("error" to e.message))
                        }
                    }
                }
            }
        }

        // 计算按钮尺寸和位置
        val buttonSize = (26 * density).toInt()
        val topSpacing = ((config.topSpacing ?: 12f) * density).toInt()
        val rightSpacing = ((config.rightSpacing ?: 12f) * density).toInt()

        // 使用 Gravity 定位到右上角
        val lp = FrameLayout.LayoutParams(buttonSize, buttonSize).apply {
            gravity = Gravity.TOP or Gravity.END
            topMargin = topSpacing
            rightMargin = rightSpacing
        }
        closeButton.layoutParams = lp

        contentRoot.addView(closeButton)
        closeButton.bringToFront()
        closeButton.requestLayout()

        logDebug(
            "close_btn_added",
            mapOf(
                "topSpacing" to topSpacing,
                "rightSpacing" to rightSpacing,
                "btn_size" to buttonSize,
                "contentRoot_w" to contentRoot.width
            )
        )
    }

    private fun resolveSize(configValue: Int?, fallbackPx: Int, context: Context): Int {
        val density = context.resources.displayMetrics.density
        return configValue?.let { (it * density).toInt() } ?: fallbackPx
    }

    private fun createStateDrawable(color: Int, radius: Float): android.graphics.drawable.Drawable {
        val normal = GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius
        }
        val pressedColor = Color.parseColor("#FFBEBEBE")
        val pressed = GradientDrawable().apply {
            setColor(pressedColor)
            cornerRadius = radius
        }
        return StateListDrawable().apply {
            addState(intArrayOf(android.R.attr.state_pressed), pressed)
            addState(intArrayOf(android.R.attr.state_focused), pressed)
            addState(intArrayOf(), normal)
        }
    }

    private fun createRippleDrawable(radius: Float): RippleDrawable {
        val mask = GradientDrawable().apply {
            setColor(Color.WHITE)
            cornerRadius = radius
        }
        val rippleColor = ColorStateList.valueOf(adjustAlpha(Color.parseColor("#FFBEBEBE"), 0.4f))
        return RippleDrawable(rippleColor, null, mask)
    }

    private fun darkerColor(color: Int): Int {
        val factor = 0.7f
        val a = Color.alpha(color)
        val r = (Color.red(color) * factor).toInt().coerceAtLeast(0)
        val g = (Color.green(color) * factor).toInt().coerceAtLeast(0)
        val b = (Color.blue(color) * factor).toInt().coerceAtLeast(0)
        return Color.argb(a, r, g, b)
    }

    private fun adjustAlpha(color: Int, factor: Float): Int {
        val a = (Color.alpha(color) * factor).toInt().coerceIn(0, 255)
        val r = Color.red(color)
        val g = Color.green(color)
        val b = Color.blue(color)
        return Color.argb(a, r, g, b)
    }

    private fun toPx(dp: Float, context: Context): Float {
        return dp * context.resources.displayMetrics.density
    }

    private fun logDebug(event: String, data: Map<String, Any?>) {
        val payload = data.entries.joinToString(", ") { "${it.key}=${it.value}" }
        Log.d(debugTag, "$event | $payload")
    }

    private fun logViewTree(root: View) {
        val queue = ArrayDeque<Pair<View, Int>>()
        queue.add(root to 0)
        while (queue.isNotEmpty()) {
            val (view, depth) = queue.removeFirst()
            val pos = IntArray(2)
            view.getLocationOnScreen(pos)
            val idInfo = getIdString(view)
            val info = mapOf(
                "depth" to depth,
                "class" to view.javaClass.simpleName,
                "id" to idInfo,
                "x" to pos[0],
                "y" to pos[1],
                "w" to view.width,
                "h" to view.height,
                "clickable" to view.isClickable,
                "focusable" to view.isFocusable,
                "visible" to (view.visibility == View.VISIBLE)
            )
            logDebug("view", info)
            if (view is ViewGroup) {
                for (i in 0 until view.childCount) {
                    queue.add(view.getChildAt(i) to (depth + 1))
                }
            }
        }
    }

    private fun getIdString(view: View): String {
        val id = view.id
        if (id == View.NO_ID) return "no_id"
        return try {
            view.resources.getResourceEntryName(id)
        } catch (_: Exception) {
            id.toString()
        }
    }

    private data class CustomLoginButtonConfig(
        val text: String?,
        val textColor: Int?,
        val textSize: Int?,
        val textBold: Boolean?,
        val backgroundColor: Int?,
        val cornerRadiusPx: Float?,
        val width: Int?,
        val height: Int?
    )

    private data class CustomCheckboxConfig(
        val offsetX: Float?,
        val offsetY: Float?
    )

    private data class CustomSmsLoginButtonConfig(
        val text: String?,
        val textColor: Int?,
        val textSize: Int?,
        val backgroundColor: Int?,
        val width: Float?,
        val height: Float?,
        val cornerRadius: Float?,
        val spacing: Float?
    )

    private data class CustomCloseButtonConfig(
        val topSpacing: Float?,
        val rightSpacing: Float?,
        val imageName: String?
    )
}
