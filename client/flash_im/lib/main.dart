import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app.dart';
import 'src/router.dart';
import 'package:flash_core/flash_core.dart';
import 'package:flash_auth/flash_auth.dart';
import 'src/starter/data/repository/startup_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 基础设施
  final httpClient = HttpClient(
    tokenProvider: () => '',
    onUnauthorized: () {},
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
    BlocProvider.value(
      value: authCubit,
      child: FlashApp(router: router),
    ),
  );
}
