import 'package:flutter/material.dart';

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    required this.title,
    required this.icon,
    super.key,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
