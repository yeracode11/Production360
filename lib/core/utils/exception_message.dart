import '../constants/app_strings.dart';

/// Extracts a user-facing message from thrown errors.
String exceptionMessage(Object error) {
  final text = error.toString();
  const prefix = 'Exception: ';
  final message = text.startsWith(prefix) ? text.substring(prefix.length) : text;

  if (message.contains('Структурная единица')) {
    return AppStrings.productionStructuralUnitError;
  }

  return message;
}
