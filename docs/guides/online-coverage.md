# Online coverage features

Three features connect your local wardrive data to the outside world: the
community coverage overlay, web map uploads, and offline map tiles. An
app-wide offline banner tracks connectivity; everything local (GPS tracking,
radio communication, sample storage) keeps working while offline.

## Community coverage overlay

The community overlay draws coverage aggregated from other users' uploads so
you can compare your own results against theirs.

- Tiles are aligned to exact geohash bounds and use the same LOD precision as
  your local coverage, so both grids line up cell for cell.
- The overlay is independent of the session filter: it stays visible while you
  browse a single session and is hidden only by its own Map Display toggle.
- Tapping an overlay cell opens the same aggregated details as the local
  coverage cells.

## Web map uploads

Recorded samples can be uploaded to one or more web maps.

- **Endpoints** are managed in Settings: each has a name and URL, and several
  can be enabled at once. Fresh installs default to the regional
  `meshcoretel.ru` endpoint for Russian locales and `meshcoretel.io`
  elsewhere.
- Uploads send batches with retry; GPS-only samples (where no ping was
  attempted) are filtered out so they do not skew success rates on the live
  map.
- Upload progress is shown during transfer.

Samples inside a privacy zone are filtered out of uploads, so published maps
never show them (see [markers and zones](markers-and-zones.md)).

## Offline tiles

Map tiles from the current provider are cached on device as you browse, and
the **Download Offline Tiles** action fetches a chosen area for fully offline
use. Note that the public OpenStreetMap and CARTO endpoints used by default
have usage policies about bulk downloading and prefetching - the provider
investigation in the development docs tracks the compliant options.

## Connectivity

An app-wide offline banner detects restricted or unavailable internet access
with a short periodic connectivity check. GPS tracking, radio communication,
and local sample storage continue while offline; tile loading and uploads
will not.
