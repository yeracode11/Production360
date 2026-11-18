import 'package:confectionery_logistics/core/constants/app_strings.dart';
import 'package:confectionery_logistics/core/utils/exception_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('productionErrorMessage', () {
    test('keeps the 1C text for a raw-material shortage', () {
      const oneC = 'Недостаточно запасов. Номенклатура: Курица голень, '
          'Структурная единица: Акжар заготовка, Остаток: 0, Требуется: 1000';
      final message = productionErrorMessage(Exception(oneC));
      expect(message, startsWith(AppStrings.productionStockShortageError));
      expect(message, contains(oneC));
    });

    test('keeps the 1C text for a structural-unit error', () {
      const oneC = 'Структурная единица не соответствует организации';
      final message = productionErrorMessage(Exception(oneC));
      expect(message, startsWith(AppStrings.productionStructuralUnitError));
      expect(message, contains(oneC));
    });

    test('passes other errors through unchanged', () {
      expect(
        productionErrorMessage(Exception('Сервер 1С не отвечает')),
        'Сервер 1С не отвечает',
      );
    });
  });

  test('exceptionMessage no longer rewrites unrelated 1C errors', () {
    const oneC = 'Структурная единица получателя не заполнена';
    expect(exceptionMessage(Exception(oneC)), oneC);
  });
}
