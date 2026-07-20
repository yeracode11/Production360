import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/quantity_input.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../domain/entities/create_transfer_request.dart';
import '../../../domain/entities/nomenclature_product.dart';
import '../../../domain/entities/transfer_predata.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/repositories/transfer_repository.dart';
import '../../bloc/transfers/transfers_cubit.dart';
import '../../widgets/add_nomenclature_button.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/dismiss_keyboard.dart';
import 'select_recipient_warehouse_screen.dart';

class CreateTransferScreen extends StatefulWidget {
  const CreateTransferScreen({super.key, required this.warehouse});

  final Warehouse warehouse;

  @override
  State<CreateTransferScreen> createState() => _CreateTransferScreenState();
}

class _CreateTransferScreenState extends State<CreateTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  TransferPredata? _predata;
  TransferWarehouseOption? _selectedRecipient;
  final List<_TransferLineRow> _lines = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPredata();
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPredata() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final predata = await sl<TransferRepository>().fetchPredata(
        warehouseId: widget.warehouse.id,
      );
      if (!mounted) return;
      setState(() {
        _predata = predata;
        _selectedRecipient = predata.availableWarehouses.isNotEmpty
            ? predata.availableWarehouses.first
            : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = exceptionMessage(e);
        _isLoading = false;
      });
    }
  }

  void _addProduct(NomenclatureProduct product) {
    final existing = _lines.where((l) => l.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      final row = existing.first;
      final current = parseAmount(row.quantityController.text) ?? 0;
      row.quantityController.text = (current + 1).toString();
      setState(() {});
    } else {
      setState(() {
        final row = _TransferLineRow(product: product);
        row.quantityController.text = '1';
        _lines.add(row);
      });
    }
  }

  void _removeLine(_TransferLineRow row) {
    setState(() {
      row.dispose();
      _lines.remove(row);
    });
  }

  Future<void> _submit() async {
    if (_selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectRecipientWarehouse)),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final items = <CreateTransferItemRequest>[];
    for (final row in _lines) {
      final amount = parseAmount(row.quantityController.text);
      if (amount == null || amount <= 0) continue;
      items.add(
        CreateTransferItemRequest(
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
      title: AppStrings.confirmCreateTransfer,
    );
    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      final result = await sl<TransferRepository>().createTransfer(
        CreateTransferRequest(
          senderWarehouseId: widget.warehouse.id,
          clientWarehouseId: _selectedRecipient!.id,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          items: items,
        ),
      );

      if (!mounted) return;
      context.read<TransfersCubit>().refreshCurrentWarehouse();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.transferCreated}: ${result.number}',
          ),
        ),
      );
      Navigator.of(context).pop(true);
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
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createTransferTitle)),
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
              onPressed: _loadPredata,
              child: const Text(AppStrings.pullToRefresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final predata = _predata!;

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
                              labelText: AppStrings.warehouseSender,
                            ),
                            child: Text(widget.warehouse.name),
                          ),
                          const SizedBox(height: 12),
                          if (predata.availableWarehouses.isEmpty)
                            Text(
                              AppStrings.noRecipientWarehouses,
                              style: TextStyle(color: AppColors.error),
                            )
                          else
                            _buildRecipientSelector(predata),
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
                  Text(
                    AppStrings.transferItems,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AddNomenclatureButton(
                    organizationId: predata.organizationId,
                    onProductSelected: _addProduct,
                    isProductAdded: _isProductInLines,
                  ),
                  const SizedBox(height: 12),
                  if (_lines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppStrings.transfersSearchPrompt,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    )
                  else
                    for (final row in _lines)
                      _TransferLineCard(
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
                      : const Text(AppStrings.createTransfer),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRecipientSelector(TransferPredata predata) async {
    FocusScope.of(context).unfocus();
    final selected = await Navigator.of(context).push<TransferWarehouseOption>(
      MaterialPageRoute(
        builder: (_) => SelectRecipientWarehouseScreen(
          warehouses: predata.availableWarehouses,
          selected: _selectedRecipient,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedRecipient = selected);
    }
  }

  Widget _buildRecipientSelector(TransferPredata predata) {
    final selected = _selectedRecipient;

    return InkWell(
      onTap: () => _openRecipientSelector(predata),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: AppStrings.recipientWarehouse,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected?.name ?? AppStrings.selectRecipientWarehouse,
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

  bool _isProductInLines(String productId) {
    return _lines.any((line) => line.product.id == productId);
  }
}

class _TransferLineRow {
  _TransferLineRow({required this.product});

  final NomenclatureProduct product;
  final quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}

class _TransferLineCard extends StatelessWidget {
  const _TransferLineCard({required this.row, required this.onRemove});

  final _TransferLineRow row;
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
