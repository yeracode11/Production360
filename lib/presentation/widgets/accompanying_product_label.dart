import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// Badge для видов заявок с `forInfo: true` (сопутствующий товар).
class AccompanyingProductLabel extends StatelessWidget {
  const AccompanyingProductLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.turquoise.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        AppStrings.accompanyingProduct,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.turquoiseDark,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}
