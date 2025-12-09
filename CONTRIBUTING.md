# 贡献指南

感谢你考虑为 quick_login_flutter 做出贡献！

## 开始之前

在提交代码之前，请确保：

1. 阅读了 [README.md](README.md) 了解项目功能
2. 阅读了 [SECURITY.md](SECURITY.md) 了解安全配置
3. 配置好了开发环境

## 开发环境配置

### 1. Fork 并克隆仓库

```bash
git clone https://github.com/your-username/quick_login_flutter.git
cd quick_login_flutter
```

### 2. 配置凭证（用于测试）

```bash
cd example
cp .env.example .env
# 编辑 .env 填入你的测试凭证
```

### 3. 安装依赖

```bash
flutter pub get
cd example
flutter pub get
```

## 提交代码

### Commit 规范

请使用语义化的 commit message：

- `feat:` 新功能
- `fix:` 修复 bug
- `docs:` 文档更新
- `style:` 代码格式（不影响代码运行）
- `refactor:` 重构
- `test:` 测试相关
- `chore:` 构建过程或辅助工具的变动

示例：

```
feat: 添加自定义登录按钮背景色支持
fix: 修复 iOS 平台授权页圆角显示问题
docs: 更新 README 添加配置说明
```

### Pull Request 流程

1. 从 `main` 分支创建你的功能分支

```bash
git checkout -b feat/your-feature-name
```

2. 进行开发并提交

```bash
git add .
git commit -m "feat: 你的功能描述"
```

3. 推送到你的 fork

```bash
git push origin feat/your-feature-name
```

4. 在 GitHub 上创建 Pull Request

### PR 检查清单

在提交 PR 前，请确认：

- [ ] 代码遵循项目的代码风格
- [ ] 已添加必要的注释和文档
- [ ] 测试通过（如果有）
- [ ] 更新了 README（如有必要）
- [ ] **没有提交任何敏感信息**（appId、appKey、密钥等）

## 🔒 安全规范

### 必须遵守的安全规则

**绝对禁止提交以下内容：**

1. ❌ 真实的 appId 和 appKey
2. ❌ 签名密钥文件（.keystore, .jks）
3. ❌ 包含密码的配置文件（key.properties）
4. ❌ 环境变量文件（.env）
5. ❌ 本地配置文件（local.properties）
6. ❌ 任何个人隐私信息

### Pre-commit Hook

项目已配置 pre-commit hook，会自动检测并阻止敏感文件被提交。

如果你看到类似提示：

```
❌ 阻止提交敏感文件: example/android/key.properties
```

这说明你尝试提交了不应该提交的文件，请检查并移除。

### 代码示例规范

在代码或文档中使用示例凭证时，请使用占位符：

✅ 正确：

```dart
await quickLogin.initialize(
  appId: 'your_app_id',
  appKey: 'your_app_key',
);
```

❌ 错误：

```dart
await quickLogin.initialize(
  appId: '300012345678',  // 真实的 appId
  appKey: 'abc123xyz',     // 真实的 appKey
);
```

## 代码规范

### Dart 代码

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 指南
- 使用 `flutter analyze` 检查代码
- 保持代码简洁清晰

### 原生代码

**Android (Kotlin):**

- 遵循 [Kotlin 编码规范](https://kotlinlang.org/docs/coding-conventions.html)
- 添加必要的注释说明

**iOS (Swift):**

- 遵循 [Swift API 设计指南](https://swift.org/documentation/api-design-guidelines/)
- 使用清晰的命名

## 测试

如果添加了新功能，请考虑：

1. 在 iOS 和 Android 平台上测试
2. 测试不同的 UI 配置
3. 测试错误处理逻辑

## 问题反馈

如果发现问题，欢迎提交 Issue，请包含：

- 问题描述
- 复现步骤
- 预期行为
- 实际行为
- 环境信息（Flutter 版本、设备型号等）

## 功能建议

欢迎提出新功能建议！请在 Issue 中说明：

- 功能描述
- 使用场景
- 预期的 API 设计

## 许可证

提交代码即表示你同意你的贡献将在与项目相同的许可证下发布。

## 获取帮助

如有任何问题，可以：

- 查看现有的 [Issues](../../issues)
- 创建新的 Issue
- 查看项目文档

---

再次感谢你的贡献！🎉
