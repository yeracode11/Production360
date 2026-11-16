import 'package:confectionery_logistics/core/utils/one_c_author.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OneCAuthorFields', () {
    test('ignores the 1C service account returned in list «Автор»', () {
      final fields = OneCAuthorFields.parse({'Автор': 'svc_mobile'});
      expect(fields.login, isNull);
      expect(fields.name, isNull);
    });

    test('prefers the real author over the service account', () {
      final fields = OneCAuthorFields.parse({
        'АвторЛогин': 'ivanov',
        'Автор': 'svc_mobile',
      });
      expect(fields.login, 'ivanov');
    });

    test('falls through the service account to the next field', () {
      final fields = OneCAuthorFields.parse({
        'Автор': 'SVC_MOBILE',
        'Пользователь': 'petrov',
      });
      expect(fields.login, 'petrov');
    });

    test('keeps ordinary logins', () {
      final fields = OneCAuthorFields.parse({'Автор': 'sidorov'});
      expect(fields.login, 'sidorov');
      expect(fields.name, 'sidorov');
    });

    test('isServiceAccount', () {
      expect(OneCAuthorFields.isServiceAccount('svc_mobile'), isTrue);
      expect(OneCAuthorFields.isServiceAccount(' svc_other '), isTrue);
      expect(OneCAuthorFields.isServiceAccount('ivanov'), isFalse);
      expect(OneCAuthorFields.isServiceAccount(null), isFalse);
    });
  });
}
