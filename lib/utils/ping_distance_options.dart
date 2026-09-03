import 'package:flutter/material.dart';

class PingDistanceOptions {
  const PingDistanceOptions._();

  static const List<double> presets = [50.0, 200.0, 400.0, 805.0, 1609.0];

  static List<double> valuesFor(double current) {
    final values = <double>{...presets, current}.toList()..sort();
    return values;
  }

  static String labelFor(double meters) {
    if (meters == 805.0) return '0.5mi';
    if (meters == 1609.0) return '1mi';
    if (meters == meters.roundToDouble()) {
      return '${meters.toInt()}m';
    }
    return '${meters}m';
  }

  static List<DropdownMenuItem<double>> menuItems(double current) {
    return [
      for (final value in valuesFor(current))
        DropdownMenuItem<double>(
          value: value,
          child: Text(labelFor(value), style: const TextStyle(fontSize: 12)),
        ),
    ];
  }
}
