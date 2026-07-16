// flash_session — 闪讯会话模块
// 提供用户资料编辑、密码管理、头像渲染、会话状态管理能力：

// ─── 数据层 ─────────────────────────────────────────────────────────────────
export 'src/data/session_repository.dart' show SessionRepository;
export 'package:flash_core/flash_core.dart' show User;

// ─── 逻辑层 ─────────────────────────────────────────────────────────────────
export 'src/logic/session_cubit.dart' show SessionCubit;
export 'src/logic/session_state.dart' show SessionState, SessionStatus;

// ─── 视图层 ─────────────────────────────────────────────────────────────────
export 'src/view/edit_profile_page.dart' show EditProfilePage;
export 'src/view/set_password_page.dart' show SetPasswordPage;
export 'src/view/change_password_page.dart' show ChangePasswordPage;
export 'src/view/widget/identicon_avatar.dart' show IdenticonAvatar;
export 'src/view/widget/user_card.dart' show UserCard, UserAvatar;
