import 'package:equatable/equatable.dart';
import 'package:flash_core/flash_core.dart';

enum SessionStatus { initial, ready, error }

class SessionState extends Equatable {
  final SessionStatus status;
  final User? user;
  final bool hasPassword;
  final String? errorMessage;

  const SessionState({
    this.status = SessionStatus.initial,
    this.user,
    this.hasPassword = false,
    this.errorMessage,
  });

  const SessionState.initial()
      : status = SessionStatus.initial,
        user = null,
        hasPassword = false,
        errorMessage = null;

  SessionState.ready({
    User? user,
    bool? hasPassword,
  }) : this(
          status: SessionStatus.ready,
          user: user,
          hasPassword: hasPassword ?? false,
          errorMessage: null,
        );

  SessionState.error(String message)
      : this(
          status: SessionStatus.error,
          user: null,
          hasPassword: false,
          errorMessage: message,
        );

  @override
  List<Object?> get props => [status, user, hasPassword, errorMessage];
}
