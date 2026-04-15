import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/hourly_forecast.dart';

class HourlyTimelineSelector extends StatelessWidget {
  const HourlyTimelineSelector({
    super.key,
    required this.days,
    required this.selectedDayIndex,
    required this.selectedHourIndex,
    required this.onDaySelected,
    required this.onHourSelected,
  });

  final List<HourlyDayOption> days;
  final int selectedDayIndex;
  final int selectedHourIndex;
  final ValueChanged<int> onDaySelected;
  final ValueChanged<int> onHourSelected;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeDayIndex = selectedDayIndex.clamp(0, days.length - 1);
    final selectedDay = days[safeDayIndex];
    final safeHourIndex = selectedDay.hours.isEmpty
        ? 0
        : selectedHourIndex.clamp(0, selectedDay.hours.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map time controls',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ChoiceChip(
                label: Text(days[index].label),
                selected: safeDayIndex == index,
                onSelected: (_) => onDaySelected(index),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selectedDay.hours.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final hour = selectedDay.hours[index];
              final label = _isToday(hour.time) && index == 0
                  ? 'Now'
                  : DateFormat('HH:mm').format(hour.time);
              return ChoiceChip(
                label: Text(label),
                selected: safeHourIndex == index,
                onSelected: (_) => onHourSelected(index),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }
}

class HourlyDayOption {
  const HourlyDayOption({
    required this.date,
    required this.label,
    required this.hours,
  });

  final DateTime date;
  final String label;
  final List<HourlyForecast> hours;
}
