import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { asset, file }

class PhotoItem {
  const PhotoItem.asset(this.assetPath)
      : source = PhotoSource.asset,
        bytes = null,
        ext = 'jpg';

  const PhotoItem.file(this.bytes, this.ext) : source = PhotoSource.file, assetPath = null;

  final PhotoSource source;
  final String? assetPath;
  final Uint8List? bytes;
  final String ext;

  String get displayLabel {
    if (source == PhotoSource.asset) return assetPath!.split('/').last;
    return 'foto.$ext';
  }
}

typedef PhotoPickerCallback = Future<void> Function(PhotoItem photo);

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
        SnackBar(content: Text('Maximo $maxPhotos fotos')),
      );
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galeria'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar'),
              onTap: () => Navigator.of(context).pop(null),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    final picker = ImagePicker();
    XFile? file;
    try {
      if (action == 'camera') {
        file = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 2048,
          imageQuality: 85,
        );
      } else {
        file = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 2048,
          imageQuality: 85,
        );
      }
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
    final safeExt = (ext == 'png' || ext == 'webp' || ext == 'jpeg' || ext == 'jpg')
        ? (ext == 'jpeg' ? 'jpg' : ext)
        : 'jpg';

    final newPhoto = PhotoItem.file(bytes, safeExt);
    if (context.mounted) {
      onPhotosChanged([...photos, newPhoto]);
    }
  }

  void _removePhoto(BuildContext context, int index) {
    final next = [...photos]..removeAt(index);
    onPhotosChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: photos.length + 1,
      itemBuilder: (ctx, i) {
        if (i == photos.length) {
          return InkWell(
            onTap: () => _addPhoto(ctx),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                size: 32,
              ),
            ),
          );
        }
        final photo = photos[i];
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _Thumb(photo: photo),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _removePhoto(ctx, i),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            if (photo.source == PhotoSource.asset)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'demo',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo});
  final PhotoItem photo;

  @override
  Widget build(BuildContext context) {
    if (photo.source == PhotoSource.asset) {
      return Image.asset(
        photo.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: Colors.black12,
          child: const Icon(Icons.broken_image, size: 32),
        ),
      );
    }
    return Image.memory(
      photo.bytes!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Container(
        color: Colors.black12,
        child: const Icon(Icons.broken_image, size: 32),
      ),
    );
  }
}
