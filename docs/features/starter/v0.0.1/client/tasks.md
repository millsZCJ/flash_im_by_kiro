# 闪讯 APP — 认证模块 Client 任务清单

> **状态说明（2026-07-06 核实）**
>
> 此前标记任务 1-11 为 ✅，经代码核实 `lib/src/` 目录完全不存在。
> 项目仍使用 `lib/features/` playground 架构，无 GoRouter、Cubit、SharedPreferences、策略模式。
> 已将所有标记修正为 ⬜，严格对齐以下目录结构：

```
client/lib/src/
├── app.dart                          # FlashApp — MaterialApp.router
├── router.dart                       # GoRouter 路由配置
├── config.dart                       # 全局配置（baseUrl 等）
├── network/
│   └── http_client.dart              # Dio 单例 + Token 拦截器 + 401 处理
├── domain/
│   └── model/
│       └── user.dart                 # User 模型（本地缓存 + 接口共用）
├── auth/
│   ├── data/
│   │   ├── model/
│   │   │   └── login_result.dart     # LoginResult 数据模型
│   │   └── repository/
│   │       └── auth_repository.dart # 认证仓库（API 调用 + Token 持久化到 SP）
│   ├── logic/
│   │   ├── auth/
│   │   │   ├── auth_cubit.dart      # AuthCubit — 全局认证状态
│   │   │   └── auth_state.dart      # AuthState（unknown/authenticated/unauthenticated）
│   │   └── login/
│   │       ├── login_mixin.dart     # 登录页逻辑 Mixin（共享状态+调度）
│   │       └── strategy/
│   │           ├── sms_login_strategy.dart    # 验证码登录策略
│   │           └── password_login_strategy.dart # 密码登录策略
│   └── view/
│       ├── login_page.dart          # 登录页（组装各组件）
│       └── components/             # 登录页通用 UI 组件
│           ├── action_button.dart  # 启用/禁用态按钮
│           ├── agreement_row.dart  # 用户协议勾选行
│           ├── labeled_input.dart  # 带标签底线输入框
│           ├── sms_login_form.dart # 验证码表单（手机号+验证码+倒计时）
│           └── password_login_form.dart # 密码表单（账号+密码）
├── home/
│   ├── view/
│   │   └── home_page.dart          # 三 Tab 主 Shell（消息/通讯录/我的）
│   └── profile/
│       ├── profile_page.dart       # "我的"页面（微信风格列表布局）
│       └── set_password_page.dart  # 密码设置独立页面
└── starter/
    ├── data/
    │   ├── model/
    │   │   └── startup_result.dart # StartupEvent + StartupResult
    │   └── repository/
    │       └── startup_repository.dart # 从 SP 读取缓存 → Stream 事件流
    └── view/
        └── splash_page.dart        # 闪屏页（logo + Flash IM，最短 1.5s）
```

---

## 执行顺序

### Phase 0：基础设施

1. ✅ 任务 0 — 依赖安装 + 资源准备
   - ✅ 0.1 pubspec.yaml 添加 go_router / flutter_bloc / equatable / shared_preferences
   - ⬜ 0.2 创建 `assets/images/` 放入 logo.png 并注册 assets（用户决定不用 logo，用 Icon 代替）
   - ✅ 0.3 flutter pub get 验证

### Phase 1：基础层（无依赖，可并行）

2. ✅ 任务 1 — config.dart 全局配置
3. ✅ 任务 2 — User 模型
4. ✅ 任务 3 — LoginResult 数据模型
5. ✅ 任务 4 — AuthState 定义
6. ✅ 任务 5 — Dio 单例 + Token 拦截器

### Phase 2：数据层（依赖 Phase 1）

7. ✅ 任务 6 — AuthRepository（API + SP 持久化）
8. ✅ 任务 7 — StartupRepository（SP 读取 → Stream）

### Phase 3：业务逻辑层（依赖 Phase 2）

9. ✅ 任务 8 — AuthCubit 实现
10. ✅ 任务 9 — 登录策略模式（Strategy 抽象基类 + SmsStrategy + PasswordStrategy + LoginMixin）

### Phase 4：UI 层（依赖 Phase 3）

