import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/offline_tile_dialogs.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('offline tile options return a typed zoom range', (tester) async {
    OfflineTileDownloadOptions? result;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<OfflineTileDownloadOptions>(
                context: context,
                builder: (context) => OfflineTileDownloadDialog(
                  bounds: LatLngBounds(
                    const LatLng(55.7, 37.5),
                    const LatLng(55.8, 37.7),
                  ),
                  initialZoom: 10,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.mapDownload));
    await tester.pumpAndSettle();

    expect(result?.minZoom, 10);
    expect(result?.maxZoom, 13);
  });

  testWidgets('offline progress starts download once and returns outcome', (
    tester,
  ) async {
    OfflineTileDownloadOutcome? result;
    var starts = 0;
    await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<OfflineTileDownloadOutcome>(
                context: context,
                barrierDismissible: false,
                builder: (context) => OfflineTileDownloadProgressDialog(
                  totalTiles: 2,
                  download: (onProgress) async {
                    starts++;
                    onProgress(1, 2);
                    await Future<void>.delayed(Duration.zero);
                    onProgress(2, 2);
                    return 2;
                  },
                  onCancel: () {},
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(starts, 1);
    expect(result?.cancelled, isFalse);
    expect(result?.succeeded, 2);
  });
}
