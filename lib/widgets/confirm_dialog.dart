import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Shows a Cancel/Confirm dialog that resolves to true only when the confirm
/// action was tapped. The confirm label is rendered in the error color when
/// [destructive] is set.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              confirmLabel,
              style: destructive ? const TextStyle(color: Colors.red) : null,
            ),
          ),
        ],
      );
    },
  );
}
