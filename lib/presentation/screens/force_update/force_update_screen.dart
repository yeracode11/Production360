import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_update_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _openStore(BuildContext context) async {
    final urls = Platform.isIOS
        ? [
            AppUpdateConfig.iosAppStoreDeepLink,
            AppUpdateConfig.iosAppStoreUrl,
            AppUpdateConfig.iosAppStoreSearchUrl,
          ]
        : [
            AppUpdateConfig.androidMarketUrl,
            AppUpdateConfig.androidPlayStoreUrl,
          ];

    for (final url in urls) {
      final uri = Uri.parse(url);
      try {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) {
          return;
        }
      } catch (_) {
        continue;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Platform.isIOS
                ? AppUpdateConfig.iosAppStoreUrl
                : AppUpdateConfig.androidPlayStoreUrl,
          ),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: AppStrings.close,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Icon(
                  Icons.system_update_alt,
                  size: 72,
                  color: AppColors.turquoiseDark,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.forceUpdateTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.forceUpdateMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openStore(context),
                    child: const Text(AppStrings.forceUpdateButton),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
