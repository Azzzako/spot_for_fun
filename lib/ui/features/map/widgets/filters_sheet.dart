import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spot_for_fun/data/repositories/spot_repository.dart';
import 'package:spot_for_fun/data/services/spot_service.dart';
import 'package:spot_for_fun/domain/enums.dart';
import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';
import 'package:spot_for_fun/ui/shared/widgets/spot_marker.dart';
import 'package:spot_for_fun/ui/shared/widgets/urban_chip.dart';

class FiltersSheet extends ConsumerWidget {
  const FiltersSheet({super.key});

  Set<T> _toggled<T>(Set<T> current, T value) {
    final next = <T>{...current};
    if (!next.remove(value)) next.add(value);
    return next;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(spotFilterProvider);
    final notifier = ref.read(spotFilterProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
              child: Row(
                children: [
                  Text('FILTROS', style: AppTheme.display(30)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
                children: [
                  const _SectionLabel('Tipo de spot'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      for (final t in SpotType.values)
                        UrbanChip(
                          label: t.label,
                          icon: spotIconFor(classifySpotKind(t.dbValue)),
                          selected: filter.types.contains(t),
                          onTap: () => notifier.state = filter.copyWith(
                            types: _toggled(filter.types, t),
                          ),
                        ),
                    ],
                  ),
                  const _SectionLabel('Nivel'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      for (final d in SpotDifficulty.values)
                        UrbanChip(
                          label: d.label,
                          selected: filter.difficulties.contains(d),
                          onTap: () => notifier.state = filter.copyWith(
                            difficulties: _toggled(filter.difficulties, d),
                          ),
                        ),
                    ],
                  ),
                  const _SectionLabel('Mejor hora'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      for (final slot in BestTimeSlot.values)
                        UrbanChip(
                          label: slot.label,
                          icon: _iconForSlot(slot),
                          selected: filter.bestTime.contains(slot),
                          onTap: () => notifier.state = filter.copyWith(
                            bestTime: _toggled(filter.bestTime, slot),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => notifier.state = const SpotFilter(),
                          child: const Text('LIMPIAR'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('APLICAR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForSlot(BestTimeSlot slot) {
    return switch (slot) {
      BestTimeSlot.morning => Icons.wb_sunny_outlined,
      BestTimeSlot.midday => Icons.wb_sunny,
      BestTimeSlot.afternoon => Icons.wb_cloudy_outlined,
      BestTimeSlot.evening => Icons.nights_stay_outlined,
      BestTimeSlot.night => Icons.dark_mode_outlined,
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.label(12, color: AppColors.boneMuted),
      ),
    );
  }
}