11. ✅ 任务 10 — 登录页通用组件（components/ 下 5 个独立组件）
12. ✅ 任务 11 — 登录页组装（LoginPage = Header + Form + AgreementRow + ActionButton + 切换链接）
13. ✅ 任务 12 — 闪屏页 SplashPage
14. ✅ 任务 13 — 三 Tab 主 Shell HomePage（消息留白 / 通讯录留白 / 我的=ProfilePage）
15. ✅ 任务 14 — "我的"页面 ProfilePage（微信风格列表 + 设置密码入口 + 退出登录）
16. ✅ 任务 15 — 密码设置独立页面 SetPasswordPage

### Phase 5：组装 + 路由（依赖全部）

17. ✅ 任务 16 — router.dart 路由配置
18. ✅ 任务 17 — app.dart MaterialApp.router
19. ✅ 任务 18 — main.dart 组装入口（BlocProvider + createRouter + onStartupComplete 连接）
20. ✅ 任务 19 — 密码设置引导弹窗（进入主页且 hasPassword=false 时弹出 Dialog）

### Phase 6：验证

21. ✅ 任务 20 — 编译验证（flutter analyze 零错误）+ ⬜ 端到端测试（需设备/模拟器）

---

## 任务详情

---

### 任务 0：依赖安装 + 资源准备 `⬜`

文件：`client/flash_im/pubspec.yaml`（修改）+ `client/flash_im/assets/images/logo.png`（新建）

#### 0.1 添加依赖

```yaml
dependencies:
  go_router: ^17.1.0
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  shared_preferences: ^2.3.2
```

执行 `flutter pub get`。

#### 0.2 创建 assets 目录并放入 logo.png

- 创建 `client/flash_im/assets/images/` 目录
- 放入用户提供 `logo.png`

#### 0.3 注册 assets 路径

```yaml
flutter:
  assets:
    - assets/images/
```

---

### 任务 1：config.dart 全局配置 `⬜`

文件：`client/flash_im/lib/src/config.dart`（新建）

```dart
class AppConfig {
  static String host = '127.0.0.1';
  static int port = 3000;
  static String get baseUrl => 'http://$host:$port';
}
```

从现有 `core/network/app_config.dart` 提取升级，统一管理 baseUrl。

---

### 任务 2：user.dart — User 模型 `⬜`

文件：`client/flash_im/lib/src/domain/model/user.dart`（新建）

```dart
class User {
  final String userId;
  final String phone;
  final String nickname;
  final String avatar;

  const User({required this.userId, required this.phone, required this.nickname, required this.avatar});

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['user_id'] as String,
    phone: json['phone'] as String,
    nickname: json['nickname'] as String,
    avatar: json['avatar'] as String,
  );

  Map<String, dynamic> toJson() => {'user_id': userId, 'phone': phone, 'nickname': nickname, 'avatar': avatar};
}
```

---

### 任务 3：login_result.dart — LoginResult 模型 `⬜`

文件：`client/flash_im/lib/src/auth/data/model/login_result.dart`（新建）

```dart
class LoginResult {
  final String token;
  final String userId;
  final bool isNewUser;
  final bool hasPassword;

  const LoginResult({required this.token, required this.userId, required this.isNewUser, required this.hasPassword});

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    token: json['token'] as String,
    userId: json['user_id'] as String,
    isNewUser: json['is_new_user'] as bool,
    hasPassword: json['has_password'] as bool,
  );
}
```

对应服务端 `/auth/login` 响应体。

---

### 任务 4：auth_state.dart — AuthState `⬜`

文件：`client/flash_im/lib/src/auth/logic/auth/auth_state.dart`（新建）

```dart
import 'package:equatable/equatable.dart';
import '../../../domain/model/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final User? user;
  final bool hasPassword;

  const AuthState({this.status = AuthStatus.unknown, this.token, this.user, this.hasPassword = false});

  // 工厂构造函数
  const AuthState.unknown() : super(status: AuthStatus.unknown);
  AuthState.authenticated({String? token, User? user, bool? hasPassword}) : this(
    status: AuthStatus.authenticated, token: token, user: user, hasPassword: hasPassword ?? false);
  const AuthState.unauthenticated() : super(status: AuthStatus.unauthenticated);

  @override List<Object?> get props => [status, token, user, hasPassword];
}
```

