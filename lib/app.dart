import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/storage/selected_warehouse_storage.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/services/force_update_notifier.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/orders/orders_cubit.dart';
import 'presentation/bloc/update/update_cubit.dart';
import 'presentation/bloc/update/update_state.dart';
import 'presentation/bloc/warehouse/warehouse_cubit.dart';
import 'presentation/screens/force_update/force_update_screen.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/main/main_shell.dart';

class ConfectioneryApp extends StatelessWidget {
  const ConfectioneryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => UpdateCubit(
            forceUpdateNotifier: sl<ForceUpdateNotifier>(),
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
          home: const _AppRoot(),
        ),
      ),
    );
  }
}

/// Корневой виджет: force update блокирует всё остальное.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

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

        if (state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
