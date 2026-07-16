import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app.dart';
import 'src/router.dart';
import 'package:flash_core/flash_core.dart';
import 'package:flash_auth/flash_auth.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'src/starter/data/repository/startup_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 基础设施
  final httpClient = HttpClient(
    tokenProvider: () => '',
    onUnauthorized: () {},
  );
  final authRepository = AuthRepository(dio: httpClient.dio);
  final sessionRepository = SessionRepository(dio: httpClient.dio);

  // 2. 状态管理
  final authCubit = AuthCubit(authRepository: authRepository);
  final sessionCubit = SessionCubit(sessionRepository: sessionRepository);
  final startupRepository = StartupRepository();

  // 3. WebSocket 客户端
  final wsClient = WsClient(
    config: ImConfig(
      wsUrl: 'ws://${AppConfig.host}:${AppConfig.port}/ws/im',
    ),
    tokenProvider: () => authCubit.state.token,
  );

  // 4. 回调连接：TokenProvider + OnUnauthorized
  httpClient.tokenProvider = () => authRepository.token ?? authCubit.state.token ?? '';
  httpClient.onUnauthorized = () => authCubit.logout();

  // 5. 路由
  final router = createRouter(
    startupRepository: startupRepository,
    authRepository: authRepository,
    onStartupComplete: (result) {
      authCubit.applyStartupSnapshot(
        token: result.token,
        user: result.user,
        hasPassword: result.hasPassword,
      );
      // 同步初始化 SessionCubit
      sessionCubit.init(user: result.user, hasPassword: result.hasPassword);

      // 启动恢复时已认证则连接 WebSocket
      if (result.authenticated) {
        wsClient.connect();
      }
    },
  );

  runApp(
    RepositoryProvider.value(
      value: wsClient,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          BlocProvider.value(value: sessionCubit),
        ],
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              wsClient.connect();
            } else if (state.status == AuthStatus.unauthenticated) {
              wsClient.disconnect();
            }
          },
          child: FlashApp(router: router),
        ),
      ),
    ),
  );
}
