/// Номера документов 1С (НФ…) не показываем как название позиции заказа.
bool isNfOrderNumberLabel(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  return trimmed.toUpperCase().startsWith('НФ');
}

String? orderItemDisplayName(String name) {
  if (isNfOrderNumberLabel(name)) {
    return null;
  }
  return name.trim().isEmpty ? null : name.trim();
}

/// Код номенклатуры 1С (НФ-…) не показываем в форме создания заказа.
String? productCodeDisplayLabel(String code) {
  if (isNfOrderNumberLabel(code)) {
    return null;
  }
  final trimmed = code.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final _deliveryServiceNamePattern = RegExp(
  r'^-?\s*доставка',
  caseSensitive: false,
);

/// Услуги доставки из 1С («-доставка 1500», «Доставка Экспресс»).
bool isDeliveryServiceProductName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  return _deliveryServiceNamePattern.hasMatch(trimmed);
}

bool isServiceProductType(String? productType) {
  return productType?.trim().toLowerCase() == 'услуга';
}

/// Позиции, которые можно выбирать при создании заказа (только товары, не услуги).
bool isSelectableCreateOrderProduct({
  required String name,
  String? productType,
}) {
  if (isDeliveryServiceProductName(name)) {
    return false;
  }
  if (isServiceProductType(productType)) {
    return false;
  }
  return orderItemDisplayName(name) != null;
}
