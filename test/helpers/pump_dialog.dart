import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';

import 'l10n_harness.dart';

/// Pumps a localized scaffold hosting a single [buttonLabel] button whose
/// handler runs [open] — the shared harness of the dialog widget tests —
/// and returns the localized strings for asserting dialog labels.
Future<AppLocalizations> pumpDialog(
  WidgetTester tester,
  FutureOr<void> Function(BuildContext context) open, {
  String buttonLabel = 'Open',
}) {
  return pumpWithL10n(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => open(context),
          child: Text(buttonLabel),
        ),
      ),
    ),
  );
}

/// Taps the [buttonLabel] button and settles the opened dialog route.
Future<void> openDialog(
  WidgetTester tester, {
  String buttonLabel = 'Open',
}) async {
  await tester.tap(find.text(buttonLabel));
  await tester.pumpAndSettle();
}
