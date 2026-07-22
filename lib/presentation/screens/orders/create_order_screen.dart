import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/quantity_input.dart';
import '../../../domain/entities/create_order_request.dart';
import '../../../domain/entities/delivery_date_option.dart';
import '../../../domain/entities/order_type.dart';
import '../../../domain/entities/order_type_data.dart';
import '../../../domain/entities/order_type_product.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../bloc/orders/orders_cubit.dart';
import '../../widgets/accompanying_product_label.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/document_author_row.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/order_create_preview_item.dart';
import 'create_order_preview_screen.dart';

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
  CreateOrderPreviewData? _createdOrderPreview;

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
    if (!_formKey.currentState!.validate()) return;

    final items = _collectOrderItems();
    if (items == null) return;

    final confirmed = await showConfirmActionDialog(
      context,
      title: AppStrings.confirmCreateOrder,
    );
    if (!confirmed) return;

    await _performCreateOrder(items);
  }

  Future<void> _previewOrder() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deliveryDateRequired)),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final items = _collectOrderItems();
    if (items == null) return;

    final typeData = _typeData!;
    final previewItems = _buildPreviewItems(items);

    final shouldCreate = await openCreateOrderPreviewScreen(
      context,
      data: CreateOrderPreviewData(
        warehouseName: widget.warehouse.name,
        orderTypeName: typeData.name,
        orderTypeForInfo: typeData.forInfo,
        organizationName: typeData.organizationName,
        supplierWarehouseName: typeData.warehouseName,
        deliveryDate: _selectedDate!.display,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        items: previewItems,
      ),
    );

    if (shouldCreate == true && mounted) {
      await _submit();
    }
  }

  List<CreateOrderItemRequest>? _collectOrderItems() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deliveryDateRequired)),
      );
      return null;
    }

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
      return null;
    }

    return items;
  }

  List<OrderCreatePreviewItem> _buildPreviewItems(
    List<CreateOrderItemRequest> items,
  ) {
    final previewItems = <OrderCreatePreviewItem>[];
    for (final item in items) {
      final row = _productRows.firstWhere(
        (r) => r.product.id == item.productId,
      );
      final product = row.product;
      previewItems.add(
        OrderCreatePreviewItem(
          name: product.name,
          code: product.code,
          quantity: item.amount,
          unit: product.unit,
        ),
      );
    }
    return previewItems;
  }

  CreateOrderPreviewData _buildPreviewData(List<CreateOrderItemRequest> items) {
    final typeData = _typeData!;
    return CreateOrderPreviewData(
      warehouseName: widget.warehouse.name,
      orderTypeName: typeData.name,
      orderTypeForInfo: typeData.forInfo,
      organizationName: typeData.organizationName,
      supplierWarehouseName: typeData.warehouseName,
      deliveryDate: _selectedDate!.display,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      items: _buildPreviewItems(items),
    );
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
        FocusScope.of(context).unfocus();
        context.read<OrdersCubit>().refreshCurrentWarehouse();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.orderCreated)),
        );
        setState(() => _createdOrderPreview = _buildPreviewData(items));
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
    final created = _createdOrderPreview;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          created != null
              ? AppStrings.orderDetailsTitle
              : AppStrings.createOrderTitle,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorBody()
              : created != null
                  ? CreateOrderPreviewContent(data: created)
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
            child: DismissKeyboard.onTap(
              context,
              RefreshIndicator(
                onRefresh: _loadTypeData,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(typeData.name),
                                  if (typeData.forInfo) ...[
                                    const SizedBox(height: 4),
                                    const AccompanyingProductLabel(),
                                  ],
                                ],
                              ),
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
                                  labelText: AppStrings.shipmentDate,
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
                            const SizedBox(height: 12),
                            const CurrentUserAuthorRow(),
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
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _previewOrder,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: AppColors.turquoiseDark,
                        side: const BorderSide(
                          color: AppColors.turquoise,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text(
                        AppStrings.previewReceipt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        backgroundColor: AppColors.turquoiseDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              AppStrings.createOrderAction,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ],
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
              inputFormatters: const [QuantityInputFormatter()],
              validator: (v) => validateQuantityInput(v),
            ),
          ],
        ),
      ),
    );
  }
}
