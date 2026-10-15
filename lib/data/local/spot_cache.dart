import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A circle of the map whose spots were downloaded at [fetchedAt].
@immutable
class CachedArea {
  const CachedArea({
    required this.lat,
    required this.lng,
    required this.radiusM,
    required this.fetchedAt,
  });

  final double lat;
  final double lng;
  final double radiusM;
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'radiusM': radiusM,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  static CachedArea fromJson(Map<String, dynamic> json) => CachedArea(
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    radiusM: (json['radiusM'] as num).toDouble(),
    fetchedAt: DateTime.parse(json['fetchedAt'] as String),
  );
}

/// What's on disk: raw spot rows by id (as PostgREST returned them) and
/// the areas already downloaded.
class SpotCacheData {
  SpotCacheData({
    Map<String, Map<String, dynamic>>? rows,
    List<CachedArea>? areas,
  }) : rows = rows ?? {},
       areas = areas ?? [];

  final Map<String, Map<String, dynamic>> rows;
  final List<CachedArea> areas;
}

/// Spots kept on the phone between launches, in one JSON file under the
/// app support directory. Hundreds of spots load in a few ms; if the
/// catalog ever reaches tens of thousands this should move to sqflite.
class SpotCache {
  static const _version = 1;
  static const _fileName = 'spots_cache_v1.json';
  static const maxAreas = 30;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Empty data when there's no cache yet, or it's unreadable / from
  /// another version (it'll simply be downloaded again).
  Future<SpotCacheData> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return SpotCacheData();
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (json['version'] != _version) return SpotCacheData();
      final rows = (json['spots'] as Map<String, dynamic>).map(
        (id, row) => MapEntry(id, (row as Map).cast<String, dynamic>()),
      );
      final areas = (json['areas'] as List)
          .cast<Map<String, dynamic>>()
          .map(CachedArea.fromJson)
          .toList();
      return SpotCacheData(rows: rows, areas: areas);
    } catch (e) {
      debugPrint('[SpotCache] ignoring unreadable cache: $e');
      return SpotCacheData();
    }
  }

  /// Writes to a temp file and renames it, so a crash mid-write never
  /// leaves a half-written cache behind.
  Future<void> save(SpotCacheData data) async {
    try {
      final file = await _file();
      final tmp = File('${file.path}.tmp');
      final areas = data.areas.length > maxAreas
          ? data.areas.sublist(data.areas.length - maxAreas)
          : data.areas;
      await tmp.writeAsString(
        jsonEncode({
          'version': _version,
          'spots': data.rows,
          'areas': [for (final a in areas) a.toJson()],
        }),
      );
      await tmp.rename(file.path);
    } catch (e) {
      debugPrint('[SpotCache] could not save: $e');
    }
  }
}
