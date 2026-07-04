import 'dart:async';

import '../../domain/services/force_update_notifier.dart';

class ForceUpdateNotifierImpl implements ForceUpdateNotifier {
  final _controller = StreamController<void>.broadcast();
  bool _updateRequired = false;

  @override
  Stream<void> get onForceUpdateRequired => _controller.stream;

  @override
  bool get isUpdateRequired => _updateRequired;

  @override
  void notifyForceUpdateRequired() {
    _updateRequired = true;
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() {
    _controller.close();
  }
}