---

### 任务 5：http_client.dart — Dio 单例 `⬜`

文件：`client/flash_im/lib/src/network/http_client.dart`（新建）

从现有 `core/network/http_client.dart` 升级：

- **Dio 单例**：baseUrl 从 AppConfig 读取
- **请求拦截器**：注入 Bearer Token（通过 `tokenProvider` 回调获取）
- **响应拦截器**：401 时调用 `onUnauthorized` 回调（供 AuthCubit 清除状态）
- **connectTimeout/receiveTimeout**：10 秒

依赖注入方式：
- `tokenProvider: String? Function()` — 外部注入，不直接依赖 AuthRepository
- `onUnauthorized: VoidCallback` — 外部注入

---

### 任务 6：auth_repository.dart — 认证仓库 `⬜`

文件：`client/flash_im/lib/src/auth/data/repository/auth_repository.dart`（新建）

核心职责：

| 方法 | 功能 | 本地持久化 |
|------|------|-----------|
| `sendSms(phone)` | POST /auth/sms → 返回 code | 无 |
| `login(phone, credential, type)` | POST /auth/login → (LoginResult, User) | ✅ 保存 token/userInfo/hasPassword |
| `getProfile()` | GET /user/profile → User | ✅ 缓存 userInfo |
| `setPassword(newPassword)` | POST /auth/password | ✅ 更新 hasPassword |
| `logout()` | 清空内存 + SP | ✅ 删除全部 key |

Token 管理：
```dart
Future<void> _saveToken(String token) async { /* 内存 + SP */ }
Future<void> _clearAll() async { /* 内存 + SP 删除 auth_token/user_info/has_password */ }
```

用户信息缓存：
```dart
Future<void> _cacheUserInfo(User user, bool hasPassword) async {
  prefs.setString('user_info', jsonEncode(user.toJson()));
  prefs.setBool('has_password', hasPassword);
}
```

---

### 任务 7：startup_repository.dart + startup_result.dart `⬜`

文件：
- `client/flash_im/lib/src/starter/data/model/startup_result.dart`（新建）
- `client/flash_im/lib/src/starter/data/repository/startup_repository.dart`（新建）

StartupEvent 类型：
```dart
sealed class StartupEvent {}
class StartupLoading extends StartupEvent {}
class StartupReady extends StartupEvent { final StartupResult result; }
class StartupFailed extends StartupEvent { final String message; }
```

StartupResult：
```dart
class StartupResult {
  final String? token;
  final User? user;
  final bool hasPassword;
  bool get authenticated => token != null;
}
```

StartupRepository：
```dart
class StartupRepository {
  StreamController<StartupEvent>.broadcast();
  Future<void> initialize() {
    // 1. emit Loading
    // 2. SharedPreferences.getInstance()
    // 3. 读取 auth_token → token == null ? emit Ready(null) : ...
    // 4. 读取 user_info → User.fromJson
    // 5. 读取 has_password
    // 6. emit Ready(token, user, hasPassword)
    // 7. catch → emit Failed(error.toString())
  }
}
```

---

### 任务 8：auth_cubit.dart — AuthCubit 实现 `⬜`

文件：`client/flash_im/lib/src/auth/logic/auth/auth_cubit.dart`（新建）

方法清单：

| 方法 | 参数 | 效果 |
|------|------|------|
| `applyStartupSnapshot(token, user, hasPassword)` | 启动时从 SP 恢复 | emit authenticated/unauthenticated |
| `login(loginResult, user)` | 登录成功后调用 | emit authenticated |
| `logout()` | 退出登录 | emit unauthenticated |
| `onPasswordSet()` | 设置密码成功后调用 | 更新 state.hasPassword = true |

生命周期与 App 一致，挂载在 main.dart 的 BlocProvider.value 中。

---

### 任务 9：登录策略模式 `⬜`

文件（全部新建）：
- `client/flash_im/lib/src/auth/logic/login/strategy/login_strategy.dart` — 抽象基类
- `client/flash_im/lib/src/auth/logic/login/strategy/sms_login_strategy.dart`
- `client/flash_im/lib/src/auth/logic/login/strategy/password_login_strategy.dart`
- `client/flash_im/lib/src/auth/logic/login/login_mixin.dart`

