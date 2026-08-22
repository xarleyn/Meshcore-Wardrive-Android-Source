import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/tile_download_service.dart';

class OfflineTileDownloadOptions {
  const OfflineTileDownloadOptions({
    required this.minZoom,
    required this.maxZoom,
  });

  final int minZoom;
  final int maxZoom;
}

class OfflineTileDownloadOutcome {
  const OfflineTileDownloadOutcome.completed({required this.succeeded})
    : cancelled = false,
      completed = 0;

  const OfflineTileDownloadOutcome.cancelled({required this.completed})
    : cancelled = true,
      succeeded = 0;

  final bool cancelled;
  final int completed;
  final int succeeded;
}

typedef OfflineTileDownload = Future<int> Function(
  void Function(int done, int total) onProgress,
);

class OfflineTileDownloadDialog extends StatefulWidget {
  const OfflineTileDownloadDialog({
    required this.bounds,
    required this.initialZoom,
    super.key,
  });

  final LatLngBounds bounds;
  final int initialZoom;

  @override
  State<OfflineTileDownloadDialog> createState() =>
      _OfflineTileDownloadDialogState();
}

class _OfflineTileDownloadDialogState extends State<OfflineTileDownloadDialog> {
  late int _minZoom;
  late int _maxZoom;

  @override
  void initState() {
    super.initState();
    _minZoom = widget.initialZoom.clamp(3, 18);
    _maxZoom = (widget.initialZoom + 3).clamp(3, 18);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tileCount = TileDownloadService.estimateTileCount(
      widget.bounds.southWest,
      widget.bounds.northEast,
      _minZoom,
      _maxZoom,
    );
    final estimatedMb = (tileCount * 15 / 1024).toStringAsFixed(1);

    return AlertDialog(
      title: Text(l10n.settingsDownloadOfflineTiles),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mapDownloadTilesBlurb),
          const SizedBox(height: 16),
          Text(l10n.mapMinZoom('$_minZoom')),
          Slider(
            value: _minZoom.toDouble(),
            min: 3,
            max: 18,
            divisions: 15,
            label: '$_minZoom',
            onChanged: (value) {
              setState(() {
                _minZoom = value.round();
                if (_maxZoom < _minZoom) _maxZoom = _minZoom;
              });
            },
          ),
          Text(l10n.mapMaxZoom('$_maxZoom')),
          Slider(
            value: _maxZoom.toDouble(),
            min: 3,
            max: 18,
            divisions: 15,
            label: '$_maxZoom',
            onChanged: (value) {
              setState(() {
                _maxZoom = value.round();
                if (_minZoom > _maxZoom) _minZoom = _maxZoom;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.mapTilesEstimate(tileCount, estimatedMb),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (tileCount > 5000)
            Text(
              l10n.mapLargeDownloadWarning,
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.settingsCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            OfflineTileDownloadOptions(minZoom: _minZoom, maxZoom: _maxZoom),
          ),
          child: Text(l10n.mapDownload),
        ),
      ],
    );
  }
}

class OfflineTileDownloadProgressDialog extends StatefulWidget {
  const OfflineTileDownloadProgressDialog({
    required this.totalTiles,
    required this.download,
    required this.onCancel,
    super.key,
  });

  final int totalTiles;
  final OfflineTileDownload download;
  final VoidCallback onCancel;

  @override
  State<OfflineTileDownloadProgressDialog> createState() =>
      _OfflineTileDownloadProgressDialogState();
}

class _OfflineTileDownloadProgressDialogState
    extends State<OfflineTileDownloadProgressDialog> {
  int _completed = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_startDownload());
  }

  Future<void> _startDownload() async {
    final succeeded = await widget.download((done, _) {
      if (!mounted) return;
      setState(() => _completed = done);
    });
    if (!mounted) return;
    Navigator.pop(
      context,
      OfflineTileDownloadOutcome.completed(succeeded: succeeded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = widget.totalTiles > 0
        ? _completed / widget.totalTiles
        : 0.0;

    return AlertDialog(
      title: Text(l10n.mapDownloadingTiles),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 12),
          Text(l10n.mapTilesProgress(_completed, widget.totalTiles)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancel();
            Navigator.pop(
              context,
              OfflineTileDownloadOutcome.cancelled(completed: _completed),
            );
          },
          child: Text(l10n.settingsCancel),
        ),
      ],
    );
  }
}
