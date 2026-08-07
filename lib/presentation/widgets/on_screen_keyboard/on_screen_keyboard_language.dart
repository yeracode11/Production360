enum OnScreenKeyboardLanguage {
  kazakh,
  russian,
  english,
}

extension OnScreenKeyboardLanguageX on OnScreenKeyboardLanguage {
  String get label {
    switch (this) {
      case OnScreenKeyboardLanguage.kazakh:
        return 'ҚАЗ';
      case OnScreenKeyboardLanguage.russian:
        return 'РУС';
      case OnScreenKeyboardLanguage.english:
        return 'ENG';
    }
  }
}
