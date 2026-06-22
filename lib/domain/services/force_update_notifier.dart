/// Сигнал о необходимости принудительного обновления (из сетевого слоя).
abstract class ForceUpdateNotifier {
  Stream<void> get onForceUpdateRequired;

  void notifyForceUpdateRequired();
}
