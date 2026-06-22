import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../domain/entities/create_order_request.dart';
import '../../../domain/entities/delivery_date_option.dart';
import '../../../domain/entities/order_type.dart';
import '../../../domain/entities/order_type_data.dart';
import '../../../domain/entities/order_type_product.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../bloc/orders/orders_cubit.dart';
import '../../widgets/confirm_action_dialog.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({
    super.key,
    required this.warehouse,
    required this.orderType,
  });

  final Warehouse warehouse;
  final OrderType orderType;

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  OrderTypeData? _typeData;
  DeliveryDateOption? _selectedDate;
  List<_ProductRow> _productRows = [];
  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTypeData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (final row in _productRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTypeData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    for (final row in _productRows) {
      row.dispose();
    }
    _productRows = [];

    try {
      final data = await sl<OrderRepository>().fetchOrderTypeData(
        orderTypeId: widget.orderType.uid,
        warehouseId: widget.warehouse.id,
      );
      final rows = data.products
          .where(
            (product) => isSelectableCreateOrderProduct(name: product.name),
          )
          .map((product) => _ProductRow(product: product))
          .toList();

      setState(() {
        _typeData = data;
        _productRows = rows;
        _selectedDate = data.dates.isNotEmpty ? data.dates.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deliveryDateRequired)),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final items = <CreateOrderItemRequest>[];
    for (final row in _productRows) {
      final amount = formatAmountFor1C(row.quantityController.text);
      if (amount == null) continue;
      items.add(
        CreateOrderItemRequest(
          productId: row.product.id,
          amount: amount,
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.atLeastOneItem)),
      );
      return;
    }

    final confirmed = await showConfirmActionDialog(
      context,
      message: AppStrings.confirmCreateOrder,
    );
    if (!confirmed) return;

    await _performCreateOrder(items);
  }

  Future<void> _performCreateOrder(List<CreateOrderItemRequest> items) async {
    setState(() => _isSaving = true);

    try {
      final typeData = _typeData!;

      final request = CreateOrderRequest(
        skladClientId: widget.warehouse.id,
        organizationId: typeData.organizationId,
        skladId: typeData.warehouseId,
        orderTypeId: typeData.id,
        date: _selectedDate!.value,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        items: items,
      );

      await sl<OrderRepository>().createOrder(request);

      if (mounted) {
        context.read<OrdersCubit>().refreshCurrentWarehouse();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.orderCreated)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createOrderTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorBody()
              : _buildForm(),
    );
  }

  Widget _buildErrorBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTypeData,
              child: const Text(AppStrings.pullToRefresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final typeData = _typeData!;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTypeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.mainInfo,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: AppStrings.customer,
                              ),
                              child: Text(widget.warehouse.name),
                            ),
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: AppStrings.orderType,
                              ),
                              child: Text(typeData.name),
                            ),
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: AppStrings.organization,
                              ),
                              child: Text(typeData.organizationName),
                            ),
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: AppStrings.warehouse,
                              ),
                              child: Text(typeData.warehouseName),
                            ),
                            const SizedBox(height: 12),
                            if (typeData.dates.isEmpty)
                              Text(
                                AppStrings.noDeliveryDates,
                                style: TextStyle(color: AppColors.error),
                              )
                            else
                              InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: AppStrings.deliveryDate,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<DeliveryDateOption>(
                                    isExpanded: true,
                                    value: _selectedDate,
                                    items: typeData.dates
                                        .map(
                                          (d) => DropdownMenuItem(
                                            value: d,
                                            child: Text(d.display),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedDate = value);
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _commentController,
                              maxLines: null,
                              minLines: 2,
                              decoration: const InputDecoration(
                                labelText: AppStrings.comment,
                                hintText: AppStrings.commentHint,
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_productRows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          AppStrings.noProducts,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      )
                    else
                      for (final row in _productRows)
                        _ProductCard(row: row),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(AppStrings.createOrder),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow {
  _ProductRow({required this.product});

  final OrderTypeProduct product;
  final quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.row});

  final _ProductRow row;

  @override
  Widget build(BuildContext context) {
    final product = row.product;
    final codeLabel = productCodeDisplayLabel(product.code);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (codeLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                codeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            if (product.stockBalance.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.stockBalance}: ${product.stockBalance} ${product.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else if (product.unit.isNotEmpty) ...[
              Text(
                product.unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: row.quantityController,
              decoration: InputDecoration(
                labelText: AppStrings.itemQuantity,
                hintText: product.unit,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final amount = parseAmount(v);
                if (amount == null || amount <= 0) {
                  return AppStrings.itemQuantityInvalid;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
