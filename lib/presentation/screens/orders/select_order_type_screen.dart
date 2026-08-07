import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/order_type.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/accompanying_product_label.dart';
import 'create_order_screen.dart';

/// Loads order types from 1C GET /mobile/zayavka/types.
class SelectOrderTypeScreen extends StatefulWidget {
  const SelectOrderTypeScreen({super.key, required this.warehouse});

  final Warehouse warehouse;

  @override
  State<SelectOrderTypeScreen> createState() => _SelectOrderTypeScreenState();
}

class _SelectOrderTypeScreenState extends State<SelectOrderTypeScreen> {
  List<OrderType> _types = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final types = await sl<OrderRepository>().fetchOrderTypes(
        warehouseId: widget.warehouse.id,
      );
      setState(() {
        _types = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _openCreateForm(OrderType orderType) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          warehouse: widget.warehouse,
          orderType: orderType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithKeyboard(title: AppStrings.createOrderTitle),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderSection(warehouseName: widget.warehouse.name),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadTypes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.pullToRefresh,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
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

    if (_types.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTypes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: Center(
                child: Text(
                  AppStrings.noOrderTypes,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.deepBrownLight,
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTypes,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final type in _types)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OrderTypeCard(
                orderType: type,
                onTap: () => _openCreateForm(type),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.warehouseName});

  final String warehouseName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceMuted),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, size: 18, color: AppColors.turquoiseDark),
              const SizedBox(width: 6),
              Text(
                AppStrings.orderingFor,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            warehouseName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.selectOrderType,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.selectOrderTypeHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _OrderTypeCard extends StatelessWidget {
  const _OrderTypeCard({
    required this.orderType,
    required this.onTap,
  });

  final OrderType orderType;
  final VoidCallback onTap;

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('сырь')) return Icons.grain_outlined;
    if (lower.contains('пирож')) return Icons.cake_outlined;
    return Icons.assignment_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.surfaceMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(orderType.name),
                  color: AppColors.turquoiseDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderType.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (orderType.forInfo) ...[
                      const SizedBox(height: 4),
                      const AccompanyingProductLabel(),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.turquoise,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
