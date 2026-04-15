import 'package:flutter/material.dart';

class WeatherMetricChip extends StatelessWidget {
  const WeatherMetricChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final background = dark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFFF2F7FC);
    final textColor = dark ? Colors.white : const Color(0xFF17324D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor.withValues(alpha: dark ? 0.82 : 0.72),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
