# Starter 模块 — Client 任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
前端项目当前为空白状态，本次从零搭建启动流程。
启动流程使用 Stream（broadcast）驱动，路由使用 go_router 管理。
启动完成后通过 `onStartupComplete` 回调将结果传出，组装层（main.dart）拆包交给 AuthCubit。
starter 和 auth 模块彼此完全解耦。

> **状态说明（2026-07-03 核实）**
>
> 此前任务 1-7 被标记为 ✅，经代码核实**全部未实现**：
> - `lib/src/` 目录不存在，仍是 playground 架构（`lib/main.dart` → `MainShell`）
> - pubspec.yaml 未添加 go_router / flutter_bloc / equatable / shared_preferences
> - 无 SplashPage / AuthCubit / StartupRepository / GoRouter
> - 无 logo.png 资源
>
> 已将所有标记修正为 ⬜，并补充遗漏的依赖和资源准备任务。

---

## 执行顺序

1. ⬜ 任务 1 — 依赖安装 + 资源准备（无依赖）
   - ⬜ 1.1 pubspec.yaml 添加 go_router / flutter_bloc / equatable / shared_preferences
   - ⬜ 1.2 创建 assets/images/ 目录，放入 logo.png
   - ⬜ 1.3 pubspec.yaml 注册 assets 路径
2. ⬜ 任务 2 — User 模型（无依赖，纯定义）
   - ⬜ 2.1 domain/model/user.dart — User 模型 + toJson/fromJson
3. ⬜ 任务 3 — 启动事件 + StartupResult 模型（依赖任务 2）
   - ⬜ 3.1 启动事件类型定义（StartupLoading / StartupReady / StartupFailed）
   - ⬜ 3.2 StartupResult 模型（token / user / hasPassword / authenticated getter）
4. ⬜ 任务 4 — StartupRepository（依赖任务 3）
   - ⬜ 4.1 StreamController.broadcast() 事件流
   - ⬜ 4.2 initialize() 从 SharedPreferences 读取本地缓存
5. ⬜ 任务 5 — SplashPage 闪屏页（依赖任务 4）
   - ⬜ 5.1 闪屏 UI（logo.png + Flash IM 文字）
   - ⬜ 5.2 Stream 监听 + onStartupComplete 回调 + go_router 跳转
   - ⬜ 5.3 失败重试
6. ⬜ 任务 6 — AuthCubit 全局认证状态（依赖任务 2）
   - ⬜ 6.1 AuthState 状态定义（unknown / authenticated / unauthenticated）
   - ⬜ 6.2 AuthCubit 实现（applyStartupSnapshot / login / logout）
7. ⬜ 任务 7 — 占位页面（无依赖，纯 UI）
   - ⬜ 7.1 auth/view/login_page.dart — 登录页文本占位
   - ⬜ 7.2 home/view/home_page.dart — 首页文本占位
8. ⬜ 任务 8 — GoRouter 路由配置 + app.dart（依赖任务 5、6、7）
   - ⬜ 8.1 router.dart — 路由表定义，默认路由为闪屏页
   - ⬜ 8.2 app.dart — MaterialApp.router 接入 GoRouter
9. ⬜ 任务 9 — main.dart 组装入口（依赖任务 4、6、8）
   - ⬜ 9.1 BlocProvider 全局提供 AuthCubit
   - ⬜ 9.2 createRouter 连接 onStartupComplete → authCubit.applyStartupSnapshot
10. ⬜ 任务 10 — 编译验证 + 端到端测试（依赖全部）
    - ⬜ 10.1 flutter analyze 零错误
    - ⬜ 10.2 端到端测试（闪屏 → 无 Token 跳登录 / 有 Token 跳首页 / 退出不经过闪屏）

---

## 任务 1：依赖安装 + 资源准备 `⬜ 待处理`

文件：`client/flash_im/pubspec.yaml`（修改） + `client/flash_im/assets/images/logo.png`（新建）

### 1.1 添加依赖 `⬜`

```yaml
dependencies:
  go_router: ^17.1.0
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  shared_preferences: ^2.3.2
```

执行 `flutter pub get`。

### 1.2 创建 assets 目录并放入 logo.png `⬜`

- 创建 `client/flash_im/assets/images/` 目录
- 放入 `logo.png`（用户提供）

### 1.3 注册 assets 路径 `⬜`

```yaml
flutter:
  assets:
    - assets/images/
```

---

## 任务 2：user.dart — User 模型 `⬜ 待处理`

文件：`client/flash_im/lib/src/domain/model/user.dart`（新建）

### 2.1 User 模型 `⬜`

```dart
class User {
  final String userId;
  final String phone;
  final String nickname;
  final String avatar;

  const User({
    required this.userId,
    required this.phone,
    required this.nickname,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['user_id'] as String,
        phone: json['phone'] as String,
        nickname: json['nickname'] as String,
        avatar: json['avatar'] as String,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'phone': phone,
        'nickname': nickname,
        'avatar': avatar,
      };
}
```

---

## 任务 3：startup_result.dart — 启动事件 + 结果模型 `⬜ 待处理`

文件：`client/flash_im/lib/src/starter/data/model/startup_result.dart`（新建）

### 3.1 启动事件类型 `⬜`

```dart
sealed class StartupEvent {}
class StartupLoading extends StartupEvent {}
class StartupReady extends StartupEvent {
  final StartupResult result;
}
class StartupFailed extends StartupEvent {
  final String message;
}
```

