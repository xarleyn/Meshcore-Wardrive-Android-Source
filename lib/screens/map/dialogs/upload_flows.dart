import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/models.dart';
import '../../../services/location_service.dart';
import '../../../services/tile_download_service.dart';
import '../../../services/upload_service.dart';
import '../../settings/widgets/upload_endpoint_selection_dialog.dart';
import 'offline_tile_dialogs.dart';
import 'upload_endpoint_dialog.dart';

/// Sample upload orchestration for the map screen.
///
/// The flow owns no state: it drives the endpoint selection and progress
/// dialogs against the injected [uploadService] and delegates screen-owned
/// concerns (snackbars, repeater names from screen data) to callbacks.
/// Localization, dialogs, and mounted checks resolve against the owning
/// screen's [context].
class UploadFlow {
  const UploadFlow({
    required this.context,
    required this.onShowSnackBar,
    required this.uploadService,
    required this.locationService,
    required this.repeaters,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  final UploadService uploadService;
  final LocationService locationService;

  /// Currently known repeaters used to enrich uploads with repeater names.
  final List<Repeater> Function() repeaters;

  /// Uploads all samples to the selected endpoints with a progress dialog.
  Future<void> uploadSamples() async {
    final endpoints = await uploadService.getUploadEndpoints();
    final savedSelectedSites = await uploadService.getSelectedEndpoints();
    if (!context.mounted) return;

    final selectedSites = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => UploadEndpointSelectionDialog(
        endpoints: endpoints,
        initiallySelectedNames: savedSelectedSites,
      ),
    );
    if (!context.mounted || selectedSites == null || selectedSites.isEmpty) {
      return;
    }

    // Build repeater names map from discovered repeaters and LoRa service
    final repeaterNames = <String, String>{};
    for (final repeater in repeaters()) {
      if (repeater.name != null) {
        repeaterNames[repeater.id] = repeater.name!;
      }
    }

    final loraService = locationService.loraCompanion;
    for (final contact in loraService.discoveredRepeaters) {
      if (contact.name != null && !repeaterNames.containsKey(contact.id)) {
        repeaterNames[contact.id] = contact.name!;
      }
    }

    final outcome = await showDialog<UploadProgressOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UploadProgressDialog(
        upload: (onProgress) async {
          if (selectedSites.isNotEmpty && endpoints.isNotEmpty) {
            return uploadService.uploadToSelectedEndpoints(
              endpointNames: selectedSites,
              repeaterNames: repeaterNames,
              onProgress: onProgress,
            );
          }

          final result = await uploadService.uploadAllSamples(
            repeaterNames: repeaterNames,
            onProgress: (current, total) => onProgress('', current, total),
          );
          return {UploadService.defaultEndpointName: result};
        },
      ),
    );

    if (outcome == null || !context.mounted) return;
    if (outcome.error != null) {
      onShowSnackBar(
        AppLocalizations.of(context).mapUploadError('${outcome.error}'),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          UploadResultsDialog(results: outcome.results!),
    );
  }

  /// Edits upload endpoints and their selection in a modal sheet.
  Future<void> manageUploadSites() async {
    final endpoints = await uploadService.getUploadEndpoints();
    final selectedNames = await uploadService.getSelectedEndpoints();

    if (!context.mounted) return;
    final configuration = await showModalBottomSheet<UploadSitesConfiguration>(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) => ManageUploadSitesSheet(
        initialEndpoints: endpoints,
        initiallySelectedNames: selectedNames,
      ),
    );

    if (configuration == null) return;
    await uploadService.setUploadEndpoints(configuration.endpoints);
    await uploadService.setSelectedEndpoints(configuration.selectedNames);
    if (!context.mounted) return;
    onShowSnackBar(AppLocalizations.of(context).mapUploadSitesUpdated);
  }
}

