import '../../core/constants/app_strings.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/auth_session_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthService authService,
    required DioClient dioClient,
    required AuthSessionStorage sessionStorage,
  })  : _authService = authService,
        _dioClient = dioClient,
        _sessionStorage = sessionStorage;

  final AuthService _authService;
  final DioClient _dioClient;
  final AuthSessionStorage _sessionStorage;
  UserModel? _currentUser;

  @override
  Future<User> login({required String username, required String password}) async {
    _currentUser = await _authService.login(username, password);
    await _sessionStorage.saveSession(
      username: username.trim(),
      password: password,
      user: _currentUser!,
    );
    return _currentUser!;
  }

  @override
  Future<User?> restorePersistedSession() async {
    final credentials = _sessionStorage.readCredentials();
    if (credentials == null) {
      _currentUser = null;
      return null;
    }

    _dioClient.setBasicAuth(credentials.username, credentials.password);
    _currentUser = _sessionStorage.readUserSnapshot();

    try {
      _currentUser = await _authService.fetchSession();
      await _sessionStorage.saveUserSnapshot(_currentUser!);
      return _currentUser!;
    } catch (e) {
      if (_isAuthFailure(e)) {
        await logout();
        return null;
      }
      return _currentUser;
    }
  }

  @override
  Future<User> validateSession() async {
    await _ensureAuthHeaders();

    try {
      _currentUser = await _authService.fetchSession();
      await _sessionStorage.saveUserSnapshot(_currentUser!);
      return _currentUser!;
    } catch (e) {
      if (_isAuthFailure(e)) {
        await logout();
        throw Exception(AppStrings.invalidCredentials);
      }

      if (_currentUser != null) {
        return _currentUser!;
      }

      final snapshot = _sessionStorage.readUserSnapshot();
      if (snapshot != null) {
        _currentUser = snapshot;
        return _currentUser!;
      }

      rethrow;
    }
  }

  @override
  Future<List<Warehouse>> fetchWarehousesFromApi() async {
    await validateSession();
    return _currentUser!.warehouses;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _dioClient.clearAuth();
    await _sessionStorage.clear();
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    _currentUser = _sessionStorage.readUserSnapshot();
    return _currentUser;
  }

  Future<void> _ensureAuthHeaders() async {
    if (_dioClient.hasAuth) {
      return;
    }

    final credentials = _sessionStorage.readCredentials();
    if (credentials == null) {
      throw Exception(AppStrings.invalidCredentials);
    }

    _dioClient.setBasicAuth(credentials.username, credentials.password);
    _currentUser ??= _sessionStorage.readUserSnapshot();
  }

  bool _isAuthFailure(Object error) {
    final message = error.toString();
    return message.contains(AppStrings.invalidCredentials);
  }
}
