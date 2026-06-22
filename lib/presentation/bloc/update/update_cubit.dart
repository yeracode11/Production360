import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/services/force_update_notifier.dart';
import 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit({required ForceUpdateNotifier forceUpdateNotifier})
      : _forceUpdateNotifier = forceUpdateNotifier,
        super(const UpdateState.normal()) {
    _subscription = _forceUpdateNotifier.onForceUpdateRequired.listen(
      (_) => requireUpdate(),
    );
  }

  final ForceUpdateNotifier _forceUpdateNotifier;
  late final StreamSubscription<void> _subscription;

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