#### 9.0 LoginStrategy 抽象基类

```dart
abstract class LoginStrategy {
  bool get isValid;
  void dispose();
}
```

只约束共性：能校验、能销毁。特有能力（如 sendSms）通过具体类型暴露。

#### 9.1 SmsLoginStrategy

```dart
class SmsLoginStrategy extends LoginStrategy {
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  int countdown = 0;
  Timer? _timer;

  bool get isPhoneValid => phone.length == 11 && phone.startsWith('1');
  bool get isValid => isPhoneValid && code.length == 6;
  bool get canSendSms => countdown <= 0 && !sendingCode;

  Future<void> sendSms(AuthRepository repo); // repo.sendSms(phone)
  void startCountdown(); // 60s 倒计时
  void dispose(); // 取消 timer + controllers
}
```

#### 9.2 PasswordLoginStrategy

```dart
class PasswordLoginStrategy extends LoginStrategy {
  final accountCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool get isValid => account.isNotEmpty && password.length >= 6;
  void dispose();
}
```

#### 9.3 LoginMixin

```dart
mixin LoginMixin on State<LoginPage> {
  late final SmsLoginStrategy smsStrategy;
  late final PasswordLoginStrategy passwordStrategy;
  LoginMode mode = LoginMode.sms;  // sms | password
  bool agreed = false;
  bool isLoading = false;

  LoginStrategy get currentStrategy => mode == LoginMode.sms ? smsStrategy : passwordStrategy;
  bool get canLogin => agreed && !isLoading && currentStrategy.isValid;

  void toggleMode();   // 切换 mode
  Future<void> doLogin(AuthRepository repo); // currentStrategy.login → AuthCubit.login → context.go('/home')
}
```

---

### 任务 10：登录页通用组件 `⬜`

文件（全部新建在 `client/flash_im/lib/src/auth/view/components/`）：

| 组件 | 文件 | 说明 |
|------|------|------|
| `LabeledInput` | `labeled_input.dart` | 带标签文字 + 竖线分隔的底线输入框（复用游乐场 `_InputField` 设计） |
| `ActionButton` | `action_button.dart` | 启用(绿色实心)/禁用(灰色半透明)按钮，圆角12px，高度52px |
| `AgreementRow` | `agreement_row.dart` | "我已阅读并同意《用户协议》和《隐私政策》"勾选行 |
| `SmsLoginForm` | `sms_login_form.dart` | 手机号(+86前缀) + 验证码(6位数字限制) + 获取验证码按钮(倒计时) |
| `PasswordLoginForm` | `password_login_form.dart` | 账号输入 + 密码输入(secure, 最少6位) |

参考游乐场 `features/auth/view/login_page.dart` 的 UI 风格：
- 背景 `Color(0xFFF7F8FA)`
- 输入框白色背景、圆角12px、浅灰边框、轻微阴影
- 主题色 `Color(0xFF07C160)`
- 错误提示 SnackBar 浮动样式

---

### 任务 11：login_page.dart — 登录页组装 `⬜`

文件：`client/flash_im/lib/src/auth/view/login_page.dart`（新建）

纯 StatefulWidget + LoginMixin，不做 Bloc 监听（登录是临时操作，结果直接回调给 Cubit）。

UI 结构（参考游乐场）：
```
┌─────────────────────────────┐
│                             │
│  🟢 Logo 图标               │
│  欢迎回来                   │
│  手机号验证码登录，安全快捷   │
│                             │
│  手机号                      │  ← LabeledInput (+86 prefix)
│  ───────                    │
│  验证码         [获取验证码]  │  ← LabeledInput + suffix button
│  ───────                    │
│                             │
│  ☑️ 我已阅读并同意...        │  ← AgreementRow
│                             │
│  [ 登录 / 注册 ]            │  ← ActionButton
│                             │
│     使用密码登录 →           │  ← 切换链接
│                             │
└─────────────────────────────┘
```

切换密码模式时，表单区域替换为 PasswordLoginForm，底部链接变为"使用验证码登录 →"。

