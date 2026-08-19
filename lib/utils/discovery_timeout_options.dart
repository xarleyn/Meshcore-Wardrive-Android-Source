import 'package:flutter/material.dart';

class DiscoveryTimeoutOptions {
  const DiscoveryTimeoutOptions._();

  static const List<int> presets = [5, 10, 15, 20, 25, 30];

  static List<int> valuesFor(int current) {
    final values = <int>{...presets, current}.toList()..sort();
    return values;
  }

  static String labelFor(int seconds) => '${seconds}s';

  static List<DropdownMenuItem<int>> menuItems(int current) {
    return [
      for (final value in valuesFor(current))
        DropdownMenuItem<int>(value: value, child: Text(labelFor(value))),
    ];
  }
}

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
