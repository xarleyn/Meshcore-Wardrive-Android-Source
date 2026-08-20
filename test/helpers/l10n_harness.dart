import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';

Future<AppLocalizations> pumpWithL10n(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale('en'),
}) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return home;
        },
      ),
    ),
  );
  return l10n;
}
