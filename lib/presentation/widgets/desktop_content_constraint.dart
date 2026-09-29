import 'package:flutter/material.dart';

import '../../core/utils/platform_layout.dart';

/// Limits content width on wide desktop layouts so forms and cards don't stretch.
class DesktopContentConstraint extends StatelessWidget {
  const DesktopContentConstraint({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (!PlatformLayout.useDesktopNavigation(context)) {
      return child;
    }

    final width = maxWidth ?? PlatformLayout.contentMaxWidth;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: SizedBox(
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
