import 'package:flutter/material.dart';
import '../../features/auth/api/auth_api.dart';
import '../../features/auth/view/login_page.dart';

/// Playground 入口：用户认证
class AuthCase extends StatefulWidget {
  const AuthCase({super.key});

  static const String title = '🔐 用户认证（JWT）';

  @override
  State<AuthCase> createState() => _AuthCaseState();
}

class _AuthCaseState extends State<AuthCase> {
  // AuthApi 在 case 级别持有，保证 token 在登录/个人信息页之间共享
  final _api = AuthApi();

  @override
  Widget build(BuildContext context) => LoginPage(api: _api);
}
