import 'dart:async';

import '../../domain/services/force_update_notifier.dart';

class ForceUpdateNotifierImpl implements ForceUpdateNotifier {
  final _controller = StreamController<void>.broadcast();

  @override
  Stream<void> get onForceUpdateRequired => _controller.stream;

  @override
  void notifyForceUpdateRequired() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() {
    _controller.close();
  }
}
