import 'package:flutter/material.dart';

import '../utils/ping_distance_options.dart';

class PingDistanceDropdown extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const PingDistanceDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = PingDistanceOptions.menuItems(value);
    final matching = items.where((item) => item.value == value).toList();
    final dropdownValue = matching.length == 1
        ? matching.single.value
        : items.first.value;

    return DropdownButton<double>(
      value: dropdownValue,
      isDense: true,
      items: items,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
