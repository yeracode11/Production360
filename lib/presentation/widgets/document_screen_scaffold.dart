import 'package:flutter/material.dart';

import 'app_bar_with_keyboard.dart';

/// Scaffold для экранов документов.
class DocumentScreenScaffold extends StatelessWidget {
  const DocumentScreenScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.actions = const [],
    this.bottom,
    this.leading,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithKeyboard(
        title: title,
        titleWidget: titleWidget,
        actions: actions,
        bottom: bottom,
        leading: leading,
      ),
      body: body,
    );
  }
}
