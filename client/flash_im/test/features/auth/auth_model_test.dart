import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/features/auth/model/auth_model.dart';

void main() {
  group('LoginResult', () {
    test('fromJson 解析正确', () {
      final json = {
        'token': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...',
        'user_id': '9c5e836d-0f18-4bf7-9911-fa6df837fc71',
        'is_new_user': true,
      };

      final result = LoginResult.fromJson(json);

      expect(result.token, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...');
      expect(result.userId, '9c5e836d-0f18-4bf7-9911-fa6df837fc71');
      expect(result.isNewUser, true);
    });

    test('fromJson 处理 is_new_user 为 false', () {
      final json = {
        'token': 'token123',
        'user_id': 'user456',
        'is_new_user': false,
      };

      final result = LoginResult.fromJson(json);

      expect(result.isNewUser, false);
    });

    test('fromJson 字段缺失时抛出异常', () {
      final json = {'token': 'abc'};

      expect(
        () => LoginResult.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('UserProfile', () {
    test('fromJson 解析正确', () {
      final json = {
        'user_id': '9c5e836d-0f18-4bf7-9911-fa6df837fc71',
        'phone': '13800138000',
        'nickname': '张三',
        'avatar': 'https://api.dicebear.com/7.x/thumbs/svg?seed=abc',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.userId, '9c5e836d-0f18-4bf7-9911-fa6df837fc71');
      expect(profile.phone, '13800138000');
      expect(profile.nickname, '张三');
      expect(profile.avatar, 'https://api.dicebear.com/7.x/thumbs/svg?seed=abc');
    });

    test('fromJson 处理空字符串', () {
      final json = {
        'user_id': '',
        'phone': '',
        'nickname': '',
        'avatar': '',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.userId, '');
      expect(profile.phone, '');
      expect(profile.nickname, '');
      expect(profile.avatar, '');
    });

    test('fromJson 字段缺失时抛出异常', () {
      final json = {'user_id': 'abc'};

      expect(
        () => UserProfile.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
