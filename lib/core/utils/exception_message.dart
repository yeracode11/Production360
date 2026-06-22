/// Extracts a user-facing message from thrown errors.
String exceptionMessage(Object error) {
  final text = error.toString();
  const prefix = 'Exception: ';
  if (text.startsWith(prefix)) {
    return text.substring(prefix.length);
  }
  return text;
}
