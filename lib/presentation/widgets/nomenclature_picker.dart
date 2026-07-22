import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/exception_message.dart';
import '../../domain/entities/nomenclature_product.dart';
import '../../domain/repositories/catalog_repository.dart';
import 'nomenclature_quantity_stepper.dart';

class _BrowseLevel {
  const _BrowseLevel({this.id, this.name = AppStrings.nomenclatureRootGroups});

  final String? id;
  final String name;
}

/// Иерархический выбор номенклатуры: группы → подгруппы → товары + глобальный поиск.
class NomenclaturePicker extends StatefulWidget {
  const NomenclaturePicker({
    super.key,
    required this.organizationId,
    required this.onProductSelected,
    required this.onProductRemoved,
    required this.isProductAdded,
    this.productQuantity,
    this.onQuantityChanged,
    this.onTitleChanged,
    this.batchSize = 30,
    this.allowZeroQuantity = false,
  });

  final String organizationId;
  final ValueChanged<NomenclatureProduct> onProductSelected;
  final ValueChanged<NomenclatureProduct> onProductRemoved;
  final bool Function(String productId) isProductAdded;
  final num? Function(String productId)? productQuantity;
  final void Function(NomenclatureProduct product, num quantity)?
      onQuantityChanged;
  final ValueChanged<String>? onTitleChanged;
  final int batchSize;
  final bool allowZeroQuantity;

  @override
  State<NomenclaturePicker> createState() => _NomenclaturePickerState();
}

class _NomenclaturePickerState extends State<NomenclaturePicker> {
  final _searchController = TextEditingController();
  final List<NomenclatureProduct> _groups = [];
  final List<NomenclatureProduct> _products = [];
  final List<NomenclatureProduct> _searchItems = [];
  final List<_BrowseLevel> _breadcrumb = [_BrowseLevel()];

  Timer? _searchDebounce;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = false;
  int _productsTotal = 0;
  int _productsOffset = 0;
  int _searchTotal = 0;
  int _searchOffset = 0;
  bool _searchHasMore = false;
  String? _error;
  String _activeQuery = '';

  bool get _isSearchMode => _activeQuery.isNotEmpty;

  String? get _currentParentId =>
      _breadcrumb.isEmpty ? null : _breadcrumb.last.id;

