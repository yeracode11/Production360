/// Lifecycle states for procurement orders.
enum OrderStatus {
  pendingConfirmation,
  pendingDelivery,
  completed,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendingConfirmation:
        return 'Ожидание подтверждения';
      case OrderStatus.pendingDelivery:
        return 'Ожидание доставки';
      case OrderStatus.completed:
        return 'Завершен';
    }
  }
}
