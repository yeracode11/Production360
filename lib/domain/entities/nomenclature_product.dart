import 'package:equatable/equatable.dart';

/// Номенклатура из каталога p360 (перемещение, списание, инвентаризация, производство).
class NomenclatureProduct extends Equatable {
  const NomenclatureProduct({
    required this.id,
    required this.name,
    required this.code,
    required this.unit,
    this.isGroup = false,
    this.parentId,
    this.showInMobileApp = true,
    this.usagePlaces = const [],
  });

  final String id;
  final String name;
  final String code;
  final String unit;
  final bool isGroup;
  final String? parentId;
  final bool showInMobileApp;
  final List<NomenclatureUsagePlace> usagePlaces;

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        unit,
        isGroup,
        parentId,
        showInMobileApp,
        usagePlaces,
      ];
}

class NomenclatureUsagePlace extends Equatable {
  const NomenclatureUsagePlace({
    required this.type,
    required this.id,
    required this.name,
  });

  final String type;
  final String id;
  final String name;

  @override
  List<Object?> get props => [type, id, name];
}
