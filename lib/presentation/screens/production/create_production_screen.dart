import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/quantity_input.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../domain/entities/create_production_request.dart';
import '../../../domain/entities/nomenclature_product.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/entities/transfer_predata.dart';
import '../../../domain/repositories/production_repository.dart';
import '../../bloc/production/production_cubit.dart';
import '../../widgets/add_nomenclature_button.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/document_author_row.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../production/production_details_screen.dart';
import '../transfers/select_recipient_warehouse_screen.dart';

class CreateProductionScreen extends StatefulWidget {
  const CreateProductionScreen({super.key, required this.warehouse});

  final Warehouse warehouse;

  @override
  State<CreateProductionScreen> createState() => _CreateProductionScreenState();
}

class _CreateProductionScreenState extends State<CreateProductionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final List<_ProductionLineRow> _lines = [];
  TransferPredata? _predata;
  TransferWarehouseOption? _selectedRawMaterialsWarehouse;
  bool _isLoadingPredata = true;
  String? _predataError;
  bool _isSaving = false;
  String? _createdDocumentId;

  @override
  void initState() {
    super.initState();
    _loadPredata();
  }

  Future<void> _loadPredata() async {
    setState(() {
      _isLoadingPredata = true;
      _predataError = null;
    });

    try {
      final predata = await sl<ProductionRepository>().fetchPredata(
        warehouseId: widget.warehouse.id,
      );
      if (!mounted) return;
      setState(() {
        _predata = predata;
        _selectedRawMaterialsWarehouse = null;
        _isLoadingPredata = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _predataError = exceptionMessage(e);
        _isLoadingPredata = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _addProduct(NomenclatureProduct product) {
    final existing = _lines.where((l) => l.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      final row = existing.first;
      final current = parseAmount(row.quantityController.text) ?? 0;
      row.quantityController.text = formatQuantityForInput(current + 1);
      setState(() {});
    } else {
      setState(() {
        final row = _ProductionLineRow(product: product);
        row.quantityController.text = '1';
        _lines.add(row);
      });
    }
  }

  void _removeLine(_ProductionLineRow row) {
    setState(() {
      row.dispose();
      _lines.remove(row);
    });
  }

  void _removeProduct(NomenclatureProduct product) {
    final matches =
        _lines.where((line) => line.product.id == product.id).toList();
    if (matches.isEmpty) return;
    _removeLine(matches.first);
  }

  bool _isProductInLines(String productId) {
    return _lines.any((line) => line.product.id == productId);
  }

  num? _productQuantity(String productId) {
    for (final row in _lines) {
      if (row.product.id == productId) {
        return parseAmount(row.quantityController.text) ?? 1;
      }
    }
    return null;
  }

  void _changeProductQuantity(NomenclatureProduct product, num quantity) {
    if (quantity <= 0) {
      _removeProduct(product);
      return;
    }

    final text = formatQuantityForInput(quantity);
    final existing =
        _lines.where((line) => line.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantityController.text = text;
      setState(() {});
      return;
    }

    setState(() {
      final row = _ProductionLineRow(product: product);
      row.quantityController.text = text;
      _lines.add(row);
    });
  }

  Future<void> _submit() async {
    if (_selectedRawMaterialsWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectRawMaterialsWarehouse)),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final items = <CreateProductionItemRequest>[];
    for (final row in _lines) {
      final amount = parseAmount(row.quantityController.text);
      if (amount == null || amount <= 0) continue;
      items.add(
        CreateProductionItemRequest(
          productId: row.product.id,
          amount: amount.toDouble(),
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
      title: AppStrings.confirmCreateProduction,
    );
    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      final result = await sl<ProductionRepository>().createProduction(
        CreateProductionRequest(
          productsWarehouseId: widget.warehouse.id,
          rawMaterialsWarehouseId: _selectedRawMaterialsWarehouse!.id,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          items: items,
        ),
      );

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      context.read<ProductionCubit>().refreshCurrentWarehouse();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.productionCreated}: ${result.number}',
          ),
        ),
      );
      setState(() => _createdDocumentId = result.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exceptionMessage(e)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = _createdDocumentId;

    if (_isLoadingPredata) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.createProductionTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_predataError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.createProductionTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _predataError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadPredata,
                  child: const Text(AppStrings.pullToRefresh),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          created != null
              ? AppStrings.productionDetailsTitle
              : AppStrings.createProductionTitle,
        ),
      ),
      body: created != null
          ? ProductionDetailsScreen(
              productionId: created,
              embedded: true,
            )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    final predata = _predata!;
    final rawWarehouseOptions = predata.availableWarehouses;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: DismissKeyboard.onTap(
              context,
              SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                                labelText: AppStrings.organization,
                              ),
                              child: Text(predata.organizationName),
                            ),
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: AppStrings.productionWarehouse,
                              ),
                              child: Text(widget.warehouse.name),
                            ),
                            const SizedBox(height: 12),
                            if (rawWarehouseOptions.isEmpty)
                              Text(
                                AppStrings.noWarehouses,
                                style: TextStyle(color: AppColors.error),
                              )
                            else
                              _buildRawMaterialsSelector(rawWarehouseOptions),
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
                    Text(
                      AppStrings.productionItems,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    AddNomenclatureButton(
                      organizationId: predata.organizationId,
                      onProductSelected: _addProduct,
                      onProductRemoved: _removeProduct,
                      isProductAdded: _isProductInLines,
                      productQuantity: _productQuantity,
                      onQuantityChanged: _changeProductQuantity,
                    ),
                    const SizedBox(height: 12),
                    if (_lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          AppStrings.productionSearchPrompt,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      )
                    else
                      for (final row in _lines)
                        _ProductionLineCard(
                          row: row,
                          onRemove: () => _removeLine(row),
                        ),
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
                      : const Text(AppStrings.createProduction),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRawMaterialsSelector(
    List<TransferWarehouseOption> warehouses,
  ) async {
    FocusScope.of(context).unfocus();
    final selected = await Navigator.of(context).push<TransferWarehouseOption>(
      MaterialPageRoute(
        builder: (_) => SelectRecipientWarehouseScreen(
          title: AppStrings.rawMaterialsWarehouse,
          warehouses: warehouses,
          selected: _selectedRawMaterialsWarehouse,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedRawMaterialsWarehouse = selected);
    }
  }

  Widget _buildRawMaterialsSelector(List<TransferWarehouseOption> warehouses) {
    final selected = _selectedRawMaterialsWarehouse;

    return InkWell(
      onTap: () => _openRawMaterialsSelector(warehouses),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: AppStrings.rawMaterialsWarehouse,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected?.name ?? AppStrings.selectRawMaterialsWarehouse,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductionLineRow {
  _ProductionLineRow({required this.product});

  final NomenclatureProduct product;
  final quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}

class _ProductionLineCard extends StatelessWidget {
  const _ProductionLineCard({required this.row, required this.onRemove});

  final _ProductionLineRow row;
  final VoidCallback onRemove;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: AppStrings.removeItem,
                  onPressed: onRemove,
                ),
              ],
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
            TextFormField(
              controller: row.quantityController,
              decoration: InputDecoration(
                labelText: AppStrings.itemQuantity,
                suffix: product.unit.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          product.unit,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.turquoiseDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      )
                    : null,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [QuantityInputFormatter()],
              validator: (v) => validateQuantityInput(v, required: true),
            ),
          ],
        ),
      ),
    );
  }
}