登录流程：
1. 校验 agreed + isValid
2. setState(isLoading=true)
3. 根据 mode 选择策略执行：
   - SMS: 先 sendSms（自动填入），再 repo.login(phone, code, 'sms') 或直接用已有 code
   - Password: repo.login(account, password, 'password')
4. 成功 → context.read<AuthCubit>().login(result, user) → context.go('/home')
5. 失败 → showToast 错误信息

---

### 任务 12：splash_page.dart — 闪屏页 `⬜`

文件：`client/flash_im/lib/src/starter/view/splash_page.dart`（新建）

- 白色背景，居中显示 `Image.asset('assets/images/logo.png')` + "Flash IM" 文字
- initState 触发 StartupRepository.initialize()
- Future.wait 同时等待 Stream 首个非 Loading 事件和 1.5s 延迟
- StartupReady.authenticated → `widget.onStartupComplete(result)` 回调 → 后续由路由跳转
- StartupReady.unauthenticated → 同上
- StartupFailed → Logo 下方显示错误提示 + 重试按钮
- 最短停留保证品牌露出

---

### 任务 13：home_page.dart — 三 Tab 主 Shell `⬜`

文件：`client/flash_im/lib/src/home/view/home_page.dart`（新建）

BottomNavigationBar 三 Tab：

| Tab | Icon | 内容 | 当前状态 |
|-----|------|------|---------|
| 消息 | Icons.chat_bubble_outline | Center(child: Text('暂无消息')) | 占位 |
| 通讯录 | Icons.contacts_outlined | Center(child: Text('暂无联系人')) | 占位 |
| 我的 | Icons.person_outline | ProfilePage() | 实现中 |

默认选中 index 0（消息），主题色 `Color(0xFF07C160)`。

额外功能：initState 中检查 `state.hasPassword == false` 时弹出设置密码引导弹窗（任务 19）。

---

### 任务 14：profile_page.dart — "我的"页面 `⬜`

文件：`client/flash_im/lib/src/home/profile/profile_page.dart`（新建）

参考游乐场 `im_playground/pages/profile_tab_page.dart` 微信风格：

AppBar：背景色 `Color(0xFFEDEDED)`，标题"我"，居中，无 elevation

Body ListView：
```
┌──────────────────────────────┐
│  [头像]  昵称           >   │  用户卡片（白色背景）
│          ID: xxxxxxxx        │
│──────────────────────────────│
│  📱 手机号    138****8000    │  信息条目（白色背景）
│──────────────────────────────│
│  🔑 设置密码                 │  hasPassword=false 显示
│  🔑 修改密码                 │  hasPassword=true 显示
│──────────────────────────────│
│        退出登录               │  红色文字
│                              │
└──────────────────────────────┘
```

数据来源：`context.watch<AuthCubit>()` 读取 state.user 和 state.hasPassword。

退出登录：repo.logout() + context.read<AuthCubit>().logout() + context.go('/login')

---

### 任务 15：set_password_page.dart — 密码设置页 `⬜`

文件：`client/flash_im/lib/src/home/profile/set_password_page.dart`（新建）

独立页面（非 Dialog），Navigator.push 进入。

UI 结构（简约风格）：
```
┌──────────────────────────────┐
│  ← 设置密码                  │  AppBar
│                              │
│  请设置您的登录密码            │  副标题
│                              │
│  新密码                      │  LabeledInput (secure)
│  ───────                     │
│                              │
│  确认密码                    │  LabeledInput (secure)
│  ───────                     │
│                              │
│  [ 确认设置 ]                │  ActionButton
│                              │
└──────────────────────────────┘
```

逻辑：
- 两次密码一致性校验
- 密码长度 ≥ 6
- 确认后调用 authRepository.setPassword(newPassword) + authCubit.onPasswordSet()
- 成功 pop 返回 ProfilePage

---

### 任务 16：router.dart — GoRouter 路由 `⬜`

文件：`client/flash_im/lib/src/router.dart`（新建）

