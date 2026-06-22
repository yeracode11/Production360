import '../../models/order_request_model.dart';

/// In-memory storage for orders created via app forms.
class LocalDataStore {
  final List<OrderRequestModel> orders = [];
}
