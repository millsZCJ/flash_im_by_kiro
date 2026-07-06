// flash_auth — 闪讯认证模块
// 提供完整的登录认证能力：
// AuthCubit / AuthState, AuthRepository, LoginPage / LoginMixin / LoginStrategy,
// SetPasswordPage, LabeledInput / ActionButton / AgreementRow

// ─── 数据层 ─────────────────────────────────────────────────────────────────
export 'src/data/model/login_result.dart';
export 'src/data/repository/auth_repository.dart';

// ─── 逻辑层 ─────────────────────────────────────────────────────────────────
export 'src/logic/auth/auth_cubit.dart';
export 'src/logic/auth/auth_state.dart';
export 'src/logic/login/login_mixin.dart';
export 'src/logic/login/strategy/login_strategy.dart';
export 'src/logic/login/strategy/sms_login_strategy.dart';
export 'src/logic/login/strategy/password_login_strategy.dart';

// ─── 视图层 ─────────────────────────────────────────────────────────────────
export 'src/view/login_page.dart';
export 'src/view/components/action_button.dart';
export 'src/view/components/agreement_row.dart';
export 'src/view/components/labeled_input.dart';
export 'src/view/components/sms_login_form.dart';
export 'src/view/components/password_login_form.dart';
