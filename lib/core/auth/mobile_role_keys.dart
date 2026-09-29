/// Ключи ролей из POST/GET `/mobile/auth` → поле `roles`.
abstract final class MobileRoleKeys {
  static const orders = 'zayavka';
  static const transfers = 'internaltransfer';
  static const writeoffs = 'spisanie';
  static const returns = 'vozvrat';
  static const inventory = 'invent';
  static const production = 'proizvodstvo';
}
