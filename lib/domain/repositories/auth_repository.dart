import '../../domain/entities/warehouse.dart';
import '../entities/user.dart';

/// Contract for 1C authentication.
abstract class AuthRepository {
  Future<User> login({required String username, required String password});

  /// Восстанавливает сессию из локального хранилища после перезапуска приложения.
  Future<User?> restorePersistedSession();

  /// Мгновенно восстанавливает пользователя из кэша и выставляет Basic Auth.
  User? bootstrapPersistedSession();

  bool get hasPersistedCredentials;

  /// Проверяет сессию на сервере 1С и обновляет локальный снимок пользователя.
  Future<User?> refreshPersistedSession();

  Future<User> validateSession();
  Future<List<Warehouse>> fetchWarehousesFromApi();

  Future<void> logout();
  Future<User?> getCurrentUser();
}
