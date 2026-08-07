import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../../core/config/catalog_config.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/app_version_check_service.dart';
import '../../data/services/force_update_notifier_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/repositories/printer_repository_impl.dart';
import '../../data/repositories/production_repository_impl.dart';
import '../../data/repositories/transfer_repository_impl.dart';
import '../../data/repositories/writeoff_repository_impl.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/printer_repository.dart';
import '../../domain/repositories/production_repository.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../../domain/repositories/writeoff_repository.dart';
import '../../domain/services/force_update_notifier.dart';
import '../../presentation/widgets/on_screen_keyboard/on_screen_keyboard_controller.dart';
import '../network/app_version_provider.dart';
import '../network/dio_client.dart';
import '../storage/auth_session_storage.dart';
import '../storage/document_author_storage.dart';
import '../storage/inventory_completed_storage.dart';
import '../storage/printer_config_storage.dart';
import '../storage/selected_warehouse_storage.dart';

final GetIt sl = GetIt.instance;

/// Registers all dependencies. Call once before runApp.
Future<void> configureDependencies() async {
  final warehouseStorage = await SelectedWarehouseStorage.create();
  sl.registerSingleton<SelectedWarehouseStorage>(warehouseStorage);

  final authSessionStorage = await AuthSessionStorage.create();
  sl.registerSingleton<AuthSessionStorage>(authSessionStorage);

  final documentAuthorStorage = await DocumentAuthorStorage.create();
  sl.registerSingleton<DocumentAuthorStorage>(documentAuthorStorage);

  final printerConfigStorage = await PrinterConfigStorage.create();
  sl.registerSingleton<PrinterConfigStorage>(printerConfigStorage);

  final inventoryCompletedStorage = await InventoryCompletedStorage.create();
  sl.registerSingleton<InventoryCompletedStorage>(inventoryCompletedStorage);

  sl.registerLazySingleton<AppVersionProvider>(() => AppVersionProvider());
  sl.registerLazySingleton<ForceUpdateNotifier>(
    () => ForceUpdateNotifierImpl(),
  );
  sl.registerLazySingleton<AppVersionCheckService>(
    () => AppVersionCheckService(
      versionProvider: sl<AppVersionProvider>(),
      forceUpdateNotifier: sl<ForceUpdateNotifier>(),
    ),
  );

  // Кэшируем версию до первого HTTP-запроса.
  await sl<AppVersionProvider>().getVersion();

  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      versionProvider: sl<AppVersionProvider>(),
      forceUpdateNotifier: sl<ForceUpdateNotifier>(),
    ),
  );

  sl.registerLazySingleton<AuthService>(
    () => AuthService(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authService: sl<AuthService>(),
      dioClient: sl<DioClient>(),
      sessionStorage: sl<AuthSessionStorage>(),
    ),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<TransferRepository>(
    () => TransferRepositoryImpl(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<WriteoffRepository>(
    () => WriteoffRepositoryImpl(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(
      dioClient: sl<DioClient>(),
      completedStorage: sl<InventoryCompletedStorage>(),
    ),
  );
  sl.registerLazySingleton<ProductionRepository>(
    () => ProductionRepositoryImpl(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<PrinterRepository>(
    () => PrinterRepositoryImpl(
      storage: sl<PrinterConfigStorage>(),
      dioClient: sl<DioClient>(),
    ),
  );

  sl.registerLazySingleton<Dio>(
    () {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final token = CatalogConfig.bearerToken.trim();
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      return Dio(
        BaseOptions(
          baseUrl: CatalogConfig.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: headers,
        ),
      );
    },
    instanceName: 'catalog',
  );
  sl.registerLazySingleton<CatalogRepository>(
    () => CatalogRepositoryImpl(dio: sl<Dio>(instanceName: 'catalog')),
  );

  sl.registerLazySingleton<OnScreenKeyboardController>(
    OnScreenKeyboardController.new,
  );
}
