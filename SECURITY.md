# 安全配置指南

## 概述

本插件需要配置运营商提供的 appId 和 appKey，以及 Android 应用签名密钥。为保护这些敏感信息，请遵循以下配置指南。

## 🔒 重要提示

**⚠️ 切勿将以下文件提交到版本控制系统：**
- `.env` 文件（包含 appId 和 appKey）
- `key.properties` 文件（包含签名密钥配置）
- `*.keystore` 或 `*.jks` 文件（签名密钥库）
- `local.properties` 文件（包含本地路径）

## 配置步骤

### 1. 配置一键登录凭证

复制环境变量模板文件：

```bash
cd example
cp .env.example .env
```

编辑 `.env` 文件，填入你从中国移动能力开放平台获取的真实凭证：

```env
# iOS 平台配置
IOS_APP_ID=你的iOS_AppId
IOS_APP_KEY=你的iOS_AppKey

# Android 平台配置
ANDROID_APP_ID=你的Android_AppId
ANDROID_APP_KEY=你的Android_AppKey
```

### 2. 配置 Android 签名（仅开发/发布需要）

#### 2.1 生成签名密钥（如果还没有）

```bash
cd example/android
keytool -genkey -v -keystore app_release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias my_app_key
```

按提示输入密码和信息。

#### 2.2 配置签名信息

复制配置模板：

```bash
cp key.properties.example key.properties
```

编辑 `key.properties`，填入你的签名信息：

```properties
keyAlias=my_app_key
keyPassword=你的密钥密码
storePassword=你的KeyStore密码
storeFile=../app_release.keystore
```

## 🛡️ 安全措施

### Git Pre-commit Hook

本项目已配置 git pre-commit hook，会自动检测并阻止敏感文件被提交。

如果你尝试提交敏感文件，会看到类似提示：

```
🔍 检查敏感文件...
❌ 阻止提交敏感文件: example/android/key.properties
🚫 提交被阻止！
```

### .gitignore 规则

`.gitignore` 文件已配置忽略所有敏感文件：

```gitignore
# 环境变量
.env
example/.env
!.env.example

# Android 签名密钥
*.keystore
*.jks
key.properties

# 本地配置
local.properties
```

## 🔧 团队协作

### 新成员配置指南

1. 克隆仓库后，从团队负责人处获取凭证信息
2. 按照上述步骤配置 `.env` 和 `key.properties`
3. 确保这些文件只保存在本地，切勿分享或提交

### CI/CD 配置

如需在 CI/CD 环境中使用：

#### GitHub Actions 示例

```yaml
- name: Create .env file
  run: |
    echo "IOS_APP_ID=${{ secrets.IOS_APP_ID }}" >> example/.env
    echo "IOS_APP_KEY=${{ secrets.IOS_APP_KEY }}" >> example/.env
    echo "ANDROID_APP_ID=${{ secrets.ANDROID_APP_ID }}" >> example/.env
    echo "ANDROID_APP_KEY=${{ secrets.ANDROID_APP_KEY }}" >> example/.env
```

在 GitHub 仓库的 Settings → Secrets → Actions 中配置这些密钥。

## 📝 获取凭证

### 中国移动一键登录平台

1. 访问中国移动能力开放平台
2. 注册开发者账号
3. 创建应用并获取 appId 和 appKey
4. iOS 和 Android 平台需要分别申请

### Android 签名密钥

- **开发环境**：可以使用调试密钥（debug.keystore）
- **生产环境**：必须使用安全生成的发布密钥
- 发布密钥务必妥善保管，一旦丢失将无法更新已发布的应用

## ⚠️ 泄露应急处理

如果不慎将敏感信息提交到仓库：

1. **立即撤销凭证**：联系运营商重新生成 appId/appKey
2. **重新生成密钥**：为应用生成新的签名密钥
3. **清理 Git 历史**：使用 git-filter-repo 或 BFG 清理历史记录
4. **通知团队**：告知所有团队成员更新凭证

清理命令示例：

```bash
# 安装 git-filter-repo
pip install git-filter-repo

# 删除敏感文件的所有历史记录
git filter-repo --path example/.env --invert-paths
git filter-repo --path example/android/key.properties --invert-paths
git filter-repo --path example/android/app_key.keystore --invert-paths

# 强制推送
git push origin --force --all
```

## 📚 更多资源

- [Git 安全最佳实践](https://docs.github.com/en/code-security/getting-started/best-practices-for-preventing-data-leaks-in-your-organization)
- [Android 应用签名](https://developer.android.com/studio/publish/app-signing)
- [环境变量管理](https://12factor.net/config)

---

如有任何安全问题，请联系项目维护者。
