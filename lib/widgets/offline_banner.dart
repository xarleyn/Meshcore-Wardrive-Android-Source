import 'package:flutter/material.dart';

import '../services/internet_connectivity_service.dart';

/// Adds a compact, app-wide offline banner above the navigator.
class OfflineAppFrame extends StatelessWidget {
  const OfflineAppFrame({
    super.key,
    required this.connectivity,
    required this.child,
  });

  final InternetConnectivityService connectivity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) {
        if (!connectivity.isOffline) return child;

        final colors = Theme.of(context).colorScheme;
        return Column(
          children: [
            Material(
              color: colors.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: 'You are offline. Local tracking continues.',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 18,
                          color: colors.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "You're offline - local tracking continues",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
