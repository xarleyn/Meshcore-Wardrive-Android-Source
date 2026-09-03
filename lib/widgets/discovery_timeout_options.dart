import 'package:flutter/material.dart';

import '../utils/discovery_timeout_options.dart';

class DiscoveryTimeoutDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDense;
  final TextStyle? itemStyle;

  const DiscoveryTimeoutDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDense = true,
    this.itemStyle = const TextStyle(fontSize: 12),
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final item in DiscoveryTimeoutOptions.valuesFor(value))
        DropdownMenuItem<int>(
          value: item,
          child: Text(DiscoveryTimeoutOptions.labelFor(item), style: itemStyle),
        ),
    ];
    final matching = items.where((item) => item.value == value).toList();
    final dropdownValue = matching.length == 1
        ? matching.single.value
        : items.first.value;

    return DropdownButton<int>(
      value: dropdownValue,
      isDense: isDense,
      items: items,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
