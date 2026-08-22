import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../models/models.dart';
import '../../../utils/color_blind_palette.dart';

/// Displays known repeater positions and forwards marker taps to its owner.
class RepeaterLayer extends StatelessWidget {
  const RepeaterLayer({
    super.key,
    required this.repeaters,
    required this.colorBlindMode,
    required this.onRepeaterTap,
  });

  final List<Repeater> repeaters;
  final String colorBlindMode;
  final ValueChanged<Repeater> onRepeaterTap;

  @override
  Widget build(BuildContext context) {
    if (repeaters.isEmpty) return const SizedBox.shrink();

    return MarkerLayer(
      markers: repeaters.map((repeater) {
        return Marker(
          point: repeater.position,
          width: 30,
          height: 30,
          child: GestureDetector(
            onTap: () => onRepeaterTap(repeater),
            child: Icon(
              Icons.cell_tower,
              color: ColorBlindPalette.getRepeaterColor(colorBlindMode),
              size: 30,
            ),
          ),
        );
      }).toList(),
    );
  }
}
