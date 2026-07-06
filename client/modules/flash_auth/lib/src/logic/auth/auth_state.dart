import 'package:equatable/equatable.dart';
import 'package:flash_core/flash_core.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? token;
  final User? user;
  final bool hasPassword;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.token,
    this.user,
    this.hasPassword = false,
  });

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        token = null,
        user = null,
        hasPassword = false;

  // ignore: prefer_const_constructors_in_immutables
  AuthState.authenticated({
    String? token,
    User? user,
    bool? hasPassword,
  }) : this(
          status: AuthStatus.authenticated,
          token: token,
          user: user,
          hasPassword: hasPassword ?? false,
        );

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        token = null,
        user = null,
        hasPassword = false;

  @override
  List<Object?> get props => [status, token, user, hasPassword];
}
