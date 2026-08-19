# Map provider investigation

Investigation date: 2026-08-19.

## Current implementation

The app uses `flutter_map` with raster XYZ tiles:

- light map: the public OpenStreetMap standard tile service;
- dark map: the public CARTO Dark Matter endpoint;
- a shared on-device cache and a user-triggered area downloader.

This is technically simple, but the current production setup has compliance
risks that should be addressed before expanding distribution:

- The [OpenStreetMap tile usage policy](https://operations.osmfoundation.org/policies/tiles/)
  requires visible attribution and explicitly prohibits bulk downloading and
  offline prefetching from `tile.openstreetmap.org`.
- No OSM or CARTO attribution is currently rendered on the map.
- [CARTO requires attribution](https://carto.com/attribution/) to CARTO and the
  underlying data provider. Its [basemap documentation](https://docs.carto.com/faqs/carto-basemaps)
  says commercial use requires an Enterprise license and free non-commercial
  use is for CARTO grantees.

The interactive cache may remain useful when it honors the provider's HTTP
cache headers. The explicit **Download Offline Tiles** workflow must only be
enabled for a provider and plan that permits prefetching.

## Yandex options

### Yandex Tiles API

This is the smallest technical change. The official
[Tiles API](https://yandex.com/maps-api/docs/tiles-api/index.html) returns raster
tiles and supports the spherical `web_mercator` projection used by
`flutter_map`. Its documented URL parameters include `x`, `y`, `z`, language,
projection, and an API key. Existing coverage polygons, samples, repeaters,
heatmap, camera handling, and most of the tile cache can remain unchanged.

Work still required:

- obtain and securely configure a Yandex API key;
- implement a provider-specific URL builder instead of committing a key;
- add the required clickable Yandex logo and terms link;
- keep the documented request-rate limits in mind;
- verify whether the intended distribution and tracking use case qualify for
  the selected license.

The free tier is not a safe fit for the app as it exists today. Yandex's
[free-use summary](https://yandex.com/dev/commercial/doc/en/) prohibits storing
API data and real-time transport/employee monitoring, requires branding and an
"Open in Maps" control, and says map screenshots are not allowed. Those terms
conflict with offline tile downloads and the app's map screenshot feature.
Written confirmation or an appropriate commercial agreement would be needed.

### Yandex MapKit for Flutter

Yandex also provides an official
[Flutter MapKit package](https://yandex.com/maps-api/docs/mapkit/flutter/generated/getting_started.html).
It provides a native vector map, styling, and broader Yandex functionality, but
it replaces `FlutterMap`; it is not a drop-in tile URL change. Every overlay,
gesture, camera callback, screenshot path, and map lifecycle hook would need to
be ported and regression-tested. MapKit's
[offline maps](https://yandex.com/maps-api/docs/mapkit/android/generated/tutorials/map_offline.html)
are available only under a paid license.

MapKit is worthwhile only if Yandex-native features or licensed offline Yandex
maps are a product requirement. For a basemap-only change, Tiles API is much
less invasive.

## Other candidates

| Option | Current overlay reuse | Offline/prefetch | Main trade-off |
| --- | --- | --- | --- |
| Licensed raster XYZ provider | High | Contract-dependent | Small code change, but recurring service and API-key dependency |
| MapTiler Cloud raster tiles | High | Bulk download prohibited by default | Straightforward authenticated XYZ API; offline requires a separate agreement or self-hosting |
| Mapbox Maps SDK for Flutter | Low | Supported by the SDK within account limits | Strong native vector/offline support, but requires a map-widget and overlay rewrite |
| MapLibre plus licensed/self-hosted vector tiles | Low to medium | Supported when the tile source license allows it | No vendor-locked renderer; more migration and data-hosting work |
| Self-hosted OSM-derived raster XYZ | High | Under project control | Best fit for the existing widget and downloader, but the project owns tile generation, hosting, updates, and capacity |

References:

- [MapTiler XYZ Tiles API](https://docs.maptiler.com/cloud/api/tiles/) and
  [cloud terms](https://www.maptiler.com/terms/cloud/), which prohibit bulk tile
  downloading without a separate agreement.
- [Mapbox Maps SDK for Flutter](https://docs.mapbox.com/flutter/maps/guides/)
  and its [offline map example](https://docs.mapbox.com/flutter/maps/examples/offline/).
- [MapLibre Native offline regions API](https://maplibre.org/maplibre-native/android/api/-map-libre%20-native%20-android/org.maplibre.android.offline/index.html).

## Recommendation

1. First make the basemap a provider configuration with explicit attribution,
   allowed-cache behavior, light/dark styles, and an `allowsOfflineDownload`
   capability.
2. Disable the area downloader for the public OSM and current CARTO endpoints
   until the service terms explicitly permit it.
3. For the lowest migration cost, evaluate a licensed raster XYZ provider or a
   self-hosted OSM-derived raster service. The current overlays can stay intact.
4. Run a Yandex Tiles API proof of concept only after license clarification for
   wardriving, screenshots, and offline behavior. Do not use undocumented
   Yandex tile endpoints.
5. Choose Yandex MapKit, Mapbox, or MapLibre only as a deliberate second-stage
   renderer migration, with a spike covering coverage polygons, heatmap,
   markers, rotation/follow mode, screenshots, and offline regions.

The recommended near-term architecture is therefore provider-neutral raster
XYZ with compliant attribution and per-provider capability flags. It keeps the
existing Flutter map logic and leaves a later vector-renderer migration open.
