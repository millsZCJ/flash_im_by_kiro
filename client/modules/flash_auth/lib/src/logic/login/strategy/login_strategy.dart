/// 登录策略抽象基类
abstract class LoginStrategy {
  bool get isValid;
  void dispose();
}
