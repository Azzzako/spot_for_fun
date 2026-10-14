import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';
import 'package:spot_for_fun/ui/shared/widgets/brand_wordmark.dart';
import 'package:spot_for_fun/ui/shared/widgets/tape_label.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ACERCA DE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const BrandWordmark(size: 52),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: TapeLabel('Encuentra. Explora. Patina.'),
          ),
          const SizedBox(height: 24),
          Text(
            'Spot For Fun es un mapa de spots de skate hecho por y para la '
            'comunidad. Agrega los spots que conoces, califícalos y guarda '
            'tus favoritos. Cada spot nuevo lo revisa el equipo antes de '
            'aparecer en el mapa.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 28),
          Text(
            'CRÉDITOS',
            style: AppTheme.label(12, color: AppColors.boneMuted),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('https://www.openstreetmap.org/copyright'),
              mode: LaunchMode.externalApplication,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: const [
                    TextSpan(text: 'Mapas © '),
                    TextSpan(
                      text: 'colaboradores de OpenStreetMap',
                      style: TextStyle(
                        color: AppColors.tape,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
