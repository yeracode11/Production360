import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/nomenclature_product.dart';
import 'app_bar_with_keyboard.dart';
import 'nomenclature_picker.dart';

/// Полноэкранный выбор номенклатуры: группы → товары + глобальный поиск.
class SelectNomenclatureScreen extends StatefulWidget {
  const SelectNomenclatureScreen({
    super.key,
    required this.organizationId,
    required this.onProductSelected,
    required this.onProductRemoved,
    required this.isProductAdded,
    this.productQuantity,
    this.onQuantityChanged,
    this.allowZeroQuantity = false,
    this.quantityEmptyOnAdd = false,
  });

  final String organizationId;
  final ValueChanged<NomenclatureProduct> onProductSelected;
  final ValueChanged<NomenclatureProduct> onProductRemoved;
  final bool Function(String productId) isProductAdded;
  final num? Function(String productId)? productQuantity;
  final void Function(NomenclatureProduct product, num? quantity)?
      onQuantityChanged;
  final bool allowZeroQuantity;
  final bool quantityEmptyOnAdd;

  @override
  State<SelectNomenclatureScreen> createState() =>
      _SelectNomenclatureScreenState();
}

class _SelectNomenclatureScreenState extends State<SelectNomenclatureScreen> {
  String _title = AppStrings.nomenclatureRootGroups;
  final Set<String> _addedDuringSession = {};
  final Set<String> _removedDuringSession = {};
  final Map<String, num?> _quantitiesDuringSession = {};

  bool _isProductAdded(String productId) {
    if (_removedDuringSession.contains(productId)) return false;
    return widget.isProductAdded(productId) ||
        _addedDuringSession.contains(productId);
  }

  num? _resolveQuantity(String productId) {
    if (_removedDuringSession.contains(productId)) return null;
    if (_quantitiesDuringSession.containsKey(productId)) {
      return _quantitiesDuringSession[productId];
    }
    return widget.productQuantity?.call(productId);
  }

  void _handleProductSelected(NomenclatureProduct product) {
    if (widget.onQuantityChanged != null) {
      if (widget.quantityEmptyOnAdd) {
        if (_isProductAdded(product.id)) return;
        widget.onProductSelected(product);
        setState(() {
          _removedDuringSession.remove(product.id);
          _addedDuringSession.add(product.id);
          _quantitiesDuringSession.remove(product.id);
        });
        return;
      }
      final current = _resolveQuantity(product.id) ?? 0;
      _handleQuantityChanged(product, current + 1);
      return;
    }

    widget.onProductSelected(product);
    setState(() {
      _removedDuringSession.remove(product.id);
      _addedDuringSession.add(product.id);
    });
  }

  void _handleProductRemoved(NomenclatureProduct product) {
    widget.onProductRemoved(product);
    setState(() {
      _addedDuringSession.remove(product.id);
      _removedDuringSession.add(product.id);
      _quantitiesDuringSession.remove(product.id);
    });
  }

  void _handleQuantityChanged(NomenclatureProduct product, num? quantity) {
    if (quantity == null) {
      if (!widget.quantityEmptyOnAdd) {
        _handleProductRemoved(product);
        return;
      }
      widget.onQuantityChanged?.call(product, null);
      setState(() {
        _removedDuringSession.remove(product.id);
        _addedDuringSession.add(product.id);
        _quantitiesDuringSession[product.id] = null;
      });
      return;
    }

    if (quantity < 0 || (!widget.allowZeroQuantity && quantity <= 0)) {
      _handleProductRemoved(product);
      return;
    }

    widget.onQuantityChanged?.call(product, quantity);

    setState(() {
      _removedDuringSession.remove(product.id);
      _addedDuringSession.add(product.id);
      _quantitiesDuringSession[product.id] = quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithKeyboard(
        titleWidget: Text(_title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox.expand(
            child: NomenclaturePicker(
              organizationId: widget.organizationId,
              onTitleChanged: (title) {
                if (_title == title) return;
                setState(() => _title = title);
              },
              onProductSelected: _handleProductSelected,
              onProductRemoved: _handleProductRemoved,
              isProductAdded: _isProductAdded,
              productQuantity: _resolveQuantity,
              onQuantityChanged: widget.onQuantityChanged == null
                  ? null
                  : _handleQuantityChanged,
              allowZeroQuantity: widget.allowZeroQuantity,
              quantityEmptyOnAdd: widget.quantityEmptyOnAdd,
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка «Добавить товар» — открывает [SelectNomenclatureScreen].
class AddNomenclatureButton extends StatelessWidget {
  const AddNomenclatureButton({
    super.key,
    required this.organizationId,
    required this.onProductSelected,
    required this.onProductRemoved,
    required this.isProductAdded,
    this.productQuantity,
    this.onQuantityChanged,
    this.allowZeroQuantity = false,
    this.quantityEmptyOnAdd = false,
  });

  final String organizationId;
  final ValueChanged<NomenclatureProduct> onProductSelected;
  final ValueChanged<NomenclatureProduct> onProductRemoved;
  final bool Function(String productId) isProductAdded;
  final num? Function(String productId)? productQuantity;
  final void Function(NomenclatureProduct product, num? quantity)?
      onQuantityChanged;
  final bool allowZeroQuantity;
  final bool quantityEmptyOnAdd;

  Future<void> _openPicker(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SelectNomenclatureScreen(
          organizationId: organizationId,
          isProductAdded: isProductAdded,
          onProductSelected: onProductSelected,
          onProductRemoved: onProductRemoved,
          productQuantity: productQuantity,
          onQuantityChanged: onQuantityChanged,
          allowZeroQuantity: allowZeroQuantity,
          quantityEmptyOnAdd: quantityEmptyOnAdd,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = organizationId.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? () => _openPicker(context) : null,
        icon: Icon(Icons.add, color: AppColors.turquoiseDark),
        label: const Text(AppStrings.addProduct),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.turquoise.withValues(alpha: 0.5)),
          foregroundColor: AppColors.turquoiseDark,
        ),
      ),
    );
  }
}