### 3.2 StartupResult 模型 `⬜`

```dart
class StartupResult {
  final String? token;
  final User? user;
  final bool hasPassword;
  bool get authenticated => token != null;
}
```

---

## 任务 4：startup_repository.dart — 启动仓库 `⬜ 待处理`

文件：`client/flash_im/lib/src/starter/data/repository/startup_repository.dart`（新建）

### 4.1 StreamController.broadcast() 事件流 `⬜`

```dart
class StartupRepository {
  final _controller = StreamController<StartupEvent>.broadcast();

  Stream<StartupEvent> get stream => _controller.stream;
  void dispose() => _controller.close();
}
```

### 4.2 initialize() 从本地缓存读取 `⬜`

```dart
Future<void> initialize()
// 1. _controller.add(StartupLoading())
// 2. try: SharedPreferences.getInstance()
// 3. 读取 token = prefs.getString('auth_token')
// 4. token == null → emit StartupReady(token: null)
// 5. 读取 userJson = prefs.getString('user_info')，jsonDecode → User.fromJson
// 6. 读取 hasPassword = prefs.getBool('has_password')
// 7. emit StartupReady(token, user, hasPassword)
// 8. catch → emit StartupFailed(error.toString())
```

---

## 任务 5：splash_page.dart — 闪屏页 `⬜ 待处理`

文件：`client/flash_im/lib/src/starter/view/splash_page.dart`（新建）

### 5.1 闪屏 UI `⬜`

- 白色背景，居中显示 `Image.asset('assets/images/logo.png')` + "Flash IM" 文字
- Logo 和文字纵向排列，间距适中

### 5.2 Stream 监听 + onStartupComplete 回调 + go_router 跳转 `⬜`

- `initState` 中触发 `StartupRepository.initialize()`
- `Future.wait` 同时等待 Stream 首个非 Loading 事件和 1.5 秒延迟
- `StartupReady` → `widget.onStartupComplete(result)` 通过回调传出结果
- `result.authenticated`（token != null）→ `context.go('/home')`
- `!result.authenticated`（token == null）→ `context.go('/login')`

### 5.3 失败重试 `⬜`

- `StartupFailed` → Logo 下方显示错误提示 + 重试按钮
- 点击重试 → 重新调用 `initialize()`

---

## 任务 6：AuthCubit — 全局认证状态 `⬜ 待处理`

### 6.1 AuthState 状态定义 `⬜`

文件：`client/flash_im/lib/src/auth/cubit/auth_state.dart`（新建）

```dart
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final User? user;
  final bool hasPassword;
}
```

- `unknown` — 初始状态，启动尚未完成
- `authenticated` — 已认证，携带 token、user、hasPassword
- `unauthenticated` — 未认证

### 6.2 AuthCubit 实现 `⬜`

文件：`client/flash_im/lib/src/auth/cubit/auth_cubit.dart`（新建）

```dart
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.unknown());

  void applyStartupSnapshot({     // 接收原始字段，不依赖 StartupResult
    required String? token,
    User? user,
    bool hasPassword = false,
  });
  void login({token, user, hasPassword});
  void logout();
}
```

---

## 任务 7：占位页面 `⬜ 待处理`

### 7.1 登录页占位 `⬜`

文件：`client/flash_im/lib/src/auth/view/login_page.dart`（新建）

```dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('登录页（待实现）')),
    );
  }
}
```

### 7.2 首页占位 `⬜`

文件：`client/flash_im/lib/src/home/view/home_page.dart`（新建）

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('首页（待实现）')),
    );
  }
}
```

---

## 任务 8：router.dart + app.dart — 路由与应用入口 `⬜ 待处理`

### 8.1 GoRouter 路由配置 `⬜`

文件：`client/flash_im/lib/src/router.dart`（新建）

```dart
GoRouter createRouter({
  required StartupRepository startupRepository,
  required ValueChanged<StartupResult> onStartupComplete,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => SplashPage(
        startupRepository: startupRepository,
        onStartupComplete: onStartupComplete,
      )),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    ],
  );
}
```

### 8.2 app.dart — MaterialApp.router `⬜`

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
      routerConfig: router,
    );
  }
}
```

---

## 任务 9：main.dart — 组装入口 `⬜ 待处理`

文件：`client/flash_im/lib/main.dart`（修改，替换旧的 playground 入口）

### 9.1 + 9.2 组装 AuthCubit + Router `⬜`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startupRepository = StartupRepository();
  final authCubit = AuthCubit();
  final router = createRouter(
    startupRepository: startupRepository,
    onStartupComplete: (result) => authCubit.applyStartupSnapshot(
      token: result.token,
      user: result.user,
      hasPassword: result.hasPassword,
    ),
  );
  runApp(
    BlocProvider.value(
      value: authCubit,
      child: FlashApp(router: router),
    ),
  );
}
```

---

## 任务 10：编译验证 + 端到端测试 `⬜ 待处理`

### 10.1 编译通过 `⬜`

```zsh
cd client/flash_im
flutter analyze
```

确保零错误、零 warning。

### 10.2 端到端测试 `⬜`

1. 启动后进入闪屏页，显示 logo.png + "Flash IM"
2. 无 Token → 闪屏结束后跳转 `/login`
3. 有有效 Token → 闪屏结束后跳转 `/home`
4. 退出登录 → 回到 `/login`（不经过闪屏）
5. 重启应用 → 再次经过闪屏
