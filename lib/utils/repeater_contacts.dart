import 'package:latlong2/latlong.dart';

import '../models/models.dart';

/// Merge repeater contacts into a single list for pickers such as the
/// Carpeater target repeater selector.
///
/// Later [positioned] entries win over earlier ones and over [nameOnly]
/// stubs, which use the (0, 0) unknown-position sentinel. The result is
/// sorted by advertised name (case-insensitive, unnamed contacts last),
/// then by repeater ID.
List<Repeater> mergeRepeaterContacts({
  required Map<String, String> nameOnly,
  required Iterable<Repeater> positioned,
}) {
  final merged = <String, Repeater>{
    for (final entry in nameOnly.entries)
      entry.key: Repeater(
        id: entry.key,
        position: const LatLng(0, 0),
        name: entry.value,
      ),
    for (final repeater in positioned) repeater.id: repeater,
  };
  final repeaters = merged.values.toList()..sort(compareRepeaterContacts);
  return List.unmodifiable(repeaters);
}

int compareRepeaterContacts(Repeater a, Repeater b) {
  final nameA = a.name?.toLowerCase();
  final nameB = b.name?.toLowerCase();
  if (nameA != null && nameB != null) {
    final byName = nameA.compareTo(nameB);
    if (byName != 0) return byName;
  } else if (nameA != null) {
    return -1;
  } else if (nameB != null) {
    return 1;
  }
  return a.id.compareTo(b.id);
}
