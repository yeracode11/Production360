import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/storage/selected_warehouse_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/services/app_version_check_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/repositories/inventory_repository.dart';
import 'domain/repositories/production_repository.dart';
import 'domain/repositories/return_repository.dart';
import 'domain/repositories/transfer_repository.dart';
import 'domain/repositories/writeoff_repository.dart';
import 'domain/services/force_update_notifier.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/inventory/inventory_cubit.dart';
import 'presentation/bloc/production/production_cubit.dart';
import 'presentation/bloc/orders/orders_cubit.dart';
import 'presentation/bloc/returns/returns_cubit.dart';
import 'presentation/bloc/transfers/transfers_cubit.dart';
import 'presentation/bloc/writeoffs/writeoffs_cubit.dart';
import 'presentation/bloc/update/update_cubit.dart';
import 'presentation/bloc/update/update_state.dart';
import 'presentation/bloc/warehouse/warehouse_cubit.dart';
import 'presentation/screens/force_update/force_update_screen.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/main/main_shell.dart';
import 'presentation/widgets/dismiss_keyboard.dart';
import 'presentation/widgets/on_screen_keyboard/on_screen_keyboard_host.dart';

class ConfectioneryApp extends StatelessWidget {
  const ConfectioneryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => UpdateCubit(
            forceUpdateNotifier: sl<ForceUpdateNotifier>(),
            versionCheckService: sl<AppVersionCheckService>(),
          ),
        ),
        BlocProvider(
          create: (_) => AuthBloc(authRepository: sl<AuthRepository>())
            ..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => WarehouseCubit(
            authRepository: sl<AuthRepository>(),
            storage: sl<SelectedWarehouseStorage>(),
          ),
        ),
        BlocProvider(
          create: (context) => OrdersCubit(
            orderRepository: sl<OrderRepository>(),
            warehouseCubit: context.read<WarehouseCubit>(),
          ),
        ),
        BlocProvider(
          create: (context) => TransfersCubit(
            transferRepository: sl<TransferRepository>(),
            warehouseCubit: context.read<WarehouseCubit>(),
          ),
        ),
        BlocProvider(
          create: (context) => WriteoffsCubit(
            writeoffRepository: sl<WriteoffRepository>(),
            warehouseCubit: context.read<WarehouseCubit>(),
          ),
        ),
        BlocProvider(
          create: (context) => ReturnsCubit(
            returnRepository: sl<ReturnRepository>(),
            warehouseCubit: context.read<WarehouseCubit>(),
          ),
        ),
        BlocProvider(
          create: (context) => InventoryCubit(
            inventoryRepository: sl<InventoryRepository>(),
            warehouseCubit: context.read<WarehouseCubit>(),
          ),
        ),
        BlocProvider(
          create: (context) => ProductionCubit(
            productionRepository: sl<ProductionRepository>(),
            warehouseCubit: context.read<WarehouseCubit>(),
          ),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          final warehouseCubit = context.read<WarehouseCubit>();
          if (state is AuthAuthenticated) {
            warehouseCubit.loadFromApi();
          } else if (state is AuthUnauthenticated) {
            warehouseCubit.reset();
          }
        },
        child: MaterialApp(
          title: AppStrings.appName,
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return OnScreenKeyboardHost(
              child: DismissKeyboard(
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: const _AppRoot(),
        ),
      ),
    );
  }
}

/// Корневой виджет: force update блокирует всё остальное.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<UpdateCubit>().recheckVersion();
      context.read<AuthBloc>().add(const AuthSessionRefreshRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, updateState) {
        if (updateState.status == AppStatus.updateRequired) {
          return const ForceUpdateScreen();
        }

        return const _AuthGate();
      },
    );
  }
}

/// Routes between login and main shell based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const MainShell();
        }

        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
