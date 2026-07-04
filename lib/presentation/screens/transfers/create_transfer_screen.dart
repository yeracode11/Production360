import 'dart:async';

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
import '../../../domain/entities/order_type_product.dart';
import '../../../domain/entities/transfer_predata.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/repositories/transfer_repository.dart';
import '../../bloc/transfers/transfers_cubit.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/dismiss_keyboard.dart';

class CreateTransferScreen extends StatefulWidget {
  const CreateTransferScreen({super.key, required this.warehouse});

  final Warehouse warehouse;

  @override
  State<CreateTransferScreen> createState() => _CreateTransferScreenState();
}

class _CreateTransferScreenState extends State<CreateTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _searchController = TextEditingController();

  TransferPredata? _predata;
  TransferWarehouseOption? _selectedRecipient;
  final List<_TransferLineRow> _lines = [];
  List<OrderTypeProduct> _searchResults = [];
  Timer? _searchDebounce;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSaving = false;
  String? _loadError;
  String? _searchError;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPredata();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
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

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
        _isSearching = false;
        _lastSearchQuery = '';
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
      _lastSearchQuery = query;
    });

    try {
      final results = await sl<CatalogRepository>().searchNomenclature(query);
      if (!mounted || _lastSearchQuery != query) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted || _lastSearchQuery != query) return;
      setState(() {
        _searchError = exceptionMessage(e);
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _addProduct(OrderTypeProduct product) {
    final existing = _lines.where((l) => l.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      final row = existing.first;
      final current = parseAmount(row.quantityController.text) ?? 0;
      row.quantityController.text = (current + 1).toString();
    } else {
      setState(() {
        final row = _TransferLineRow(product: product);
        row.quantityController.text = '1';
        _lines.add(row);
      });
    }
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _searchError = null;
    });
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
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: AppStrings.recipientWarehouse,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<TransferWarehouseOption>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: _selectedRecipient,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.textSecondary,
                                  ),
                                  selectedItemBuilder: (context) {
                                    return predata.availableWarehouses
                                        .map(
                                          (w) => Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              w.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                        )
                                        .toList();
                                  },
                                  items: predata.availableWarehouses
                                      .map(
                                        (w) => DropdownMenuItem(
                                          value: w,
                                          child: Text(
                                            w.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedRecipient = value);
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
                  Text(
                    AppStrings.addProduct,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildNomenclatureSearchSection(context),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.transferItems,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
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

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _searchError = null;
      _isSearching = false;
      _lastSearchQuery = '';
    });
  }

  bool _isProductInLines(String productId) {
    return _lines.any((line) => line.product.id == productId);
  }

  Widget _buildNomenclatureSearchSection(BuildContext context) {
    final query = _searchController.text.trim();
    final showResultsPanel = query.isNotEmpty && !_isSearching;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: AppStrings.nomenclatureSearchHint,
            prefixIcon: Icon(Icons.search, color: AppColors.turquoiseDark),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: AppStrings.clearSearch,
                    onPressed: _clearSearch,
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceCard,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surfaceMuted),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.turquoise,
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_isSearching) ...[
          const SizedBox(height: 8),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        ],
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          _SearchPanel(
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _searchError!,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showResultsPanel && _searchError == null && _searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _SearchPanel(
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.nomenclatureNoResults,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (showResultsPanel && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SearchPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    '${AppStrings.searchResultsFound}: ${_searchResults.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.turquoiseDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ...List.generate(_searchResults.length, (index) {
                  final product = _searchResults[index];
                  final isLast = index == _searchResults.length - 1;
                  return _SearchResultTile(
                    product: product,
                    isAdded: _isProductInLines(product.id),
                    onTap: () => _addProduct(product),
                    showDivider: !isLast,
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TransferLineRow {
  _TransferLineRow({required this.product});

  final OrderTypeProduct product;
  final quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: child,
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.product,
    required this.onTap,
    required this.isAdded,
    this.showDivider = true,
  });

  final OrderTypeProduct product;
  final VoidCallback onTap;
  final bool isAdded;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final codeLabel = productCodeDisplayLabel(product.code);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceMuted),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: AppColors.turquoiseDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        if (codeLabel != null || product.unit.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (codeLabel != null)
                                _ProductMetaChip(
                                  icon: Icons.tag,
                                  label: codeLabel,
                                ),
                              if (product.unit.isNotEmpty)
                                _ProductMetaChip(
                                  icon: Icons.straighten,
                                  label: product.unit,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AddProductButton(isAdded: isAdded),
                ],
              ),
              if (showDivider) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: AppColors.surfaceMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductMetaChip extends StatelessWidget {
  const _ProductMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _AddProductButton extends StatelessWidget {
  const _AddProductButton({required this.isAdded});

  final bool isAdded;

  @override
  Widget build(BuildContext context) {
    if (isAdded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              AppStrings.productAdded,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.turquoise,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.turquoise.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 22),
    );
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
