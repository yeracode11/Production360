import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/app_version_check_service.dart';
import '../../../domain/services/force_update_notifier.dart';
import 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit({
    required ForceUpdateNotifier forceUpdateNotifier,
    required AppVersionCheckService versionCheckService,
  })  : _forceUpdateNotifier = forceUpdateNotifier,
        _versionCheckService = versionCheckService,
        super(const UpdateState.normal()) {
    _subscription = _forceUpdateNotifier.onForceUpdateRequired.listen(
      (_) => requireUpdate(),
    );
  }

  final ForceUpdateNotifier _forceUpdateNotifier;
  final AppVersionCheckService _versionCheckService;
  late final StreamSubscription<void> _subscription;

  Future<void> recheckVersion() => _versionCheckService.checkMinVersion();

  void requireUpdate() {
    if (state.status == AppStatus.updateRequired) {
      return;
    }
    emit(const UpdateState.updateRequired());
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
