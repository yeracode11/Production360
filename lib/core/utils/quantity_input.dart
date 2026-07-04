import 'package:flutter/services.dart';

import '../constants/app_strings.dart';

/// Ограничения количества: до запятой [orderIntegerDigits], после — [fractionDigits].
abstract final class QuantityLimits {
  static const int orderIntegerDigits = 11;
  static const int fractionDigits = 3;
}

/// Ввод количества: цифры и одна запятая, лимит целой и дробной части.
class QuantityInputFormatter extends TextInputFormatter {
  const QuantityInputFormatter({
    this.maxIntegerDigits = QuantityLimits.orderIntegerDigits,
    this.maxFractionDigits = QuantityLimits.fractionDigits,
  });

  final int maxIntegerDigits;
  final int maxFractionDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('.', ',');
    if (text.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final pattern = RegExp(
      '^\\d{0,$maxIntegerDigits}([,]\\d{0,$maxFractionDigits})?\$',
    );
    if (pattern.hasMatch(text)) {
      return TextEditingValue(
        text: text,
        selection: newValue.selection,
      );
    }
    return oldValue;
  }
}

/// Проверка количества при сохранении формы.
String? validateQuantityInput(
  String? value, {
  int maxIntegerDigits = QuantityLimits.orderIntegerDigits,
  int maxFractionDigits = QuantityLimits.fractionDigits,
  bool required = false,
  bool allowZero = false,
}) {
  if (value == null || value.trim().isEmpty) {
    return required ? AppStrings.itemQuantityRequired : null;
  }

  final normalized = value.trim().replaceAll('.', ',');
  if (!RegExp(r'^\d+(,\d+)?$').hasMatch(normalized)) {
    return AppStrings.itemQuantityInvalid;
  }

  final parts = normalized.split(',');
  if (parts[0].length > maxIntegerDigits) {
    return AppStrings.itemQuantityIntegerInvalid;
  }
  if (parts.length > 1 && parts[1].length > maxFractionDigits) {
    return AppStrings.itemQuantityFractionInvalid;
  }

  final amount = num.tryParse(normalized.replaceAll(',', '.'));
  if (amount == null || amount < 0 || (!allowZero && amount <= 0)) {
    return AppStrings.itemQuantityInvalid;
  }

  return null;
}
