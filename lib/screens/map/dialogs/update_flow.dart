import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_version.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../utils/update_check.dart';
import 'map_workflow_dialogs.dart';

/// In-app update check and releases-page navigation.
///
/// The flow owns no state: it performs the GitHub releases request itself and
/// reports user-facing outcomes through [onShowSnackBar]. The caller passes
/// the owning screen's [context] so mounted checks after asynchronous gaps
/// match the screen's lifetime, and localization and dialogs resolve against
/// the same context.
class UpdateFlow {
  const UpdateFlow({required this.context, required this.onShowSnackBar});

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  /// Queries GitHub releases and offers to download a newer version.
  Future<void> checkForUpdates() async {
    try {
      final response = await http
          .get(Uri.parse(updateCheckApiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final releases = jsonDecode(response.body) as List<dynamic>;
        final latestVersion = latestVersionFromReleaseTags(
          releases
              .whereType<Map<String, dynamic>>()
              .map((release) => release['tag_name'])
              .whereType<String>(),
        );

        if (!context.mounted) return;
        if (latestVersion == null) {
          onShowSnackBar(AppLocalizations.of(context).mapCouldNotCheckUpdates);
        } else if (!isNewerAppVersion(latestVersion, appVersion)) {
          onShowSnackBar(AppLocalizations.of(context).mapOnLatestVersion);
        } else {
          final shouldDownload = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => UpdateAvailableDialog(
              latestVersion: latestVersion,
              currentVersion: appVersion,
            ),
          );
          if (shouldDownload == true) await openGitHub();
        }
      } else {
        if (!context.mounted) return;
        onShowSnackBar(AppLocalizations.of(context).mapCouldNotCheckUpdates);
      }
    } on SocketException {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapNoInternetTryAgain);
    } on TimeoutException {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapUpdateCheckTimedOut);
    } catch (_) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapCouldNotCheckUpdates);
    }
  }

  /// Opens the releases page in an external browser.
  Future<void> openGitHub() async {
    final url = Uri.parse(updateCheckReleasesUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapCouldNotOpenGitHub);
    }
  }
}
