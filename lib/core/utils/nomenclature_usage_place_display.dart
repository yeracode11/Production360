import '../../core/constants/app_strings.dart';

/// Подпись типа места использования (`organization`, `warehouse`, …).
String nomenclatureUsagePlaceTypeLabel(String type) {
  switch (type.trim().toLowerCase()) {
    case 'organization':
      return AppStrings.organization;
    case 'warehouse':
      return AppStrings.warehouse;
    default:
      if (type.trim().isEmpty) return AppStrings.productionUsagePlace;
      return type.trim();
  }
}
