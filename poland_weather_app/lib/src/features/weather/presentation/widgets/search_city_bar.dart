import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/city.dart';
import '../providers/weather_providers.dart';
import 'state_views.dart';

class SearchCityBar extends ConsumerStatefulWidget {
  const SearchCityBar({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
  });

  final City selectedCity;
  final ValueChanged<City> onCitySelected;

  @override
  ConsumerState<SearchCityBar> createState() => _SearchCityBarState();
}

class _SearchCityBarState extends ConsumerState<SearchCityBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedCity.name);
  }

  @override
  void didUpdateWidget(covariant SearchCityBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCity.name != widget.selectedCity.name) {
      _controller.text = widget.selectedCity.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(citySearchResultsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search city in Poland',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  ref.read(citySearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Warsaw, Krakow, Gdansk...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    _controller.clear();
                    ref.read(citySearchQueryProvider.notifier).state = '';
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
            const SizedBox(height: 14),
            searchState.when(
              loading: () =>
                  const _SearchInfo(message: 'Searching Polish cities...'),
              error: (error, _) => const _SearchInfo(
                message: 'Search is temporarily unavailable.',
              ),
              data: (results) {
                final query = ref.watch(citySearchQueryProvider).trim();
                if (query.isEmpty) {
                  return const _SearchInfo(
                    message:
                        'Default city is Warsaw. Start typing to search locations in Poland.',
                  );
                }
                if (results.isEmpty) {
                  return const EmptyStateView(
                    title: 'No matching cities',
                    message: 'Try another Polish city name or a shorter query.',
                    compact: true,
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: results.map((city) {
                    final isSelected =
                        city.name == widget.selectedCity.name &&
                        city.admin1 == widget.selectedCity.admin1;
                    return ChoiceChip(
                      label: Text(city.fullLabel),
                      selected: isSelected,
                      onSelected: (_) {
                        widget.onCitySelected(city);
                        FocusScope.of(context).unfocus();
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchInfo extends StatelessWidget {
  const _SearchInfo({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF66798D)),
    );
  }
}
