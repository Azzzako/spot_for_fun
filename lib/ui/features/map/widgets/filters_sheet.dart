import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/data/services/spot_service.dart';
import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/ui/shared/widgets/spot_marker.dart';

enum _ServiceKind { restroom, parking, shade, water }

extension on _ServiceKind {
  IconData get icon => switch (this) {
        _ServiceKind.restroom => Icons.wc_rounded,
        _ServiceKind.parking => Icons.local_parking_rounded,
        _ServiceKind.shade => Icons.beach_access_rounded,
        _ServiceKind.water => Icons.water_drop_rounded,
      };

  String get label => switch (this) {
        _ServiceKind.restroom => 'Baños',
        _ServiceKind.parking => 'Estacionamiento',
        _ServiceKind.shade => 'Sombra',
        _ServiceKind.water => 'Agua',
      };
}

class FiltersSheet extends ConsumerStatefulWidget {
  const FiltersSheet({super.key});

  @override
  ConsumerState<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<FiltersSheet> {
  final Set<_ServiceKind> _services = {};
  double _maxDistance = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(spotFilterProvider);
    final notifier = ref.read(spotFilterProvider.notifier);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.85],
      builder: (context, scrollController) {
        final effectiveScroll = _scrollController.hasClients
            ? _scrollController
            : scrollController;
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Filtros',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  controller: effectiveScroll,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + mediaQuery.viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tipo de spot',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SpotType.values.map((t) {
                          final selected = filter.types.contains(t);
                          final kind = classifySpotKind(t.dbValue);
                          return _TypeChip(
                            label: t.label,
                            icon: spotIconFor(kind),
                            iconColor: spotColorFor(kind, theme.brightness),
                            selected: selected,
                            onTap: () {
                              final next = <SpotType>{...filter.types};
                              if (selected) {
                                next.remove(t);
                              } else {
                                next.add(t);
                              }
                              notifier.state = filter.copyWith(types: next);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text('Dificultad',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SpotDifficulty.values.map((d) {
                          final selected = filter.difficulties.contains(d);
                          return _ChoiceChip(
                            label: d.label,
                            selected: selected,
                            onTap: () {
                              final next =
                                  <SpotDifficulty>{...filter.difficulties};
                              if (selected) {
                                next.remove(d);
                              } else {
                                next.add(d);
                              }
                              notifier.state =
                                  filter.copyWith(difficulties: next);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text('Servicios',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _ServiceKind.values.map((s) {
                          final selected = _services.contains(s);
                          return _TypeChip(
                            label: s.label,
                            icon: s.icon,
                            iconColor: theme.colorScheme.onSurface,
                            selected: selected,
                            onTap: () => setState(() {
                              if (selected) {
                                _services.remove(s);
                              } else {
                                _services.add(s);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Distancia máxima',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            '${_maxDistance.toStringAsFixed(0)} km',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _maxDistance,
                        min: 1,
                        max: 25,
                        divisions: 24,
                        onChanged: (v) => setState(() => _maxDistance = v),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                notifier.state = const SpotFilter();
                                setState(() {
                                  _services.clear();
                                  _maxDistance = 10;
                                });
                              },
                              child: const Text('Limpiar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Aplicar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainer;
    final fg = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? fg : iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
