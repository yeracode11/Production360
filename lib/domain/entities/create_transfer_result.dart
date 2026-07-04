import 'package:equatable/equatable.dart';

/// Ответ POST /mobile/internaltransfer/create при success.
class CreateTransferResult extends Equatable {
  const CreateTransferResult({
    required this.id,
    required this.number,
    required this.date,
    required this.isPosted,
    this.dateDisplay,
  });

  final String id;
  final String number;
  final DateTime date;
  final bool isPosted;
  final String? dateDisplay;

  @override
  List<Object?> get props => [id, number, date, isPosted, dateDisplay];
}
