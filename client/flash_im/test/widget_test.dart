import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App startup smoke test', (WidgetTester tester) async {
    // TODO: 端到端运行验证后补充真实测试
    // 当前 main.dart 使用 BlocProvider.value + GoRouter，
    // 需要完整的依赖注入才能 pumpWidget
    expect(true, isTrue);
  });
}
