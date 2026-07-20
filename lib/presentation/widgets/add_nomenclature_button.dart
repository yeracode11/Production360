import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/nomenclature_product.dart';
import 'nomenclature_picker.dart';

/// Полноэкранный поиск и выбор номенклатуры.
class SelectNomenclatureScreen extends StatelessWidget {
  const SelectNomenclatureScreen({
    super.key,
    required this.organizationId,
    required this.isProductAdded,
  });

  final String organizationId;
  final bool Function(String productId) isProductAdded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addProduct)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: NomenclaturePicker(
            organizationId: organizationId,
            onProductSelected: (product) {
              Navigator.of(context).pop(product);
            },
            isProductAdded: isProductAdded,
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
    required this.isProductAdded,
  });

  final String organizationId;
  final ValueChanged<NomenclatureProduct> onProductSelected;
  final bool Function(String productId) isProductAdded;

  Future<void> _openPicker(BuildContext context) async {
    final product = await Navigator.of(context).push<NomenclatureProduct>(
      MaterialPageRoute(
        builder: (_) => SelectNomenclatureScreen(
          organizationId: organizationId,
          isProductAdded: isProductAdded,
        ),
      ),
    );
    if (product != null) {
      onProductSelected(product);
    }
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
