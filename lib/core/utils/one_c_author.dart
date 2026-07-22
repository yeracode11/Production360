/// Поля автора документа из ответа 1С.
abstract final class OneCAuthorFields {
  static ({String? name, String? login}) parse(Map<String, dynamic> json) {
    final login = _nullable(json['АвторЛогин']) ??
        _nullable(json['Автор']) ??
        _nullable(json['ИмяПользователя']) ??
        _nullable(json['Пользователь']);
    final name = _nullable(json['АвторНаименование']) ??
        _nullable(json['Ответственный']) ??
        login;
    return (name: name, login: login);
  }

  static String? _nullable(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
