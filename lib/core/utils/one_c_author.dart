/// Поля автора документа из ответа 1С.
abstract final class OneCAuthorFields {
  /// Логины служебных пользователей 1С, под которыми работает HTTP-сервис
  /// мобильного приложения. В списках документов 1С может возвращать их
  /// в поле «Автор» вместо реального автора, поэтому автором они не считаются.
  static const Set<String> _serviceLogins = {'svc_mobile'};
  static const String _serviceLoginPrefix = 'svc_';

  /// Является ли [value] служебным пользователем 1С, а не реальным автором.
  static bool isServiceAccount(String? value) {
    final text = value?.trim().toLowerCase();
    if (text == null || text.isEmpty) return false;
    return _serviceLogins.contains(text) || text.startsWith(_serviceLoginPrefix);
  }

  static ({String? name, String? login}) parse(Map<String, dynamic> json) {
    final login = _author(json['АвторЛогин']) ??
        _author(json['Автор']) ??
        _author(json['ИмяПользователя']) ??
        _author(json['Пользователь']);
    final name = _author(json['АвторНаименование']) ??
        _author(json['Ответственный']) ??
        login;
    return (name: name, login: login);
  }

  static String? _author(dynamic value) {
    final text = _nullable(value);
    if (text == null || isServiceAccount(text)) return null;
    return text;
  }

  static String? _nullable(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
