import 'package:equatable/equatable.dart';

import 'order_type_product.dart';

/// Страница номенклатуры из GET /nomenclature/search.
class NomenclaturePage extends Equatable {
  const NomenclaturePage({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });

  final List<OrderTypeProduct> items;
  final int total;
  final int offset;
  final int limit;

  bool get hasMore => offset + items.length < total;

  int get nextOffset => offset + items.length;

  @override
  List<Object?> get props => [items, total, offset, limit];
}