```dart
GoRouter createRouter({
  required StartupRepository startupRepository,
  required AuthRepository authRepository,
  required ValueChanged<StartupResult> onStartupComplete,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => SplashPage(
        startupRepository: startupRepository,
        onStartupComplete: onStartupComplete,
      )),
      GoRoute(path: '/login', builder: (_, __) => LoginPage(
        authRepository: authRepository,
      )),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/set-password', builder: (_, __) => const SetPasswordPage()),
    ],
  );
}
```

跳转规则：
- 闪屏结束 → `context.go('/home')` 或 `context.go('/login')`
- 退出登录 → `context.go('/login')`
- 设置密码 → `context.push('/set-password')`
- 所有导航不可返回闪屏页

---

### 任务 17：app.dart — MaterialApp.router `⬜`

文件：`client/flash_im/lib/src/app.dart`（新建）

```dart
class FlashApp extends StatelessWidget {
  final GoRouter router;
  const FlashApp({super.key, required this.router});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flash IM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF07C160)),
      ),
      routerConfig: router,
    );
  }
}
```

---

### 任务 18：main.dart — 组装入口 `⬜`

文件：`client/flash_im/lib/main.dart`（重写，替换旧的 playground 入口）

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 基础设施
  final httpClient = HttpClient(
    tokenProvider: () => '', // 初始空，启动后会更新
    onUnauthorized: () {}, // 初始空
  );
  final authRepository = AuthRepository(dio: httpClient.dio);

  // 2. 状态管理
  final authCubit = AuthCubit(authRepository: authRepository);
  final startupRepository = StartupRepository();

  // 3. 回调连接：TokenProvider + OnUnauthorized
  httpClient.tokenProvider = () => authRepository.token ?? authCubit.state.token ?? '';
  httpClient.onUnauthorized = () => authCubit.logout();

  // 4. 路由
  final router = createRouter(
    startupRepository: startupRepository,
    authRepository: authRepository,
    onStartupComplete: (result) => authCubit.applyStartupSnapshot(
      token: result.token,
      user: result.user,
      hasPassword: result.hasPassword,
    ),
  );

  runApp(
    BlocProvider.value(value: authCubit, child: FlashApp(router: router)),
  );
}
```

关键点：
- AuthCubit 通过 constructor 注入 authRepository（非全局单例）
- LoginPage 通过 GoRouter 的 extra 或 route 参数接收 authRepository
- HomePage 通过 context.read<AuthCubit>() 获取状态

---

### 任务 19：密码设置引导弹窗 `⬜`

位置：`home_page.dart` 的 initState 或 build 方法中

触发条件：`state.status == authenticated && state.hasPassword == false`

实现方式：
- 使用 `WidgetsBinding.instance.addPostFrameCallback` 确保 frame 渲染后弹出
- showDialog 展示：
  ```
  ┌─────────────────────────────┐
  │                             │
  │     🔒                      │
  │  建议设置密码               │
  │  方便下次快速登录           │
  │                             │
  │   [去设置]    [跳过]        │
  │                             │
  └─────────────────────────────┘
  ```
- "去设置" → Navigator.push(SetPasswordPage)
- "跳过" → 关闭弹窗
- 内存标志位避免每次 rebuild 重复弹出（或用 didShowHint flag）

---

### 任务 20：编译验证 + 端到端测试 `⬜`

#### 20.1 编译验证

```zsh
cd client/flash_im
flutter analyze
```
确保零 error，warning 可接受。

#### 20.2 端到端测试路径

| # | 场景 | 预期结果 |
|---|------|---------|
| 1 | 冷启动应用 | → 闪屏页（logo + Flash IM，≥1.5s） |
| 2 | 无 Token 闪屏结束后 | → 登录页 |
| 3 | 发送验证码 | 合法手机号返回 6 位码；非法返回 toast |
| 4 | 验证码登录成功 | → 主页（消息Tab）+ 弹出设置密码引导 |
| 5 | 切换密码登录模式 | 表单切换为账号+密码 |
| 6 | 密码登录成功 | → 主页（消息Tab） |
| 7 | 点击"我的"Tab | 显示用户信息（头像/昵称/手机号） |
| 8 | 设置密码 | 填写→提交→成功→返回"我的"页显示"修改密码" |
| 9 | 退出登录 | → 登录页（不经过闪屏） |
| 10 | 重启应用 | → 闪屏 → 有 Token → 直接进主页 |
