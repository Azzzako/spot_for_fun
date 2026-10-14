import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

/// OSM's light tiles turned into an asphalt map: grayscale, inverted and
/// slightly compressed so land sits near #131313 and labels stay light.
const _darkTiles = ColorFilter.matrix(<double>[
  -0.1807, -0.6079, -0.0614, 0, 224.75, //
  -0.1807, -0.6079, -0.0614, 0, 224.75, //
  -0.1807, -0.6079, -0.0614, 0, 224.75, //
  0, 0, 0, 1, 0,
]);

/// The OpenStreetMap tile layer every map in the app uses, darkened.
class UrbanTileLayer extends StatelessWidget {
  const UrbanTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.spotforfun.app',
      tileProvider: NetworkTileProvider(),
      tileBuilder: (context, tile, _) =>
          ColorFiltered(colorFilter: _darkTiles, child: tile),
    );
  }
}

/// OSM's tile policy asks for visible credit on the map.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.asphalt.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        onTap: () => launchUrl(
          Uri.parse('https://www.openstreetmap.org/copyright'),
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            '© OpenStreetMap',
            style: AppTheme.label(10, color: AppColors.boneMuted),
          ),
        ),
      ),
    );
  }
}
