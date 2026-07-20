import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/exception_message.dart';
import '../../core/utils/order_item_display.dart';
import '../../domain/entities/nomenclature_product.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Поиск номенклатуры для перемещения, списания, инвентаризации, производства.
class NomenclaturePicker extends StatefulWidget {
  const NomenclaturePicker({
    super.key,
    required this.onProductSelected,
    required this.isProductAdded,
    this.batchSize = 30,
  });

  final ValueChanged<NomenclatureProduct> onProductSelected;
  final bool Function(String productId) isProductAdded;
  final int batchSize;

  @override
  State<NomenclaturePicker> createState() => _NomenclaturePickerState();
}

class _NomenclaturePickerState extends State<NomenclaturePicker> {
  final _searchController = TextEditingController();
  final List<NomenclatureProduct> _items = [];
  Timer? _searchDebounce;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _total = 0;
  int _nextOffset = 0;
  String? _error;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _items.clear();
      _nextOffset = 0;
      _hasMore = false;
      _total = 0;
    });

    try {
      final page = await sl<CatalogRepository>().searchNomenclature(
        query: _activeQuery.isEmpty ? null : _activeQuery,
        limit: widget.batchSize,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _nextOffset = page.nextOffset;
        _hasMore = page.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = exceptionMessage(e);
        _items.clear();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _error = null;
    });

    try {
      final page = await sl<CatalogRepository>().searchNomenclature(
        query: _activeQuery.isEmpty ? null : _activeQuery,
        limit: widget.batchSize,
        offset: _nextOffset,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _nextOffset = page.nextOffset;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = exceptionMessage(e);
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    final query = value.trim();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_activeQuery == query) return;
      _activeQuery = query;
      _loadInitial();
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {});
    if (_activeQuery.isEmpty) return;
    _activeQuery = '';
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

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
        if (_isLoading) ...[
          const SizedBox(height: 8),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          _Panel(
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: _loadInitial,
                  child: const Text(AppStrings.pullToRefresh),
                ),
              ],
            ),
          ),
        ],
        if (!_isLoading && _error == null && _items.isEmpty) ...[
          const SizedBox(height: 8),
          _Panel(
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
        ],
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    _activeQuery.isEmpty
                        ? '${AppStrings.nomenclatureShown}: ${_items.length}'
                            '${_total > 0 ? ' ${AppStrings.nomenclatureOf} $_total' : ''}'
                        : '${AppStrings.searchResultsFound}: ${_items.length}'
                            '${_total > 0 ? ' ${AppStrings.nomenclatureOf} $_total' : ''}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.turquoiseDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ...List.generate(_items.length, (index) {
                  final product = _items[index];
                  final isLast = index == _items.length - 1 && !_hasMore;
                  return _ProductTile(
                    product: product,
                    isAdded: widget.isProductAdded(product.id),
                    onTap: () => widget.onProductSelected(product),
                    showDivider: !isLast || _hasMore,
                  );
                }),
                if (_hasMore) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoadingMore ? null : _loadMore,
                      child: _isLoadingMore
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '${AppStrings.loadMoreNomenclature}'
                              ' (${widget.batchSize})',
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

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

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.isAdded,
    this.showDivider = true,
  });

  final NomenclatureProduct product;
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
                                _MetaChip(icon: Icons.tag, label: codeLabel),
                              if (product.unit.isNotEmpty)
                                _MetaChip(
                                  icon: Icons.straighten,
                                  label: product.unit,
                                ),
                            ],
                          ),
                        ],
                        if (product.usagePlaces.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final place in product.usagePlaces)
                                _MetaChip(
                                  icon: place.type.toLowerCase() == 'warehouse'
                                      ? Icons.warehouse_outlined
                                      : Icons.business_outlined,
                                  label: place.name,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AddButton(isAdded: isAdded),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

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

class _AddButton extends StatelessWidget {
  const _AddButton({required this.isAdded});

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