  @override
  void initState() {
    super.initState();
    _notifyTitle();
    _loadBrowse();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _notifyTitle() {
    widget.onTitleChanged?.call(
      _isSearchMode
          ? AppStrings.nomenclatureGlobalSearch
          : _breadcrumb.last.name,
    );
  }

  Future<void> _loadBrowse() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _groups.clear();
      _products.clear();
      _productsOffset = 0;
      _hasMoreProducts = false;
      _productsTotal = 0;
    });

    try {
      final repo = sl<CatalogRepository>();
      final groupsFuture = repo.listNomenclatureGroups(
        organizationId: widget.organizationId,
        parentId: _currentParentId,
      );

      if (_currentParentId == null) {
        final groupsPage = await groupsFuture;
        if (!mounted) return;
        setState(() {
          _groups
            ..clear()
            ..addAll(groupsPage.items.where((item) => item.isGroup));
          _isLoading = false;
        });
        return;
      }

      final productsFuture = repo.listNomenclatureProducts(
        organizationId: widget.organizationId,
        parentId: _currentParentId!,
        limit: widget.batchSize,
        offset: 0,
      );

      final results = await Future.wait([groupsFuture, productsFuture]);
      if (!mounted) return;

      final groupsPage = results[0];
      final productsPage = results[1];

      setState(() {
        _groups
          ..clear()
          ..addAll(groupsPage.items.where((item) => item.isGroup));
        _products
          ..clear()
          ..addAll(productsPage.items.where((item) => !item.isGroup));
        _productsTotal = productsPage.total;
        _productsOffset = productsPage.nextOffset;
        _hasMoreProducts = productsPage.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = exceptionMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    final parentId = _currentParentId;
    if (_isLoadingMore || !_hasMoreProducts || parentId == null) return;

    setState(() {
      _isLoadingMore = true;
      _error = null;
    });

    try {
      final page = await sl<CatalogRepository>().listNomenclatureProducts(
        organizationId: widget.organizationId,
        parentId: parentId,
        limit: widget.batchSize,
        offset: _productsOffset,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(page.items.where((item) => !item.isGroup));
        _productsTotal = page.total;
        _productsOffset = page.nextOffset;
        _hasMoreProducts = page.hasMore;
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

  Future<void> _loadSearch({required bool initial}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _error = null;
        _searchItems.clear();
        _searchOffset = 0;
        _searchTotal = 0;
        _searchHasMore = false;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    }

    try {
      final page = await sl<CatalogRepository>().searchNomenclature(
        organizationId: widget.organizationId,
        query: _activeQuery,
        limit: widget.batchSize,
        offset: initial ? 0 : _searchOffset,
      );
      if (!mounted) return;
      setState(() {
        if (initial) {
          _searchItems
            ..clear()
            ..addAll(page.items.where((item) => !item.isGroup));
        } else {
          _searchItems.addAll(page.items.where((item) => !item.isGroup));
        }
        _searchTotal = page.total;
        _searchOffset = page.nextOffset;
        _searchHasMore = page.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = exceptionMessage(e);
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _openGroup(NomenclatureProduct group) {
    if (!group.isGroup) return;
    setState(() {
      _breadcrumb.add(_BrowseLevel(id: group.id, name: group.name));
    });
    _notifyTitle();
    _loadBrowse();
  }

  void _goBack() {
    if (_breadcrumb.length <= 1) return;
    setState(() {
      _breadcrumb.removeLast();
    });
    _notifyTitle();
    _loadBrowse();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    final query = value.trim();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_activeQuery == query) return;
      _activeQuery = query;
      _notifyTitle();
      if (query.isEmpty) {
        _loadBrowse();
      } else {
        _loadSearch(initial: true);
      }
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {});
    if (_activeQuery.isEmpty) return;
    _activeQuery = '';
    _notifyTitle();
    _loadBrowse();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final listChildren = _isSearchMode ? _buildSearchList() : _buildBrowseList();

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
        if (!_isSearchMode && _breadcrumb.length > 1) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(_breadcrumb[_breadcrumb.length - 2].name),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.turquoiseDark,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ],
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
                  onPressed: _isSearchMode
                      ? () => _loadSearch(initial: true)
                      : _loadBrowse,
                  child: const Text(AppStrings.pullToRefresh),
                ),
              ],
            ),
          ),
        ],
        if (!_isLoading && _error == null && listChildren.isEmpty) ...[
          const SizedBox(height: 8),
          _Panel(
            child: Row(
              children: [
                Icon(
                  _isSearchMode
                      ? Icons.search_off_outlined
                      : Icons.folder_open_outlined,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isSearchMode
                        ? AppStrings.nomenclatureNoResults
                        : AppStrings.nomenclatureEmptyGroup,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (listChildren.isNotEmpty) ...[
          const SizedBox(height: 8),
          if (_isSearchMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                '${AppStrings.searchResultsFound}: ${_searchItems.length}'
                '${_searchTotal > 0 ? ' ${AppStrings.nomenclatureOf} $_searchTotal' : ''}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.turquoiseDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          Expanded(
            child: _Panel(
              child: ListView(
                padding: EdgeInsets.zero,
                children: listChildren,
              ),
            ),
          ),
        ] else if (!_isLoading && _error == null) ...[
          const Expanded(child: SizedBox.shrink()),
        ],
      ],
    );
  }

  List<Widget> _buildBrowseList() {
    final children = <Widget>[];

    if (_groups.isNotEmpty) {
      children.add(_SectionHeader(title: AppStrings.nomenclatureGroups));
      for (var i = 0; i < _groups.length; i++) {
        if (i > 0) {
          children.add(Divider(height: 1, color: AppColors.surfaceMuted));
        }
        children.add(_GroupTile(
          group: _groups[i],
          onTap: () => _openGroup(_groups[i]),
        ));
      }
    }

    if (_currentParentId != null) {
      if (_products.isNotEmpty) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 8));
        }
        children.add(_SectionHeader(title: AppStrings.nomenclatureProducts));
        for (var i = 0; i < _products.length; i++) {
          if (i > 0) {
            children.add(Divider(height: 1, color: AppColors.surfaceMuted));
          }
          final product = _products[i];
          children.add(_ProductTile(
            product: product,
            isAdded: widget.isProductAdded(product.id),
            quantity: widget.productQuantity?.call(product.id),
            allowZero: widget.allowZeroQuantity,
            onAdd: () => widget.onProductSelected(product),
            onRemove: () => widget.onProductRemoved(product),
            onQuantityChanged: widget.onQuantityChanged == null
                ? null
                : (value) => widget.onQuantityChanged!(product, value),
          ));
        }
        if (_hasMoreProducts) {
          children.add(const SizedBox(height: 8));
          children.add(
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoadingMore ? null : _loadMoreProducts,
                child: _isLoadingMore
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '${AppStrings.loadMoreNomenclature} (${widget.batchSize})',
                      ),
              ),
            ),
          );
        } else if (_productsTotal > 0) {
          children.add(const SizedBox(height: 8));
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(
                '${AppStrings.nomenclatureShown}: ${_products.length}'
                ' ${AppStrings.nomenclatureOf} $_productsTotal',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.turquoiseDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          );
        }
      }
    }

    return children;
  }

  List<Widget> _buildSearchList() {
    final children = <Widget>[];
    for (var i = 0; i < _searchItems.length; i++) {
      if (i > 0) {
        children.add(Divider(height: 1, color: AppColors.surfaceMuted));
      }
      final product = _searchItems[i];
      children.add(_ProductTile(
        product: product,
        isAdded: widget.isProductAdded(product.id),
        quantity: widget.productQuantity?.call(product.id),
        allowZero: widget.allowZeroQuantity,
        onAdd: () => widget.onProductSelected(product),
        onRemove: () => widget.onProductRemoved(product),
        onQuantityChanged: widget.onQuantityChanged == null
            ? null
            : (value) => widget.onQuantityChanged!(product, value),
      ));
    }

    if (_searchHasMore) {
      children.add(const SizedBox(height: 8));
      children.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoadingMore ? null : () => _loadSearch(initial: false),
            child: _isLoadingMore
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '${AppStrings.loadMoreNomenclature} (${widget.batchSize})',
                  ),
          ),
        ),
      );
    }

    return children;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.turquoiseDark,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final NomenclatureProduct group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
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
                  Icons.folder_outlined,
                  size: 20,
                  color: AppColors.turquoiseDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  group.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
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
    required this.onAdd,
    required this.onRemove,
    required this.isAdded,
    this.quantity,
    this.onQuantityChanged,
    this.allowZero = false,
  });

  final NomenclatureProduct product;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool isAdded;
  final num? quantity;
  final ValueChanged<num>? onQuantityChanged;
  final bool allowZero;

  bool get _showQuantityStepper =>
      isAdded && quantity != null && onQuantityChanged != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    if (product.unit.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _MetaChip(
                        icon: Icons.straighten,
                        label: product.unit,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_showQuantityStepper)
                NomenclatureQuantityStepper(
                  quantity: quantity!,
                  allowZero: allowZero,
                  onChanged: onQuantityChanged!,
                  onRemove: onRemove,
                )
              else
                _AddButton(
                  isAdded: isAdded,
                  onAdd: onAdd,
                  onRemove: onRemove,
                ),
            ],
          ),
        ],
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
  const _AddButton({
    required this.isAdded,
    required this.onAdd,
    required this.onRemove,
  });

  final bool isAdded;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (isAdded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.4)),
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
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: AppColors.error),
            tooltip: AppStrings.removeItem,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onRemove,
          ),
        ],
      );
    }

    return Material(
      color: AppColors.turquoise,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      shadowColor: AppColors.turquoise.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
