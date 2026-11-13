import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/inventory_completed_storage.dart';
import '../../../core/storage/inventory_draft_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/quantity_input.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../domain/entities/create_inventory_request.dart';
import '../../../domain/entities/nomenclature_product.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/entities/writeoff_predata.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../../domain/repositories/writeoff_repository.dart';
import '../../bloc/inventory/inventory_cubit.dart';
import '../../widgets/add_nomenclature_button.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/document_author_row.dart';
import '../../widgets/document_screen_scaffold.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/on_screen_keyboard/on_screen_keyboard_field.dart';
class CreateInventoryScreen extends StatefulWidget {
  const CreateInventoryScreen({super.key, required this.warehouse});

  final Warehouse warehouse;

  @override
  State<CreateInventoryScreen> createState() => _CreateInventoryScreenState();
}

class _CreateInventoryScreenState extends State<CreateInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final List<_InventoryLineRow> _lines = [];
  WriteoffPredata? _predata;
  bool _isLoadingPredata = true;
  String? _predataError;
  bool _isSaving = false;
  bool _isLeaving = false;

  /// Снимок состояния на момент последнего сохранения/восстановления черновика.
  String _savedSignature = '';

  InventoryDraftStorage get _draftStorage => sl<InventoryDraftStorage>();

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _savedSignature = _currentSignature();
    _loadPredata();
  }

  void _restoreDraft() {
    final draft = _draftStorage.read(widget.warehouse.id);
    if (draft == null) return;
    _commentController.text = draft.comment;
    for (final item in draft.items) {
      final row = _InventoryLineRow(product: item.product);
      row.quantityController.text = item.quantityText;
      _lines.add(row);
    }
  }

  InventoryDraft _buildDraft() {
    return InventoryDraft(
      warehouseId: widget.warehouse.id,
      comment: _commentController.text,
      savedAt: DateTime.now(),
      items: [
        for (final row in _lines)
          InventoryDraftItem(
            product: row.product,
            quantityText: row.quantityController.text.trim(),
          ),
      ],
    );
  }

  String _currentSignature() {
    final buffer = StringBuffer(_commentController.text.trim());
    for (final row in _lines) {
      buffer
        ..write('|')
        ..write(row.product.id)
        ..write('=')
        ..write(row.quantityController.text.trim());
    }
    return buffer.toString();
  }

  bool get _hasUnsavedChanges =>
      !_isLeaving && _currentSignature() != _savedSignature;

  Future<void> _saveDraft({bool showMessage = true}) async {
    final draft = _buildDraft();
    if (draft.isEmpty) {
      await _draftStorage.delete(widget.warehouse.id);
    } else {
      await _draftStorage.save(draft);
    }
    _savedSignature = _currentSignature();
    if (!mounted || !showMessage) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.inventoryDraftSaved)),
    );
  }

  Future<void> _saveDraftAndLeave() async {
    FocusScope.of(context).unfocus();
    await _saveDraft();
    if (!mounted) return;
    _isLeaving = true;
    Navigator.of(context).pop(false);
  }

  /// Выход с экрана с несохранёнными изменениями: спросить про черновик.
  Future<void> _handleLeaveRequest() async {
    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.inventoryDraftLeaveTitle),
        content: const Text(AppStrings.inventoryDraftLeaveMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_LeaveChoice.cancel),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_LeaveChoice.discard),
            child: Text(
              AppStrings.inventoryDraftDiscard,
              style: TextStyle(color: AppColors.error),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(_LeaveChoice.save),
            child: const Text(AppStrings.saveInventoryDraft),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _LeaveChoice.save:
        await _saveDraftAndLeave();
      case _LeaveChoice.discard:
        // «Не сохранять» — предыдущий сохранённый черновик (если был) остаётся.
        setState(() => _isLeaving = true);
        Navigator.of(context).pop(false);
      case _LeaveChoice.cancel:
      case null:
        break;
    }
  }

  Future<void> _loadPredata() async {
    setState(() {
      _isLoadingPredata = true;
      _predataError = null;
    });

    try {
      final predata = await sl<WriteoffRepository>().fetchPredata(
        warehouseId: widget.warehouse.id,
      );
      if (!mounted) return;
      setState(() {
        _predata = predata;
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
    if (_lines.any((line) => line.product.id == product.id)) return;
    setState(() {
      _lines.add(_InventoryLineRow(product: product));
    });
  }

  void _removeLine(_InventoryLineRow row) {
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
        final text = row.quantityController.text.trim();
        if (text.isEmpty) return null;
        return parseAmount(text);
      }
    }
    return null;
  }

  void _changeProductQuantity(NomenclatureProduct product, num? quantity) {
    if (quantity != null && quantity < 0) {
      _removeProduct(product);
      return;
    }

    final text =
        quantity == null ? '' : formatQuantityForInput(quantity);
    final existing =
        _lines.where((line) => line.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantityController.text = text;
      setState(() {});
      return;
    }

    setState(() {
      final row = _InventoryLineRow(product: product);
      row.quantityController.text = text;
      _lines.add(row);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final items = <CreateInventoryItemRequest>[];
    for (final row in _lines) {
      final amount = parseAmount(row.quantityController.text.trim());
      if (amount == null || amount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.itemQuantityRequired)),
        );
        return;
      }
      items.add(
        CreateInventoryItemRequest(
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
      title: AppStrings.confirmCreateInventory,
    );
    if (!confirmed) return;

    setState(() => _isSaving = true);

    var leaveScreen = false;
    try {
      final result = await sl<InventoryRepository>().createInventory(
        CreateInventoryRequest(
          warehouseId: widget.warehouse.id,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          items: items,
        ),
      );

      if (!mounted) return;
      leaveScreen = true;
      _isLeaving = true;
      FocusScope.of(context).unfocus();
      await sl<InventoryCompletedStorage>().markCompleted(result.id);
      await _draftStorage.delete(widget.warehouse.id);
      if (!mounted) return;
      context.read<InventoryCubit>().refreshCurrentWarehouse();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.inventoryCreated}: ${result.number}',
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
      if (mounted && !leaveScreen) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPredata) {
      return const DocumentScreenScaffold(
        title: AppStrings.createInventoryTitle,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_predataError != null) {
      return DocumentScreenScaffold(
        title: AppStrings.createInventoryTitle,
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

    return PopScope(
      // Ввод количества не вызывает rebuild, поэтому решаем в колбэке.
      // Navigator.pop() из кода PopScope не блокирует.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isSaving) return;
        if (!_hasUnsavedChanges) {
          _isLeaving = true;
          Navigator.of(context).pop(false);
          return;
        }
        _handleLeaveRequest();
      },
      child: DocumentScreenScaffold(
        title: AppStrings.createInventoryTitle,
        actions: [
          IconButton(
            tooltip: AppStrings.saveInventoryDraft,
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: _isSaving ? null : _saveDraftAndLeave,
          ),
        ],
        body: _buildForm(),
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
                      AppStrings.inventoryItems,
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
                      allowZeroQuantity: true,
                      quantityEmptyOnAdd: true,
                    ),
                    const SizedBox(height: 12),
                    if (_lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          AppStrings.inventorySearchPrompt,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      )
                    else
                      for (final row in _lines)
                        _InventoryLineCard(
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
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _saveDraftAndLeave,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.turquoiseDark,
                          side: const BorderSide(
                            color: AppColors.turquoise,
                            width: 1.2,
                          ),
                          backgroundColor:
                              AppColors.mintSoft.withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.saveInventoryDraftShort,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppStrings.createInventory,
                                  maxLines: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LeaveChoice { save, discard, cancel }

class _InventoryLineRow {
  _InventoryLineRow({required this.product});

  final NomenclatureProduct product;
  final quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}

class _InventoryLineCard extends StatelessWidget {
  const _InventoryLineCard({required this.row, required this.onRemove});

  final _InventoryLineRow row;
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
              validator: (v) =>
                  validateQuantityInput(v, required: true, allowZero: true),
            ),
          ],
        ),
      ),
    );
  }
}