/// Community coverage download orchestration for the map screen.
///
/// The flow owns no state: it picks the endpoint, downloads (or falls back to
/// the cached) coverage, and hands the raw coverage map to [onCoverageLoaded]
/// for the screen to apply.
class CommunityCoverageFlow {
  const CommunityCoverageFlow({
    required this.context,
    required this.onShowSnackBar,
    required this.uploadService,
    required this.onCoverageLoaded,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  final UploadService uploadService;

  /// Applies downloaded coverage on the screen.
  final void Function(Map<String, dynamic> coverage) onCoverageLoaded;

  /// Downloads community coverage from the chosen endpoint, falling back to
  /// the cached copy on failure.
  Future<void> downloadCommunityCoverage() async {
    // Get endpoint to download from
    final endpoints = await uploadService.getUploadEndpoints();

    UploadEndpoint? selectedEndpoint;
    if (endpoints.length == 1) {
      selectedEndpoint = endpoints.first;
    } else {
      // Let user pick which endpoint to download from
      if (!context.mounted) return;
      selectedEndpoint = await showDialog<UploadEndpoint>(
        context: context,
        builder: (dialogContext) =>
            CommunityCoverageEndpointDialog(endpoints: endpoints),
      );
    }

    if (selectedEndpoint == null) return;

    if (!context.mounted) return;
    onShowSnackBar(AppLocalizations.of(context).mapDownloadingCoverage);

    final data = await uploadService.downloadCoverage(
      selectedEndpoint.url,
      onProgress: (current, total) {
        // Update snackbar with progress (won't stack, just shows latest)
      },
    );
    if (data != null && data['coverage'] != null) {
      final coverage = data['coverage'] as Map<String, dynamic>;
      onCoverageLoaded(coverage);
      if (!context.mounted) return;
      onShowSnackBar(
        AppLocalizations.of(context)
            .mapDownloadedCoverageCells(coverage.length),
      );
    } else {
      // Try loading from cache
      final cached = await uploadService.loadCachedCoverage();
      if (cached != null && cached['coverage'] != null) {
        onCoverageLoaded(cached['coverage'] as Map<String, dynamic>);
        if (!context.mounted) return;
        onShowSnackBar(AppLocalizations.of(context).mapLoadedCachedCoverage);
      } else {
        if (!context.mounted) return;
        onShowSnackBar(
          AppLocalizations.of(context).mapDownloadFailed(
            uploadService.lastDownloadError ??
                AppLocalizations.of(context).mapUnknownError,
          ),
        );
      }
    }
  }
}

/// Offline tile download orchestration for the map screen.
///
/// The flow owns no state: it reads the visible map region and theme through
/// callbacks, runs the options and progress dialogs, and drives the
/// [TileDownloadService].
class OfflineTileFlow {
  const OfflineTileFlow({
    required this.context,
    required this.onShowSnackBar,
    required this.hasTileCache,
    required this.getVisibleBounds,
    required this.getCameraZoom,
    required this.usesDarkMapTiles,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  /// Whether the offline tile cache has been initialized.
  final bool Function() hasTileCache;

  /// The currently visible map bounds.
  final LatLngBounds Function() getVisibleBounds;

  /// The current camera zoom.
  final double Function() getCameraZoom;

  /// Whether dark basemap tiles should be downloaded.
  final bool Function() usesDarkMapTiles;

  /// Downloads the visible region's tiles for offline use.
  Future<void> downloadOfflineTiles() async {
    if (!hasTileCache()) {
      onShowSnackBar(AppLocalizations.of(context).mapTileCacheNotInitialized);
      return;
    }

    final bounds = getVisibleBounds();
    final currentZoom = getCameraZoom().floor();
    final isDarkMode = usesDarkMapTiles();

    final options = await showDialog<OfflineTileDownloadOptions>(
      context: context,
      builder: (dialogContext) =>
          OfflineTileDownloadDialog(bounds: bounds, initialZoom: currentZoom),
    );

    if (options == null || !context.mounted) return;

    final urlTemplate = isDarkMode
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final cacheDir =
        '${(await getApplicationDocumentsDirectory()).path}/tile_cache';
    final downloader = TileDownloadService(cacheDir);
    final totalTiles = TileDownloadService.estimateTileCount(
      bounds.southWest,
      bounds.northEast,
      options.minZoom,
      options.maxZoom,
    );

    if (!context.mounted) return;
    final outcome = await showDialog<OfflineTileDownloadOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => OfflineTileDownloadProgressDialog(
        totalTiles: totalTiles,
        download: (onProgress) => downloader.downloadTiles(
          sw: bounds.southWest,
          ne: bounds.northEast,
          minZoom: options.minZoom,
          maxZoom: options.maxZoom,
          urlTemplate: urlTemplate,
          onProgress: onProgress,
        ),
        onCancel: downloader.cancel,
      ),
    );

    if (outcome == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    if (outcome.cancelled) {
      onShowSnackBar(l10n.mapDownloadCancelled(outcome.completed));
    } else {
      onShowSnackBar(l10n.mapDownloadedTiles(outcome.succeeded, totalTiles));
    }
  }
}
