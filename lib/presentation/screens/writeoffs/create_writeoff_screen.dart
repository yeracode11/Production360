import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/quantity_input.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../domain/entities/create_writeoff_request.dart';
import '../../../domain/entities/nomenclature_product.dart';
import '../../../domain/entities/writeoff_predata.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/repositories/writeoff_repository.dart';
import '../../bloc/writeoffs/writeoffs_cubit.dart';
import '../../widgets/add_nomenclature_button.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/document_author_row.dart';
import '../../widgets/document_screen_scaffold.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/on_screen_keyboard/on_screen_keyboard_field.dart';
import 'select_writeoff_reason_screen.dart';
import 'writeoff_details_screen.dart';

class CreateWriteoffScreen extends StatefulWidget {
  const CreateWriteoffScreen({super.key, required this.warehouse});

  final Warehouse warehouse;

  @override
  State<CreateWriteoffScreen> createState() => _CreateWriteoffScreenState();
}

class _CreateWriteoffScreenState extends State<CreateWriteoffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  WriteoffPredata? _predata;
  WriteoffReasonOption? _selectedReason;
  final List<_WriteoffLineRow> _lines = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _createdDocumentId;
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
      final predata = await sl<WriteoffRepository>().fetchPredata(
        warehouseId: widget.warehouse.id,
      );
      if (!mounted) return;
      setState(() {
        _predata = predata;
        _selectedReason = null;
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
      row.quantityController.text = formatQuantityForInput(current + 1);
      setState(() {});
    } else {
      setState(() {
        final row = _WriteoffLineRow(product: product);
        row.quantityController.text = '1';
        _lines.add(row);
      });
    }
  }

  void _removeLine(_WriteoffLineRow row) {
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

  void _changeProductQuantity(NomenclatureProduct product, num? quantity) {
    if (quantity == null || quantity <= 0) {
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
      final row = _WriteoffLineRow(product: product);
      row.quantityController.text = text;
      _lines.add(row);
    });
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectWriteoffReason)),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final items = <CreateWriteoffItemRequest>[];
    for (final row in _lines) {
      final amount = parseAmount(row.quantityController.text);
      if (amount == null || amount <= 0) continue;
      items.add(
        CreateWriteoffItemRequest(
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
      title: AppStrings.confirmCreateWriteoff,
    );
    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      final result = await sl<WriteoffRepository>().createWriteoff(
        CreateWriteoffRequest(
          warehouseId: widget.warehouse.id,
          reasonId: _selectedReason!.id,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          items: items,
        ),
      );

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      context.read<WriteoffsCubit>().refreshCurrentWarehouse();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.writeoffCreated}: ${result.number}',
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

    return DocumentScreenScaffold(
      title: created != null
          ? AppStrings.writeoffDetailsTitle
          : AppStrings.createWriteoffTitle,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorBody()
              : created != null
                  ? WriteoffDetailsScreen(
                      writeoffId: created,
                      embedded: true,
                    )
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
                                labelText: AppStrings.warehouse,
                              ),
                              child: Text(widget.warehouse.name),
                            ),
                            const SizedBox(height: 12),
                            if (predata.availableReasons.isEmpty)
                              Text(
                                AppStrings.noWriteoffReasons,
                                style: TextStyle(color: AppColors.error),
                              )
                            else
                              _buildReasonSelector(predata),
                            const SizedBox(height: 12),
                            OnScreenKeyboardTextField(
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
                      AppStrings.writeoffItems,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    AddNomenclatureButton(
                      organizationId: _predata!.organizationId,
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
                          AppStrings.writeoffsSearchPrompt,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      )
                    else
                      for (final row in _lines)
                        _WriteoffLineCard(
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
                      : const Text(AppStrings.createWriteoff),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReasonSelector(WriteoffPredata predata) async {
    FocusScope.of(context).unfocus();
    final selected = await Navigator.of(context).push<WriteoffReasonOption>(
      MaterialPageRoute(
        builder: (_) => SelectWriteoffReasonScreen(
          reasons: predata.availableReasons,
          selected: _selectedReason,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedReason = selected);
    }
  }

  Widget _buildReasonSelector(WriteoffPredata predata) {
    final selected = _selectedReason;

    return InkWell(
      onTap: () => _openReasonSelector(predata),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppStrings.writeoffReason,
          errorText: null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                selected?.name ?? AppStrings.selectWriteoffReason,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      height: 1.35,
                      fontWeight:
                          selected == null ? FontWeight.w400 : FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WriteoffLineRow {
  _WriteoffLineRow({required this.product});

  final NomenclatureProduct product;
  final quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}

class _WriteoffLineCard extends StatelessWidget {
  const _WriteoffLineCard({required this.row, required this.onRemove});

  final _WriteoffLineRow row;
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
            OnScreenKeyboardTextField(
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
