/// Basemap tile templates shared by the live map layer and offline tile
/// downloads, so both always fetch from the same providers.
const String osmTileUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Carto dark raster tiles; requires [cartoDarkSubdomains] for `{s}`.
const String cartoDarkTileUrlTemplate =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

/// Subdomain pool used by [cartoDarkTileUrlTemplate]'s `{s}` placeholder.
const List<String> cartoDarkSubdomains = <String>['a', 'b', 'c', 'd'];

/// Tile URL template matching the [dark] map mode.
String tileUrlTemplate({required bool dark}) =>
    dark ? cartoDarkTileUrlTemplate : osmTileUrlTemplate;
