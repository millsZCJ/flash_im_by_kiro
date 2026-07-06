import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:flash_im/src/starter/data/repository/startup_repository.dart';
import 'package:flash_im/src/auth/data/repository/auth_repository.dart';
import 'package:flash_im/src/auth/view/login_page.dart';
import 'package:flash_im/src/starter/view/splash_page.dart';
import 'package:flash_im/src/home/view/home_page.dart';
import 'package:flash_im/src/home/profile/set_password_page.dart';

typedef OnStartupComplete = ValueChanged<StartupResult>;

/// GoRouter 路由配置
GoRouter createRouter({
  required StartupRepository startupRepository,
  required AuthRepository authRepository,
  required ValueChanged<StartupResult> onStartupComplete,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => SplashPage(
          startupRepository: startupRepository,
          onStartupComplete: onStartupComplete,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          authRepository: authRepository,
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/set-password',
        builder: (context, state) => const SetPasswordPage(),
      ),
    ],
  );
}
