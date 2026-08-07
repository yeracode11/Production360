import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_update_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/platform_layout.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  bool get _isDesktop =>
      PlatformLayout.isDesktopPlatform &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> _openStore(BuildContext context) async {
    if (_isDesktop) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.forceUpdateDesktopHint),
            duration: Duration(seconds: 8),
          ),
        );
      }
      return;
    }

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      _isDesktop
                          ? AppStrings.forceUpdateDesktopMessage
                          : AppStrings.forceUpdateMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 32),
                    if (!_isDesktop)
                      ElevatedButton(
                        onPressed: () => _openStore(context),
                        child: const Text(AppStrings.forceUpdateButton),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
