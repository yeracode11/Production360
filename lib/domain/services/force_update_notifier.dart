/// Сигнал о необходимости принудительного обновления (из сетевого слоя).
abstract class ForceUpdateNotifier {
  Stream<void> get onForceUpdateRequired;

  /// true, если сигнал уже был до подписки UI.
  bool get isUpdateRequired;

  void notifyForceUpdateRequired();
}
