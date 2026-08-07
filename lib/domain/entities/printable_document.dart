import 'package:equatable/equatable.dart';

/// Унифицированное представление документа для печати на чековом принтере.
class PrintableDocument extends Equatable {
  const PrintableDocument({
    required this.title,
    required this.warehouseId,
    this.subtitle,
    this.fields = const [],
    this.items = const [],
    this.footer,
  });

  final String title;
  final String warehouseId;
  final String? subtitle;
  final List<PrintableField> fields;
  final List<PrintableItem> items;
  final String? footer;

  @override
  List<Object?> get props => [title, warehouseId, subtitle, fields, items, footer];
}

class PrintableField extends Equatable {
  const PrintableField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  List<Object?> get props => [label, value];
}

class PrintableItem extends Equatable {
  const PrintableItem({
    required this.name,
    required this.quantityLabel,
    this.code,
  });

  final String name;
  final String quantityLabel;
  final String? code;

  @override
  List<Object?> get props => [name, quantityLabel, code];
}
