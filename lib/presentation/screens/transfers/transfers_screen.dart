import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../domain/entities/order_type_product.dart';
import '../../../domain/repositories/catalog_repository.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<OrderTypeProduct> _results = [];
  bool _isSearching = false;
  String? _error;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && _results.isNotEmpty) {
        setState(() {
          _results = [];
          _error = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _isSearching = false;
        _lastQuery = '';
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _isSearching = true;
      _error = null;
      _lastQuery = query;
    });

    try {
      final results = await sl<CatalogRepository>().searchNomenclature(query);
      if (!mounted || _lastQuery != query) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted || _lastQuery != query) return;
      setState(() {
        _error = exceptionMessage(e);
        _results = [];
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _results = [];
      _error = null;
      _isSearching = false;
      _lastQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.cream,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppStrings.nomenclatureSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: AppStrings.clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        if (_isSearching)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz, size: 56, color: AppColors.deepBrownLight),
              const SizedBox(height: 16),
              Text(
                AppStrings.transfersSearchPrompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isSearching && _results.isEmpty) {
      return Center(
        child: Text(
          AppStrings.nomenclatureNoResults,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _NomenclatureSearchTile(product: _results[index]);
      },
    );
  }
}

class _NomenclatureSearchTile extends StatelessWidget {
  const _NomenclatureSearchTile({required this.product});

  final OrderTypeProduct product;

  @override
  Widget build(BuildContext context) {
    final codeLabel = productCodeDisplayLabel(product.code);

    return Card(
      child: ListTile(
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (codeLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                codeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (product.unit.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                product.unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
        isThreeLine: codeLabel != null && product.unit.isNotEmpty,
      ),
    );
  }
}
