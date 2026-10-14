import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:spot_for_fun/ui/core/theme/app_colors.dart';
import 'package:spot_for_fun/ui/core/theme/app_theme.dart';

enum PhotoSource { file }

/// A photo picked on the device, waiting to be uploaded.
class PhotoItem {
  const PhotoItem.file(this.bytes, this.ext) : source = PhotoSource.file;

  final PhotoSource source;
  final Uint8List? bytes;
  final String ext;
}

class PhotoPickerGrid extends StatelessWidget {
  const PhotoPickerGrid({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.maxPhotos = 8,
  });

  final List<PhotoItem> photos;
  final ValueChanged<List<PhotoItem>> onPhotosChanged;
  final int maxPhotos;

  Future<void> _addPhoto(BuildContext context) async {
    if (photos.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo $maxPhotos fotos')),
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 85,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la foto')),
        );
      }
      return;
    }

    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt = switch (ext) {
      'png' || 'webp' || 'jpg' => ext,
      _ => 'jpg',
    };

    if (context.mounted) {
      onPhotosChanged([...photos, PhotoItem.file(bytes, safeExt)]);
    }
  }

  void _removePhoto(int index) {
    onPhotosChanged([...photos]..removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < maxPhotos;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: photos.length + (canAdd ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == photos.length) {
          return Material(
            color: AppColors.concrete,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.lineStrong, width: 1.5),
            ),
            child: InkWell(
              onTap: () => _addPhoto(ctx),
              borderRadius: BorderRadius.circular(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.tape,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text('AGREGAR', style: AppTheme.label(10)),
                ],
              ),
            ),
          );
        }
        final photo = photos[i];
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                photo.bytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.concreteHigh,
                  child: Icon(Icons.broken_image, color: AppColors.boneMuted),
                ),
              ),
            ),
            if (i == 0)
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  color: AppColors.tape,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'PORTADA',
                    style: AppTheme.label(9, color: AppColors.asphalt),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: AppColors.asphalt.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(3),
                  onTap: () => _removePhoto(i),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.bone,
                      semanticLabel: 'Quitar foto',
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
