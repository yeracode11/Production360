import '../constants/app_strings.dart';

/// Extracts a user-facing message from thrown errors.
String exceptionMessage(Object error) {
  final text = error.toString();
  const prefix = 'Exception: ';
  return text.startsWith(prefix) ? text.substring(prefix.length) : text;
}

/// User-facing message for a failed production create/post in 1C.
///
/// 1C reports both stock shortages and warehouse/structural-unit problems
/// with the words «Структурная единица», so the original 1C text is always
/// kept: hiding it made a plain shortage of raw materials look like a
/// warehouse configuration error.
String productionErrorMessage(Object error) {
  final message = exceptionMessage(error).trim();
  if (message.isEmpty) return message;

  if (_isStockShortage(message)) {
    return '${AppStrings.productionStockShortageError}\n\n'
        '${AppStrings.oneCResponse}: $message';
  }

  if (message.contains('Структурная единица')) {
    return '${AppStrings.productionStructuralUnitError}\n\n'
        '${AppStrings.oneCResponse}: $message';
  }

  return message;
}

bool _isStockShortage(String message) {
  final lower = message.toLowerCase();
  const markers = [
    'недостаточно',
    'не хватает',
    'нехватк',
    'превышает остаток',
    'превышает свободный остаток',
    'остаток:',
    'требуется:',
  ];
  return markers.any(lower.contains);
}
