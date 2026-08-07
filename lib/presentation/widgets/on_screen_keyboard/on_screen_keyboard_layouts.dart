import 'on_screen_keyboard_language.dart';

abstract final class OnScreenKeyboardLayouts {
  static const digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];

  static const russian = [
    digits,
    ['й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х', 'ъ'],
    ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э'],
    ['я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', '-', '.'],
  ];

  static const kazakh = [
    digits,
    ['ә', 'і', 'ң', 'ғ', 'ү', 'ұ', 'қ', 'ө', 'һ'],
    ['й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х', 'ъ'],
    ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э'],
    ['я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', '-', '.'],
  ];

  static const english = [
    digits,
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', '-', '.'],
  ];

  static List<List<String>> rowsFor(OnScreenKeyboardLanguage language) {
    switch (language) {
      case OnScreenKeyboardLanguage.kazakh:
        return kazakh;
      case OnScreenKeyboardLanguage.russian:
        return russian;
      case OnScreenKeyboardLanguage.english:
        return english;
    }
  }
}
